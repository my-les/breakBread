import SwiftUI

struct SplitFlowView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            currentStepView
                .navigationDestination(for: SplitFlowStep.self) { step in
                    stepView(for: step)
                }
        }
        .environment(\.dismissSplitFlow, DismissAction { dismiss() })
        .environment(\.splitFlowNav, SplitFlowNavigation(
            advance: { navPath.append($0) },
            back: { navPath.isEmpty ? dismiss() : navPath.removeLast() },
            finish: { dismiss() }
        ))
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch vm.currentStep {
        case .search: RestaurantSearchView()
        case .party: PartySetupView()
        case .scan: ReceiptCaptureView()
        case .review: ReceiptReviewView()
        case .assign: ItemAssignmentView()
        case .tip: TipTaxView()
        case .quickTip: QuickTipView()
        case .splitEven: SplitEvenView()
        case .summary: SplitSummaryView()
        case .payment: PaymentView()
        case .menuPicker: MenuPickerView(sections: vm.restaurantMenu)
        }
    }

    @ViewBuilder
    private func stepView(for step: SplitFlowStep) -> some View {
        switch step {
        case .menuPicker: MenuPickerView(sections: vm.restaurantMenu)
        case .party: PartySetupView()
        case .scan: ReceiptCaptureView()
        case .review: ReceiptReviewView()
        case .assign: ItemAssignmentView()
        case .tip: TipTaxView()
        case .quickTip: QuickTipView()
        case .splitEven: SplitEvenView()
        case .summary: SplitSummaryView()
        case .payment: PaymentView()
        case .confirmation: PaymentConfirmationView()
        case .gamesHub: SplitGamesHubView()
        }
    }
}

enum SplitFlowStep: Hashable {
    case quickTip, splitEven, menuPicker, party, scan, review, assign, tip, summary, payment, confirmation, gamesHub
}

struct DismissAction {
    let action: () -> Void
    func callAsFunction() { action() }
}

private struct DismissSplitFlowKey: EnvironmentKey {
    static let defaultValue = DismissAction { }
}

struct SplitFlowNavigation {
    var advance: (SplitFlowStep) -> Void = { _ in }
    var back: () -> Void = { }
    var finish: () -> Void = { }
}

private struct SplitFlowNavKey: EnvironmentKey {
    static let defaultValue = SplitFlowNavigation()
}

extension EnvironmentValues {
    var dismissSplitFlow: DismissAction {
        get { self[DismissSplitFlowKey.self] }
        set { self[DismissSplitFlowKey.self] = newValue }
    }

    var splitFlowNav: SplitFlowNavigation {
        get { self[SplitFlowNavKey.self] }
        set { self[SplitFlowNavKey.self] = newValue }
    }
}
