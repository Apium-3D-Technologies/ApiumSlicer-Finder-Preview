import Foundation
import CoreGraphics
import simd

public struct MeshDetails {
    public let format: String
    public let dimensions: SIMD3<Double>
    public let vertexCount: Int
    public let faceCount: Int
    public let triangleCount: Int
    public let fileSize: Int
}

struct MeshGeometry {
    var vertices: [SIMD3<Double>] = []
    var triangles: [SIMD3<Int>] = []
    var faceCount = 0
}

public struct MeshParser: PreviewParsing {
    private static let maxBytes = 256 * 1024 * 1024
    private static let maxTriangles = 1_000_000
    public init() {}

    public func parse(url: URL) throws -> PreviewMetadata {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        guard try handle.seekToEnd() <= Self.maxBytes else { throw PreviewParserError.invalidMesh }
        try handle.seek(toOffset: 0)
        let data = try handle.readToEnd() ?? Data()
        let (mesh, format) = try geometry(data: data, extension: url.pathExtension.lowercased())
        var minimum = mesh.vertices[mesh.triangles[0].x]
        var maximum = minimum
        for face in mesh.triangles {
            for index in [face.x, face.y, face.z] {
                minimum = simd_min(minimum, mesh.vertices[index])
                maximum = simd_max(maximum, mesh.vertices[index])
            }
        }
        var metadata = PreviewMetadata(previewImage: MeshRenderer.render(mesh), isApiumFile: false)
        metadata.mesh = MeshDetails(format: format, dimensions: maximum - minimum,
                                    vertexCount: Set(mesh.vertices).count, faceCount: mesh.faceCount,
                                    triangleCount: mesh.triangles.count, fileSize: data.count)
        return metadata
    }

    func geometry(data: Data, extension ext: String) throws -> (MeshGeometry, String) {
        guard !data.isEmpty, data.count <= Self.maxBytes else { throw PreviewParserError.invalidMesh }
        var mesh = MeshGeometry()
        func add(_ a: Int, _ b: Int, _ c: Int) throws {
            guard mesh.triangles.count < Self.maxTriangles else { throw PreviewParserError.invalidMesh }
            let normal = simd_cross(mesh.vertices[b] - mesh.vertices[a], mesh.vertices[c] - mesh.vertices[a])
            if simd_length(normal) > 1e-8 { mesh.triangles.append(SIMD3(a, b, c)) }
        }
        if ext == "stl", data.count >= 84 {
            func uint(_ offset: Int) -> UInt32 {
                (0..<4).reduce(UInt32(0)) { $0 | UInt32(data[offset + $1]) << (8 * $1) }
            }
            let count = Int(uint(80))
            if 84 + count * 50 == data.count {
                guard count <= Self.maxTriangles else { throw PreviewParserError.invalidMesh }
                for face in 0..<count {
                    let start = mesh.vertices.count
                    for vertex in 0..<3 {
                        let offset = 84 + face * 50 + 12 + vertex * 12
                        let point = SIMD3<Double>(Double(Float(bitPattern: uint(offset))),
                                                  Double(Float(bitPattern: uint(offset + 4))),
                                                  Double(Float(bitPattern: uint(offset + 8))))
                        guard point.x.isFinite, point.y.isFinite, point.z.isFinite else { throw PreviewParserError.invalidMesh }
                        mesh.vertices.append(point)
                    }
                    try add(start, start + 1, start + 2)
                }
                mesh.faceCount = mesh.triangles.count
                guard !mesh.triangles.isEmpty else { throw PreviewParserError.invalidMesh }
                return (mesh, "STL Binary")
            }
        }
        guard let text = String(data: data, encoding: .utf8) else { throw PreviewParserError.invalidMesh }
        var stlVertices: [Int] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard let token = parts.first else { continue }
            if (ext == "obj" && token == "v") || (ext == "stl" && token.lowercased() == "vertex") {
                guard parts.count >= 4, let x = Double(parts[1]), let y = Double(parts[2]), let z = Double(parts[3]),
                      x.isFinite, y.isFinite, z.isFinite, max(abs(x), abs(y), abs(z)) <= 1e12, mesh.vertices.count < 3 * Self.maxTriangles else {
                    throw PreviewParserError.invalidMesh
                }
                mesh.vertices.append(SIMD3(x, y, z))
                if ext == "stl" {
                    stlVertices.append(mesh.vertices.count - 1)
                    if stlVertices.count == 3 {
                        try add(stlVertices[0], stlVertices[1], stlVertices[2])
                        stlVertices.removeAll(keepingCapacity: true)
                        mesh.faceCount += 1
                    }
                }
            } else if ext == "obj", token == "f" {
                var indices: [Int] = []
                for part in parts.dropFirst() {
                    guard let value = part.split(separator: "/", omittingEmptySubsequences: false).first.flatMap({ Int($0) }), value != 0 else {
                        throw PreviewParserError.invalidMesh
                    }
                    let index = value > 0 ? value - 1 : mesh.vertices.count + value
                    guard mesh.vertices.indices.contains(index) else { throw PreviewParserError.invalidMesh }
                    indices.append(index)
                }
                guard indices.count >= 3 else { throw PreviewParserError.invalidMesh }
                for i in 1..<(indices.count - 1) { try add(indices[0], indices[i], indices[i + 1]) }
                mesh.faceCount += 1
            }
        }
        guard !mesh.triangles.isEmpty, stlVertices.isEmpty else { throw PreviewParserError.invalidMesh }
        return (mesh, ext == "obj" ? "OBJ" : "STL ASCII")
    }
}
