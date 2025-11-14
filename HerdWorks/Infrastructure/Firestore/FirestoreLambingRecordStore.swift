//
//  FirestoreLambingRecordStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation
import FirebaseFirestore
import Combine

final class FirestoreLambingRecordStore: LambingRecordStore {
    private let db = Firestore.firestore()
    
    init() {
        print("🔵 FirestoreLambingRecordStore initialized")
    }
    
    // MARK: - Private Helpers
    
    private func collectionPath(userId: String, farmId: String, groupId: String) -> CollectionReference {
        return db.collection("users")
            .document(userId)
            .collection("farms")
            .document(farmId)
            .collection("lambingSeasonGroups")
            .document(groupId)
            .collection("lambingRecords")
    }
    
    private func documentPath(userId: String, farmId: String, groupId: String, recordId: String) -> DocumentReference {
        return collectionPath(userId: userId, farmId: farmId, groupId: groupId).document(recordId)
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [LambingRecord] {
        print("🔵 [LAMBING-FETCH] Starting fetch all lambing records")
        print("🔵 [LAMBING-FETCH] User ID: \(userId)")
        print("🔵 [LAMBING-FETCH] Farm ID: \(farmId)")
        print("🔵 [LAMBING-FETCH] Group ID: \(groupId)")
        
        let path = collectionPath(userId: userId, farmId: farmId, groupId: groupId)
        print("🔵 [LAMBING-FETCH] Path: users/\(userId)/farms/\(farmId)/lambingSeasonGroups/\(groupId)/lambingRecords")
        
        do {
            let snapshot = try await path.getDocuments()
            print("🔵 [LAMBING-FETCH] Got \(snapshot.documents.count) documents")
            
            let records = snapshot.documents.compactMap { doc -> LambingRecord? in
                print("🔵 [LAMBING-FETCH] Processing document: \(doc.documentID)")
                do {
                    let record = try doc.data(as: LambingRecord.self)
                    print("✅ [LAMBING-FETCH] Successfully mapped record: \(record.ewesLambed) ewes, \(record.lambsBorn) lambs")
                    return record
                } catch {
                    print("⚠️ [LAMBING-FETCH] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent first
            let sorted = records.sorted { $0.createdAt > $1.createdAt }
            
            print("✅ [LAMBING-FETCH] Returning \(sorted.count) records")
            return sorted
        } catch {
            print("❌ [LAMBING-FETCH] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, recordId: String) async throws -> LambingRecord? {
        print("🔵 [LAMBING-FETCH-ID] Fetching record by ID: \(recordId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId, recordId: recordId)
        
        do {
            let snapshot = try await docRef.getDocument()
            
            guard snapshot.exists else {
                print("⚠️ [LAMBING-FETCH-ID] Document does not exist")
                return nil
            }
            
            let record = try snapshot.data(as: LambingRecord.self)
            print("✅ [LAMBING-FETCH-ID] Successfully fetched record: \(record.ewesLambed) ewes, \(record.lambsBorn) lambs")
            return record
        } catch {
            print("❌ [LAMBING-FETCH-ID] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Write Operations
    
    func create(_ record: LambingRecord) async throws {
        print("🔵 [LAMBING-CREATE] Creating new record")
        print("🔵 [LAMBING-CREATE] Record ID: \(record.id)")
        print("🔵 [LAMBING-CREATE] Ewes Lambed: \(record.ewesLambed)")
        print("🔵 [LAMBING-CREATE] Lambs Born: \(record.lambsBorn)")
        
        let docRef = documentPath(
            userId: record.userId,
            farmId: record.farmId,
            groupId: record.lambingSeasonGroupId,
            recordId: record.id
        )
        
        do {
            try docRef.setData(from: record)
            print("✅ [LAMBING-CREATE] Successfully created record")
        } catch {
            print("❌ [LAMBING-CREATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func update(_ record: LambingRecord) async throws {
        print("🔵 [LAMBING-UPDATE] Updating record: \(record.id)")

        let docRef = documentPath(
            userId: record.userId,
            farmId: record.farmId,
            groupId: record.lambingSeasonGroupId,
            recordId: record.id
        )

        do {
            var data = try Firestore.Encoder().encode(record)
            // Use server timestamp for updatedAt to avoid clock skew issues
            data["updatedAt"] = FieldValue.serverTimestamp()

            try await docRef.setData(data, merge: true)
            print("✅ [LAMBING-UPDATE] Successfully updated record")
        } catch {
            print("❌ [LAMBING-UPDATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func delete(userId: String, farmId: String, groupId: String, recordId: String) async throws {
        print("🔵 [LAMBING-DELETE] Deleting record: \(recordId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId, recordId: recordId)
        
        do {
            try await docRef.delete()
            print("✅ [LAMBING-DELETE] Successfully deleted record")
        } catch {
            print("❌ [LAMBING-DELETE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Real-time Listener
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[LambingRecord], Error>) -> Void
    ) -> AnyCancellable {
        print("🔵 [LAMBING-LISTEN] Setting up listener for group: \(groupId)")
        
        let path = collectionPath(userId: userId, farmId: farmId, groupId: groupId)
        
        let listener = path.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ [LAMBING-LISTEN] Listener error: \(error.localizedDescription)")
                onChange(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ [LAMBING-LISTEN] Snapshot is nil")
                onChange(.success([]))
                return
            }
            
            print("📡 [LAMBING-LISTEN] Received snapshot with \(snapshot.documents.count) documents")
            
            let records = snapshot.documents.compactMap { doc -> LambingRecord? in
                do {
                    return try doc.data(as: LambingRecord.self)
                } catch {
                    print("⚠️ [LAMBING-LISTEN] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent first
            let sorted = records.sorted { $0.createdAt > $1.createdAt }
            
            print("📡 [LAMBING-LISTEN] Delivering \(sorted.count) records")
            onChange(.success(sorted))
        }
        
        return AnyCancellable {
            print("🔵 [LAMBING-LISTEN] Removing listener for group: \(groupId)")
            listener.remove()
        }
    }
}
