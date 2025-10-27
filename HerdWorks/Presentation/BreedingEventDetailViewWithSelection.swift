//
//  BreedingEventDetailViewWithSelection.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/27.
//

import SwiftUI
import FirebaseAuth

struct BreedingEventDetailViewWithSelection: View {
    @StateObject private var viewModel: BreedingEventDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case none
    }
    
    @State private var selectedFarmId: String = ""
    @State private var selectedGroupId: String = ""
    
    private let eventStore: BreedingEventStore
    private let groupStore: LambingSeasonGroupStore
    private let farms: [Farm]
    private let groups: [LambingSeasonGroup]
    
    init(
        eventStore: BreedingEventStore,
        groupStore: LambingSeasonGroupStore,
        farms: [Farm],
        groups: [LambingSeasonGroup]
    ) {
        self.eventStore = eventStore
        self.groupStore = groupStore
        self.farms = farms
        self.groups = groups
        
        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: BreedingEventDetailViewModel(
                store: eventStore,
                userId: uid,
                farmId: "",
                groupId: "",
                event: nil
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                selectionSection
                
                breedingMethodSection
                
                if viewModel.useAI {
                    aiBreedingSection
                }
                
                if viewModel.useNaturalMating {
                    naturalMatingSection
                }
                
                followUpRamsSection
                
                calculatedInfoSection
            }
            .navigationTitle("breeding.add_event".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("breeding.add_event".localized())
                            .font(.headline)
                        if !canSave && !viewModel.isSaving {
                            Text("form.fix_highlighted_fields_to_save".localized())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
                        Task {
                            await MainActor.run { focusedField = nil }
                            try? await Task.sleep(nanoseconds: 150_000_000)
                            if await saveWithSelection() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave || viewModel.isSaving)
                    .opacity(!canSave || viewModel.isSaving ? 0.4 : 1.0)
                }
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) {}
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
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
    
    // MARK: - Computed Properties
    
    private var availableGroups: [LambingSeasonGroup] {
        guard !selectedFarmId.isEmpty else {
            return []
        }
        return groups.filter { $0.farmId == selectedFarmId }
    }
    
    private var canSave: Bool {
        !selectedFarmId.isEmpty &&
        !selectedGroupId.isEmpty &&
        viewModel.isValid
    }
    
    // MARK: - Form Sections
    
    private var selectionSection: some View {
        Section(
            header: Text("breeding.farm_selection".localized()),
            footer: Group {
                if selectedFarmId.isEmpty && !farms.isEmpty {
                    Text("breeding.farm_selection_required".localized())
                        .foregroundColor(.red)
                } else if selectedGroupId.isEmpty && !selectedFarmId.isEmpty && !availableGroups.isEmpty {
                    Text("breeding.group_selection_required".localized())
                        .foregroundColor(.red)
                } else if !selectedFarmId.isEmpty && availableGroups.isEmpty {
                    Text("breeding.no_groups_available".localized())
                        .foregroundColor(.orange)
                }
            }
        ) {
            // Farm Picker
            if farms.isEmpty {
                Text("lambing.no_farms_available".localized())
                    .foregroundColor(.secondary)
            } else {
                Picker("breeding.select_farm".localized(), selection: $selectedFarmId) {
                    Text("breeding.choose_farm".localized())
                        .tag("")
                    
                    ForEach(farms) { farm in
                        Text(farm.name).tag(farm.id)
                    }
                }
                .onChange(of: selectedFarmId) { _, _ in
                    // Reset group selection when farm changes
                    selectedGroupId = ""
                }
            }
            
            // Group Picker (only if farm selected)
            if !selectedFarmId.isEmpty {
                if availableGroups.isEmpty {
                    Text("breeding.no_groups_available".localized())
                        .foregroundColor(.secondary)
                } else {
                    Picker("breeding.select_group".localized(), selection: $selectedGroupId) {
                        Text("breeding.choose_group".localized())
                            .tag("")
                        
                        ForEach(availableGroups) { group in
                            Text(group.displayName).tag(group.id)
                        }
                    }
                }
            }
        }
    }
    
    // NOTE: All other sections (breedingMethodSection, aiBreedingSection, etc.)
    // are identical to BreedingEventDetailView.swift
    // For brevity, they're not repeated here, but in actual implementation
    // you would copy them exactly as they are in BreedingEventDetailView
    
    private var breedingMethodSection: some View {
        Section(
            header: Text("breeding.breeding_method".localized()),
            footer: VStack(alignment: .leading, spacing: 4) {
                Text("breeding.method_required_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !viewModel.hasBreedingMethod {
                    Text(viewModel.breedingMethodError ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        ) {
            Toggle("breeding.use_ai".localized(), isOn: $viewModel.useAI)
            Toggle("breeding.use_natural".localized(), isOn: $viewModel.useNaturalMating)
        }
    }
    
    // (... other sections identical to BreedingEventDetailView ...)
    
    private var aiBreedingSection: some View {
        Section(
            header: Text("breeding.ai_section".localized()),
            footer: Text("breeding.ai_footer".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        ) {
            DatePicker(
                "breeding.ai_date".localized(),
                selection: $viewModel.aiDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
        }
    }
    
    private var naturalMatingSection: some View {
        Section(
            header: Text("breeding.natural_section".localized()),
            footer: VStack(alignment: .leading, spacing: 8) {
                Text("breeding.natural_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !viewModel.naturalMatingDatesValid {
                    Text(viewModel.naturalMatingDatesError ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        ) {
            DatePicker(
                "breeding.natural_start".localized(),
                selection: $viewModel.naturalMatingStart,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .onChange(of: viewModel.naturalMatingStart) { _, _ in
                viewModel.correctNaturalMatingDates()
            }
            
            DatePicker(
                "breeding.natural_end".localized(),
                selection: $viewModel.naturalMatingEnd,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .onChange(of: viewModel.naturalMatingEnd) { _, _ in
                viewModel.correctNaturalMatingDates()
            }
            
            if let days = viewModel.naturalMatingDays {
                HStack {
                    Text("breeding.natural_days".localized())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(days) \("lambing.days".localized())")
                        .foregroundColor(days > 0 ? .primary : .red)
                }
            }
        }
    }
    
    private var followUpRamsSection: some View {
        Section(
            header: Text("breeding.followup_section".localized()),
            footer: VStack(alignment: .leading, spacing: 8) {
                Text("breeding.followup_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !viewModel.followUpDatesValid {
                    Text(viewModel.followUpDatesError ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        ) {
            Toggle("breeding.use_followup".localized(), isOn: $viewModel.usedFollowUpRams)
            
            if viewModel.usedFollowUpRams {
                DatePicker(
                    "breeding.rams_in".localized(),
                    selection: $viewModel.followUpRamsIn,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .onChange(of: viewModel.followUpRamsIn) { _, _ in
                    viewModel.correctFollowUpDates()
                }
                
                DatePicker(
                    "breeding.rams_out".localized(),
                    selection: $viewModel.followUpRamsOut,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .onChange(of: viewModel.followUpRamsOut) { _, _ in
                    viewModel.correctFollowUpDates()
                }
                
                if let days = viewModel.followUpDays {
                    HStack {
                        Text("breeding.followup_days".localized())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(days) \("lambing.days".localized())")
                            .foregroundColor(days > 0 ? .primary : .red)
                    }
                }
            }
        }
    }
    
    private var calculatedInfoSection: some View {
        Section(
            header: Text("breeding.summary_section".localized()),
            footer: Text("breeding.calculated_info_footer".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        ) {
            HStack {
                Text("breeding.year".localized())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.year)")
                    .fontWeight(.semibold)
            }
            
            if let date = viewModel.calculationDate {
                HStack {
                    Text("breeding.calculation_date".localized())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(date, style: .date)
                }
            }
        }
    }
    
    // MARK: - Save Logic
    
    private func saveWithSelection() async -> Bool {
        guard canSave else {
            await MainActor.run {
                if selectedFarmId.isEmpty {
                    viewModel.errorMessage = "breeding.farm_selection_required".localized()
                } else if selectedGroupId.isEmpty {
                    viewModel.errorMessage = "breeding.group_selection_required".localized()
                } else {
                    viewModel.errorMessage = viewModel.breedingMethodError
                }
                viewModel.showError = true
            }
            return false
        }
        
        let event = BreedingEvent(
            userId: Auth.auth().currentUser?.uid ?? "",
            farmId: selectedFarmId,
            lambingSeasonGroupId: selectedGroupId,
            aiDate: viewModel.useAI ? viewModel.aiDate : nil,
            naturalMatingStart: viewModel.useNaturalMating ? viewModel.naturalMatingStart : nil,
            naturalMatingEnd: viewModel.useNaturalMating ? viewModel.naturalMatingEnd : nil,
            usedFollowUpRams: viewModel.usedFollowUpRams,
            followUpRamsIn: viewModel.usedFollowUpRams ? viewModel.followUpRamsIn : nil,
            followUpRamsOut: viewModel.usedFollowUpRams ? viewModel.followUpRamsOut : nil
        )
        
        await MainActor.run { viewModel.isSaving = true }
        defer { Task { await MainActor.run { viewModel.isSaving = false } } }
        
        do {
            try await eventStore.create(event)
            print("✅ [BREEDING-WITH-SELECTION] Event created successfully")
            return true
        } catch {
            print("❌ [BREEDING-WITH-SELECTION] Failed to create event: \(error)")
            await MainActor.run {
                viewModel.errorMessage = String(format: "error.failed_to_save".localized(), error.localizedDescription)
                viewModel.showError = true
            }
            return false
        }
    }
}

// MARK: - Previews

#Preview {
    let farms = [
        Farm(
            userId: "preview",
            name: "Test Farm 1",
            breed: .dohneMerino,
            totalProductionEwes: 100,
            city: "Cape Town",
            province: .westernCape
        ),
        Farm(
            userId: "preview",
            name: "Test Farm 2",
            breed: .dorper,
            totalProductionEwes: 200,
            city: "Stellenbosch",
            province: .westernCape
        )
    ]
    
    let groups = [
        LambingSeasonGroup(
            userId: "preview",
            farmId: farms[0].id,
            code: "A25",
            name: "Spring 2025",
            matingStart: Date(),
            matingEnd: Date().addingTimeInterval(86400 * 30),
            lambingStart: Date().addingTimeInterval(86400 * 145),
            lambingEnd: Date().addingTimeInterval(86400 * 175),
            isActive: true
        )
    ]
    
    return BreedingEventDetailViewWithSelection(
        eventStore: InMemoryBreedingEventStore(),
        groupStore: InMemoryLambingSeasonGroupStore(),
        farms: farms,
        groups: groups
    )
    .environmentObject(LanguageManager.shared)
}
