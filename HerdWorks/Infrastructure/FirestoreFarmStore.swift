//
//  FirestoreFarmStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@MainActor
final class FirestoreFarmStore: FarmStore, ObservableObject {
    private let db: Firestore
    
    init(db: Firestore = .firestore()) {
        self.db = db
        print("🔵 FirestoreFarmStore initialized")
    }
    
    func create(_ farm: Farm) async throws {
        print("🔵 [CREATE] Starting farm creation")
        print("🔵 [CREATE] Farm name: \(farm.name)")
        print("🔵 [CREATE] User ID: \(farm.userId)")
        print("🔵 [CREATE] Farm ID: \(farm.id)")
        
        let ref = db.collection("users").document(farm.userId)
                    .collection("farms").document(farm.id)
        
        print("🔵 [CREATE] Firestore path: users/\(farm.userId)/farms/\(farm.id)")
        
        let dto = FirestoreFarmDTO(fromDomain: farm)
        print("🔵 [CREATE] DTO created successfully")
        
        var data = try Firestore.Encoder().encode(dto)
        print("🔵 [CREATE] Data encoded successfully")
        
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        do {
            try await ref.setData(data)
            print("✅ [CREATE] Farm created successfully in Firestore")
        } catch {
            print("❌ [CREATE] Failed to create farm")
            print("❌ [CREATE] Error: \(error)")
            print("❌ [CREATE] Error description: \(error.localizedDescription)")
            print("❌ [CREATE] Error type: \(type(of: error))")
            throw error
        }
    }
    
    func fetchAll(userId: String) async throws -> [Farm] {
        print("🔵 [FETCH] Starting fetch all farms")
        print("🔵 [FETCH] User ID: \(userId)")
        print("🔵 [FETCH] Path: users/\(userId)/farms")
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                                       .collection("farms")
                                       .order(by: "name")
                                       .getDocuments()
            
            print("🔵 [FETCH] Got \(snapshot.documents.count) documents")
            
            let farms: [Farm] = snapshot.documents.compactMap { doc -> Farm? in
                print("🔵 [FETCH] Processing document: \(doc.documentID)")
                
                guard let dto = try? doc.data(as: FirestoreFarmDTO.self) else {
                    print("⚠️ [FETCH] Failed to decode document: \(doc.documentID)")
                    return nil
                }
                
                guard let farm = FarmMapper.toDomain(dto: dto) else {
                    print("⚠️ [FETCH] Failed to map DTO to domain: \(doc.documentID)")
                    return nil
                }
                
                print("✅ [FETCH] Successfully mapped farm: \(farm.name)")
                return farm
            }
            
            print("✅ [FETCH] Returning \(farms.count) farms")
            return farms
        } catch {
            print("❌ [FETCH] Failed to fetch farms")
            print("❌ [FETCH] Error: \(error)")
            print("❌ [FETCH] Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    func update(_ farm: Farm) async throws {
        print("🔵 [UPDATE] Starting farm update")
        print("🔵 [UPDATE] Farm name: \(farm.name)")
        print("🔵 [UPDATE] Farm ID: \(farm.id)")
        print("🔵 [UPDATE] User ID: \(farm.userId)")
        
        let ref = db.collection("users").document(farm.userId)
                    .collection("farms").document(farm.id)
        
        print("🔵 [UPDATE] Path: users/\(farm.userId)/farms/\(farm.id)")
        
        let dto = FirestoreFarmDTO(fromDomain: farm)
        var data = try Firestore.Encoder().encode(dto)
        
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        do {
            try await ref.setData(data, merge: true)
            print("✅ [UPDATE] Farm updated successfully")
        } catch {
            print("❌ [UPDATE] Failed to update farm")
            print("❌ [UPDATE] Error: \(error)")
            print("❌ [UPDATE] Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    func delete(farmId: String, userId: String) async throws {
        print("🔵 [DELETE] Starting farm deletion")
        print("🔵 [DELETE] Farm ID: \(farmId)")
        print("🔵 [DELETE] User ID: \(userId)")
        
        let ref = db.collection("users").document(userId)
                    .collection("farms").document(farmId)
        
        print("🔵 [DELETE] Path: users/\(userId)/farms/\(farmId)")
        
        do {
            try await ref.delete()
            print("✅ [DELETE] Farm deleted successfully")
        } catch {
            print("❌ [DELETE] Failed to delete farm")
            print("❌ [DELETE] Error: \(error)")
            print("❌ [DELETE] Error description: \(error.localizedDescription)")
            throw error
        }
    }
}

#else

@MainActor
final class FirestoreFarmStore: FarmStore, ObservableObject {
    init() {}
    
    func create(_ farm: Farm) async throws {
        fatalError("Firebase not linked")
    }
    
    func fetchAll(userId: String) async throws -> [Farm] {
        fatalError("Firebase not linked")
    }
    
    func update(_ farm: Farm) async throws {
        fatalError("Firebase not linked")
    }
    
    func delete(farmId: String, userId: String) async throws {
        fatalError("Firebase not linked")
    }
}

#endif
