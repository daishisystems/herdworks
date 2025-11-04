//
//  InMemoryBenchmarkStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation

final class InMemoryBenchmarkStore: BenchmarkStore {
    private var benchmarks: [String: BenchmarkData] = [:]
    
    init() {
        print("🔵 InMemoryBenchmarkStore initialized")
        
        // Add some preview data
        let preview = BenchmarkData.preview
        benchmarks[preview.id] = preview
    }
    
    func fetch(breed: SheepBreed, province: SouthAfricanProvince, year: Int) async throws -> BenchmarkData? {
        let id = BenchmarkData.generateId(breed: breed, province: province, year: year)
        return benchmarks[id]
    }
    
    func fetchById(id: String) async throws -> BenchmarkData? {
        return benchmarks[id]
    }
}
