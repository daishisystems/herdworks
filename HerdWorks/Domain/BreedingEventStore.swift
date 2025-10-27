//
//  BreedingEventStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/24.
//

import Foundation
import Combine

/// Protocol for breeding event persistence operations
protocol BreedingEventStore {
    /// Fetch all breeding events for a specific lambing season group
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    /// - Returns: Array of breeding events, sorted by most recent first
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [BreedingEvent]
    
    /// Fetch a single breeding event by ID
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - eventId: The breeding event identifier
    /// - Returns: The breeding event if found, nil otherwise
    func fetchById(userId: String, farmId: String, groupId: String, eventId: String) async throws -> BreedingEvent?
    
    /// Create a new breeding event
    /// - Parameter event: The breeding event to create
    func create(_ event: BreedingEvent) async throws
    
    /// Update an existing breeding event
    /// - Parameter event: The breeding event to update (with new updatedAt timestamp)
    func update(_ event: BreedingEvent) async throws
    
    /// Delete a breeding event
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - farmId: The farm identifier
    ///   - groupId: The lambing season group identifier
    ///   - eventId: The breeding event identifier to delete
    func delete(userId: String, farmId: String, groupId: String, eventId: String) async throws
    
    /// Listen for real-time changes to all breeding events for a specific lambing season group
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
        onChange: @escaping (Result<[BreedingEvent], Error>) -> Void
    ) -> AnyCancellable
}
