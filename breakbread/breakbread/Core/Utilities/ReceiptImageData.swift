import CoreGraphics
import Foundation
import ImageIO
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum ReceiptImageData {
    /// Decodes image bytes to a `CGImage` for OCR and previews on iOS and macOS.
    static func cgImage(from data: Data) -> CGImage? {
        #if canImport(UIKit)
        if let ui = UIImage(data: data), let cg = ui.cgImage {
            return cg
        }
        #endif
        #if canImport(AppKit)
        if let ns = NSImage(data: data) {
            var rect = CGRect(origin: .zero, size: ns.size)
            if let cg = ns.cgImage(forProposedRect: &rect, context: nil, hints: nil) {
                return cg
            }
        }
        #endif
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }
}
