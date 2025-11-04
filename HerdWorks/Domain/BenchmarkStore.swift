//
//  BenchmarkStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation

/// Protocol for benchmark data operations
protocol BenchmarkStore {
    /// Fetch benchmark data for a specific breed, province, and year
    /// - Parameters:
    ///   - breed: The sheep breed
    ///   - province: The South African province
    ///   - year: The year
    /// - Returns: Benchmark data if available, nil otherwise
    func fetch(breed: SheepBreed, province: SouthAfricanProvince, year: Int) async throws -> BenchmarkData?
    
    /// Fetch benchmark data by ID
    /// - Parameter id: The benchmark ID (format: "{breed}_{province}_{year}")
    /// - Returns: Benchmark data if available, nil otherwise
    func fetchById(id: String) async throws -> BenchmarkData?
}
