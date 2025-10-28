//
//  FirestoreBreedingEventStore.swift
//  HerdWorks
//
//  Updated: Phase 4 - Works with new BreedingEvent model
//

import Foundation
import FirebaseFirestore
import Combine

final class FirestoreBreedingEventStore: BreedingEventStore {
    private let db = Firestore.firestore()
    
    init() {
        print("🔵 FirestoreBreedingEventStore initialized")
    }
    
    // MARK: - Private Helpers
    
    private func collectionPath(userId: String, farmId: String, groupId: String) -> CollectionReference {
        return db.collection("users")
            .document(userId)
            .collection("farms")
            .document(farmId)
            .collection("lambingSeasonGroups")
            .document(groupId)
            .collection("breedingEvents")
    }
    
    private func documentPath(userId: String, farmId: String, groupId: String, eventId: String) -> DocumentReference {
        return collectionPath(userId: userId, farmId: farmId, groupId: groupId).document(eventId)
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [BreedingEvent] {
        print("🔵 [BREEDING-FETCH] Starting fetch all breeding events")
        print("🔵 [BREEDING-FETCH] User ID: \(userId)")
        print("🔵 [BREEDING-FETCH] Farm ID: \(farmId)")
        print("🔵 [BREEDING-FETCH] Group ID: \(groupId)")
        
        let path = collectionPath(userId: userId, farmId: farmId, groupId: groupId)
        print("🔵 [BREEDING-FETCH] Path: users/\(userId)/farms/\(farmId)/lambingSeasonGroups/\(groupId)/breedingEvents")
        
        do {
            let snapshot = try await path.getDocuments()
            print("🔵 [BREEDING-FETCH] Got \(snapshot.documents.count) documents")
            
            let events = snapshot.documents.compactMap { doc -> BreedingEvent? in
                print("🔵 [BREEDING-FETCH] Processing document: \(doc.documentID)")
                do {
                    let event = try doc.data(as: BreedingEvent.self)
                    print("✅ [BREEDING-FETCH] Successfully mapped event: \(event.matingType.displayName) - Year \(event.year)")
                    return event
                } catch {
                    print("⚠️ [BREEDING-FETCH] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent calculation date first
            let sorted = events.sorted { event1, event2 in
                guard let date1 = event1.displayDate,
                      let date2 = event2.displayDate else {
                    return false
                }
                return date1 > date2
            }
            
            print("✅ [BREEDING-FETCH] Returning \(sorted.count) events")
            return sorted
        } catch {
            print("❌ [BREEDING-FETCH] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> BreedingEvent? {
        print("🔵 [BREEDING-FETCH-ID] Fetching event by ID: \(eventId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId, eventId: eventId)
        
        do {
            let snapshot = try await docRef.getDocument()
            
            guard snapshot.exists else {
                print("⚠️ [BREEDING-FETCH-ID] Document does not exist")
                return nil
            }
            
            let event = try snapshot.data(as: BreedingEvent.self)
            print("✅ [BREEDING-FETCH-ID] Successfully fetched event: \(event.matingType.displayName) - Year \(event.year)")
            return event
        } catch {
            print("❌ [BREEDING-FETCH-ID] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Write Operations
    
    func create(_ event: BreedingEvent) async throws {
        print("🔵 [BREEDING-CREATE] Starting create breeding event")
        print("🔵 [BREEDING-CREATE] Event ID: \(event.id)")
        print("🔵 [BREEDING-CREATE] User ID: \(event.userId)")
        print("🔵 [BREEDING-CREATE] Farm ID: \(event.farmId)")
        print("🔵 [BREEDING-CREATE] Group ID: \(event.lambingSeasonGroupId)")
        print("🔵 [BREEDING-CREATE] Mating Type: \(event.matingType.displayName)")
        print("🔵 [BREEDING-CREATE] Number of Ewes: \(event.numberOfEwesMated)")
        print("🔵 [BREEDING-CREATE] Year: \(event.year)")
        
        let docRef = documentPath(
            userId: event.userId,
            farmId: event.farmId,
            groupId: event.lambingSeasonGroupId,
            eventId: event.id
        )
        print("🔵 [BREEDING-CREATE] Path: users/\(event.userId)/farms/\(event.farmId)/lambingSeasonGroups/\(event.lambingSeasonGroupId)/breedingEvents/\(event.id)")
        
        do {
            try docRef.setData(from: event)
            print("✅ [BREEDING-CREATE] Event created successfully")
        } catch {
            print("❌ [BREEDING-CREATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func update(_ event: BreedingEvent) async throws {
        print("🔵 [BREEDING-UPDATE] Starting event update")
        print("🔵 [BREEDING-UPDATE] Event ID: \(event.id)")
        print("🔵 [BREEDING-UPDATE] User ID: \(event.userId)")
        print("🔵 [BREEDING-UPDATE] Farm ID: \(event.farmId)")
        print("🔵 [BREEDING-UPDATE] Group ID: \(event.lambingSeasonGroupId)")
        print("🔵 [BREEDING-UPDATE] Mating Type: \(event.matingType.displayName)")
        print("🔵 [BREEDING-UPDATE] Number of Ewes: \(event.numberOfEwesMated)")
        print("🔵 [BREEDING-UPDATE] Year: \(event.year)")
        
        // Create updated event with new timestamp
        let updatedEvent = BreedingEvent(
            id: event.id,
            userId: event.userId,
            farmId: event.farmId,
            lambingSeasonGroupId: event.lambingSeasonGroupId,
            matingType: event.matingType,
            numberOfEwesMated: event.numberOfEwesMated,
            naturalMatingStart: event.naturalMatingStart,
            naturalMatingDays: event.naturalMatingDays,
            aiDate: event.aiDate,
            usedFollowUpRams: event.usedFollowUpRams,
            followUpRamsIn: event.followUpRamsIn,
            followUpRamsOut: event.followUpRamsOut
        )
        
        let docRef = documentPath(
            userId: event.userId,
            farmId: event.farmId,
            groupId: event.lambingSeasonGroupId,
            eventId: event.id
        )
        print("🔵 [BREEDING-UPDATE] Path: users/\(event.userId)/farms/\(event.farmId)/lambingSeasonGroups/\(event.lambingSeasonGroupId)/breedingEvents/\(event.id)")
        
        do {
            try docRef.setData(from: updatedEvent)
            print("✅ [BREEDING-UPDATE] Event updated successfully")
        } catch {
            print("❌ [BREEDING-UPDATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws {
        print("🔵 [BREEDING-DELETE] Starting delete breeding event")
        print("🔵 [BREEDING-DELETE] Event ID: \(eventId)")
        print("🔵 [BREEDING-DELETE] User ID: \(userId)")
        print("🔵 [BREEDING-DELETE] Farm ID: \(farmId)")
        print("🔵 [BREEDING-DELETE] Group ID: \(groupId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId, eventId: eventId)
        print("🔵 [BREEDING-DELETE] Path: users/\(userId)/farms/\(farmId)/lambingSeasonGroups/\(groupId)/breedingEvents/\(eventId)")
        
        do {
            try await docRef.delete()
            print("✅ [BREEDING-DELETE] Event deleted successfully")
        } catch {
            print("❌ [BREEDING-DELETE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Real-time Listeners
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[BreedingEvent], Error>) -> Void
    ) -> AnyCancellable {
        let path = collectionPath(userId: userId, farmId: farmId, groupId: groupId)
        print("🔵 [BREEDING-LISTEN] Attaching listener for group: \(groupId)")
        
        let listener = path.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ [BREEDING-LISTEN] Snapshot error: \(error)")
                onChange(.failure(error))
                return
            }
            
            guard let docs = snapshot?.documents else {
                print("⚠️ [BREEDING-LISTEN] No documents in snapshot")
                onChange(.success([]))
                return
            }
            
            let events: [BreedingEvent] = docs.compactMap { doc in
                do {
                    let event = try doc.data(as: BreedingEvent.self)
                    return event
                } catch {
                    print("⚠️ [BREEDING-LISTEN] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent calculation date first
            let sorted = events.sorted { event1, event2 in
                guard let date1 = event1.displayDate,
                      let date2 = event2.displayDate else {
                    return false
                }
                return date1 > date2
            }
            
            print("📡 [BREEDING-LISTEN] Emitting \(sorted.count) events for group: \(groupId)")
            onChange(.success(sorted))
        }
        
        return AnyCancellable {
            print("🔵 [BREEDING-LISTEN] Removing listener for group: \(groupId)")
            listener.remove()
        }
    }
}
