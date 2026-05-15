import SwiftUI

@main
struct ApiumQuickLookHostApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 10) {
                Text("Apium QuickLook Host")
                    .font(.title2)
                Text("Install this app to register embedded Quick Look extensions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(minWidth: 420, minHeight: 220)
        }
    }
}
