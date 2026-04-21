import Foundation

/// Snapshot of split-flow data passed into party games (names + receipt figures).
struct SplitGameSeed: Hashable {
    var memberNames: [String]
    var subtotal: Double
    var tax: Double

    /// Subtotal + tax (tip not included yet — matches “guess the check” before tip step).
    var suggestedBillTotal: Double {
        subtotal + tax
    }
}
