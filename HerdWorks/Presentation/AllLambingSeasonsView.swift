//
//  AllLambingSeasonsView.swift
//  HerdWorks
//
//  Created by OpenAI Assistant on 2025/02/15.
//

import SwiftUI
import FirebaseAuth

struct AllLambingSeasonsView: View {
    @StateObject private var viewModel: AllLambingSeasonsViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingAddGroup = false
    @State private var selectedGroup: LambingSeasonGroup?
    @State private var showActiveOnly = true

    private let lambingStore: LambingSeasonGroupStore
    private let farmStore: FarmStore

    init(lambingStore: LambingSeasonGroupStore, farmStore: FarmStore) {
        self.lambingStore = lambingStore
        self.farmStore = farmStore

        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: AllLambingSeasonsViewModel(
                lambingStore: lambingStore,
                farmStore: farmStore,
                userId: userId
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    loadingView
                } else if filteredGroups.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("lambing.all_seasons_title".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    filterToggle
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingAddGroup) {
                LambingSeasonGroupDetailViewWithFarmSelection(
                    lambingStore: lambingStore,
                    farms: viewModel.farms
                )
            }
            .sheet(item: $selectedGroup) { group in
                LambingSeasonGroupDetailView(
                    store: lambingStore,
                    farmId: group.farmId,
                    group: group
                )
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) {}
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .alert("lambing.no_farms_title".localized(), isPresented: $viewModel.showNoFarmsAlert) {
                Button("common.ok".localized(), role: .cancel) {}
            } message: {
                Text("lambing.no_farms_message".localized())
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("common.loading".localized())
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(showActiveOnly ? "lambing.no_active_seasons".localized() : "lambing.no_seasons".localized())
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("lambing.no_seasons_subtitle".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if viewModel.farms.isEmpty {
                    viewModel.showNoFarmsAlert = true
                } else {
                    showingAddGroup = true
                }
            } label: {
                Label("lambing.add_first_season".localized(), systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    private var listView: some View {
        List {
            ForEach(filteredGroups) { group in
                AllSeasonsGroupRow(
                    group: group,
                    farmName: viewModel.farmName(for: group.farmId)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedGroup = group
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteGroup(group)
                        }
                    } label: {
                        Label("common.delete".localized(), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var addButton: some View {
        Button {
            if viewModel.farms.isEmpty {
                viewModel.showNoFarmsAlert = true
            } else {
                showingAddGroup = true
            }
        } label: {
            Image(systemName: "plus")
        }
    }

    private var filterToggle: some View {
        Menu {
            Toggle("lambing.show_active_only".localized(), isOn: $showActiveOnly)

            Divider()

            Button {
                showActiveOnly = false
            } label: {
                Label("lambing.show_all".localized(), systemImage: "list.bullet")
            }

            Button {
                showActiveOnly = true
            } label: {
                Label("lambing.show_active".localized(), systemImage: "checkmark.circle")
            }
        } label: {
            Image(systemName: showActiveOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var filteredGroups: [LambingSeasonGroup] {
        showActiveOnly ? viewModel.groups.filter { $0.isActive } : viewModel.groups
    }
}

private struct AllSeasonsGroupRow: View {
    let group: LambingSeasonGroup
    let farmName: String

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.displayName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Label(farmName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.blue)

                        if group.isActive {
                            Label("lambing.active".localized(), systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else {
                            Label("lambing.inactive".localized(), systemImage: "xmark.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("lambing.mating_period".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(group.matingStart, formatter: dateFormatter)")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("lambing.lambing_period".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(group.lambingStart, formatter: dateFormatter)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            ProgressBar(group: group)
        }
        .padding(.vertical, 8)
    }
}

private struct ProgressBar: View {
    let group: LambingSeasonGroup

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                if group.isActive {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 8)
                }
            }
        }
        .frame(height: 8)
    }

    private var progressColor: Color {
        let now = Date()

        if now < group.matingStart {
            return .blue.opacity(0.3)
        } else if now <= group.matingEnd {
            return .blue
        } else if now < group.lambingStart {
            return .orange
        } else if now <= group.lambingEnd {
            return .green
        } else {
            return .gray
        }
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let now = Date()
        let totalDuration = group.lambingEnd.timeIntervalSince(group.matingStart)
        guard totalDuration > 0 else { return 0 }

        let elapsed = min(max(0, now.timeIntervalSince(group.matingStart)), totalDuration)
        let progress = elapsed / totalDuration
        return totalWidth * progress
    }
}

#Preview {
    AllLambingSeasonsView(
        lambingStore: InMemoryLambingSeasonGroupStore(),
        farmStore: InMemoryFarmStore()
    )
    .environmentObject(LanguageManager.shared)
}
