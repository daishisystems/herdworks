//
//  BreedingEventListView.swift
//  HerdWorks
//
//  Updated: Phase 4 - Fixed icons and number formatting
//

import SwiftUI
import FirebaseAuth

struct BreedingEventListView: View {
    @StateObject private var viewModel: BreedingEventListViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingAddEvent = false
    @State private var selectedEvent: BreedingEvent?
    
    private let store: BreedingEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    private let groupName: String
    
    init(
        store: BreedingEventStore,
        userId: String,
        farmId: String,
        groupId: String,
        groupName: String
    ) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
        self.groupName = groupName
        
        _viewModel = StateObject(
            wrappedValue: BreedingEventListViewModel(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId
            )
        )
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.events.isEmpty {
                loadingView
            } else if viewModel.events.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .navigationTitle("breeding.list_title".localized())
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
        }
        .task {
            await viewModel.loadEvents()
            viewModel.attachListener()
        }
        .sheet(isPresented: $showingAddEvent) {
            BreedingEventDetailView(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId,
                event: nil
            )
        }
        .sheet(item: $selectedEvent) { event in
            BreedingEventDetailView(
                store: store,
                userId: userId,
                farmId: farmId,
                groupId: groupId,
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
        .alert(
            "breeding.delete_title".localized(),
            isPresented: $viewModel.showDeleteConfirmation,
            presenting: viewModel.eventToDelete
        ) { event in
            Button("common.cancel".localized(), role: .cancel) {}
            Button("common.delete".localized(), role: .destructive) {
                Task {
                    await viewModel.deleteEvent()
                }
            }
        } message: { event in
            // FIXED: Force non-localized integer formatting
            let yearString = String(format: "%d", event.year)
            Text(String(format: "breeding.delete_message".localized(), "\(groupName) - \(yearString)"))
        }
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
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            VStack(spacing: 8) {
                Text("breeding.empty_title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("breeding.empty_subtitle".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    showingAddEvent = true
                }
            } label: {
                Label("breeding.add_first_event".localized(), systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(viewModel.events) { event in
                BreedingEventRow(event: event)
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
    
    private var addButton: some View {
        Button {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                showingAddEvent = true
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Breeding Event Row

private struct BreedingEventRow: View {
    let event: BreedingEvent
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon based on mating type
            Circle()
                .fill(Color.green.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // FIXED: Force non-localized integer formatting
                let yearString = String(format: "%d", event.year)
                Text("\("breeding.year".localized()): \(yearString)")
                    .font(.headline)
                
                // Breeding method
                Text(event.breedingMethodDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Dates
                if let date = event.displayDate {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Number of ewes
                let ewesString = String(format: "%d", event.numberOfEwesMated)
                Text("\("breeding.number_of_ewes".localized()): \(ewesString)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Indicators
            VStack(alignment: .trailing, spacing: 4) {
                // Natural mating duration
                if let days = event.naturalMatingDays {
                    let daysString = String(format: "%d", days)
                    Label("\(daysString)d", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Follow-up rams indicator
                if event.usedFollowUpRams {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
    
    // FIXED: Always return valid SF Symbol name based on mating type
    private var iconName: String {
        switch event.matingType {
        case .cervicalAI, .laparoscopicAI:
            return "syringe.fill"
        case .naturalMating:
            return "heart.fill"
        }
    }
}

// MARK: - Previews

#Preview("With Events") {
    NavigationStack {
        BreedingEventListView(
            store: InMemoryBreedingEventStore.withSampleData(),
            userId: "preview-user",
            farmId: "preview-farm",
            groupId: "preview-group",
            groupName: "Test Group"
        )
    }
    .environmentObject(LanguageManager.shared)
}

#Preview("Empty State") {
    NavigationStack {
        BreedingEventListView(
            store: InMemoryBreedingEventStore(),
            userId: "preview-user",
            farmId: "preview-farm",
            groupId: "preview-group",
            groupName: "Test Group"
        )
    }
    .environmentObject(LanguageManager.shared)
}

