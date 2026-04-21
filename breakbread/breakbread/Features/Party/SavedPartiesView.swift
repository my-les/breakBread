import SwiftUI
import SwiftData
import Contacts

struct SavedPartiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedParty.lastUsed, order: .reverse) private var parties: [SavedParty]

    @State private var showingNewParty = false
    @State private var editingParty: SavedParty?

    var body: some View {
        VStack(spacing: 0) {
            if parties.isEmpty {
                emptyState
            } else {
                partiesList
            }
        }
        .background(BBColor.background)
        .navigationTitle("saved parties")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewParty = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showingNewParty) {
            EditPartySheet(party: nil) { name, members in
                let party = SavedParty(name: name)
                party.setMembers(members)
                modelContext.insert(party)
            }
        }
        .sheet(item: $editingParty) { party in
            EditPartySheet(party: party) { name, members in
                party.name = name
                party.setMembers(members)
                party.lastUsed = .now
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: BBSpacing.lg) {
            Spacer()
            Image(systemName: "person.2.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)
            Text("no saved parties")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            Text("save groups of friends you eat with often")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
                .multilineTextAlignment(.center)
            BBButton(title: "create party") {
                showingNewParty = true
            }
            .padding(.horizontal, BBSpacing.xxl)
            Spacer()
        }
    }

    private var partiesList: some View {
        ScrollView {
            LazyVStack(spacing: BBSpacing.sm) {
                ForEach(parties) { party in
                    Button { editingParty = party } label: {
                        partyRow(party)
                    }
                }
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.top, BBSpacing.md)
        }
    }

    private func partyRow(_ party: SavedParty) -> some View {
        let members = party.getMembers()

        return HStack(spacing: BBSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(party.name)
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.primaryText)

                Text("\(members.count) people")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }

            Spacer()

            HStack(spacing: -8) {
                ForEach(members.prefix(3)) { member in
                    BBAvatar(name: member.name, size: 28)
                        .overlay(
                            Circle().strokeBorder(BBColor.cardSurface, lineWidth: 2)
                        )
                }
            }
        }
        .padding(BBSpacing.md)
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(party)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit / Create Party Sheet

struct EditPartySheet: View {
    @Environment(\.dismiss) private var dismiss

    let party: SavedParty?
    let onSave: (String, [PartyMember]) -> Void

    @State private var partyName = ""
    @State private var members: [PartyMember] = []
    @State private var newMemberName = ""
    @State private var showingContacts = false
    @State private var contactsService = ContactsService.shared

    init(party: SavedParty?, onSave: @escaping (String, [PartyMember]) -> Void) {
        self.party = party
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    BBInputField(label: "PARTY NAME", text: $partyName, placeholder: "friday crew")

                    membersSection
                    addMemberSection
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.md)
            }
            .background(BBColor.background)
            .navigationTitle(party == nil ? "new party" : "edit party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(BBFont.body)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(partyName, members)
                        dismiss()
                    }
                    .font(BBFont.bodyBold)
                    .disabled(partyName.isEmpty)
                }
            }
            .onAppear {
                if let party {
                    partyName = party.name
                    members = party.getMembers()
                }
            }
            .sheet(isPresented: $showingContacts) {
                contactPickerForParty
            }
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("members (\(members.count))")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            if members.isEmpty {
                Text("add people to this party")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            } else {
                ForEach(members) { member in
                    HStack(spacing: BBSpacing.md) {
                        BBAvatar(name: member.name, size: 32)
                        Text(member.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                        Spacer()
                        Button {
                            members.removeAll { $0.id == member.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(BBColor.border)
                        }
                    }
                }
            }
        }
    }

    private var addMemberSection: some View {
        VStack(spacing: BBSpacing.sm) {
            HStack(spacing: BBSpacing.sm) {
                TextField("name", text: $newMemberName)
                    .font(BBFont.body)
                    .padding(.horizontal, BBSpacing.md)
                    .frame(height: 44)
                    .background(BBColor.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                    .onSubmit { addMember() }

                Button("add") { addMember() }
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.accent)
                    .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            BBSmallButton("from contacts", icon: "person.crop.circle") {
                showingContacts = true
            }
        }
    }

    private var contactPickerForParty: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if contactsService.authorizationStatus != .authorized {
                    VStack(spacing: BBSpacing.lg) {
                        Spacer()
                        BBButton(title: "allow contacts access") {
                            Task { _ = await contactsService.requestAccess() }
                        }
                        .padding(.horizontal, BBSpacing.xl)
                        Spacer()
                    }
                } else {
                    List(contactsService.contacts) { contact in
                        Button {
                            if !members.contains(where: { $0.name == contact.name }) {
                                members.append(contact)
                                HapticManager.tap()
                            }
                        } label: {
                            HStack(spacing: BBSpacing.md) {
                                BBAvatar(name: contact.name, size: 32)
                                Text(contact.name)
                                    .font(BBFont.body)
                                    .foregroundStyle(BBColor.primaryText)
                                Spacer()
                                if members.contains(where: { $0.name == contact.name }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BBColor.success)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("add contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") { showingContacts = false }
                        .font(BBFont.bodyBold)
                }
            }
            .task {
                if contactsService.authorizationStatus == .authorized && contactsService.contacts.isEmpty {
                    await contactsService.loadContacts()
                }
            }
        }
    }

    private func addMember() {
        let name = newMemberName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        members.append(PartyMember(name: name))
        newMemberName = ""
        HapticManager.tap()
    }
}

#Preview {
    NavigationStack {
        SavedPartiesView()
    }
    .modelContainer(for: SavedParty.self, inMemory: true)
}
