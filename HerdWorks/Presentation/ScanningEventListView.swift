//
//  ScanningEventListView.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import SwiftUI
import FirebaseAuth

struct ScanningEventListView: View {
    @StateObject private var viewModel: ScanningEventListViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var showingAddSheet = false
    @State private var selectedEvent: ScanningEvent?
    
    private let store: ScanningEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    
    init(
        store: ScanningEventStore,
        userId: String,
        farmId: String,
        groupId: String
    ) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
        
        _viewModel = StateObject(
            wrappedValue: ScanningEventListViewModel(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId
            )
        )
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.events.isEmpty {
                ProgressView()
            } else if viewModel.events.isEmpty {
                emptyState
            } else {
                eventsList
            }
        }
        .navigationTitle("scanning.list_title".localized())
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ScanningEventDetailView(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId
            )
        }
        .sheet(item: $selectedEvent) { event in
            ScanningEventDetailView(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId,
                event: event
            )
        }
        .alert("common.error".localized(), isPresented: $viewModel.showError) {
            Button("common.ok".localized(), role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert(
            "common.delete".localized(),
            isPresented: Binding(
                get: { viewModel.eventToDelete != nil },
                set: { if !$0 { viewModel.cancelDelete() } }
            ),
            presenting: viewModel.eventToDelete
        ) { event in
            Button("common.cancel".localized(), role: .cancel) {
                viewModel.cancelDelete()
            }
            Button("common.delete".localized(), role: .destructive) {
                Task {
                    await viewModel.deleteEvent(event)
                }
            }
        } message: { event in
            Text("scanning.delete_confirmation_message".localized())
        }
        .task {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    // MARK: - Views
    
    private var eventsList: some View {
        List {
            ForEach(viewModel.events) { event in
                ScanningEventRow(event: event)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(event)
                        } label: {
                            Label("common.delete".localized(), systemImage: "trash")
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
            
            Text("scanning.empty_subtitle".localized())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingAddSheet = true
            } label: {
                Text("scanning.add_first_event".localized())
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}

// MARK: - Scanning Event Row

struct ScanningEventRow: View {
    let event: ScanningEvent
    
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
                HStack {
                    Text("\(event.ewesMated)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("scanning.ewes_mated_short".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    // Conception Ratio
                    HStack(spacing: 4) {
                        Text("scanning.conception_short".localized() + ":")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f%%", event.conceptionRatio))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                    
                    // Fetuses
                    HStack(spacing: 4) {
                        Text("scanning.fetuses_short".localized() + ":")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(event.scannedFetuses)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }
                }
                
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

// MARK: - Previews

#Preview("With Data") {
    NavigationStack {
        ScanningEventListView(
            store: InMemoryScanningEventStore.withMockData(),
            userId: "preview-user",
            farmId: "preview-farm",
            groupId: "preview-group"
        )
        .environmentObject(LanguageManager.shared)
    }
}

#Preview("Empty State") {
    NavigationStack {
        ScanningEventListView(
            store: InMemoryScanningEventStore(),
            userId: "preview-user",
            farmId: "preview-farm",
            groupId: "preview-group"
        )
        .environmentObject(LanguageManager.shared)
    }
}
