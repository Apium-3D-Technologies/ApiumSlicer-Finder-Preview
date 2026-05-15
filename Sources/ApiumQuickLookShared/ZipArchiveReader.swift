import Foundation
import zlib

struct ZipArchiveReader {
    private let data: Data

    struct Entry {
        let path: String
        let compressedSize: Int
        let uncompressedSize: Int
        let compressionMethod: UInt16
        let localHeaderOffset: Int
    }

    init(url: URL) throws {
        self.data = try Data(contentsOf: url, options: [.mappedIfSafe])
    }

    func readFile(named path: String) throws -> Data? {
        let entries = try centralDirectoryEntries()
        guard let entry = entries.first(where: { $0.path == path }) else {
            return nil
        }
        return try extract(entry: entry)
    }

    func readFirstExistingFile(candidates: [String]) throws -> Data? {
        let entries = try centralDirectoryEntries()
        for candidate in candidates {
            if let entry = entries.first(where: { $0.path == candidate }) {
                return try extract(entry: entry)
            }
        }
        return nil
    }

    func listPaths(withPrefix prefix: String) throws -> [String] {
        try centralDirectoryEntries()
            .map(\.path)
            .filter { $0.hasPrefix(prefix) }
    }

    private func centralDirectoryEntries() throws -> [Entry] {
        let eocdOffset = try findEndOfCentralDirectoryOffset()
        let totalRecords = Int(readUInt16LE(at: eocdOffset + 10))
        let centralDirOffset = Int(readUInt32LE(at: eocdOffset + 16))

        var entries: [Entry] = []
        entries.reserveCapacity(totalRecords)

        var cursor = centralDirOffset
        for _ in 0..<totalRecords {
            let signature = readUInt32LE(at: cursor)
            guard signature == 0x02014b50 else {
                throw PreviewParserError.invalidArchive
            }

            let method = readUInt16LE(at: cursor + 10)
            let compressedSize = Int(readUInt32LE(at: cursor + 20))
            let uncompressedSize = Int(readUInt32LE(at: cursor + 24))
            let fileNameLength = Int(readUInt16LE(at: cursor + 28))
            let extraLength = Int(readUInt16LE(at: cursor + 30))
            let commentLength = Int(readUInt16LE(at: cursor + 32))
            let localHeaderOffset = Int(readUInt32LE(at: cursor + 42))

            let nameStart = cursor + 46
            let nameEnd = nameStart + fileNameLength
            guard nameEnd <= data.count else { throw PreviewParserError.invalidArchive }
            let nameData = data.subdata(in: nameStart..<nameEnd)
            let name = String(data: nameData, encoding: .utf8) ?? ""

            entries.append(
                Entry(
                    path: name,
                    compressedSize: compressedSize,
                    uncompressedSize: uncompressedSize,
                    compressionMethod: method,
                    localHeaderOffset: localHeaderOffset
                )
            )

            cursor = nameEnd + extraLength + commentLength
        }

        return entries
    }

    private func extract(entry: Entry) throws -> Data {
        let localOffset = entry.localHeaderOffset
        let signature = readUInt32LE(at: localOffset)
        guard signature == 0x04034b50 else {
            throw PreviewParserError.invalidArchive
        }

        let fileNameLength = Int(readUInt16LE(at: localOffset + 26))
        let extraLength = Int(readUInt16LE(at: localOffset + 28))
        let dataStart = localOffset + 30 + fileNameLength + extraLength
        let dataEnd = dataStart + entry.compressedSize
        guard dataStart >= 0, dataEnd <= data.count, dataEnd >= dataStart else {
            throw PreviewParserError.invalidArchive
        }

        let payload = data.subdata(in: dataStart..<dataEnd)

        switch entry.compressionMethod {
        case 0:
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

        guard status == Z_STREAM_END else {
            throw PreviewParserError.invalidArchive
        }

        return result
    }

    private func findEndOfCentralDirectoryOffset() throws -> Int {
        let signature: [UInt8] = [0x50, 0x4b, 0x05, 0x06]
        let minimumSize = 22
        guard data.count >= minimumSize else { throw PreviewParserError.invalidArchive }

        let maxCommentLength = 0xFFFF
        let searchStart = max(0, data.count - minimumSize - maxCommentLength)
        let searchRange = searchStart..<(data.count - 3)

        for i in searchRange.reversed() {
            if data[i] == signature[0] && data[i + 1] == signature[1] && data[i + 2] == signature[2] && data[i + 3] == signature[3] {
                return i
            }
        }

        throw PreviewParserError.invalidArchive
    }

    private func readUInt16LE(at offset: Int) -> UInt16 {
        let b0 = UInt16(data[offset])
        let b1 = UInt16(data[offset + 1]) << 8
        return b0 | b1
    }

    private func readUInt32LE(at offset: Int) -> UInt32 {
        let b0 = UInt32(data[offset])
        let b1 = UInt32(data[offset + 1]) << 8
        let b2 = UInt32(data[offset + 2]) << 16
        let b3 = UInt32(data[offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }
}
