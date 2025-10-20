//
//  FarmDetailView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth

struct FarmDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FarmDetailViewModel
    
    init(store: FarmStore, farm: Farm? = nil) {
        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: FarmDetailViewModel(store: store, userId: userId, farm: farm))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Required Fields Section
                Section {
                    TextField("Farm Name", text: $viewModel.name)
                        .font(.title3)
                        .textContentType(.organizationName)
                        .autocorrectionDisabled()
                    
                    Picker("Breed", selection: $viewModel.breed) {
                        ForEach(SheepBreed.allCases, id: \.self) { breed in
                            Text(breed.displayName).tag(breed)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Number of Production Ewes", text: $viewModel.ewesText)
                        .font(.title3)
                        .keyboardType(.numberPad)
                    
                    TextField("City", text: $viewModel.city)
                        .font(.title3)
                        .textContentType(.addressCity)
                    
                    Picker("Province", selection: $viewModel.province) {
                        ForEach(SouthAfricanProvince.allCases, id: \.self) { province in
                            Text(province.displayName).tag(province)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Required Information")
                } footer: {
                    Text("These fields are required to create a farm")
                }
                
                // Optional Fields Section
                Section(isExpanded: $viewModel.showOptionalFields) {
                    TextField("Company Name", text: $viewModel.companyName)
                        .textContentType(.organizationName)
                    
                    TextField("Size (Hectares)", text: $viewModel.sizeText)
                        .keyboardType(.decimalPad)
                    
                    TextField("Street Address", text: $viewModel.streetAddress)
                        .textContentType(.streetAddressLine1)
                    
                    TextField("Postal Code", text: $viewModel.postalCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                    
                    Picker("Production System", selection: $viewModel.productionSystem) {
                        Text("Not Specified").tag(nil as ProductionSystem?)
                        ForEach(ProductionSystem.allCases, id: \.self) { system in
                            Text(system.displayName).tag(system as ProductionSystem?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Preferred Agent", text: $viewModel.preferredAgent)
                    
                    TextField("Preferred Abattoir", text: $viewModel.preferredAbattoir)
                    
                    TextField("Preferred Veterinarian", text: $viewModel.preferredVeterinarian)
                    
                    TextField("Co-op", text: $viewModel.coOp)
                } header: {
                    Text("Additional Details (Optional)")
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
            .navigationTitle(viewModel.navigationTitle)
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
                            if await viewModel.saveFarm() {
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
        }
    }
}

#Preview("New Farm") {
    FarmDetailView(store: InMemoryFarmStore())
}

#Preview("Edit Farm") {
    let farm = Farm(
        userId: "preview-user",
        name: "Lamont Boerdery",
        breed: .dohneMerino,
        totalProductionEwes: 2700,
        city: "Saldanha",
        province: .westernCape,
        companyName: "Elderberry Investments",
        sizeHectares: 1300
    )
    
    return FarmDetailView(store: InMemoryFarmStore(), farm: farm)
}
