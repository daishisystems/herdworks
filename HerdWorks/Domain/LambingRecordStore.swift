//
//  LambingRecordStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation
import Combine

/// Protocol for lambing record persistence operations
protocol LambingRecordStore {
    /// Fetch all lambing records for a specific lambing season group
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    /// - Returns: Array of lambing records, sorted by most recent first
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [LambingRecord]
    
    /// Fetch a single lambing record by ID
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - recordId: The lambing record identifier
    /// - Returns: The lambing record if found, nil otherwise
    func fetchById(userId: String, farmId: String, groupId: String, recordId: String) async throws -> LambingRecord?
    
    /// Create a new lambing record
    /// - Parameter record: The lambing record to create
    func create(_ record: LambingRecord) async throws
    
    /// Update an existing lambing record
    /// - Parameter record: The lambing record to update (with new updatedAt timestamp)
    func update(_ record: LambingRecord) async throws
    
    /// Delete a lambing record
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - recordId: The lambing record identifier to delete
    func delete(userId: String, farmId: String, groupId: String, recordId: String) async throws
    
    /// Listen for real-time changes to all lambing records for a specific lambing season group
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - onChange: Callback invoked on each snapshot with either an updated array of records or an error
    /// - Returns: A cancellable that removes the underlying listener when canceled
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[LambingRecord], Error>) -> Void
    ) -> AnyCancellable
}
