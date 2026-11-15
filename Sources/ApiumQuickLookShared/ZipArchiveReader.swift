import Foundation
import zlib

struct ZipArchiveReader {
    private let data: Data
    private let entries: [Entry]
    private static let maxEntryBytes = 64 * 1024 * 1024

    struct Entry {
        let path: String
        let compressedSize: Int
        let uncompressedSize: Int
        let compressionMethod: UInt16
        let localHeaderOffset: Int
    }

    init(url: URL) throws {
        let bytes = try Data(contentsOf: url, options: [.mappedIfSafe])
        self.data = bytes
        self.entries = try Self.centralDirectoryEntries(in: bytes)
    }

    func readFile(named path: String) throws -> Data? {
        guard let entry = entries.first(where: { Self.normalizedPath($0.path) == Self.normalizedPath(path) }) else {
            return nil
        }
        return try extract(entry: entry)
    }

    func readFirstExistingFile(candidates: [String]) throws -> Data? {
        for candidate in candidates {
            if let entry = entries.first(where: { Self.normalizedPath($0.path) == Self.normalizedPath(candidate) }) {
                return try extract(entry: entry)
            }
        }
        return nil
    }

    func listPaths(withPrefix prefix: String) throws -> [String] {
        entries.map(\.path).filter { Self.normalizedPath($0).hasPrefix(Self.normalizedPath(prefix)) }
    }

    private static func normalizedPath(_ path: String) -> String {
        path.replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/").filter { $0 != "." }.joined(separator: "/").lowercased()
    }

    private static func centralDirectoryEntries(in data: Data) throws -> [Entry] {
        guard data.count >= 22 else { throw PreviewParserError.invalidArchive }
        let start = max(0, data.count - 22 - 0xffff)
        let eocd = (start...(data.count - 22)).reversed().first { offset in
            readUInt32LE(data, at: offset) == 0x06054b50
                && offset + 22 + Int(readUInt16LE(data, at: offset + 20)) == data.count
        }
        guard let end = eocd,
              readUInt16LE(data, at: end + 4) == 0,
              readUInt16LE(data, at: end + 6) == 0,
              readUInt16LE(data, at: end + 8) == readUInt16LE(data, at: end + 10)
        else { throw PreviewParserError.invalidArchive }
        let count = Int(readUInt16LE(data, at: end + 10))
        let directorySize = Int(readUInt32LE(data, at: end + 12))
        var cursor = Int(readUInt32LE(data, at: end + 16))
        let directoryEnd = cursor + directorySize
        guard count != 0xffff, directoryEnd <= end else { throw PreviewParserError.invalidArchive }
        var entries: [Entry] = []
        for _ in 0..<count {
            guard cursor + 46 <= directoryEnd, readUInt32LE(data, at: cursor) == 0x02014b50 else {
                throw PreviewParserError.invalidArchive
            }
            let nameLength = Int(readUInt16LE(data, at: cursor + 28))
            let next = cursor + 46 + nameLength + Int(readUInt16LE(data, at: cursor + 30))
                + Int(readUInt16LE(data, at: cursor + 32))
            guard next <= directoryEnd, readUInt16LE(data, at: cursor + 8) & 1 == 0 else {
                throw PreviewParserError.invalidArchive
            }
            let name = String(decoding: data[(cursor + 46)..<(cursor + 46 + nameLength)], as: UTF8.self)
            entries.append(Entry(path: name,
                                 compressedSize: Int(readUInt32LE(data, at: cursor + 20)),
                                 uncompressedSize: Int(readUInt32LE(data, at: cursor + 24)),
                                 compressionMethod: readUInt16LE(data, at: cursor + 10),
                                 localHeaderOffset: Int(readUInt32LE(data, at: cursor + 42))))
            cursor = next
        }
        return entries
    }

    private func extract(entry: Entry) throws -> Data {
        let localOffset = entry.localHeaderOffset
        guard localOffset + 30 <= data.count, entry.uncompressedSize <= Self.maxEntryBytes,
              entry.compressedSize <= Self.maxEntryBytes else { throw PreviewParserError.invalidArchive }
        let signature = Self.readUInt32LE(data, at: localOffset)
        guard signature == 0x04034b50 else {
            throw PreviewParserError.invalidArchive
        }

        let fileNameLength = Int(Self.readUInt16LE(data, at: localOffset + 26))
        let extraLength = Int(Self.readUInt16LE(data, at: localOffset + 28))
        let dataStart = localOffset + 30 + fileNameLength + extraLength
        let dataEnd = dataStart + entry.compressedSize
        guard dataStart >= 0, dataEnd <= data.count, dataEnd >= dataStart else {
            throw PreviewParserError.invalidArchive
        }

        let payload = data.subdata(in: dataStart..<dataEnd)

        switch entry.compressionMethod {
        case 0:
            guard payload.count == entry.uncompressedSize else { throw PreviewParserError.invalidArchive }
            return payload
        case 8:
            return try inflateRawDeflate(payload, expectedSize: entry.uncompressedSize)
        default:
            throw PreviewParserError.invalidArchive
        }
    }

    private func inflateRawDeflate(_ data: Data, expectedSize: Int) throws -> Data {
        var stream = z_stream()
        var result = Data()
        let chunkSize = 64 * 1024
        result.reserveCapacity(max(expectedSize, chunkSize))

        var status = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else {
            throw PreviewParserError.invalidArchive
        }

        defer {
            inflateEnd(&stream)
        }

        status = data.withUnsafeBytes { inBytes -> Int32 in
            guard let inBase = inBytes.baseAddress else { return Z_DATA_ERROR }
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inBase.assumingMemoryBound(to: Bytef.self))
            stream.avail_in = uInt(data.count)

            var outBuffer = [UInt8](repeating: 0, count: chunkSize)

            while true {
                let code: Int32 = outBuffer.withUnsafeMutableBufferPointer { outPtr in
                    guard let outBase = outPtr.baseAddress else { return Z_BUF_ERROR }
                    stream.next_out = UnsafeMutablePointer<Bytef>(outBase)
                    stream.avail_out = uInt(chunkSize)
                    return inflate(&stream, Z_NO_FLUSH)
                }

                let produced = chunkSize - Int(stream.avail_out)
                if produced > 0 {
                    guard result.count + produced <= expectedSize else { return Z_DATA_ERROR }
                    result.append(outBuffer, count: produced)
                }

                if code == Z_STREAM_END {
                    return Z_STREAM_END
                }

                if code != Z_OK {
                    return code
                }

                if stream.avail_in == 0 && produced == 0 {
                    return Z_DATA_ERROR
                }
            }
        }

        guard status == Z_STREAM_END, result.count == expectedSize else {
            throw PreviewParserError.invalidArchive
        }

        return result
    }

    private static func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
        let b0 = UInt16(data[offset])
        let b1 = UInt16(data[offset + 1]) << 8
        return b0 | b1
    }

    private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        let b0 = UInt32(data[offset])
        let b1 = UInt32(data[offset + 1]) << 8
        let b2 = UInt32(data[offset + 2]) << 16
        let b3 = UInt32(data[offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }
}
