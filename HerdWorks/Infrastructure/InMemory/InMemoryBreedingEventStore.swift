//
//  InMemoryBreedingEventStore.swift
//  HerdWorks
//
//  Updated: Phase 4 - Works with new BreedingEvent model
//

import Foundation
import Combine

final class InMemoryBreedingEventStore: BreedingEventStore {
    private var events: [BreedingEvent] = []
    private var listeners: [UUID: (Result<[BreedingEvent], Error>) -> Void] = [:]
    
    init() {
        print("🔵 [IN-MEMORY-BREEDING] InMemoryBreedingEventStore initialized")
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [BreedingEvent] {
        print("🔵 [IN-MEMORY-BREEDING] fetchAll")
        let filtered = events.filter { $0.userId == userId && $0.farmId == farmId && $0.lambingSeasonGroupId == groupId }
        
        // Sort by most recent date first
        let sorted = filtered.sorted { event1, event2 in
            guard let date1 = event1.displayDate,
                  let date2 = event2.displayDate else {
                return false
            }
            return date1 > date2
        }
        
        return sorted
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> BreedingEvent? {
        print("🔵 [IN-MEMORY-BREEDING] fetchById: \(eventId)")
        return events.first { $0.id == eventId }
    }
    
    // MARK: - Write Operations
    
    func create(_ event: BreedingEvent) async throws {
        print("🔵 [IN-MEMORY-BREEDING] create: \(event.id)")
        events.append(event)
        notifyListeners(for: event.userId, farmId: event.farmId, groupId: event.lambingSeasonGroupId)
    }
    
    func update(_ event: BreedingEvent) async throws {
        print("🔵 [IN-MEMORY-BREEDING] update: \(event.id)")
        
        guard let index = events.firstIndex(where: { $0.id == event.id }) else {
            throw NSError(domain: "InMemoryBreedingEventStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        
        events[index] = event
        print("✅ [IN-MEMORY-BREEDING] Event updated")
        
        notifyListeners(for: event.userId, farmId: event.farmId, groupId: event.lambingSeasonGroupId)
    }
    
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws {
        print("🔵 [IN-MEMORY-BREEDING] delete: \(eventId)")
        
        guard let index = events.firstIndex(where: { $0.id == eventId }) else {
            throw NSError(domain: "InMemoryBreedingEventStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        
        events.remove(at: index)
        print("✅ [IN-MEMORY-BREEDING] Event deleted")
        
        notifyListeners(for: userId, farmId: farmId, groupId: groupId)
    }
    
    // MARK: - Real-time Listeners
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[BreedingEvent], Error>) -> Void
    ) -> AnyCancellable {
        let listenerId = UUID()
        print("🔵 [IN-MEMORY-BREEDING] Attaching listener: \(listenerId)")
        
        listeners[listenerId] = onChange
        
        // Send initial data
        Task {
            let filtered = try await fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            onChange(.success(filtered))
        }
        
        return AnyCancellable { [weak self] in
            print("🔵 [IN-MEMORY-BREEDING] Removing listener: \(listenerId)")
            self?.listeners.removeValue(forKey: listenerId)
        }
    }
    
    // MARK: - Private Helpers
    
    private func notifyListeners(for userId: String, farmId: String, groupId: String) {
        Task {
            let filtered = try await fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            
            for listener in listeners.values {
                listener(.success(filtered))
            }
        }
    }
}

// MARK: - Sample Data

extension InMemoryBreedingEventStore {
    static func withSampleData() -> InMemoryBreedingEventStore {
        let store = InMemoryBreedingEventStore()
        
        // Sample Event 1: Natural Mating
        let event1 = BreedingEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            matingType: .naturalMating,
            numberOfEwesMated: 300,
            naturalMatingStart: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
            naturalMatingDays: 2
        )
        
        // Sample Event 2: Cervical AI with follow-up
        let event2 = BreedingEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            matingType: .cervicalAI,
            numberOfEwesMated: 500,
            aiDate: Calendar.current.date(byAdding: .day, value: -20, to: Date()),
            usedFollowUpRams: true,
            followUpRamsIn: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            followUpRamsOut: Calendar.current.date(byAdding: .day, value: -13, to: Date())
        )
        
        // Sample Event 3: Laparoscopic AI without follow-up
        let event3 = BreedingEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            matingType: .laparoscopicAI,
            numberOfEwesMated: 250,
            aiDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            usedFollowUpRams: false
        )
        
        store.events = [event1, event2, event3]
        
        return store
    }
}
