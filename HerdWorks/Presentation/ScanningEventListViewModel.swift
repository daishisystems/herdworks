//
//  ScanningEventListViewModel.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation
import Combine

@MainActor
final class ScanningEventListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var events: [ScanningEvent] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var eventToDelete: ScanningEvent?
    
    // MARK: - Private Properties

    private let store: ScanningEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    private var listenerCancellable: AnyCancellable?
    
    // MARK: - Initializer
    
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
        
        print("🔵 [SCANNING-LIST-VM] Initialized for group: \(groupId)")
    }
    
    // MARK: - Public Methods
    
    /// Start listening for real-time updates
    func startListening() {
        print("🔵 [SCANNING-LIST-VM] Starting real-time listener")
        
        listenerCancellable = store.listenAll(
            userId: userId,
            farmId: farmId,
            groupId: groupId
        ) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let events):
                    print("✅ [SCANNING-LIST-VM] Received \(events.count) events from listener")
                    self.events = events
                    self.isLoading = false
                    
                case .failure(let error):
                    print("❌ [SCANNING-LIST-VM] Listener error: \(error.localizedDescription)")
                    self.errorMessage = "error.failed_to_load".localized() + ": \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Stop listening for updates
    func stopListening() {
        print("🔵 [SCANNING-LIST-VM] Stopping listener")
        listenerCancellable?.cancel()
        listenerCancellable = nil
    }
    
    /// Load scanning events (one-time fetch, not real-time)
    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔵 [SCANNING-LIST-VM] Loading scanning events for group: \(groupId)")
            events = try await store.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            print("✅ [SCANNING-LIST-VM] Loaded \(events.count) scanning events")
        } catch {
            print("❌ [SCANNING-LIST-VM] Error loading scanning events: \(error.localizedDescription)")
            errorMessage = "error.failed_to_load".localized() + ": \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Delete a scanning event
    func deleteEvent(_ event: ScanningEvent) async {
        print("🔵 [SCANNING-LIST-VM] Deleting scanning event: \(event.id)")
        
        do {
            try await store.delete(
                userId: userId,
                farmId: farmId,
                groupId: groupId,
                eventId: event.id
            )
            
            // Remove from local array (listener will update too if active)
            events.removeAll { $0.id == event.id }
            
            print("✅ [SCANNING-LIST-VM] Deleted scanning event successfully")
        } catch {
            print("❌ [SCANNING-LIST-VM] Error deleting scanning event: \(error.localizedDescription)")
            errorMessage = "error.failed_to_delete".localized() + ": \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Set the event to delete (triggers confirmation dialog)
    func confirmDelete(_ event: ScanningEvent) {
        eventToDelete = event
    }
    
    /// Clear the delete confirmation
    func cancelDelete() {
        eventToDelete = nil
    }
    
    deinit {
        print("🔵 [SCANNING-LIST-VM] Deinitializing, stopping listener")
        listenerCancellable?.cancel()  // ✅ Direct cancellation works
    }
}
