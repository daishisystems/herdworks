//
//  LambingSeasonGroupDetailView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import SwiftUI
import FirebaseAuth

struct LambingSeasonGroupDetailView: View {
    @StateObject private var viewModel: LambingSeasonGroupDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    init(store: LambingSeasonGroupStore, farmId: String, group: LambingSeasonGroup? = nil) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: LambingSeasonGroupDetailViewModel(
            store: store,
            userId: uid,
            farmId: farmId,
            group: group
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                matingPeriodSection
                lambingPeriodSection
                calculatedInfoSection
                
                if let warning = viewModel.gestationWarning {
                    warningSection(warning)
                }
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
                            if await viewModel.saveGroup() {
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
    
    private var basicInfoSection: some View {
        Section(header: Text("lambing.basic_info".localized()),
                footer: Text("lambing.basic_info_footer".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
            TextField("lambing.code".localized(), text: $viewModel.code)
                .textInputAutocapitalization(.characters)
            
            TextField("lambing.name".localized(), text: $viewModel.name)
                .textInputAutocapitalization(.words)
            
            Toggle("lambing.active".localized(), isOn: $viewModel.isActive)
        }
    }
    
    private var matingPeriodSection: some View {
        Section(header: Text("lambing.mating_period".localized()),
                footer: Text("lambing.mating_period_footer".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
            
            DatePicker(
                "lambing.start_date".localized(),
                selection: $viewModel.matingStart,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            
            DatePicker(
                "lambing.end_date".localized(),
                selection: $viewModel.matingEnd,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            
            HStack {
                Text("lambing.duration".localized())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.matingDurationDays) \("lambing.days".localized())")
                    .foregroundStyle(viewModel.matingDurationDays > 0 ? Color.primary : Color.red)
            }
        }
    }
    
    private var lambingPeriodSection: some View {
        Section(header: Text("lambing.lambing_period".localized()),
                footer: VStack(alignment: .leading, spacing: 8) {
                    Text("lambing.lambing_period_footer".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        viewModel.calculateLambingDatesFromMating()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.caption)
                            Text("lambing.auto_calculate".localized())
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                }) {
            
            DatePicker(
                "lambing.start_date".localized(),
                selection: $viewModel.lambingStart,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            
            DatePicker(
                "lambing.end_date".localized(),
                selection: $viewModel.lambingEnd,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            
            HStack {
                Text("lambing.duration".localized())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.lambingDurationDays) \("lambing.days".localized())")
                    .foregroundStyle(viewModel.lambingDurationDays > 0 ? Color.primary : Color.red)
            }
        }
    }
    
    private var calculatedInfoSection: some View {
        Section(header: Text("lambing.calculated_info".localized()),
                footer: Text("lambing.calculated_info_footer".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)) {
            HStack {
                Text("lambing.gestation_period".localized())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.gestationDays) \("lambing.days".localized())")
                    .foregroundStyle(
                        viewModel.gestationDays >= 140 && viewModel.gestationDays <= 160 ? Color.primary : Color.orange
                    )
                    .fontWeight(
                        viewModel.gestationDays >= 140 && viewModel.gestationDays <= 160 ? .regular : .semibold
                    )
            }
        }
    }
    
    private func warningSection(_ warning: String) -> some View {
        Section {
            Label {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(Color.orange)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)
            }
        }
    }
}

#Preview("New Group") {
    LambingSeasonGroupDetailView(
        store: InMemoryLambingSeasonGroupStore(),
        farmId: "preview-farm"
    )
    .environmentObject(LanguageManager.shared)
}

#Preview("Edit Group") {
    LambingSeasonGroupDetailView(
        store: InMemoryLambingSeasonGroupStore(),
        farmId: "preview-farm",
        group: LambingSeasonGroup.preview
    )
    .environmentObject(LanguageManager.shared)
}
