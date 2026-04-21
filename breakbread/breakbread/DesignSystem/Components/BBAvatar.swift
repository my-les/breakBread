import SwiftUI

struct BBAvatar: View {
    let name: String
    var size: CGFloat = 44
    var isSelected: Bool = false

    private var initial: String {
        String(name.prefix(1)).uppercased()
    }

    private var backgroundColor: Color {
        let colors: [Color] = [
            Color(hex: "FF385C"),
            Color(hex: "00A699"),
            Color(hex: "FC642D"),
            Color(hex: "484848"),
            Color(hex: "767676"),
            Color(hex: "008A05"),
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Text(initial)
                .font(BBFont.courier(size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .overlay {
            if isSelected {
                Circle()
                    .strokeBorder(BBColor.success, lineWidth: 2.5)
                    .frame(width: size + 4, height: size + 4)
            }
        }
    }
}

struct BBAvatarRow: View {
    let members: [PartyMember]
    var selectedId: UUID?
    var size: CGFloat = 44
    var onTap: ((PartyMember) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BBSpacing.sm) {
                ForEach(members) { member in
                    VStack(spacing: 4) {
                        BBAvatar(
                            name: member.name,
                            size: size,
                            isSelected: member.id == selectedId
                        )
                        Text(member.name.components(separatedBy: " ").first ?? member.name)
                            .font(BBFont.small)
                            .foregroundStyle(BBColor.secondaryText)
                            .lineLimit(1)
                    }
                    .onTapGesture { onTap?(member) }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack {
            BBAvatar(name: "Alice")
            BBAvatar(name: "Bob", isSelected: true)
            BBAvatar(name: "Charlie")
        }
        BBAvatarRow(members: [
            PartyMember(name: "Alice"),
            PartyMember(name: "Bob"),
            PartyMember(name: "Charlie"),
        ])
    }
    .padding()
}
