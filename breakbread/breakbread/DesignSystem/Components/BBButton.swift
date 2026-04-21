import SwiftUI

struct BBButton: View {
    let title: String
    var style: Style = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BBSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    Text(title)
                        .font(BBFont.button)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: BBRadius.md)
                        .strokeBorder(BBColor.border, lineWidth: 1)
                }
            }
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.4 : 1)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return BBColor.accent
        case .secondary: return .clear
        case .destructive: return BBColor.error
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return BBColor.onAccent
        case .secondary: return BBColor.primaryText
        case .destructive: return .white
        }
    }
}

struct BBSmallButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(BBFont.captionBold)
                    .tracking(0.5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(BBColor.primaryText)
            .background(BBColor.cardSurface)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BBButton(title: "Submit", action: {})
        BBButton(title: "Cancel", style: .secondary, action: {})
        BBButton(title: "Loading...", isLoading: true, action: {})
        BBButton(title: "Disabled", isDisabled: true, action: {})
        BBSmallButton("Add item", icon: "plus", action: {})
    }
    .padding()
}
