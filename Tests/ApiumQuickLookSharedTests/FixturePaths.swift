import Foundation

enum FixturePaths {
    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var gcodeURL: URL {
        repositoryRoot.appendingPathComponent("example/gcode.gcode")
    }

    static var project3mfURL: URL {
        repositoryRoot.appendingPathComponent("example/project.3mf")
    }
}
