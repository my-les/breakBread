import Contacts
import SwiftUI

@Observable
class ContactsService {
    static let shared = ContactsService()

    var authorizationStatus: CNAuthorizationStatus
    var contacts: [PartyMember] = []
    var isLoading = false

    init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func refreshAuthStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() async -> Bool {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
            }
            if granted {
                await loadContacts()
            }
            return granted
        } catch {
            await MainActor.run {
                refreshAuthStatus()
            }
            return false
        }
    }

    func loadContacts() async {
        await MainActor.run { isLoading = true }

        let store = CNContactStore()
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
        ] as [CNKeyDescriptor]

        var results: [PartyMember] = []
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                let phone = contact.phoneNumbers.first?.value.stringValue
                results.append(PartyMember(name: name, phoneNumber: phone))
            }
        } catch {
            // contacts just won't load
        }

        await MainActor.run {
            contacts = results
            isLoading = false
        }
    }

    func searchContacts(query: String) -> [PartyMember] {
        guard !query.isEmpty else { return contacts }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
}
