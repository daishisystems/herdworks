//
//  BreedingEventListViewModel.swift
//  HerdWorks
//
//  Created by Claude on 2025/10/24.
//

import SwiftUI
import Combine

@MainActor
final class BreedingEventListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [BreedingEvent] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation: Bool = false
    
    // MARK: - Private Properties
    private let store: BreedingEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    private var eventListener: AnyCancellable?
    var eventToDelete: BreedingEvent?
    
    // MARK: - Computed Properties
    var hasEvents: Bool {
        !events.isEmpty
    }
    
    var eventsByYear: [Int: [BreedingEvent]] {
        Dictionary(grouping: events) { $0.year }
    }
    
    var sortedYears: [Int] {
        Array(eventsByYear.keys).sorted(by: >)
    }
    
    // MARK: - Initialization
    init(store: BreedingEventStore, userId: String, farmId: String, groupId: String) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
        
        print("🔵 [BREEDING-LIST] BreedingEventListViewModel initialized")
        print("🔵 [BREEDING-LIST] User ID: \(userId)")
        print("🔵 [BREEDING-LIST] Farm ID: \(farmId)")
        print("🔵 [BREEDING-LIST] Group ID: \(groupId)")
    }
    
    // MARK: - Public Methods
    
    func loadEvents() async {
        print("🔵 [BREEDING-LIST] loadEvents() called")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            events = try await store.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            print("✅ [BREEDING-LIST] Loaded \(events.count) events")
            
            for (index, event) in events.enumerated() {
                print("✅ [BREEDING-LIST] Event \(index): Year \(event.year) - \(event.breedingMethodDescription)")
            }
        } catch {
            print("❌ [BREEDING-LIST] Error loading events: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func attachListener() {
        print("🔵 [BREEDING-LIST] Attaching real-time listener")
        
        eventListener = store.listenAll(userId: userId, farmId: farmId, groupId: groupId) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                
                switch result {
                case .failure(let error):
                    print("❌ [BREEDING-LIST] Listener error: \(error.localizedDescription)")
                    self.errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
                    self.showError = true
                    
                case .success(let events):
                    print("📡 [BREEDING-LIST] Listener update: \(events.count) events")
                    self.events = events
                }
            }
        }
    }
    
    func confirmDelete(_ event: BreedingEvent) {
        print("🔵 [BREEDING-LIST] Confirm delete: Year \(event.year)")
        eventToDelete = event
        showDeleteConfirmation = true
    }
    
    func deleteEvent() async {
        guard let event = eventToDelete else {
            print("⚠️ [BREEDING-LIST] No event to delete")
            return
        }
        
        print("🔵 [BREEDING-LIST] deleteEvent() called")
        print("🔵 [BREEDING-LIST] Event ID: \(event.id)")
        print("🔵 [BREEDING-LIST] Year: \(event.year)")
        
        do {
            try await store.delete(
                userId: userId,
                farmId: farmId,
                groupId: groupId,
                eventId: event.id
            )
            print("✅ [BREEDING-LIST] Event deleted successfully")
            
            // Remove from local array (listener will also update)
            events.removeAll { $0.id == event.id }
            print("✅ [BREEDING-LIST] Removed from local array, now have \(events.count) events")
            
            eventToDelete = nil
        } catch {
            print("❌ [BREEDING-LIST] Error deleting event: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🔵 [BREEDING-LIST] ViewModel deallocating, canceling listener")
        eventListener?.cancel()
    }
}
