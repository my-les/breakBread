import SwiftUI

/// Keyboard style for `BBInputField` (UIKit’s `UIKeyboardType` is not available on macOS).
enum BBKeyboardInput: Sendable {
    case `default`
    case decimalPad
}

struct BBSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: BBSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(BBColor.secondaryText)

            TextField(placeholder, text: $text)
                .font(BBFont.body)
                .autocorrectionDisabled()
                #if os(iOS) || os(tvOS) || os(visionOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(BBColor.secondaryText)
                }
            }
        }
        .padding(.horizontal, BBSpacing.md)
        .frame(height: 48)
        .background(BBColor.cardSurface)
        .clipShape(Capsule())
    }
}

struct BBInputField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: BBKeyboardInput = .default

    var body: some View {
        VStack(alignment: .leading, spacing: BBSpacing.xs) {
            Text(label)
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(0.5)

            TextField(placeholder, text: $text)
                .font(BBFont.body)
                .modifier(BBKeyboardModifier(keyboard: keyboard))
                .padding(.horizontal, BBSpacing.md)
                .frame(height: 48)
                .background(BBColor.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        }
    }
}

private struct BBKeyboardModifier: ViewModifier {
    let keyboard: BBKeyboardInput

    func body(content: Content) -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
        switch keyboard {
        case .default:
            content.keyboardType(.default)
        case .decimalPad:
            content.keyboardType(.decimalPad)
        }
        #else
        content
        #endif
    }
}

#Preview {
    VStack(spacing: 24) {
        BBSearchField(text: .constant(""), placeholder: "Search restaurants")
        BBSearchField(text: .constant("Nobu"))
        BBInputField(label: "NAME", text: .constant(""), placeholder: "Enter name")
    }
    .padding()
}
