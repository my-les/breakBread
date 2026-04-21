import SwiftUI
import Contacts

struct ContactPickerView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var contactsService = ContactsService.shared
    @State private var searchText = ""
    @State private var selectedContacts: Set<UUID> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                BBSearchField(text: $searchText, placeholder: "search contacts")
                    .padding(.horizontal, BBSpacing.lg)
                    .padding(.vertical, BBSpacing.md)

                if contactsService.authorizationStatus != .authorized {
                    permissionView
                } else {
                    contactsList
                }
            }
            .background(BBColor.background)
            .navigationTitle("contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(BBFont.body)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add (\(selectedContacts.count))") { addSelected() }
                        .font(BBFont.bodyBold)
                        .disabled(selectedContacts.isEmpty)
                }
            }
        }
        .task {
            contactsService.refreshAuthStatus()
            if contactsService.authorizationStatus == .authorized {
                if contactsService.contacts.isEmpty {
                    await contactsService.loadContacts()
                }
            } else if contactsService.authorizationStatus == .notDetermined {
                _ = await contactsService.requestAccess()
            }
        }
    }

    private var permissionView: some View {
        VStack(spacing: BBSpacing.lg) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(BBColor.secondaryText)
            Text("allow contacts access to quickly add friends to your party")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BBSpacing.xl)
            BBButton(title: "allow access") {
                Task { _ = await contactsService.requestAccess() }
            }
            .padding(.horizontal, BBSpacing.xl)
            Spacer()
        }
    }

    private var contactsList: some View {
        let filtered = contactsService.searchContacts(query: searchText)

        return List(filtered) { contact in
            Button {
                toggleSelection(contact)
            } label: {
                HStack(spacing: BBSpacing.md) {
                    BBAvatar(name: contact.name, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                        if let phone = contact.phoneNumber {
                            Text(phone)
                                .font(BBFont.caption)
                                .foregroundStyle(BBColor.secondaryText)
                        }
                    }

                    Spacer()

                    if selectedContacts.contains(contact.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(BBColor.success)
                    } else {
                        Circle()
                            .strokeBorder(BBColor.border, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    private func toggleSelection(_ contact: PartyMember) {
        HapticManager.selection()
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }

    private func addSelected() {
        let contacts = contactsService.contacts.filter { selectedContacts.contains($0.id) }
        vm.members.append(contentsOf: contacts)
        vm.partyCount = max(vm.partyCount, vm.members.count)
        dismiss()
    }
}

#Preview {
    ContactPickerView()
        .environment(SplitFlowViewModel())
}
