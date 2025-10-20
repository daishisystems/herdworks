//
//  FirestoreFarmStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore

actor FirestoreFarmStore: FarmStore {
    private let db: Firestore
    
    // ✅ Remove nonisolated - just regular init
    init(db: Firestore = .firestore()) {
        self.db = db
    }
    
    func create(_ farm: Farm) async throws {
        let ref = db.collection("users").document(farm.userId)
                    .collection("farms").document(farm.id)
        
        let dto = FirestoreFarmDTO(fromDomain: farm)
        var data = try Firestore.Encoder().encode(dto)
        
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        try await ref.setData(data)
    }
    
    func fetchAll(userId: String) async throws -> [Farm] {
        let snapshot = try await db.collection("users").document(userId)
                                   .collection("farms")
                                   .order(by: "name")
                                   .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            guard let dto = try? doc.data(as: FirestoreFarmDTO.self) else {
                return nil
            }
            return FarmMapper.toDomain(dto: dto)
        }
    }
    
    func update(_ farm: Farm) async throws {
        let ref = db.collection("users").document(farm.userId)
                    .collection("farms").document(farm.id)
        
        let dto = FirestoreFarmDTO(fromDomain: farm)
        var data = try Firestore.Encoder().encode(dto)
        
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        try await ref.setData(data, merge: true)
    }
    
    func delete(farmId: String, userId: String) async throws {
        let ref = db.collection("users").document(userId)
                    .collection("farms").document(farmId)
        try await ref.delete()
    }
}

#else

actor FirestoreFarmStore: FarmStore {
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
