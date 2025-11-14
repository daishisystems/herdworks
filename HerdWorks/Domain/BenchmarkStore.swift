//
//  BenchmarkStore 2.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/14.
//


//
//  BenchmarkStore.swift
//  HerdWorks
//
//  Protocol for benchmark data access
//  UPDATED: Added real-time listener method
//

import Foundation
import Combine

/// Protocol for accessing benchmark data from storage
protocol BenchmarkStore {
    /// Fetch benchmark data for a specific breed, province, and year
    /// - Parameters:
    ///   - breed: Sheep breed to filter by
    ///   - province: South African province to filter by
    ///   - year: Year to filter by
    /// - Returns: BenchmarkData if found, nil otherwise
    func fetch(breed: SheepBreed, province: SouthAfricanProvince, year: Int) async throws -> BenchmarkData?
    
    /// Real-time listener for benchmark data
    /// - Parameters:
    ///   - breed: Sheep breed to filter by
    ///   - province: South African province to filter by
    ///   - year: Year to filter by
    /// - Returns: Publisher that emits benchmark updates or nil if not found
    func listen(breed: SheepBreed, province: SouthAfricanProvince, year: Int) -> AnyPublisher<BenchmarkData?, Error>
}