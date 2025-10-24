//
//  LambingSeasonGroupDetailViewWithFarmSelection.swift
//  HerdWorks
//
//  Created by OpenAI Assistant on 2025/02/15.
//

import SwiftUI
import FirebaseAuth

struct LambingSeasonGroupDetailViewWithFarmSelection: View {
    @StateObject private var viewModel: LambingSeasonGroupDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFarmId: String = ""

    private let lambingStore: LambingSeasonGroupStore
    private let farms: [Farm]

    init(lambingStore: LambingSeasonGroupStore, farms: [Farm]) {
        self.lambingStore = lambingStore
        self.farms = farms

        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: LambingSeasonGroupDetailViewModel(
                store: lambingStore,
                userId: uid,
                farmId: "",
                group: nil
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                farmSelectionSection
                basicInfoSection
                matingPeriodSection
                lambingPeriodSection
                calculatedInfoSection

                if let warning = viewModel.gestationWarning {
                    warningSection(warning)
                }
            }
            .navigationTitle("lambing.add_group".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("lambing.add_group".localized())
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
                            if await saveWithSelectedFarm() {
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

    private var farmSelectionSection: some View {
        Section(
            header: Text("lambing.farm_selection".localized()),
            footer: Group {
                if selectedFarmId.isEmpty && !farms.isEmpty {
                    Text("lambing.farm_selection_required".localized())
                        .foregroundColor(.red)
                } else if farms.isEmpty {
                    Text("lambing.no_farms_available".localized())
                        .foregroundColor(.orange)
                }
            }
        ) {
            if farms.isEmpty {
                Text("lambing.no_farms_available".localized())
                    .foregroundColor(.secondary)
            } else {
                Picker("lambing.select_farm".localized(), selection: $selectedFarmId) {
                    Text("lambing.choose_farm".localized())
                        .tag("")

                    ForEach(farms) { farm in
                        Text(farm.name).tag(farm.id)
                    }
                }
            }
        }
    }

    private var basicInfoSection: some View {
        Section(
            header: Text("lambing.basic_info".localized()),
            footer: Text("lambing.basic_info_footer".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        ) {
            TextField("lambing.code".localized(), text: $viewModel.code)
                .textInputAutocapitalization(.characters)

            TextField("lambing.name".localized(), text: $viewModel.name)
                .textInputAutocapitalization(.words)

            Toggle("lambing.active".localized(), isOn: $viewModel.isActive)
        }
    }

    private var matingPeriodSection: some View {
        Section(
            header: Text("lambing.mating_period".localized()),
            footer: VStack(spacing: 4) {
                Text("lambing.mating_period_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.matingEnd < viewModel.matingStart {
                    Text("form.end_date_must_be_after_start".localized())
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        ) {
            DatePicker(
                "lambing.start_date".localized(),
                selection: $viewModel.matingStart,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .onChange(of: viewModel.matingStart) { _, newValue in
                if viewModel.matingEnd < newValue { viewModel.matingEnd = newValue }
            }

            DatePicker(
                "lambing.end_date".localized(),
                selection: $viewModel.matingEnd,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)

            HStack {
                Text("lambing.duration".localized())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.matingDurationDays) \("lambing.days".localized())")
                    .foregroundColor(viewModel.matingDurationDays > 0 ? .primary : .red)
            }
        }
    }

    private var lambingPeriodSection: some View {
        Section(
            header: Text("lambing.lambing_period".localized()),
            footer: VStack(alignment: .leading, spacing: 8) {
                Text("lambing.lambing_period_footer".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    viewModel.calculateLambingDatesFromMating()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.caption)
                        Text("lambing.auto_calculate".localized())
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }

                if viewModel.lambingEnd < viewModel.lambingStart {
                    Text("form.end_date_must_be_after_start".localized())
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        ) {
            DatePicker(
                "lambing.start_date".localized(),
                selection: $viewModel.lambingStart,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .onChange(of: viewModel.lambingStart) { _, newValue in
                if viewModel.lambingEnd < newValue { viewModel.lambingEnd = newValue }
            }

            DatePicker(
                "lambing.end_date".localized(),
                selection: $viewModel.lambingEnd,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)

            HStack {
                Text("lambing.duration".localized())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.lambingDurationDays) \("lambing.days".localized())")
                    .foregroundColor(viewModel.lambingDurationDays > 0 ? .primary : .red)
            }
        }
    }

    private var calculatedInfoSection: some View {
        Section(
            header: Text("lambing.calculated_info".localized()),
            footer: Text("lambing.calculated_info_footer".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        ) {
            HStack {
                Text("lambing.gestation_period".localized())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.gestationDays) \("lambing.days".localized())")
                    .foregroundColor(
                        viewModel.gestationDays >= 140 && viewModel.gestationDays <= 160 ? .primary : .orange
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
                    .foregroundColor(.orange)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private var canSave: Bool {
        !selectedFarmId.isEmpty && viewModel.isValid
    }

    private func saveWithSelectedFarm() async -> Bool {
        guard canSave else {
            viewModel.errorMessage = "lambing.farm_selection_required".localized()
            viewModel.showError = true
            return false
        }

        let group = LambingSeasonGroup(
            userId: Auth.auth().currentUser?.uid ?? "",
            farmId: selectedFarmId,
            code: viewModel.code.trimmingCharacters(in: .whitespacesAndNewlines),
            name: viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines),
            matingStart: viewModel.matingStart,
            matingEnd: viewModel.matingEnd,
            lambingStart: viewModel.lambingStart,
            lambingEnd: viewModel.lambingEnd,
            isActive: viewModel.isActive
        )

        viewModel.isSaving = true
        defer { viewModel.isSaving = false }

        do {
            print("🔵 [FARM-SELECT] Creating group for farm: \(selectedFarmId)")
            try await lambingStore.create(group)
            print("✅ [FARM-SELECT] Group created successfully")
            return true
        } catch {
            print("❌ [FARM-SELECT] Failed to create group: \(error)")
            viewModel.errorMessage = String(format: "error.failed_to_save".localized(), error.localizedDescription)
            viewModel.showError = true
            return false
        }
    }
}

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

    return LambingSeasonGroupDetailViewWithFarmSelection(
        lambingStore: InMemoryLambingSeasonGroupStore(),
        farms: farms
    )
    .environmentObject(LanguageManager.shared)
}

