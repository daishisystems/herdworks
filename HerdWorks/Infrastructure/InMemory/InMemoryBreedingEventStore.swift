//
//  InMemoryBreedingEventStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/24.
//

import Foundation
import Combine

/// In-memory implementation of BreedingEventStore for testing and SwiftUI previews
final class InMemoryBreedingEventStore: BreedingEventStore {
    // MARK: - Properties
    
    private var events: [BreedingEvent] = []
    private var listeners: [String: PassthroughSubject<Result<[BreedingEvent], Error>, Never>] = [:]
    
    // MARK: - Initialization
    
    init(initialEvents: [BreedingEvent] = []) {
        self.events = initialEvents
        print("🔵 [IN-MEMORY-BREEDING] Initialized with \(initialEvents.count) events")
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [BreedingEvent] {
        print("🔵 [IN-MEMORY-BREEDING] fetchAll for group: \(groupId)")
        
        let filtered = events.filter {
            $0.userId == userId &&
            $0.farmId == farmId &&
            $0.lambingSeasonGroupId == groupId
        }
        
        // Sort by most recent calculation date first
        let sorted = filtered.sorted { event1, event2 in
            guard let date1 = event1.displayDate,
                  let date2 = event2.displayDate else {
                return false
            }
            return date1 > date2
        }
        
        print("✅ [IN-MEMORY-BREEDING] Returning \(sorted.count) events")
        return sorted
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> BreedingEvent? {
        print("🔵 [IN-MEMORY-BREEDING] fetchById: \(eventId)")
        
        let event = events.first {
            $0.id == eventId &&
            $0.userId == userId &&
            $0.farmId == farmId &&
            $0.lambingSeasonGroupId == groupId
        }
        
        if let event = event {
            print("✅ [IN-MEMORY-BREEDING] Found event: Year \(event.year)")
        } else {
            print("⚠️ [IN-MEMORY-BREEDING] Event not found")
        }
        
        return event
    }
    
    // MARK: - Write Operations
    
    func create(_ event: BreedingEvent) async throws {
        print("🔵 [IN-MEMORY-BREEDING] create: \(event.id)")
        
        events.append(event)
        print("✅ [IN-MEMORY-BREEDING] Event created, total: \(events.count)")
        
        // Notify listeners
        await notifyListeners(for: event.userId, farmId: event.farmId, groupId: event.lambingSeasonGroupId)
    }
    
    func update(_ event: BreedingEvent) async throws {
        print("🔵 [IN-MEMORY-BREEDING] update: \(event.id)")
        
        guard let index = events.firstIndex(where: { $0.id == event.id }) else {
            print("❌ [IN-MEMORY-BREEDING] Event not found for update")
            throw NSError(domain: "InMemoryBreedingEventStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Event not found"
            ])
        }
        
        // Update with new timestamp
        var updatedEvent = event
        updatedEvent = BreedingEvent(
            id: event.id,
            userId: event.userId,
            farmId: event.farmId,
            lambingSeasonGroupId: event.lambingSeasonGroupId,
            aiDate: event.aiDate,
            naturalMatingStart: event.naturalMatingStart,
            naturalMatingEnd: event.naturalMatingEnd,
            usedFollowUpRams: event.usedFollowUpRams,
            followUpRamsIn: event.followUpRamsIn,
            followUpRamsOut: event.followUpRamsOut,
            createdAt: event.createdAt,
            updatedAt: Date()
        )
        
        events[index] = updatedEvent
        print("✅ [IN-MEMORY-BREEDING] Event updated")
        
        // Notify listeners
        await notifyListeners(for: event.userId, farmId: event.farmId, groupId: event.lambingSeasonGroupId)
    }
    
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws {
        print("🔵 [IN-MEMORY-BREEDING] delete: \(eventId)")
        
        guard let index = events.firstIndex(where: { $0.id == eventId }) else {
            print("❌ [IN-MEMORY-BREEDING] Event not found for deletion")
            throw NSError(domain: "InMemoryBreedingEventStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Event not found"
            ])
        }
        
        events.remove(at: index)
        print("✅ [IN-MEMORY-BREEDING] Event deleted, remaining: \(events.count)")
        
        // Notify listeners
        await notifyListeners(for: userId, farmId: farmId, groupId: groupId)
    }
    
    // MARK: - Real-time Listeners
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[BreedingEvent], Error>) -> Void
    ) -> AnyCancellable {
        let key = listenerKey(userId: userId, farmId: farmId, groupId: groupId)
        print("🔵 [IN-MEMORY-BREEDING] Attaching listener: \(key)")
        
        // Create subject if doesn't exist
        if listeners[key] == nil {
            listeners[key] = PassthroughSubject<Result<[BreedingEvent], Error>, Never>()
        }
        
        // Immediately emit current events
        Task {
            let currentEvents = try? await fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            onChange(.success(currentEvents ?? []))
        }
        
        // Subscribe to future updates
        let cancellable = listeners[key]!.sink { result in
            onChange(result)
        }
        
        return AnyCancellable {
            print("🔵 [IN-MEMORY-BREEDING] Removing listener: \(key)")
            cancellable.cancel()
        }
    }
    
    // MARK: - Private Helpers
    
    private func listenerKey(userId: String, farmId: String, groupId: String) -> String {
        return "\(userId)_\(farmId)_\(groupId)"
    }
    
    private func notifyListeners(for userId: String, farmId: String, groupId: String) async {
        let key = listenerKey(userId: userId, farmId: farmId, groupId: groupId)
        
        guard let subject = listeners[key] else { return }
        
        do {
            let updatedEvents = try await fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            print("📡 [IN-MEMORY-BREEDING] Notifying listeners: \(updatedEvents.count) events")
            subject.send(.success(updatedEvents))
        } catch {
            print("❌ [IN-MEMORY-BREEDING] Error notifying listeners: \(error)")
            subject.send(.failure(error))
        }
    }
}

// MARK: - Preview Helpers

extension InMemoryBreedingEventStore {
    /// Creates a store with sample breeding events for previews
    static func withSampleData() -> InMemoryBreedingEventStore {
        let userId = "preview-user"
        let farmId = "preview-farm"
        let groupId = "preview-group"
        
        let calendar = Calendar.current
        let now = Date()
        
        let events = [
            // AI breeding only
            BreedingEvent(
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                aiDate: calendar.date(byAdding: .day, value: -30, to: now),
                usedFollowUpRams: false
            ),
            
            // Natural mating only
            BreedingEvent(
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                naturalMatingStart: calendar.date(byAdding: .day, value: -60, to: now),
                naturalMatingEnd: calendar.date(byAdding: .day, value: -30, to: now),
                usedFollowUpRams: false
            ),
            
            // Both AI and natural with follow-up rams
            BreedingEvent(
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                aiDate: calendar.date(byAdding: .day, value: -90, to: now),
                naturalMatingStart: calendar.date(byAdding: .day, value: -90, to: now),
                naturalMatingEnd: calendar.date(byAdding: .day, value: -70, to: now),
                usedFollowUpRams: true,
                followUpRamsIn: calendar.date(byAdding: .day, value: -60, to: now),
                followUpRamsOut: calendar.date(byAdding: .day, value: -50, to: now)
            )
        ]
        
        return InMemoryBreedingEventStore(initialEvents: events)
    }
}
