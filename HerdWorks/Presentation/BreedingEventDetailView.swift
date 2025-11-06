//
//  BreedingEventDetailView.swift
//  HerdWorks
//
//  Updated: Phase 4 - Conditional fields based on MatingType
//

import SwiftUI
import FirebaseAuth

struct BreedingEventDetailView: View {
    @StateObject private var viewModel: BreedingEventDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case numberOfEwes
        case naturalDays
    }
    
    private let store: BreedingEventStore
    private let isEditing: Bool
    
    init(
        store: BreedingEventStore,
        userId: String,
        farmId: String,
        groupId: String,
        event: BreedingEvent? = nil
    ) {
        self.store = store
        self.isEditing = event != nil
        
        _viewModel = StateObject(
            wrappedValue: BreedingEventDetailViewModel(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId,
                event: event
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
            .navigationTitle(isEditing ? "breeding.edit_event".localized() : "breeding.add_event".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(isEditing ? "breeding.edit_event".localized() : "breeding.add_event".localized())
                            .font(.headline)
                        if !viewModel.isValid && !viewModel.isSaving {
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
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                    .opacity(!viewModel.isValid || viewModel.isSaving ? 0.4 : 1.0)
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
    
    // MARK: - Form Sections
    
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
                .onSubmit {
                    focusedField = .naturalDays
                }
                .focused($focusedField, equals: .numberOfEwes)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = .numberOfEwes
                }
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
                .onSubmit {
                    focusedField = nil
                }
                .focused($focusedField, equals: .naturalDays)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = .naturalDays
                }
            
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
                        // FIXED: Use String() to prevent comma formatting
                        Text("\(String(days)) \("lambing.days".localized())")
                            .foregroundColor(days > 0 ? .primary : .red)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Create New - Natural") {
    BreedingEventDetailView(
        store: InMemoryBreedingEventStore(),
        userId: "preview-user",
        farmId: "preview-farm",
        groupId: "preview-group",
        event: nil
    )
    .environmentObject(LanguageManager.shared)
}

#Preview("Edit Existing - AI") {
    BreedingEventDetailView(
        store: InMemoryBreedingEventStore(),
        userId: "preview-user",
        farmId: "preview-farm",
        groupId: "preview-group",
        event: BreedingEvent.previewAI
    )
    .environmentObject(LanguageManager.shared)
}
