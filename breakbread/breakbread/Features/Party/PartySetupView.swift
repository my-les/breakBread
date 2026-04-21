import SwiftUI
import SwiftData

struct PartySetupView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @Query(sort: \SavedParty.lastUsed, order: .reverse) private var savedParties: [SavedParty]

    @State private var showingContacts = false
    @State private var newMemberName = ""
    @State private var showingAddField = false

    var body: some View {
        @Bindable var vm = vm

        VStack(spacing: 0) {
            flowHeader(title: "who's splitting?", step: "step 2 of 6") {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    if !savedParties.isEmpty {
                        recentPartiesSection
                    }
                    partyStepper
                    membersSection
                    addMemberOptions
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.lg)
            }

            Spacer()

            BBButton(title: "continue") {
                ensureMembersMatchCount()
                HapticManager.tap()
                nav.advance(.scan)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.lg)
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            if !vm.members.contains(where: { $0.isCurrentUser }) {
                vm.members.insert(PartyMember(name: "You", isCurrentUser: true), at: 0)
                vm.partyCount = max(vm.partyCount, vm.members.count)
            }
        }
        .sheet(isPresented: $showingContacts) {
            ContactPickerView()
        }
    }

    // MARK: - Recent Parties

    private var recentPartiesSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("recent parties")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BBSpacing.sm) {
                    ForEach(savedParties.prefix(5)) { party in
                        savedPartyChip(party)
                    }
                }
            }
        }
    }

    private func savedPartyChip(_ party: SavedParty) -> some View {
        let members = party.getMembers()

        return Button {
            loadParty(members)
            HapticManager.tap()
        } label: {
            VStack(spacing: BBSpacing.sm) {
                HStack(spacing: -6) {
                    ForEach(members.prefix(3)) { member in
                        BBAvatar(name: member.name, size: 28)
                            .overlay(
                                Circle().strokeBorder(BBColor.cardSurface, lineWidth: 2)
                            )
                    }
                    if members.count > 3 {
                        Text("+\(members.count - 3)")
                            .font(BBFont.small)
                            .foregroundStyle(BBColor.secondaryText)
                            .frame(width: 28, height: 28)
                            .background(BBColor.background)
                            .clipShape(Circle())
                            .overlay(
                                Circle().strokeBorder(BBColor.border, lineWidth: 1)
                            )
                    }
                }

                Text(party.name)
                    .font(BBFont.small)
                    .foregroundStyle(BBColor.primaryText)
                    .lineLimit(1)

                Text("\(members.count) people")
                    .font(BBFont.small)
                    .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.md)
            .padding(.vertical, BBSpacing.sm)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        }
    }

    private func loadParty(_ members: [PartyMember]) {
        vm.members = members
        vm.partyCount = max(2, members.count)
    }

    // MARK: - Party Stepper

    private var partyStepper: some View {
        BBCard {
            HStack {
                Text("party of")
                    .font(BBFont.body)
                    .foregroundStyle(BBColor.primaryText)

                Text("\(vm.partyCount)")
                    .font(BBFont.heroNumber)
                    .foregroundStyle(BBColor.primaryText)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: vm.partyCount)

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        if vm.partyCount > 2 {
                            vm.partyCount -= 1
                            HapticManager.selection()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .foregroundStyle(vm.partyCount > 2 ? BBColor.primaryText : BBColor.border)
                    }

                    Divider().frame(height: 24)

                    Button {
                        vm.partyCount += 1
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .foregroundStyle(BBColor.primaryText)
                    }
                }
                .background(BBColor.background)
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: BBRadius.sm)
                        .strokeBorder(BBColor.border, lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Members List

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            if !vm.members.isEmpty {
                Text("members")
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.secondaryText)
                    .tracking(1)

                ForEach(vm.members) { member in
                    memberRow(member)
                }
            }
        }
    }

    private func memberRow(_ member: PartyMember) -> some View {
        HStack(spacing: BBSpacing.md) {
            BBAvatar(name: member.name, size: 36)

            Text(member.name)
                .font(BBFont.body)
                .foregroundStyle(BBColor.primaryText)

            Spacer()

            if !member.isCurrentUser {
                Button {
                    vm.members.removeAll { $0.id == member.id }
                    vm.partyCount = max(2, vm.members.count)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BBColor.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(BBColor.cardSurface)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, BBSpacing.xs)
    }

    // MARK: - Add Member

    private var addMemberOptions: some View {
        VStack(spacing: BBSpacing.sm) {
            if showingAddField {
                HStack(spacing: BBSpacing.sm) {
                    TextField("name", text: $newMemberName)
                        .font(BBFont.body)
                        .padding(.horizontal, BBSpacing.md)
                        .frame(height: 44)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                        .onSubmit { addManualMember() }

                    Button("add") { addManualMember() }
                        .font(BBFont.captionBold)
                        .foregroundStyle(BBColor.accent)
                        .disabled(newMemberName.isEmpty)
                }
            }

            HStack(spacing: BBSpacing.sm) {
                BBSmallButton("add name", icon: "plus") {
                    showingAddField = true
                }

                BBSmallButton("contacts", icon: "person.crop.circle") {
                    showingContacts = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func addManualMember() {
        guard !newMemberName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let member = PartyMember(name: newMemberName.trimmingCharacters(in: .whitespaces))
        vm.members.append(member)
        vm.partyCount = max(vm.partyCount, vm.members.count)
        newMemberName = ""
        HapticManager.tap()
    }

    private func ensureMembersMatchCount() {
        if !vm.members.contains(where: { $0.isCurrentUser }) {
            vm.members.insert(PartyMember(name: "You", isCurrentUser: true), at: 0)
        }
        while vm.members.count < vm.partyCount {
            let number = vm.members.count
            vm.members.append(PartyMember(name: "Person \(number)"))
        }
    }
}

#Preview {
    PartySetupView()
        .environment(SplitFlowViewModel())
        .modelContainer(for: SavedParty.self, inMemory: true)
}
