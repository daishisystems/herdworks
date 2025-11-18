//
//  FirestoreBenchmarkStore.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class FirestoreBenchmarkStore: BenchmarkStore, ObservableObject {
    private let db = Firestore.firestore()
    
    init() {
        print("🔵 FirestoreBenchmarkStore initialized")
    }
    
    func fetch(breed: SheepBreed, province: SouthAfricanProvince, year: Int) async throws -> BenchmarkData? {
        let id = BenchmarkData.generateId(breed: breed, province: province, year: year)
        return try await fetchById(id: id)
    }
    
    func fetchById(id: String) async throws -> BenchmarkData? {
        print("🔵 [BENCHMARK-FETCH] Fetching benchmark: \(id)")
        
        // ✅ FIX: Use correct path - benchmarks_lambing is a single collection
        let docRef = db.collection("benchmarks_lambing").document(id)
        
        do {
            let snapshot = try await docRef.getDocument()
            
            guard snapshot.exists else {
                print("⚠️ [BENCHMARK-FETCH] Benchmark not found: \(id)")
                return nil
            }
            
            let benchmark = try snapshot.data(as: BenchmarkData.self)
            print("✅ [BENCHMARK-FETCH] Found benchmark with \(benchmark.totalFarms) farms, \(benchmark.totalRecords) records")
            return benchmark
        } catch {
            print("❌ [BENCHMARK-FETCH] Error: \(error.localizedDescription)")
            throw error
        }
    }
}
