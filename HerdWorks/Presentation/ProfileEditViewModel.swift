import SwiftUI
import FirebaseAuth

@MainActor
final class ProfileEditViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var street: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipCode: String = ""
    @Published var country: String = ""
    
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let store: UserProfileStore
    private let userId: String
    
    init(store: UserProfileStore, userId: String) {
        self.store = store
        self.userId = userId
    }
    
    /// Load existing profile if available
    func loadProfile() async {
        do {
            if let profile = try await store.fetch(userId: userId) {
                // Populate fields with existing data
                firstName = profile.firstName
                lastName = profile.lastName
                email = profile.email
                phoneNumber = profile.phoneNumber
                street = profile.personalAddress.street
                city = profile.personalAddress.city
                state = profile.personalAddress.state
                zipCode = profile.personalAddress.zipCode
                country = profile.personalAddress.country
            } else {
                // New profile - pre-fill email from Firebase Auth
                if let authEmail = Auth.auth().currentUser?.email {
                    email = authEmail
                }
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Validate all fields
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty &&
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty &&
        !country.isEmpty
    }
    
    /// Save profile to Firestore (works offline)
    func saveProfile() async -> Bool {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return false
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let address = Address(
                street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: state.trimmingCharacters(in: .whitespacesAndNewlines),
                zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
                country: country.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            let profile = UserProfile(
                userId: userId,
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                personalAddress: address
            )
            
            try await store.createOrUpdate(profile)
            return true
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
}