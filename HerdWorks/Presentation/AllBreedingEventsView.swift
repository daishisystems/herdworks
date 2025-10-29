//
//  AllBreedingEventsView.swift
//  HerdWorks
//
//  Updated: Phase 4 - Fixed number formatting
//

import SwiftUI
import FirebaseAuth

struct AllBreedingEventsView: View {
    @StateObject private var viewModel: AllBreedingEventsViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingAddEvent = false
    @State private var selectedEvent: BreedingEvent?
    @State private var filterYear: Int?
    @Environment(\.dismiss) private var dismiss
    
    private let eventStore: BreedingEventStore
    private let groupStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    
    init(
        eventStore: BreedingEventStore,
        groupStore: LambingSeasonGroupStore,
        farmStore: FarmStore
    ) {
        self.eventStore = eventStore
        self.groupStore = groupStore
        self.farmStore = farmStore
        
        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(
            wrappedValue: AllBreedingEventsViewModel(
                eventStore: eventStore,
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
            .navigationTitle("breeding.all_events_title".localized())
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
                BreedingEventDetailViewWithSelection(
                    eventStore: eventStore,
                    groupStore: groupStore,
                    farms: viewModel.farms,
                    groups: viewModel.groups
                )
            }
            .sheet(item: $selectedEvent) { event in
                BreedingEventDetailView(
                    store: eventStore,
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
            .alert("breeding.no_groups_title".localized(), isPresented: $viewModel.showNoGroupsAlert) {
                Button("common.ok".localized(), role: .cancel) {}
            } message: {
                Text("breeding.no_groups_message".localized())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredEvents: [BreedingEvent] {
        guard let year = filterYear else {
            return viewModel.events
        }
        return viewModel.events.filter { $0.year == year }
    }
    
    private var availableYears: [Int] {
        let years = Set(viewModel.events.map { $0.year })
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
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            VStack(spacing: 8) {
                Text(filterYear != nil ? "breeding.no_events_for_year".localized() : "breeding.no_events".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("breeding.no_events_subtitle".localized())
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
        }
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(filteredEvents) { event in
                AllBreedingEventRow(
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
                showingAddEvent = true
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
                        // FIXED: Force non-localized formatting
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

// MARK: - All Breeding Event Row

private struct AllBreedingEventRow: View {
    let event: BreedingEvent
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
                    // FIXED: Force non-localized integer formatting
                    let yearString = String(format: "%d", event.year)
                    Text("\("breeding.year".localized()): \(yearString)")
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
            
            // Details
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("breeding.breeding_method".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(event.breedingMethodDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("breeding.number_of_ewes".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // FIXED: Force non-localized integer formatting
                    let ewesString = String(format: "%d", event.numberOfEwesMated)
                    Text(ewesString)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if let days = event.naturalMatingDays {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("breeding.natural_days".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        // FIXED: Force non-localized integer formatting
                        let daysString = String(format: "%d", days)
                        Text("\(daysString) \("lambing.days".localized())")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                if event.usedFollowUpRams, let days = event.followUpDaysIn {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("breeding.followup_days".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        // FIXED: Force non-localized integer formatting
                        let daysString = String(format: "%d", days)
                        Text("\(daysString) \("lambing.days".localized())")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

