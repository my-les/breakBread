import SwiftUI

struct BBCard<Content: View>: View {
    var padding: CGFloat = BBSpacing.md
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
    }
}

struct BBCardOutlined<Content: View>: View {
    var padding: CGFloat = BBSpacing.md
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BBColor.background)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: BBRadius.lg)
                .strokeBorder(BBColor.border, lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BBCard {
            Text("Card content")
                .font(BBFont.body)
        }
        BBCardOutlined {
            Text("Outlined card")
                .font(BBFont.body)
        }
    }
    .padding()
}
