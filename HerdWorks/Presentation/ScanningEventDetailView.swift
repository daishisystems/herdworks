//
//  ScanningEventDetailView.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import SwiftUI
import FirebaseAuth

struct ScanningEventDetailView: View {
    @StateObject private var viewModel: ScanningEventDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case ewesMated
        case ewesScanned
        case ewesPregnant
        case ewesNotPregnant
        case singles
        case twins
        case triplets
    }
    
    private let store: ScanningEventStore
    private let isEditing: Bool
    
    init(
        store: ScanningEventStore,
        userId: String,
        farmId: String,
        groupId: String,
        event: ScanningEvent? = nil
    ) {
        self.store = store
        self.isEditing = event != nil
        
        _viewModel = StateObject(
            wrappedValue: ScanningEventDetailViewModel(
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
                matingInfoSection
                scanningResultsSection
                fetusDistributionSection
                calculatedMetricsSection
                
                if !viewModel.validationWarnings.isEmpty {
                    warningsSection
                }
            }
            .navigationTitle(isEditing ? "scanning.edit_event".localized() : "scanning.add_event".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(isEditing ? "scanning.edit_event".localized() : "scanning.add_event".localized())
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
        }
    }
    
    // MARK: - Sections
    
    private var matingInfoSection: some View {
        Section {
            HStack {
                Text("scanning.ewes_mated".localized())
                    .foregroundColor(viewModel.ewesMated.isEmpty ? .red : .primary)
                Spacer()
                TextField("0", text: $viewModel.ewesMated)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .ewesMated)
            }
        } header: {
            Text("scanning.section_mating".localized())
        } footer: {
            Text("scanning.section_mating_footer".localized())
        }
    }
    
    private var scanningResultsSection: some View {
        Section {
            HStack {
                Text("scanning.ewes_scanned".localized())
                Spacer()
                TextField("0", text: $viewModel.ewesScanned)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .ewesScanned)
            }
            
            HStack {
                Text("scanning.ewes_pregnant".localized())
                Spacer()
                TextField("0", text: $viewModel.ewesPregnant)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .ewesPregnant)
            }
            
            HStack {
                Text("scanning.ewes_not_pregnant".localized())
                Spacer()
                TextField("0", text: $viewModel.ewesNotPregnant)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .ewesNotPregnant)
            }
        } header: {
            Text("scanning.section_scanning".localized())
        } footer: {
            Text("scanning.section_scanning_footer".localized())
        }
    }
    
    private var fetusDistributionSection: some View {
        Section {
            HStack {
                Text("scanning.ewes_singles".localized())
                Spacer()
                TextField("0", text: $viewModel.ewesWithSingles)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .singles)
            }
            
            HStack {
                Text("scanning.ewes_twins".localized())
                Spacer()
                TextField("0", text: $viewModel.ewesWithTwins)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .twins)
            }
            
            HStack {
                Text("scanning.ewes_triplets".localized())
                Spacer()
                TextField("0", text: $viewModel.ewesWithTriplets)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .focused($focusedField, equals: .triplets)
            }
        } header: {
            Text("scanning.section_fetuses".localized())
        } footer: {
            Text("scanning.section_fetuses_footer".localized())
        }
    }
    
    private var calculatedMetricsSection: some View {
        Section {
            HStack {
                Text("scanning.conception_ratio".localized())
                Spacer()
                Text(String(format: "%.1f%%", viewModel.conceptionRatio))
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
            
            HStack {
                Text("scanning.scanned_fetuses".localized())
                Spacer()
                Text("\(viewModel.scannedFetuses)")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
            
            HStack {
                Text("scanning.expected_lambing_pregnant".localized())
                Spacer()
                Text(String(format: "%.1f%%", viewModel.expectedLambingPercentagePregnant))
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
            
            HStack {
                Text("scanning.expected_lambing_mated".localized())
                Spacer()
                Text(String(format: "%.1f%%", viewModel.expectedLambingPercentageMated))
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
        } header: {
            Text("scanning.section_calculations".localized())
        } footer: {
            Text("scanning.section_calculations_footer".localized())
        }
    }
    
    private var warningsSection: some View {
        Section {
            ForEach(viewModel.validationWarnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.body)
                    Text(warning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("scanning.warnings_header".localized())
        }
    }
}

// MARK: - Previews

#Preview("Create Mode") {
    NavigationStack {
        ScanningEventDetailView(
            store: InMemoryScanningEventStore(),
            userId: "preview-user",
            farmId: "preview-farm",
            groupId: "preview-group"
        )
        .environmentObject(LanguageManager.shared)
    }
}

#Preview("Edit Mode") {
    NavigationStack {
        ScanningEventDetailView(
            store: InMemoryScanningEventStore(),
            userId: "preview-user",
            farmId: "preview-farm",
            groupId: "preview-group",
            event: .preview
        )
        .environmentObject(LanguageManager.shared)
    }
}
