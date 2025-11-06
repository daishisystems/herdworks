//
//  BreedingEventDetailViewWithSelection.swift
//  HerdWorks
//
//  Updated: Phase 4 - Works with new MatingType model
//

import SwiftUI
import FirebaseAuth

struct BreedingEventDetailViewWithSelection: View {
    @StateObject private var viewModel: BreedingEventDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFarm: Farm?
    @State private var selectedGroup: LambingSeasonGroup?
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case numberOfEwes
        case naturalDays
    }
    
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
        
        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: BreedingEventDetailViewModel(
                store: eventStore,
                userId: userId,
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
                
                if selectedFarm != nil && selectedGroup != nil {
                    matingTypeSection
                    numberOfEwesSection
                    
                    // Conditional sections based on mating type
                    if viewModel.matingType == .naturalMating {
                        naturalMatingSection
                    } else {
                        aiSection
                        followUpRamsSection
                    }
                }
            }
            .navigationTitle("breeding.add_event".localized())
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
                            await MainActor.run { focusedField = nil }
                            try? await Task.sleep(nanoseconds: 150_000_000)
                            if await saveEvent() {
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
    
    private var filteredGroups: [LambingSeasonGroup] {
        guard let farm = selectedFarm else { return [] }
        return groups.filter { $0.farmId == farm.id }
    }
    
    private var canSave: Bool {
        guard selectedFarm != nil, selectedGroup != nil else { return false }
        return viewModel.isValid
    }
    
    // MARK: - Form Sections
    
    private var selectionSection: some View {
        Section(
            header: Text("breeding.select_farm_and_group".localized()),
            footer: Text("breeding.select_farm_and_group_footer".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        ) {
            // Farm Picker
            Picker("farm.select_farm".localized(), selection: $selectedFarm) {
                Text("farm.select_farm_placeholder".localized()).tag(nil as Farm?)
                ForEach(farms) { farm in
                    Text(farm.name).tag(farm as Farm?)
                }
            }
            .pickerStyle(.menu)
            
            // Group Picker (only if farm selected)
            if selectedFarm != nil {
                Picker("lambing.select_group".localized(), selection: $selectedGroup) {
                    Text("lambing.select_group_placeholder".localized()).tag(nil as LambingSeasonGroup?)
                    ForEach(filteredGroups) { group in
                        Text(group.displayName).tag(group as LambingSeasonGroup?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var matingTypeSection: some View {
        Section(
            header: Text("breeding.mating_type".localized()),
            footer: Text("breeding.mating_type_footer".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        ) {
            Picker("breeding.mating_type".localized(), selection: $viewModel.matingType) {
                ForEach(MatingType.allCases, id: \.self) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var numberOfEwesSection: some View {
        Section(
            header: Text("breeding.number_of_ewes".localized()),
            footer: VStack(alignment: .leading, spacing: 4) {
                Text("breeding.number_of_ewes_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let error = viewModel.numberOfEwesMatedError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        ) {
            TextField("breeding.number_of_ewes_placeholder".localized(), text: $viewModel.numberOfEwesMated)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .submitLabel(.next)
                .onSubmit { focusedField = .naturalDays }
                .focused($focusedField, equals: .numberOfEwes)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .numberOfEwes }
        }
    }
    
    // MARK: - Natural Mating Section
    
    private var naturalMatingSection: some View {
        Section(
            header: Text("breeding.natural_section".localized()),
            footer: VStack(alignment: .leading, spacing: 8) {
                Text("breeding.natural_section_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let error = viewModel.naturalMatingDaysError {
                    Text(error)
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
            
            TextField("breeding.natural_days".localized(), text: $viewModel.naturalMatingDays)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .focused($focusedField, equals: .naturalDays)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .naturalDays }
            
            // Auto-calculated end date (read-only)
            if let endDate = viewModel.naturalMatingEnd {
                HStack {
                    Text("breeding.natural_end".localized())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(endDate, style: .date)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - AI Section
    
    private var aiSection: some View {
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
    
    // MARK: - Follow-up Rams Section
    
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
                
                // Auto-calculated days in (read-only, inclusive)
                if let days = viewModel.followUpDaysInCalculated {
                    HStack {
                        Text("breeding.followup_days".localized())
                            .foregroundColor(.secondary)
                        Spacer()
                        // FIXED: Use String(format:) to prevent comma formatting
                        let daysString = String(format: "%d", days)
                        Text("\(daysString) \("lambing.days".localized())")
                            .foregroundColor(days > 0 ? .primary : .red)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveEvent() async -> Bool {
        guard let farm = selectedFarm,
              let group = selectedGroup else {
            viewModel.errorMessage = "breeding.select_farm_and_group_error".localized()
            viewModel.showError = true
            return false
        }
        
        // Create a temporary ViewModel with the correct IDs
        let tempViewModel = BreedingEventDetailViewModel(
            store: eventStore,
            userId: Auth.auth().currentUser?.uid ?? "",
            farmId: farm.id,
            groupId: group.id,
            event: nil
        )
        
        // Copy all values from the current ViewModel
        tempViewModel.matingType = viewModel.matingType
        tempViewModel.numberOfEwesMated = viewModel.numberOfEwesMated
        tempViewModel.naturalMatingStart = viewModel.naturalMatingStart
        tempViewModel.naturalMatingDays = viewModel.naturalMatingDays
        tempViewModel.aiDate = viewModel.aiDate
        tempViewModel.usedFollowUpRams = viewModel.usedFollowUpRams
        tempViewModel.followUpRamsIn = viewModel.followUpRamsIn
        tempViewModel.followUpRamsOut = viewModel.followUpRamsOut
        
        let success = await tempViewModel.save()
        
        if !success {
            viewModel.errorMessage = tempViewModel.errorMessage
            viewModel.showError = true
        }
        
        print("✅ [BREEDING-WITH-SELECTION] Event created successfully")
        return success
    }
}
