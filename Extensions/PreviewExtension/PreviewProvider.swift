import AppKit
import QuickLook
import QuickLookUI
import SwiftUI

final class PreviewViewController: NSViewController, QLPreviewingController {
    private let parseQueue = DispatchQueue(label: "com.apium.quicklook.preview.parse", qos: .userInitiated)

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 640))
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        parseQueue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    handler(PreviewParserError.unreadableFile)
                }
                return
            }

            do {
                let metadata = try PreviewParserFactory.parse(url: url)
                DispatchQueue.main.async {
                    self.view.subviews.forEach { $0.removeFromSuperview() }

                    let hosting = NSHostingController(rootView: QuickLookPreviewView(metadata: metadata))
                    self.addChild(hosting)
                    hosting.view.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addSubview(hosting.view)

                    NSLayoutConstraint.activate([
                        hosting.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        hosting.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        hosting.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                        hosting.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                    ])

                    handler(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    handler(error)
                }
            }
        }
    }
}
