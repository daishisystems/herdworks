//
//  FirestoreLambingSeasonGroupStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import Foundation
import FirebaseFirestore

final class FirestoreLambingSeasonGroupStore: LambingSeasonGroupStore {
    private let db = Firestore.firestore()
    
    init() {
        print("🔵 FirestoreLambingSeasonGroupStore initialized")
    }
    
    // MARK: - Private Helpers
    
    private func collectionPath(userId: String, farmId: String) -> CollectionReference {
        return db.collection("users")
            .document(userId)
            .collection("farms")
            .document(farmId)
            .collection("lambingSeasonGroups")
    }
    
    private func documentPath(userId: String, farmId: String, groupId: String) -> DocumentReference {
        return collectionPath(userId: userId, farmId: farmId).document(groupId)
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String) async throws -> [LambingSeasonGroup] {
        print("🔵 [LSG-FETCH] Starting fetch all lambing season groups")
        print("🔵 [LSG-FETCH] User ID: \(userId)")
        print("🔵 [LSG-FETCH] Farm ID: \(farmId)")
        
        let path = collectionPath(userId: userId, farmId: farmId)
        print("🔵 [LSG-FETCH] Path: users/\(userId)/farms/\(farmId)/lambingSeasonGroups")
        
        do {
            let snapshot = try await path.getDocuments()
            print("🔵 [LSG-FETCH] Got \(snapshot.documents.count) documents")
            
            let groups = snapshot.documents.compactMap { doc -> LambingSeasonGroup? in
                print("🔵 [LSG-FETCH] Processing document: \(doc.documentID)")
                do {
                    let group = try doc.data(as: LambingSeasonGroup.self)  // ✅ Keep try HERE
                    print("✅ [LSG-FETCH] Successfully mapped group: \(group.displayName)")
                    return group
                } catch {
                    print("⚠️ [LSG-FETCH] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ [LSG-FETCH] Returning \(groups.count) groups")
            return groups.sorted { $0.matingStart > $1.matingStart } // Most recent first
        } catch {
            print("❌ [LSG-FETCH] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchById(userId: String, farmId: String, groupId: String) async throws -> LambingSeasonGroup? {
        print("🔵 [LSG-FETCH-ID] Fetching group by ID: \(groupId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId)
        
        do {
            let snapshot = try await docRef.getDocument()
            
            guard snapshot.exists else {
                print("⚠️ [LSG-FETCH-ID] Document does not exist")
                return nil
            }
            
            let group = try snapshot.data(as: LambingSeasonGroup.self)
            print("✅ [LSG-FETCH-ID] Successfully fetched group: \(group.displayName)")
            return group
        } catch {
            print("❌ [LSG-FETCH-ID] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchActive(userId: String, farmId: String) async throws -> [LambingSeasonGroup] {
        print("🔵 [LSG-FETCH-ACTIVE] Starting fetch active lambing season groups")
        print("🔵 [LSG-FETCH-ACTIVE] User ID: \(userId)")
        print("🔵 [LSG-FETCH-ACTIVE] Farm ID: \(farmId)")
        
        let path = collectionPath(userId: userId, farmId: farmId)
        
        do {
            let snapshot = try await path
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            print("🔵 [LSG-FETCH-ACTIVE] Got \(snapshot.documents.count) active documents")
            
            let groups = snapshot.documents.compactMap { doc -> LambingSeasonGroup? in
                print("🔵 [LSG-FETCH-ACTIVE] Processing document: \(doc.documentID)")
                do {
                    let group = try doc.data(as: LambingSeasonGroup.self)  // ✅ Keep try HERE
                    print("✅ [LSG-FETCH-ACTIVE] Successfully mapped group: \(group.displayName)")
                    return group
                } catch {
                    print("⚠️ [LSG-FETCH-ACTIVE] Failed to decode document \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ [LSG-FETCH-ACTIVE] Returning \(groups.count) active groups")
            return groups.sorted { $0.matingStart > $1.matingStart } // Most recent first
        } catch {
            print("❌ [LSG-FETCH-ACTIVE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Write Operations
    
    func create(_ group: LambingSeasonGroup) async throws {
        print("🔵 [LSG-CREATE] Starting create lambing season group")
        print("🔵 [LSG-CREATE] Group name: \(group.displayName)")
        print("🔵 [LSG-CREATE] Group ID: \(group.id)")
        print("🔵 [LSG-CREATE] User ID: \(group.userId)")
        print("🔵 [LSG-CREATE] Farm ID: \(group.farmId)")
        
        let docRef = documentPath(userId: group.userId, farmId: group.farmId, groupId: group.id)
        print("🔵 [LSG-CREATE] Path: users/\(group.userId)/farms/\(group.farmId)/lambingSeasonGroups/\(group.id)")
        
        do {
            try docRef.setData(from: group)
            print("✅ [LSG-CREATE] Group created successfully")
        } catch {
            print("❌ [LSG-CREATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func update(_ group: LambingSeasonGroup) async throws {
        print("🔵 [LSG-UPDATE] Starting group update")
        print("🔵 [LSG-UPDATE] Group name: \(group.displayName)")
        print("🔵 [LSG-UPDATE] Group ID: \(group.id)")
        print("🔵 [LSG-UPDATE] User ID: \(group.userId)")
        print("🔵 [LSG-UPDATE] Farm ID: \(group.farmId)")
        
        // Create updated group with new timestamp
        var updatedGroup = group
        updatedGroup = LambingSeasonGroup(
            id: group.id,
            userId: group.userId,
            farmId: group.farmId,
            code: group.code,
            name: group.name,
            matingStart: group.matingStart,
            matingEnd: group.matingEnd,
            lambingStart: group.lambingStart,
            lambingEnd: group.lambingEnd,
            isActive: group.isActive,
            createdAt: group.createdAt,
            updatedAt: Date()
        )
        
        let docRef = documentPath(userId: group.userId, farmId: group.farmId, groupId: group.id)
        print("🔵 [LSG-UPDATE] Path: users/\(group.userId)/farms/\(group.farmId)/lambingSeasonGroups/\(group.id)")
        
        do {
            try docRef.setData(from: updatedGroup)
            print("✅ [LSG-UPDATE] Group updated successfully")
        } catch {
            print("❌ [LSG-UPDATE] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func delete(userId: String, farmId: String, groupId: String) async throws {
        print("🔵 [LSG-DELETE] Starting delete lambing season group")
        print("🔵 [LSG-DELETE] Group ID: \(groupId)")
        print("🔵 [LSG-DELETE] User ID: \(userId)")
        print("🔵 [LSG-DELETE] Farm ID: \(farmId)")
        
        let docRef = documentPath(userId: userId, farmId: farmId, groupId: groupId)
        print("🔵 [LSG-DELETE] Path: users/\(userId)/farms/\(farmId)/lambingSeasonGroups/\(groupId)")
        
        do {
            try await docRef.delete()
            print("✅ [LSG-DELETE] Group deleted successfully")
        } catch {
            print("❌ [LSG-DELETE] Error: \(error.localizedDescription)")
            throw error
        }
    }
}
