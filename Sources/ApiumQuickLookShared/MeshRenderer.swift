import CoreGraphics
import Foundation
import simd

/// Orthographic, depth-buffered rendering without a GPU or window server.
/// A transparent canvas is shared by Finder thumbnails and Quick Look previews.
enum MeshRenderer {
    static func render(_ mesh: MeshGeometry, size: Int = 512) -> CGImage? {
        guard !mesh.triangles.isEmpty, (16...1024).contains(size) else { return nil }
        let view = simd_normalize(SIMD3<Double>(1, -1, 0.72))
        let right = simd_normalize(simd_cross(SIMD3<Double>(0, 0, 1), view))
        let up = simd_normalize(simd_cross(view, right))
        let light = simd_normalize(SIMD3<Double>(-0.35, -0.45, 0.82))
        var minimum = mesh.vertices[mesh.triangles[0].x]
        var maximum = minimum
        for triangle in mesh.triangles {
            for index in [triangle.x, triangle.y, triangle.z] {
                minimum = simd_min(minimum, mesh.vertices[index])
                maximum = simd_max(maximum, mesh.vertices[index])
            }
        }
        let center = (minimum + maximum) / 2
        let projected = mesh.vertices.map { vertex -> SIMD3<Double> in
            let v = vertex - center
            return SIMD3(simd_dot(v, right), simd_dot(v, up), simd_dot(v, view))
        }
        var minXY = SIMD2<Double>(repeating: .infinity)
        var maxXY = SIMD2<Double>(repeating: -.infinity)
        for triangle in mesh.triangles {
            for index in [triangle.x, triangle.y, triangle.z] {
                let p = SIMD2(projected[index].x, projected[index].y)
                minXY = simd_min(minXY, p)
                maxXY = simd_max(maxXY, p)
            }
        }
        let span = max(maxXY.x - minXY.x, maxXY.y - minXY.y)
        guard span.isFinite, span > 0 else { return nil }
        let scale = Double(size) * 0.88 / span
        let midpoint = (minXY + maxXY) / 2
        let points = projected.map { p in
            SIMD3((p.x - midpoint.x) * scale + Double(size) / 2,
                  (p.y - midpoint.y) * scale + Double(size) / 2, p.z)
        }
        var depth = [Double](repeating: -.infinity, count: size * size)
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        for face in mesh.triangles {
            let a = points[face.x], b = points[face.y], c = points[face.z]
            let denominator = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
            guard abs(denominator) > 1e-8 else { continue }
            let normal = simd_normalize(simd_cross(mesh.vertices[face.y] - mesh.vertices[face.x],
                                                  mesh.vertices[face.z] - mesh.vertices[face.x]))
            let shade = min(1, max(0.22, 0.28 + 0.72 * abs(simd_dot(normal, light))))
            let minX = max(0, min(size - 1, Int(floor(min(a.x, b.x, c.x)))))
            let maxX = max(0, min(size - 1, Int(ceil(max(a.x, b.x, c.x)))))
            let minY = max(0, min(size - 1, Int(floor(min(a.y, b.y, c.y)))))
            let maxY = max(0, min(size - 1, Int(ceil(max(a.y, b.y, c.y)))))
            for y in minY...maxY {
                for x in minX...maxX {
                    let px = Double(x) + 0.5, py = Double(y) + 0.5
                    let w0 = ((b.y - c.y) * (px - c.x) + (c.x - b.x) * (py - c.y)) / denominator
                    let w1 = ((c.y - a.y) * (px - c.x) + (a.x - c.x) * (py - c.y)) / denominator
                    let w2 = 1 - w0 - w1
                    guard min(w0, w1, w2) >= -1e-6 else { continue }
                    let z = w0 * a.z + w1 * b.z + w2 * c.z
                    let index = (size - y - 1) * size + x
                    guard z > depth[index] else { continue }
                    depth[index] = z
                    pixels[index * 4] = UInt8(215 * shade)
                    pixels[index * 4 + 1] = UInt8(25 * shade)
                    pixels[index * 4 + 2] = UInt8(32 * shade)
                    pixels[index * 4 + 3] = 255
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
