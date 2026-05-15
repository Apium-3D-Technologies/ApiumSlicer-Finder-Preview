import QuickLookThumbnailing
import CoreGraphics
import CoreText
import UniformTypeIdentifiers
import Foundation

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        do {
            let metadata = try PreviewParserFactory.parse(url: request.fileURL)
            // Use the actual drawing canvas from CoreGraphics. Some hosts provide a clip rect
            // that differs from request.maximumSize, which can otherwise produce tiny corner renders.
            let targetSize = request.maximumSize

            if let image = metadata.previewImage {
                let reply = QLThumbnailReply(contextSize: targetSize) { context in
                    let canvas = context.boundingBoxOfClipPath
                    let rect = canvas.isEmpty ? CGRect(origin: .zero, size: targetSize) : canvas
                    let drawRect = Self.aspectFitRect(for: image, in: rect)
                    context.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
                    context.fill(rect)
                    context.interpolationQuality = .high
                    context.draw(image, in: drawRect)
                    return true
                }
                handler(reply, nil)
                return
            }

            let reply = QLThumbnailReply(contextSize: targetSize) { context in
                let canvas = context.boundingBoxOfClipPath
                let rect = canvas.isEmpty ? CGRect(origin: .zero, size: targetSize) : canvas
                context.setFillColor(CGColor(gray: 0.12, alpha: 1.0))
                context.fill(rect)

                let ext = request.fileURL.pathExtension.uppercased()
                let text = ext.isEmpty ? "APM" : ext
                Self.drawCentered(text: text, in: rect, context: context)
                return true
            }
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }

    private static func drawCentered(text: String, in rect: CGRect, context: CGContext) {
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: CTFontCreateWithName("Menlo-Bold" as CFString, min(rect.width, rect.height) * 0.18, nil),
            kCTForegroundColorAttributeName: CGColor(gray: 0.95, alpha: 1.0)
        ]

        let attributed = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

        context.saveGState()
        context.translateBy(x: rect.midX - bounds.width / 2, y: rect.midY - bounds.height / 2)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func aspectFitRect(for image: CGImage, in bounds: CGRect) -> CGRect {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        guard width > 0, height > 0, bounds.width > 0, bounds.height > 0 else {
            return bounds
        }

        let scale = min(bounds.width / width, bounds.height / height)
        let drawSize = CGSize(width: width * scale, height: height * scale)
        let origin = CGPoint(
            x: bounds.midX - drawSize.width / 2,
            y: bounds.midY - drawSize.height / 2
        )
        return CGRect(origin: origin, size: drawSize)
    }
}
