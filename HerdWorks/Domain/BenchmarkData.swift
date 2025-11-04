//
//  BenchmarkData.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation

// MARK: - Benchmark Data Model

struct BenchmarkData: Identifiable, Codable {
    let id: String  // Format: "{breed}_{province}_{year}"
    let breed: String
    let province: String
    let year: Int
    let sampleSize: Int
    
    // Lambing Percentage Benchmarks
    let averageLambingPercentage: Double
    let medianLambingPercentage: Double
    let top10PercentLambingRate: Double
    
    // Mortality Rate Benchmarks
    let averageMortalityRate: Double
    let medianMortalityRate: Double
    let bestMortalityRate: Double  // Lowest mortality (best performance)
    
    // Hidden fields for incremental updates (used by Cloud Function)
    let _sumLambingPercentage: Double?
    let _sumMortalityRate: Double?
    
    let lastUpdated: Date
    
    // MARK: - Initializer
    
    init(
        id: String,
        breed: String,
        province: String,
        year: Int,
        sampleSize: Int,
        averageLambingPercentage: Double,
        medianLambingPercentage: Double,
        top10PercentLambingRate: Double,
        averageMortalityRate: Double,
        medianMortalityRate: Double,
        bestMortalityRate: Double,
        _sumLambingPercentage: Double? = nil,
        _sumMortalityRate: Double? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.breed = breed
        self.province = province
        self.year = year
        self.sampleSize = sampleSize
        self.averageLambingPercentage = averageLambingPercentage
        self.medianLambingPercentage = medianLambingPercentage
        self.top10PercentLambingRate = top10PercentLambingRate
        self.averageMortalityRate = averageMortalityRate
        self.medianMortalityRate = medianMortalityRate
        self.bestMortalityRate = bestMortalityRate
        self._sumLambingPercentage = _sumLambingPercentage
        self._sumMortalityRate = _sumMortalityRate
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Helper Methods
    
    /// Generate benchmark ID from farm details
    static func generateId(breed: SheepBreed, province: SouthAfricanProvince, year: Int) -> String {
        return "\(breed.rawValue)_\(province.rawValue)_\(year)"
            .replacingOccurrences(of: " ", with: "")
    }
    
    /// Calculate user's percentile ranking based on their lambing percentage
    func lambingPercentileRank(for userPercentage: Double) -> Int {
        if userPercentage >= top10PercentLambingRate {
            return 90
        } else if userPercentage >= medianLambingPercentage {
            return 50
        } else if userPercentage >= (averageLambingPercentage * 0.8) {
            return 30
        } else {
            return 10
        }
    }
    
    /// Calculate user's percentile ranking based on their mortality rate
    func mortalityPercentileRank(for userRate: Double) -> Int {
        // Lower is better for mortality
        if userRate <= bestMortalityRate {
            return 90
        } else if userRate <= medianMortalityRate {
            return 50
        } else if userRate <= (averageMortalityRate * 1.2) {
            return 30
        } else {
            return 10
        }
    }
}

// MARK: - Preview Helpers

extension BenchmarkData {
    static var preview: BenchmarkData {
        BenchmarkData(
            id: "DohneMerino_WesternCape_2025",
            breed: "Dohne Merino",
            province: "Western Cape",
            year: 2025,
            sampleSize: 47,
            averageLambingPercentage: 116.8,
            medianLambingPercentage: 117.0,
            top10PercentLambingRate: 125.0,
            averageMortalityRate: 13.2,
            medianMortalityRate: 12.8,
            bestMortalityRate: 8.5
        )
    }
}
