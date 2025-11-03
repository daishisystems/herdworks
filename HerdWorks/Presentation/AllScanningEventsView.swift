//
//  AllScanningEventsView.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import SwiftUI
import FirebaseAuth

struct AllScanningEventsView: View {
    @StateObject private var viewModel: AllScanningEventsViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var selectedEvent: ScanningEvent?
    @State private var selectedFarmId: String?
    @State private var selectedGroupId: String?
    
    private let scanningStore: ScanningEventStore
    
    init(
        scanningStore: ScanningEventStore,
        farmStore: FarmStore,
        groupStore: LambingSeasonGroupStore,
        userId: String
    ) {
        self.scanningStore = scanningStore
        
        _viewModel = StateObject(
            wrappedValue: AllScanningEventsViewModel(
                scanningStore: scanningStore,
                farmStore: farmStore,
                groupStore: groupStore,
                userId: userId
            )
        )
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.groupedEvents.isEmpty {
                ProgressView()
            } else if viewModel.groupedEvents.isEmpty {
                emptyState
            } else {
                eventsList
            }
        }
        .navigationTitle("scanning.all_events_title".localized())
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedEvent) { event in
            if let farmId = selectedFarmId, let groupId = selectedGroupId {
                ScanningEventDetailView(
                    store: scanningStore,
                    userId: event.userId,
                    farmId: farmId,
                    groupId: groupId,
                    event: event
                )
            }
        }
        .alert("common.error".localized(), isPresented: $viewModel.showError) {
            Button("common.ok".localized(), role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadAllEvents()
        }
        .refreshable {
            await viewModel.loadAllEvents()
        }
    }
    
    // MARK: - Views
    
    private var eventsList: some View {
        List {
            ForEach(viewModel.groupedEvents, id: \.group.id) { groupData in
                Section {
                    ForEach(groupData.events) { event in
                        AllScanningEventsRow(
                            event: event,
                            farmName: groupData.farm.name,
                            groupName: groupData.group.displayName
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFarmId = groupData.farm.id
                            selectedGroupId = groupData.group.id
                            selectedEvent = event
                        }
                    }
                } header: {
                    HStack {
                        Text(groupData.farm.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(groupData.group.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("scanning.empty_title".localized())
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("scanning.empty_subtitle_all".localized())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - All Scanning Events Row

struct AllScanningEventsRow: View {
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
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(.blue.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Main metric
                HStack {
                    Text("\(event.ewesMated)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("scanning.ewes_mated_short".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Key metrics in pills
                HStack(spacing: 8) {
                    MetricPill(
                        label: "scanning.conception_short".localized(),
                        value: String(format: "%.1f%%", event.conceptionRatio),
                        color: .green
                    )
                    
                    MetricPill(
                        label: "scanning.fetuses_short".localized(),
                        value: "\(event.scannedFetuses)",
                        color: .orange
                    )
                }
                
                // Date
                Text(dateFormatter.string(from: event.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Metric Pill

struct MetricPill: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Previews

#Preview("With Data") {
    NavigationStack {
        AllScanningEventsView(
            scanningStore: InMemoryScanningEventStore.withMockData(),
            farmStore: InMemoryFarmStore(),
            groupStore: InMemoryLambingSeasonGroupStore(),
            userId: "preview-user"
        )
        .environmentObject(LanguageManager.shared)
    }
}

#Preview("Empty State") {
    NavigationStack {
        AllScanningEventsView(
            scanningStore: InMemoryScanningEventStore(),
            farmStore: InMemoryFarmStore(),
            groupStore: InMemoryLambingSeasonGroupStore(),
            userId: "preview-user"
        )
        .environmentObject(LanguageManager.shared)
    }
}
