//
//  InMemoryLambingRecordStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation
import Combine

final class InMemoryLambingRecordStore: LambingRecordStore {
    private var records: [String: LambingRecord] = [:]
    private var listeners: [UUID: (Result<[LambingRecord], Error>) -> Void] = [:]
    
    init() {
        print("🔵 InMemoryLambingRecordStore initialized")
    }
    
    // MARK: - Fetch Operations
    
    func fetchAll(userId: String, farmId: String, groupId: String) async throws -> [LambingRecord] {
        let filtered = records.values.filter {
            $0.userId == userId && $0.farmId == farmId && $0.lambingSeasonGroupId == groupId
        }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    func fetchById(userId: String, farmId: String, groupId: String, recordId: String) async throws -> LambingRecord? {
        return records[recordId]
    }
    
    // MARK: - Write Operations
    
    func create(_ record: LambingRecord) async throws {
        records[record.id] = record
        notifyListeners(userId: record.userId, farmId: record.farmId, groupId: record.lambingSeasonGroupId)
    }
    
    func update(_ record: LambingRecord) async throws {
        var updatedRecord = record
        updatedRecord.updatedAt = Date()
        records[record.id] = updatedRecord
        notifyListeners(userId: record.userId, farmId: record.farmId, groupId: record.lambingSeasonGroupId)
    }
    
    func delete(userId: String, farmId: String, groupId: String, recordId: String) async throws {
        records.removeValue(forKey: recordId)
        notifyListeners(userId: userId, farmId: farmId, groupId: groupId)
    }
    
    // MARK: - Listener
    
    func listenAll(
        userId: String,
        farmId: String,
        groupId: String,
        onChange: @escaping (Result<[LambingRecord], Error>) -> Void
    ) -> AnyCancellable {
        let id = UUID()
        listeners[id] = onChange
        
        // Deliver initial data
        Task {
            let records = try await fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            onChange(.success(records))
        }
        
        return AnyCancellable {
            self.listeners.removeValue(forKey: id)
        }
    }
    
    // MARK: - Private Helpers
    
    private func notifyListeners(userId: String, farmId: String, groupId: String) {
        Task {
            let records = try await fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            listeners.values.forEach { $0(.success(records)) }
        }
    }
}
