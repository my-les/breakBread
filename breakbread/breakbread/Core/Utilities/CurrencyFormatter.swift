import Foundation

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static func format(_ amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    static func formatShort(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }

    static func formatCompact(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.1fk", amount / 1000)
        }
        return formatShort(amount)
    }
}
