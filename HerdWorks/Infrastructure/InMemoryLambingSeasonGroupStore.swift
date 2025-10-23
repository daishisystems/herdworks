//
//  InMemoryLambingSeasonGroupStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import Foundation

/// In-memory implementation of LambingSeasonGroupStore for previews and testing
actor InMemoryLambingSeasonGroupStore: LambingSeasonGroupStore {
    private var groups: [String: LambingSeasonGroup] = [:]
    
    init() {
        print("🔵 InMemoryLambingSeasonGroupStore initialized")
    }
    
    func fetchAll(userId: String, farmId: String) async throws -> [LambingSeasonGroup] {
        print("🔵 [MEM-LSG-FETCH] Fetching all groups for farm: \(farmId)")
        let filtered = groups.values.filter { $0.userId == userId && $0.farmId == farmId }
        print("✅ [MEM-LSG-FETCH] Found \(filtered.count) groups")
        return filtered.sorted { $0.matingStart > $1.matingStart }
    }
    
    func fetchById(userId: String, farmId: String, groupId: String) async throws -> LambingSeasonGroup? {
        print("🔵 [MEM-LSG-FETCH-ID] Fetching group: \(groupId)")
        let group = groups[groupId]
        
        // Verify ownership
        if let group = group, group.userId == userId && group.farmId == farmId {
            print("✅ [MEM-LSG-FETCH-ID] Found group: \(group.displayName)")
            return group
        }
        
        print("⚠️ [MEM-LSG-FETCH-ID] Group not found")
        return nil
    }
    
    func fetchActive(userId: String, farmId: String) async throws -> [LambingSeasonGroup] {
        print("🔵 [MEM-LSG-FETCH-ACTIVE] Fetching active groups for farm: \(farmId)")
        let filtered = groups.values.filter {
            $0.userId == userId && $0.farmId == farmId && $0.isActive
        }
        print("✅ [MEM-LSG-FETCH-ACTIVE] Found \(filtered.count) active groups")
        return filtered.sorted { $0.matingStart > $1.matingStart }
    }
    
    func create(_ group: LambingSeasonGroup) async throws {
        print("🔵 [MEM-LSG-CREATE] Creating group: \(group.displayName)")
        groups[group.id] = group
        print("✅ [MEM-LSG-CREATE] Group created successfully")
    }
    
    func update(_ group: LambingSeasonGroup) async throws {
        print("🔵 [MEM-LSG-UPDATE] Updating group: \(group.displayName)")
        
        guard groups[group.id] != nil else {
            print("❌ [MEM-LSG-UPDATE] Group not found")
            throw NSError(domain: "InMemoryStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Group not found"
            ])
        }
        
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
        
        groups[group.id] = updatedGroup
        print("✅ [MEM-LSG-UPDATE] Group updated successfully")
    }
    
    func delete(userId: String, farmId: String, groupId: String) async throws {
        print("🔵 [MEM-LSG-DELETE] Deleting group: \(groupId)")
        
        // Verify ownership before deleting
        if let group = groups[groupId], group.userId == userId && group.farmId == farmId {
            groups.removeValue(forKey: groupId)
            print("✅ [MEM-LSG-DELETE] Group deleted successfully")
        } else {
            print("❌ [MEM-LSG-DELETE] Group not found or access denied")
            throw NSError(domain: "InMemoryStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Group not found"
            ])
        }
    }
}
