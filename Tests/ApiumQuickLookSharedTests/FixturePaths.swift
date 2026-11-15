import Foundation

enum FixturePaths {
    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var gcodeURL: URL {
        repositoryRoot.appendingPathComponent("Tests/ApiumQuickLookSharedTests/Fixtures/sample.gcode")
    }

    static var project3mfURL: URL {
        repositoryRoot.appendingPathComponent("Tests/ApiumQuickLookSharedTests/Fixtures/project.3mf")
    }
}
