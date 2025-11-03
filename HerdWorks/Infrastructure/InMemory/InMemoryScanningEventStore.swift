//
//  InMemoryScanningEventStore.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation
import Combine

/// In-memory implementation of ScanningEventStore for testing and previews
final class InMemoryScanningEventStore: ScanningEventStore {
    
    private var events: [ScanningEvent] = []
    private let eventsSubject = PassthroughSubject<[ScanningEvent], Error>()
    
    // MARK: - Initializer
    
    init(events: [ScanningEvent] = []) {
        self.events = events
        print("🟡 InMemoryScanningEventStore initialized with \(events.count) events")
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [ScanningEvent] {
        print("🟡 [MEMORY-FETCH] Fetching scanning events for group: \(groupId)")
        let filtered = events
            .filter { $0.userId == userId && $0.farmId == farmId && $0.lambingSeasonGroupId == groupId }
            .sorted { $0.createdAt > $1.createdAt }
        print("🟡 [MEMORY-FETCH] Returning \(filtered.count) events")
        return filtered
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> ScanningEvent? {
        print("🟡 [MEMORY-FETCH-ID] Fetching event by ID: \(eventId)")
        let event = events.first {
            $0.id == eventId &&
            $0.userId == userId &&
            $0.farmId == farmId &&
            $0.lambingSeasonGroupId == groupId
        }
        if event != nil {
            print("✅ [MEMORY-FETCH-ID] Found event: \(eventId)")
        } else {
            print("⚠️ [MEMORY-FETCH-ID] Event not found: \(eventId)")
        }
        return event
    }
    
    // MARK: - Create Operation
    
    func create(_ event: ScanningEvent) async throws {
        print("🟡 [MEMORY-CREATE] Creating scanning event: \(event.id)")
        events.append(event)
        notifyListeners(for: event)
        print("✅ [MEMORY-CREATE] Created scanning event successfully")
    }
    
    // MARK: - Update Operation
    
    func update(_ event: ScanningEvent) async throws {
        print("🟡 [MEMORY-UPDATE] Updating scanning event: \(event.id)")
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            var updatedEvent = event
            updatedEvent.updatedAt = Date()
            events[index] = updatedEvent
            notifyListeners(for: event)
            print("✅ [MEMORY-UPDATE] Updated scanning event successfully")
        } else {
            print("⚠️ [MEMORY-UPDATE] Event not found: \(event.id)")
        }
    }
    
    // MARK: - Delete Operation
    
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws {
        print("🟡 [MEMORY-DELETE] Deleting scanning event: \(eventId)")
        let initialCount = events.count
        events.removeAll {
            $0.id == eventId &&
            $0.userId == userId &&
            $0.farmId == farmId &&
            $0.lambingSeasonGroupId == groupId
        }
        let deleted = initialCount != events.count
        if deleted {
            print("✅ [MEMORY-DELETE] Deleted scanning event successfully")
            // Notify with updated list
            if let remaining = events.first(where: { $0.userId == userId && $0.farmId == farmId && $0.lambingSeasonGroupId == groupId }) {
                notifyListeners(for: remaining)
            }
        } else {
            print("⚠️ [MEMORY-DELETE] Event not found: \(eventId)")
        }
    }
    
    // MARK: - Real-time Listener
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[ScanningEvent], Error>) -> Void
    ) -> AnyCancellable {
        print("🟡 [MEMORY-LISTEN] Setting up listener for group: \(groupId)")
        
        // Immediately deliver current state
        let currentEvents = events
            .filter { $0.userId == userId && $0.farmId == farmId && $0.lambingSeasonGroupId == groupId }
            .sorted { $0.createdAt > $1.createdAt }
        onChange(.success(currentEvents))
        
        // Subscribe to future changes
        return eventsSubject
            .filter { _ in true } // Filter in the subscription below
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        onChange(.failure(error))
                    }
                },
                receiveValue: { _ in
                    let filtered = self.events
                        .filter { $0.userId == userId && $0.farmId == farmId && $0.lambingSeasonGroupId == groupId }
                        .sorted { $0.createdAt > $1.createdAt }
                    onChange(.success(filtered))
                }
            )
    }
    
    // MARK: - Private Helpers
    
    private func notifyListeners(for event: ScanningEvent) {
        let relevantEvents = events
            .filter { $0.userId == event.userId && $0.farmId == event.farmId && $0.lambingSeasonGroupId == event.lambingSeasonGroupId }
        eventsSubject.send(relevantEvents)
    }
}

// MARK: - Mock Data

extension InMemoryScanningEventStore {
    /// Creates a store with sample data for previews
    static func withMockData(userId: String = "preview-user", farmId: String = "preview-farm", groupId: String = "preview-group") -> InMemoryScanningEventStore {
        let mockEvents = [
            ScanningEvent(
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                ewesMated: 300,
                ewesScanned: 295,
                ewesPregnant: 275,
                ewesNotPregnant: 20,
                ewesWithSingles: 100,
                ewesWithTwins: 150,
                ewesWithTriplets: 25
            ),
            ScanningEvent(
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                ewesMated: 500,
                ewesScanned: 482,
                ewesPregnant: 465,
                ewesNotPregnant: 17,
                ewesWithSingles: 150,
                ewesWithTwins: 250,
                ewesWithTriplets: 65
            ),
            ScanningEvent(
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                ewesMated: 1000,
                ewesScanned: 999,
                ewesPregnant: 890,
                ewesNotPregnant: 109,
                ewesWithSingles: 300,
                ewesWithTwins: 450,
                ewesWithTriplets: 140
            )
        ]
        
        return InMemoryScanningEventStore(events: mockEvents)
    }
}
