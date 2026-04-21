#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

enum HapticManager {
    enum ImpactWeight {
        case light, medium, heavy
    }

    enum NotificationKind {
        case success, error, warning
    }

    static func impact(_ weight: ImpactWeight = .medium) {
        #if canImport(UIKit)
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch weight {
        case .light: style = .light
        case .medium: style = .medium
        case .heavy: style = .heavy
        }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #elseif os(macOS)
        if #available(macOS 10.11, *) {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        }
        #endif
    }

    static func notification(_ kind: NotificationKind) {
        #if canImport(UIKit)
        let feedback: UINotificationFeedbackGenerator.FeedbackType
        switch kind {
        case .success: feedback = .success
        case .error: feedback = .error
        case .warning: feedback = .warning
        }
        UINotificationFeedbackGenerator().notificationOccurred(feedback)
        #elseif os(macOS)
        if #available(macOS 10.11, *) {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        }
        #endif
    }

    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #elseif os(macOS)
        if #available(macOS 10.11, *) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
        #endif
    }

    static func tap() {
        impact(.light)
    }

    static func success() {
        notification(.success)
    }

    static func error() {
        notification(.error)
    }
}
