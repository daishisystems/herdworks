import SwiftUI
import FirebaseAuth

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: ProfileEditViewModel
    
    init(store: UserProfileStore) {
        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: ProfileEditViewModel(store: store, userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Personal Information Section
                Section {
                    TextField("profile_edit.first_name".localized(), text: $viewModel.firstName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                    
                    TextField("profile_edit.last_name".localized(), text: $viewModel.lastName)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                    
                    TextField("profile_edit.email".localized(), text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField("profile_edit.phone_number".localized(), text: $viewModel.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                } header: {
                    Text("profile_edit.personal_info".localized())
                } footer: {
                    Text("profile_edit.personal_info_footer".localized())
                }
                
                // Address Section
                Section {
                    TextField("profile_edit.street_address".localized(), text: $viewModel.street)
                        .textContentType(.streetAddressLine1)
                    
                    TextField("profile_edit.city".localized(), text: $viewModel.city)
                        .textContentType(.addressCity)
                    
                    TextField("profile_edit.state_province".localized(), text: $viewModel.state)
                        .textContentType(.addressState)
                    
                    HStack {
                        TextField("profile_edit.zip_code".localized(), text: $viewModel.zipCode)
                            .textContentType(.postalCode)
                            .keyboardType(.numbersAndPunctuation)
                        
                        TextField("profile_edit.country".localized(), text: $viewModel.country)
                            .textContentType(.countryName)
                    }
                } header: {
                    Text("profile_edit.personal_address".localized())
                } footer: {
                    Text("profile_edit.personal_address_footer".localized())
                }
                
                // Validation Feedback
                if !viewModel.isValid {
                    Section {
                        Label("profile_edit.fill_required_fields".localized(), systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("profile_edit.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
                        Task {
                            if await viewModel.saveProfile() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                    .fontWeight(.semibold)
                }
            }
            .disabled(viewModel.isSaving)
            .overlay {
                if viewModel.isSaving {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        ProgressView("profile_edit.saving".localized())
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .task {
                await viewModel.loadProfile()
            }
        }
    }
}

#Preview("New Profile") {
    ProfileEditView(store: InMemoryUserProfileStore())
        .environmentObject(LanguageManager.shared)
}

#Preview("Existing Profile") {
    let store = InMemoryUserProfileStore()
    
    // Seed with sample data
    Task {
        let sampleProfile = UserProfile(
            userId: "preview-user",
            firstName: "Paul",
            lastName: "Mooney",
            email: "paul@herdworks.com",
            phoneNumber: "+27 82 123 4567",
            personalAddress: Address(
                street: "123 Farm Road",
                city: "Saldanha",
                state: "Western Cape",
                zipCode: "7395",
                country: "South Africa"
            )
        )
        try? await store.createOrUpdate(sampleProfile)
    }
    
    return ProfileEditView(store: store)
        .environmentObject(LanguageManager.shared)
}
