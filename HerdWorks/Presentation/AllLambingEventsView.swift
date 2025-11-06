//
//  AllLambingEventsView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import SwiftUI

struct AllLambingEventsView: View {
    @StateObject private var viewModel: AllLambingEventsViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss  // ✅ ADDED: Environment dismiss
    @State private var showingAddSheet = false
    @State private var selectedRecord: LambingRecord?
    
    init(
        recordStore: LambingRecordStore,
        groupStore: LambingSeasonGroupStore,
        farmStore: FarmStore,
        benchmarkStore: BenchmarkStore,
        userId: String
    ) {
        _viewModel = StateObject(wrappedValue: AllLambingEventsViewModel(
            recordStore: recordStore,
            groupStore: groupStore,
            farmStore: farmStore,
            benchmarkStore: benchmarkStore,
            userId: userId
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.records.isEmpty {
                    emptyStateView
                } else {
                    recordsList
                }
            }
            .navigationTitle("lambing.all_events_title".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.done".localized()) {
                        dismiss()  // ✅ FIXED: Now actually dismisses the view
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if viewModel.groups.isEmpty {
                            // preserve disabled state; no action needed
                        } else {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 150_000_000)
                                showingAddSheet = true
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.groups.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                LambingRecordDetailViewWithSelection(
                    recordStore: viewModel.recordStore,
                    farms: viewModel.farms,
                    groups: viewModel.groups,
                    userId: viewModel.userId
                )
            }
            .sheet(item: $selectedRecord) { record in
                if let groupInfo = viewModel.groupInfoCache[record.lambingSeasonGroupId] {
                    LambingRecordDetailView(
                        recordStore: viewModel.recordStore,
                        benchmarkStore: viewModel.benchmarkStore,
                        record: record,
                        farmBreed: groupInfo.farmBreed,
                        farmProvince: groupInfo.farmProvince
                    )
                }
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) { }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .alert("lambing.no_groups_title".localized(), isPresented: $viewModel.showNoGroupsAlert) {
                Button("common.ok".localized(), role: .cancel) { }
            } message: {
                Text("lambing.no_groups_message".localized())
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var recordsList: some View {
        List {
            ForEach(viewModel.records) { record in
                LambingRecordRow(
                    record: record,
                    farmName: viewModel.farmAndGroupName(for: record).farm,
                    groupName: viewModel.farmAndGroupName(for: record).group
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedRecord = record
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteRecord(record)
                        }
                    } label: {
                        Label("common.delete".localized(), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("lambing.empty_title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("lambing.empty_subtitle".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                if viewModel.groups.isEmpty {
                    viewModel.showNoGroupsAlert = true
                } else {
                    showingAddSheet = true
                }
            } label: {
                Text("lambing.add_record".localized())
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 48)
        }
    }
}

// MARK: - Lambing Record Row

struct LambingRecordRow: View {
    let record: LambingRecord
    let farmName: String
    let groupName: String
    
    @State private var ranking: String?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Text(dateFormatter.string(from: record.createdAt))
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.blue)
                Text(farmName)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "calendar")
                    .foregroundStyle(.orange)
                Text(groupName)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            
            // Metrics Grid (3 columns, 2 rows)
            HStack(spacing: 0) {
                metricColumn(
                    label: "lambing.ewes_lambed".localized(),
                    value: "\(record.ewesLambed)",
                    color: .blue
                )
                
                metricColumn(
                    label: "lambing.lambs_born".localized(),
                    value: "\(record.lambsBorn)",
                    color: .green
                )
                
                metricColumn(
                    label: "lambing.mortality_short".localized(),
                    value: "\(record.lambsMortality0to30Days)",
                    color: .red
                )
            }
            
            HStack(spacing: 0) {
                metricColumn(
                    label: "lambing.lambing_percentage_short".localized(),
                    value: String(format: "%.1f%%", record.lambingPercentage),
                    color: .orange
                )
                
                metricColumn(
                    label: "lambing.survival_short".localized(),
                    value: String(format: "%.1f%%", record.survivalRate),
                    color: .green
                )
                
                if let ranking = ranking {
                    metricColumn(
                        label: "lambing.ranking".localized(),
                        value: ranking,
                        color: .purple
                    )
                } else {
                    metricColumn(
                        label: "lambing.ranking".localized(),
                        value: "-",
                        color: .secondary
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func metricColumn(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview {
    AllLambingEventsView(
        recordStore: InMemoryLambingRecordStore(),
        groupStore: InMemoryLambingSeasonGroupStore(),
        farmStore: InMemoryFarmStore(),
        benchmarkStore: InMemoryBenchmarkStore(),
        userId: "preview-user"
    )
    .environmentObject(LanguageManager.shared)
}

