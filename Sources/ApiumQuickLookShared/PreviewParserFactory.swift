import Foundation

public enum PreviewParserFactory {
    public static func parse(url: URL) throws -> PreviewMetadata {
        switch url.pathExtension.lowercased() {
        case "gcode":
            return try GCodeParser().parse(url: url)
        case "a3d":
            return try A3DParser().parse(url: url)
        case "stl", "obj":
            return try MeshParser().parse(url: url)
        case "3mf":
            return try ThreeMFParser().parse(url: url)
        default:
            throw PreviewParserError.unsupportedFileType
        }
    }
}
