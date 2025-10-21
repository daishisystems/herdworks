//
//  FarmDetailView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth

struct FarmDetailView: View {
    @StateObject private var viewModel: FarmDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(store: FarmStore, farm: Farm? = nil) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: FarmDetailViewModel(
            store: store,
            userId: uid,
            farm: farm
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                requiredSection
                optionalSection
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveFarm() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var requiredSection: some View {
        Section {
            // Farm Name
            TextField("Farm Name", text: $viewModel.name)
                .textInputAutocapitalization(.words)
            
            // Company Name
            TextField("Company Name", text: $viewModel.companyName)
                .textInputAutocapitalization(.words)
            
            // Breed
            Picker("Breed", selection: $viewModel.breed) {
                ForEach(SheepBreed.allCases, id: \.self) { breed in
                    Text(breed.displayName).tag(breed)
                }
            }
            
            // Number of Ewes
            TextField("Number of Production Ewes", text: $viewModel.ewesText)
                .keyboardType(.numberPad)
            
            // Size
            TextField("Farm Size (Hectares)", text: $viewModel.sizeText)
                .keyboardType(.decimalPad)
            
        } header: {
            Text("Required Information")
        } footer: {
            Text("These fields are required to create a farm")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var optionalSection: some View {
        Group {
            // Address Section
            Section {
                TextField("Street Address", text: $viewModel.streetAddress)
                    .textInputAutocapitalization(.words)
                
                TextField("City", text: $viewModel.city)
                    .textInputAutocapitalization(.words)
                
                Picker("Province", selection: $viewModel.province) {
                    ForEach(SouthAfricanProvince.allCases, id: \.self) { province in
                        Text(province.displayName).tag(province)
                    }
                }
                
                TextField("Postal Code", text: $viewModel.postalCode)
                    .keyboardType(.numberPad)
                
            } header: {
                Text("Address")
            } footer: {
                Text("Postal code helps us pinpoint your farm's exact location for accurate mapping")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Production Details Section
            Section("Production System") {
                Picker("System Type", selection: $viewModel.productionSystem) {
                    Text("Not Specified").tag(nil as ProductionSystem?)
                    ForEach(ProductionSystem.allCases, id: \.self) { system in
                        Text(system.displayName).tag(system as ProductionSystem?)
                    }
                }
            }
            
            // Business Partners Section
            Section("Business Partners") {
                // Preferred Agent - Dropdown
                Picker("Preferred Agent", selection: $viewModel.preferredAgent) {
                    Text("Not Specified").tag(nil as PreferredAgent?)
                    ForEach(PreferredAgent.allCases, id: \.self) { agent in
                        Text(agent.displayName).tag(agent as PreferredAgent?)
                    }
                }
                
                // Preferred Abattoir - Text Field
                TextField("Preferred Abattoir", text: $viewModel.preferredAbattoir)
                    .textInputAutocapitalization(.words)
                
                // Preferred Veterinarian - Text Field
                TextField("Preferred Veterinarian", text: $viewModel.preferredVeterinarian)
                    .textInputAutocapitalization(.words)
                
                // Co-Op - Dropdown
                Picker("Co-Op", selection: $viewModel.coOp) {
                    Text("Not Specified").tag(nil as CoOp?)
                    ForEach(CoOp.allCases, id: \.self) { coop in
                        Text(coop.displayName).tag(coop as CoOp?)
                    }
                }
            }
        }
    }
}

#Preview {
    FarmDetailView(store: InMemoryFarmStore())
}
