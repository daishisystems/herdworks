//
//  AllScanningEventsView.swift
//  HerdWorks
//
//  Created: Phase 5 - All Scanning Events with filtering
//

import SwiftUI
import FirebaseAuth

struct AllScanningEventsView: View {
    @StateObject private var viewModel: AllScanningEventsViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingAddEvent = false
    @State private var selectedEvent: ScanningEvent?
    @State private var filterYear: Int?
    @Environment(\.dismiss) private var dismiss
    
    private let scanningStore: ScanningEventStore
    private let groupStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    
    init(
        scanningStore: ScanningEventStore,
        groupStore: LambingSeasonGroupStore,
        farmStore: FarmStore
    ) {
        self.scanningStore = scanningStore
        self.groupStore = groupStore
        self.farmStore = farmStore
        
        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: AllScanningEventsViewModel(
                scanningStore: scanningStore,
                groupStore: groupStore,
                farmStore: farmStore,
                userId: userId
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    loadingView
                } else if filteredEvents.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("scanning.all_events_title".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    filterMenu
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
            .sheet(isPresented: $showingAddEvent) {
                ScanningEventDetailViewWithSelection(
                    scanningStore: scanningStore,
                    groupStore: groupStore,
                    farms: viewModel.farms,
                    groups: viewModel.groups
                )
            }
            .sheet(item: $selectedEvent) { event in
                ScanningEventDetailView(
                    store: scanningStore,
                    userId: event.userId,
                    farmId: event.farmId,
                    groupId: event.lambingSeasonGroupId,
                    event: event
                )
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) {}
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .alert("lambing.no_groups_title".localized(), isPresented: $viewModel.showNoGroupsAlert) {
                Button("common.ok".localized(), role: .cancel) {}
            } message: {
                Text("lambing.no_groups_message".localized())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredEvents: [ScanningEvent] {
        guard let year = filterYear else {
            return viewModel.events
        }
        
        let calendar = Calendar.current
        return viewModel.events.filter { event in
            let eventYear = calendar.component(.year, from: event.createdAt)
            return eventYear == year
        }
    }
    
    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(viewModel.events.map { calendar.component(.year, from: $0.createdAt) })
        return Array(years).sorted(by: >)
    }
    
    // MARK: - Subviews
    
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
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundStyle(.purple)
            
            VStack(spacing: 8) {
                Text(filterYear != nil ? "scanning.no_events_for_year".localized() : "scanning.empty_title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("scanning.empty_subtitle_all".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if filterYear == nil {
                Button {
                    if viewModel.groups.isEmpty {
                        viewModel.showNoGroupsAlert = true
                    } else {
                        showingAddEvent = true
                    }
                } label: {
                    Label("scanning.add_first_event".localized(), systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
            }
        }
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(filteredEvents) { event in
                AllScanningEventRow(
                    event: event,
                    farmName: viewModel.farmAndGroupName(for: event).farm,
                    groupName: viewModel.farmAndGroupName(for: event).group
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedEvent = event
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteEvent(event)
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
            if viewModel.groups.isEmpty {
                viewModel.showNoGroupsAlert = true
            } else {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    showingAddEvent = true
                }
            }
        } label: {
            Image(systemName: "plus")
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Button {
                filterYear = nil
            } label: {
                Label(
                    "breeding.show_all_years".localized(),
                    systemImage: filterYear == nil ? "checkmark" : "circle"
                )
            }
            
            if !availableYears.isEmpty {
                Divider()
                
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        filterYear = year
                    } label: {
                        let yearString = String(format: "%d", year)
                        Label(
                            yearString,
                            systemImage: filterYear == year ? "checkmark" : "circle"
                        )
                    }
                }
            }
        } label: {
            Image(systemName: filterYear == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}

// MARK: - All Scanning Event Row

private struct AllScanningEventRow: View {
    let event: ScanningEvent
    let farmName: String
    let groupName: String
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: event.createdAt))
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Label(farmName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Label(groupName, systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 20) {
                StatColumn(
                    title: "scanning.ewes_scanned".localized(),
                    value: String(format: "%d", event.ewesScanned),
                    color: .blue
                )
                
                StatColumn(
                    title: "scanning.pregnant".localized(),
                    value: String(format: "%d", event.ewesPregnant),
                    color: .green
                )
                
                StatColumn(
                    title: "scanning.conception_short".localized(),
                    value: String(format: "%.1f%%", event.conceptionRatio),
                    color: .orange
                )
                
                StatColumn(
                    title: "scanning.expected_lambing_pregnant".localized(),
                    value: String(format: "%.0f%%", event.expectedLambingPercentagePregnant),
                    color: .purple
                )
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Stat Column

private struct StatColumn: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    AllScanningEventsView(
        scanningStore: FirestoreScanningEventStore(),
        groupStore: FirestoreLambingSeasonGroupStore(),
        farmStore: FirestoreFarmStore()
    )
    .environmentObject(LanguageManager.shared)
}

