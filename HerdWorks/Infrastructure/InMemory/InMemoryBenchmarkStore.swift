//
//  InMemoryBenchmarkStore 2.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/14.
//


//
//  InMemoryBenchmarkStore.swift
//  HerdWorks
//
//  In-memory implementation of BenchmarkStore for testing and previews
//  UPDATED: Added real-time listener method
//

import Foundation
import Combine

/// In-memory implementation of BenchmarkStore for testing and SwiftUI previews
final class InMemoryBenchmarkStore: BenchmarkStore {
    private var benchmarks: [String: BenchmarkData] = [:]
    private var subjects: [String: PassthroughSubject<BenchmarkData?, Error>] = [:]
    
    // MARK: - Initialization
    
    init(preloadedBenchmarks: [BenchmarkData] = []) {
        for benchmark in preloadedBenchmarks {
            let key = "\(benchmark.breed)_\(benchmark.province)_\(benchmark.year)"
            benchmarks[key] = benchmark
        }
    }
    
    // MARK: - BenchmarkStore Protocol
    
    func fetch(breed: SheepBreed, province: SouthAfricanProvince, year: Int) async throws -> BenchmarkData? {
        let key = "\(breed.rawValue)_\(province.rawValue)_\(year)"
        return benchmarks[key]
    }
    
    func listen(breed: SheepBreed, province: SouthAfricanProvince, year: Int) -> AnyPublisher<BenchmarkData?, Error> {
        let key = "\(breed.rawValue)_\(province.rawValue)_\(year)"
        
        // Get or create subject for this benchmark
        if subjects[key] == nil {
            subjects[key] = PassthroughSubject<BenchmarkData?, Error>()
        }
        
        let subject = subjects[key]!
        
        // Immediately send current value
        DispatchQueue.main.async {
            subject.send(self.benchmarks[key])
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Test Helper Methods
    
    /// Add or update a benchmark (useful for testing)
    func setBenchmark(_ benchmark: BenchmarkData) {
        let key = "\(benchmark.breed)_\(benchmark.province)_\(benchmark.year)"
        benchmarks[key] = benchmark
        
        // Notify listeners
        subjects[key]?.send(benchmark)
    }
    
    /// Remove a benchmark (useful for testing)
    func removeBenchmark(breed: SheepBreed, province: SouthAfricanProvince, year: Int) {
        let key = "\(breed.rawValue)_\(province.rawValue)_\(year)"
        benchmarks[key] = nil
        
        // Notify listeners
        subjects[key]?.send(nil)
    }
    
    /// Clear all benchmarks (useful for testing)
    func clearAll() {
        benchmarks.removeAll()
        for subject in subjects.values {
            subject.send(nil)
        }
    }
}