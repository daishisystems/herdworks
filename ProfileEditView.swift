import SwiftUI
import FirebaseAuth

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
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
                    TextField("First Name", text: $viewModel.firstName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                    
                    TextField("Last Name", text: $viewModel.lastName)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField("Phone Number", text: $viewModel.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Personal Information")
                } footer: {
                    Text("This information will be used for your account.")
                }
                
                // Address Section
                Section {
                    TextField("Street Address", text: $viewModel.street)
                        .textContentType(.streetAddressLine1)
                    
                    TextField("City", text: $viewModel.city)
                        .textContentType(.addressCity)
                    
                    TextField("State/Province", text: $viewModel.state)
                        .textContentType(.addressState)
                    
                    HStack {
                        TextField("ZIP Code", text: $viewModel.zipCode)
                            .textContentType(.postalCode)
                            .keyboardType(.numbersAndPunctuation)
                        
                        TextField("Country", text: $viewModel.country)
                            .textContentType(.countryName)
                    }
                } header: {
                    Text("Personal Address")
                } footer: {
                    Text("Your home address (separate from farm locations).")
                }
                
                // Validation Feedback
                if !viewModel.isValid {
                    Section {
                        Label("Please fill in all required fields", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
                        
                        ProgressView("Saving...")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
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
}
