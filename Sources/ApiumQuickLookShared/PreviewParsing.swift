import Foundation

public protocol PreviewParsing {
    func parse(url: URL) throws -> PreviewMetadata
}

public enum PreviewParserError: Error {
    case unsupportedFileType
    case unreadableFile
    case invalidArchive
}
