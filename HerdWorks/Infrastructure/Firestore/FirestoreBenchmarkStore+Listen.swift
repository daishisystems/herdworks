//
//  FirestoreBenchmarkStore+Listen.swift
//  HerdWorks
//
//  Created by Claude on 2025-11-14.
//  Real-time listener extension for benchmark data
//

import Foundation
import Combine
import FirebaseFirestore

extension FirestoreBenchmarkStore {
    /// Real-time listener for benchmark data
    /// - Parameters:
    ///   - breed: Sheep breed to filter by
    ///   - province: South African province to filter by
    ///   - year: Year to filter by
    /// - Returns: Publisher that emits benchmark updates or nil if not found
    func listen(breed: SheepBreed, province: SouthAfricanProvince, year: Int) -> AnyPublisher<BenchmarkData?, Error> {
        let documentId = "\(breed.rawValue)_\(province.rawValue)_\(year)"
        let docRef = Firestore.firestore().collection("benchmarks_lambing").document(documentId)
        
        print("📡 [BENCHMARK-STORE] Setting up listener for: \(documentId)")
        
        // Create a Combine subject to emit updates
        let subject = PassthroughSubject<BenchmarkData?, Error>()
        
        // Set up Firestore snapshot listener
        let listener = docRef.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("❌ [BENCHMARK-STORE] Listener error: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
                return
            }
            
            guard let document = documentSnapshot else {
                print("⚠️ [BENCHMARK-STORE] No document found")
                subject.send(nil)
                return
            }
            
            if !document.exists {
                print("⚠️ [BENCHMARK-STORE] Document doesn't exist yet: \(documentId)")
                subject.send(nil)
                return
            }
            
            do {
                let benchmark = try document.data(as: BenchmarkData.self)
                print("✅ [BENCHMARK-STORE] Received benchmark: \(benchmark.totalRecords) records from \(benchmark.totalFarms) farms")
                subject.send(benchmark)
            } catch {
                print("❌ [BENCHMARK-STORE] Decoding error: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
            }
        }
        
        // Return publisher that removes listener on cancel
        return subject
            .handleEvents(receiveCancel: {
                print("🔴 [BENCHMARK-STORE] Listener cancelled for: \(documentId)")
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
}
