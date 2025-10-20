//
//  FarmStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

protocol FarmStore {
    func create(_ farm: Farm) async throws
    func fetchAll(userId: String) async throws -> [Farm]
    func update(_ farm: Farm) async throws
    func delete(farmId: String, userId: String) async throws
}

enum FarmStoreError: Error, Equatable {
    case notFound
    case invalidData
    case unauthorized
}
