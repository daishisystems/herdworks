//
//  FirestoreScanningEventStore.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation
import FirebaseFirestore
import Combine

final class FirestoreScanningEventStore: ScanningEventStore {
    private let db = Firestore.firestore()
    
    init() {
        print("🔵 FirestoreScanningEventStore initialized")
    }
    
    // MARK: - Private Helpers
    
    private func collectionPath(userId: String, farmId: String, groupId: String) -> CollectionReference {
        return db.collection("users")
            .document(userId)
            .collection("farms")
            .document(farmId)
            .collection("lambingSeasonGroups")
            .document(groupId)
            .collection("scanningEvents")
    }
    
    private func documentPath(userId: String, farmId: String, groupId: String, eventId: String) -> DocumentReference {
        return collectionPath(userId: userId, farmId: farmId, groupId: groupId).document(eventId)
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [ScanningEvent] {
        print("🔵 [SCANNING-FETCH] Starting fetch all scanning events")
        print("🔵 [SCANNING-FETCH] User ID: \(userId)")
        print("🔵 [SCANNING-FETCH] Farm ID: \(farmId)")
        print("🔵 [SCANNING-FETCH] Group ID: \(groupId)")
        
        let path = collectionPath(userId: userId, farmId: farmId, groupId: groupId)
        print("🔵 [SCANNING-FETCH] Path: users/\(userId)/farms/\(farmId)/lambingSeasonGroups/\(groupId)/scanningEvents")
        
        do {
            let snapshot = try await path.getDocuments()
            print("🔵 [SCANNING-FETCH] Got \(snapshot.documents.count) documents")
            
            let events = snapshot.documents.compactMap { doc -> ScanningEvent? in
                print("🔵 [SCANNING-FETCH] Processing document: \(doc.documentID)")
                do {
                    let event = try doc.data(as: ScanningEvent.self)
                    print("✅ [SCANNING-FETCH] Successfully mapped event: \(event.ewesMated) ewes mated - Year \(event.year)")
                    return event
                } catch {
                    print("⚠️ [SCANNING-FETCH] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent first
            let sorted = events.sorted { $0.createdAt > $1.createdAt }
            
            print("✅ [SCANNING-FETCH] Returning \(sorted.count) events")
            return sorted
        } catch {
            print("❌ [SCANNING-FETCH] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> ScanningEvent? {
        print("🔵 [SCANNING-FETCH-ID] Fetching event by ID: \(eventId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId, eventId: eventId)
        
        do {
            let snapshot = try await docRef.getDocument()
            
            guard snapshot.exists else {
                print("⚠️ [SCANNING-FETCH-ID] Document does not exist")
                return nil
            }
            
            let event = try snapshot.data(as: ScanningEvent.self)
            print("✅ [SCANNING-FETCH-ID] Successfully fetched event: \(event.ewesMated) ewes mated - Year \(event.year)")
            return event
        } catch {
            print("❌ [SCANNING-FETCH-ID] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Create Operation
    
    func create(_ event: ScanningEvent) async throws {
        print("🔵 [SCANNING-CREATE] Creating new scanning event")
        print("🔵 [SCANNING-CREATE] Event ID: \(event.id)")
        print("🔵 [SCANNING-CREATE] Ewes Mated: \(event.ewesMated)")
        
        let docRef = documentPath(
            userId: event.userId,
            farmId: event.farmId,
            groupId: event.lambingSeasonGroupId,
            eventId: event.id
        )
        
        do {
            try docRef.setData(from: event)
            print("✅ [SCANNING-CREATE] Successfully created scanning event: \(event.id)")
        } catch {
            print("❌ [SCANNING-CREATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Update Operation
    
    func update(_ event: ScanningEvent) async throws {
        print("🔵 [SCANNING-UPDATE] Updating scanning event: \(event.id)")
        
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        
        let docRef = documentPath(
            userId: event.userId,
            farmId: event.farmId,
            groupId: event.lambingSeasonGroupId,
            eventId: event.id
        )
        
        do {
            try docRef.setData(from: updatedEvent)
            print("✅ [SCANNING-UPDATE] Successfully updated scanning event: \(event.id)")
        } catch {
            print("❌ [SCANNING-UPDATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Delete Operation
    
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws {
        print("🔵 [SCANNING-DELETE] Deleting scanning event: \(eventId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId, eventId: eventId)
        
        do {
            try await docRef.delete()
            print("✅ [SCANNING-DELETE] Successfully deleted scanning event: \(eventId)")
        } catch {
            print("❌ [SCANNING-DELETE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Real-time Listener
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[ScanningEvent], Error>) -> Void
    ) -> AnyCancellable {
        print("🔵 [SCANNING-LISTEN] Setting up real-time listener")
        print("🔵 [SCANNING-LISTEN] User ID: \(userId)")
        print("🔵 [SCANNING-LISTEN] Farm ID: \(farmId)")
        print("🔵 [SCANNING-LISTEN] Group ID: \(groupId)")
        
        let path = collectionPath(userId: userId, farmId: farmId, groupId: groupId)
        
        let listener = path.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ [SCANNING-LISTEN] Error: \(error.localizedDescription)")
                onChange(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ [SCANNING-LISTEN] No snapshot received")
                onChange(.success([]))
                return
            }
            
            print("🔵 [SCANNING-LISTEN] Received snapshot with \(snapshot.documents.count) documents")
            
            let events = snapshot.documents.compactMap { doc -> ScanningEvent? in
                do {
                    return try doc.data(as: ScanningEvent.self)
                } catch {
                    print("⚠️ [SCANNING-LISTEN] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent first
            let sorted = events.sorted { $0.createdAt > $1.createdAt }
            
            print("✅ [SCANNING-LISTEN] Delivering \(sorted.count) events")
            onChange(.success(sorted))
        }
        
        return AnyCancellable {
            print("🔵 [SCANNING-LISTEN] Removing listener")
            listener.remove()
        }
    }
}
