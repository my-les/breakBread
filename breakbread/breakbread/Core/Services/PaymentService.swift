#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import UserNotifications

enum RequestMethod: String, CaseIterable, Identifiable {
    case venmo = "Venmo"
    case cashApp = "Cash App"
    case iMessage = "iMessage"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .venmo: return "v.circle.fill"
        case .cashApp: return "dollarsign.circle.fill"
        case .iMessage: return "message.fill"
        case .other: return "square.and.arrow.up"
        }
    }
}

@Observable
class PaymentService {
    static let shared = PaymentService()

    func openVenmo(username: String, amount: Double, note: String) {
        let encodedNote = note.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let txn = "charge"
        let urlString = "venmo://paycharge?txn=\(txn)&recipients=\(username)&amount=\(String(format: "%.2f", amount))&note=\(encodedNote)"

        if let url = URL(string: urlString), PlatformLink.canOpen(url) {
            PlatformLink.open(url)
        } else if let appStore = URL(string: "https://apps.apple.com/app/venmo/id351727428") {
            PlatformLink.open(appStore)
        }
    }

    func openCashApp(username: String, amount: Double) {
        let urlString = "cashapp://cash.app/\(username)?amount=\(String(format: "%.2f", amount))"

        if let url = URL(string: urlString), PlatformLink.canOpen(url) {
            PlatformLink.open(url)
        } else if let appStore = URL(string: "https://apps.apple.com/app/cash-app/id711923939") {
            PlatformLink.open(appStore)
        }
    }

    func openIMessage(amount: Double, note: String) {
        let body = "\(note) — \(CurrencyFormatter.formatShort(amount))"
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:&body=\(encoded)") {
            PlatformLink.open(url)
        }
    }

    func shareRequest(amount: Double, note: String) {
        let text = "\(note)\nAmount: \(CurrencyFormatter.formatShort(amount))\n\nSent via breakbread."
        #if canImport(UIKit)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Open URLs (iOS: UIKit / macOS: AppKit)

private enum PlatformLink {
    static func open(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    static func canOpen(_ url: URL) -> Bool {
        #if canImport(UIKit)
        UIApplication.shared.canOpenURL(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.urlForApplication(toOpen: url) != nil
        #else
        false
        #endif
    }
}

// MARK: - Push Notification Reminders

@Observable
class ReminderService {
    static let shared = ReminderService()

    var isAuthorized = false

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func scheduleReminder(
        for memberName: String,
        amount: Double,
        restaurantName: String?,
        delayMinutes: Int = 60
    ) {
        let content = UNMutableNotificationContent()
        content.title = "breakbread. reminder"
        content.body = "\(memberName) still owes \(CurrencyFormatter.formatShort(amount))"
        if let name = restaurantName {
            content.body += " for \(name)"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delayMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "reminder-\(memberName)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyReminder(
        for memberName: String,
        amount: Double,
        restaurantName: String?
    ) {
        let content = UNMutableNotificationContent()
        content.title = "breakbread. reminder"
        content.body = "\(memberName) still owes \(CurrencyFormatter.formatShort(amount))"
        if let name = restaurantName {
            content.body += " for \(name)"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let id = "daily-reminder-\(memberName)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for memberName: String) {
        let id = "daily-reminder-\(memberName)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
