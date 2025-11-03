//
//  ScanningEventStore.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation
import Combine

/// Protocol for scanning event persistence operations
protocol ScanningEventStore {
    /// Fetch all scanning events for a specific lambing season group
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    /// - Returns: Array of scanning events, sorted by most recent first
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [ScanningEvent]
    
    /// Fetch a single scanning event by ID
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - eventId: The scanning event identifier
    /// - Returns: The scanning event if found, nil otherwise
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> ScanningEvent?
    
    /// Create a new scanning event
    /// - Parameter event: The scanning event to create
    func create(_ event: ScanningEvent) async throws
    
    /// Update an existing scanning event
    /// - Parameter event: The scanning event to update (with new updatedAt timestamp)
    func update(_ event: ScanningEvent) async throws
    
    /// Delete a scanning event
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - eventId: The scanning event identifier to delete
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws
    
    /// Listen for real-time changes to all scanning events for a specific lambing season group
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - onChange: Callback invoked on each snapshot with either an updated array of events or an error
    /// - Returns: A cancellable that removes the underlying listener when canceled
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[ScanningEvent], Error>) -> Void
    ) -> AnyCancellable
}
