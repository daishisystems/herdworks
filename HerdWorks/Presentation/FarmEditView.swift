//
//  FarmEditView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth

struct FarmEditView: View {
    @StateObject private var viewModel: FarmDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
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
                addressSection
                gpsSection
                productionSection
                businessPartnersSection
            }
            .onAppear {
                print("🔵 [FARM-DETAIL] currentFarm: \(viewModel.currentFarm?.name ?? "nil")")
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
                        Task {
                            if await viewModel.saveFarm() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) { }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    ProgressView("profile_edit.saving".localized())
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var requiredSection: some View {
        Section(header: Text("farm.required_information".localized()),
                footer: Text("farm.required_footer".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
            // Farm Name
            TextField("farm.farm_name".localized(), text: $viewModel.name)
                .textInputAutocapitalization(.words)
            
            // Company Name
            TextField("farm.company_name".localized(), text: $viewModel.companyName)
                .textInputAutocapitalization(.words)
            
            // Breed
            Picker("farm.breed".localized(), selection: $viewModel.breed) {
                ForEach(SheepBreed.allCases, id: \.self) { breed in
                    Text(breed.displayName).tag(breed)
                }
            }
            
            // Number of Ewes
            TextField("farm.production_ewes".localized(), text: $viewModel.ewesText)
                .keyboardType(.numberPad)
            
            // Size
            TextField("farm.farm_size_hectares".localized(), text: $viewModel.sizeText)
                .keyboardType(.decimalPad)
        }
    }
    
    private var addressSection: some View {
        Section(header: Text("farm.address".localized()),
                footer: Text("farm.address_footer".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
            TextField("farm.street_address".localized(), text: $viewModel.streetAddress)
                .textInputAutocapitalization(.words)
            
            TextField("farm.city".localized(), text: $viewModel.city)
                .textInputAutocapitalization(.words)
            
            Picker("farm.province".localized(), selection: $viewModel.province) {
                ForEach(SouthAfricanProvince.allCases, id: \.self) { province in
                    Text(province.displayName).tag(province)
                }
            }
            
            TextField("farm.postal_code".localized(), text: $viewModel.postalCode)
                .keyboardType(.numberPad)
        }
    }
    
    private var gpsSection: some View {
        Section(header: Text("farm.gps_location".localized()),
                footer: Text(viewModel.useManualGPS ? "farm.gps_footer_manual".localized() : "farm.gps_footer_auto".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
            Toggle("farm.manual_gps_toggle".localized(), isOn: $viewModel.useManualGPS)
            
            if viewModel.useManualGPS {
                TextField("farm.latitude".localized(), text: $viewModel.manualLatitude)
                    .keyboardType(.decimalPad)
                
                TextField("farm.longitude".localized(), text: $viewModel.manualLongitude)
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    private var productionSection: some View {
        Section(header: Text("farm.production_system".localized())) {
            Picker("farm.system_type".localized(), selection: $viewModel.productionSystem) {
                Text("farm.not_specified".localized()).tag(nil as ProductionSystem?)
                ForEach(ProductionSystem.allCases, id: \.self) { system in
                    Text(system.displayName).tag(system as ProductionSystem?)
                }
            }
        }
    }
    
    private var businessPartnersSection: some View {
        Section(header: Text("farm.business_partners".localized())) {
            // Preferred Agent - Dropdown
            Picker("farm.preferred_agent".localized(), selection: $viewModel.preferredAgent) {
                Text("farm.not_specified".localized()).tag(nil as PreferredAgent?)
                ForEach(PreferredAgent.allCases, id: \.self) { agent in
                    Text(agent.displayName).tag(agent as PreferredAgent?)
                }
            }
            
            // Preferred Abattoir - Text Field
            TextField("farm.preferred_abattoir".localized(), text: $viewModel.preferredAbattoir)
                .textInputAutocapitalization(.words)
            
            // Preferred Veterinarian - Text Field
            TextField("farm.preferred_veterinarian".localized(), text: $viewModel.preferredVeterinarian)
                .textInputAutocapitalization(.words)
            
            // Co-Op - Dropdown
            Picker("farm.coop".localized(), selection: $viewModel.coOp) {
                Text("farm.not_specified".localized()).tag(nil as CoOp?)
                ForEach(CoOp.allCases, id: \.self) { coop in
                    Text(coop.displayName).tag(coop as CoOp?)
                }
            }
        }
    }
}

#Preview {
    FarmEditView(store: InMemoryFarmStore())
        .environmentObject(LanguageManager.shared)
}
