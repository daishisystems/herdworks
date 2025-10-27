//
//  BreedingEventDetailView.swift
//  HerdWorks
//
//  Created by Claude on 2025/10/24.
//

import SwiftUI
import FirebaseAuth

struct BreedingEventDetailView: View {
    @StateObject private var viewModel: BreedingEventDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case none
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
                breedingMethodSection
                
                // AI Section - with explicit animation
                if viewModel.useAI {
                    aiBreedingSection
                        .transition(.opacity)
                }
                
                // Natural Mating Section - with explicit animation
                if viewModel.useNaturalMating {
                    naturalMatingSection
                        .transition(.opacity)
                }
                
                followUpRamsSection
                
                calculatedInfoSection
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.useAI)
            .animation(.easeInOut(duration: 0.2), value: viewModel.useNaturalMating)
            .animation(.easeInOut(duration: 0.2), value: viewModel.usedFollowUpRams)
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
            .datePickerStyle(.graphical)
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
            .datePickerStyle(.graphical)
            .onChange(of: viewModel.naturalMatingStart) { _, _ in
                viewModel.correctNaturalMatingDates()
            }
            
            DatePicker(
                "breeding.natural_end".localized(),
                selection: $viewModel.naturalMatingEnd,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
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
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.followUpRamsIn) { _, _ in
                    viewModel.correctFollowUpDates()
                }
                .transition(.opacity)
                
                DatePicker(
                    "breeding.rams_out".localized(),
                    selection: $viewModel.followUpRamsOut,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.followUpRamsOut) { _, _ in
                    viewModel.correctFollowUpDates()
                }
                .transition(.opacity)
                
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
                Text(viewModel.year, format: .number.grouping(.never))  // ✅ FIXED - No comma!
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
}

// MARK: - Previews

#Preview("Create New") {
    BreedingEventDetailView(
        store: InMemoryBreedingEventStore(),
        userId: "preview-user",
        farmId: "preview-farm",
        groupId: "preview-group",
        event: nil
    )
    .environmentObject(LanguageManager.shared)
}

#Preview("Edit Existing") {
    let event = BreedingEvent(
        userId: "preview-user",
        farmId: "preview-farm",
        lambingSeasonGroupId: "preview-group",
        aiDate: Date(),
        usedFollowUpRams: false
    )
    
    return BreedingEventDetailView(
        store: InMemoryBreedingEventStore(),
        userId: "preview-user",
        farmId: "preview-farm",
        groupId: "preview-group",
        event: event
    )
    .environmentObject(LanguageManager.shared)
}
