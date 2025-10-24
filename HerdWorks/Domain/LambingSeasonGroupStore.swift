//
//  LambingSeasonGroupStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import Foundation
import Combine

/// Protocol for lambing season group persistence operations
protocol LambingSeasonGroupStore {
    /// Fetch all lambing season groups for a specific farm
    func fetchAll(userId: String, farmId: String) async throws -> [LambingSeasonGroup]
    
    /// Fetch a single lambing season group by ID
    func fetchById(userId: String, farmId: String, groupId: String) async throws -> LambingSeasonGroup?
    
    /// Create a new lambing season group
    func create(_ group: LambingSeasonGroup) async throws
    
    /// Update an existing lambing season group
    func update(_ group: LambingSeasonGroup) async throws
    
    /// Delete a lambing season group
    func delete(userId: String, farmId: String, groupId: String) async throws
    
    /// Fetch only active lambing season groups for a farm
    func fetchActive(userId: String, farmId: String) async throws -> [LambingSeasonGroup]
    
    /// Listen for real-time changes to all lambing season groups for a specific farm.
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - onChange: Callback invoked on each snapshot with either an updated array of groups or an error
    /// - Returns: A cancellable that removes the underlying listener when canceled
    func listenAll(userId: String, farmId: String, onChange: @escaping (Result<[LambingSeasonGroup], Error>) -> Void) -> AnyCancellable
}
