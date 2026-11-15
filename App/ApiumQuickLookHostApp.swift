import SwiftUI

@main
struct ApiumQuickLookHostApp: App {
    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return "Version \(version) (Build \(build))"
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 10) {
                Text("Apium QuickLook Host")
                    .font(.title2)
                Text(versionDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Install this app to register embedded Quick Look extensions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(minWidth: 420, minHeight: 220)
        }
    }
}
