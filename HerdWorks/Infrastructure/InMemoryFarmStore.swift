//
//  InMemoryFarmStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

actor InMemoryFarmStore: FarmStore {
    private var storage: [String: Farm] = [:]
    
    func create(_ farm: Farm) async throws {
        storage[farm.id] = farm
    }
    
    func fetchAll(userId: String) async throws -> [Farm] {
        return storage.values
            .filter { $0.userId == userId }
            .sorted { $0.name < $1.name }
    }
    
    func update(_ farm: Farm) async throws {
        guard storage[farm.id] != nil else {
            throw FarmStoreError.notFound
        }
        
        var updated = farm
        updated.updatedAt = Date()
        storage[farm.id] = updated
    }
    
    func delete(farmId: String, userId: String) async throws {
        guard let farm = storage[farmId], farm.userId == userId else {
            throw FarmStoreError.notFound
        }
        storage[farmId] = nil
    }
}
