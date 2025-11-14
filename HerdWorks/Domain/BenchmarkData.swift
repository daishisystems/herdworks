//
//  BenchmarkData.swift
//  HerdWorks
//
//  Updated: 2025/11/11
//  Complete benchmark data structure matching Cloud Function output
//

import Foundation

// MARK: - Benchmark Data Model

/// Industry benchmark data aggregated from all farms for a specific breed, province, and year
/// Matches the Cloud Function output structure exactly
struct BenchmarkData: Identifiable, Codable {
    let id: String  // Format: "{breed}_{province}_{year}"
    let breed: String
    let province: String
    let year: Int
    let totalFarms: Int      // Number of farms contributing to benchmarks
    let totalRecords: Int    // Total number of lambing records aggregated
    
    // MARK: - Scanning Performance Benchmarks (4 metrics)
    
    /// Conception Rate: (Ewes Pregnant / Ewes Scanned) × 100
    /// Higher is better - indicates breeding program effectiveness
    let conceptionRate: StatisticalData
    
    /// Scanning Rate: (Ewes Scanned / Ewes Mated) × 100
    /// Higher is better - indicates scanning program thoroughness
    let scanningRate: StatisticalData
    
    /// Expected Lambs per Ewe Pregnant: Scanned Fetuses / Ewes Pregnant
    /// Higher is better - indicates multiple births (twins, triplets)
    let expectedLambsPerEwePregnant: StatisticalData
    
    /// Expected Lambs per Ewe Mated: Scanned Fetuses / Ewes Mated
    /// Higher is better - overall breeding program productivity
    let expectedLambsPerEweMated: StatisticalData
    
    // MARK: - Lambing Performance Benchmarks (6 metrics)
    
    /// Lambing % (of Mated): (Ewes Lambed / Ewes Mated) × 100
    /// Higher is better - percentage of mated ewes that successfully lambed
    let lambingPercentageMated: StatisticalData
    
    /// Lambing % (of Lambed): (Lambs Born / Ewes Lambed) × 100
    /// Higher is better - average lambs per ewe that lambed
    let lambingPercentageLambed: StatisticalData
    
    /// Born Alive %: (Lambs Alive / Lambs Born) × 100
    /// Higher is better - survival rate of lambs at birth
    let bornAlivePercentage: StatisticalData
    
    /// Mortality %: (Lambs Dead / Lambs Born) × 100
    /// Lower is better - lamb mortality rate in first 30 days
    let mortalityPercentage: StatisticalData
    
    /// Dry Ewes %: ((Ewes Mated - Ewes Lambed) / Ewes Mated) × 100
    /// Lower is better - percentage of ewes that didn't lamb
    let dryEwesPercentage: StatisticalData
    
    /// Mortality % per Ewe Lambed: (Lambs Dead / Ewes Lambed) × 100
    /// Lower is better - mortality rate relative to ewes that lambed
    let mortalityPercentageEwesLambed: StatisticalData
    
    // MARK: - Metadata
    
    let lastUpdated: Date
    let lastContributingFarm: String?
    
    // MARK: - Computed Properties
    
    /// All scanning metrics as a tuple array for easy iteration
    var scanningMetrics: [(name: String, stats: StatisticalData, lowerIsBetter: Bool)] {
        return [
            ("Conception Rate", conceptionRate, false),
            ("Scanning Rate", scanningRate, false),
            ("Expected Lambs/Ewe (Pregnant)", expectedLambsPerEwePregnant, false),
            ("Expected Lambs/Ewe (Mated)", expectedLambsPerEweMated, false)
        ]
    }
    
    /// All lambing metrics as a tuple array for easy iteration
    var lambingMetrics: [(name: String, stats: StatisticalData, lowerIsBetter: Bool)] {
        return [
            ("Lambing % (Mated)", lambingPercentageMated, false),
            ("Lambing % (Lambed)", lambingPercentageLambed, false),
            ("Born Alive %", bornAlivePercentage, false),
            ("Mortality %", mortalityPercentage, true),  // Lower is better
            ("Dry Ewes %", dryEwesPercentage, true),     // Lower is better
            ("Mortality/Ewe Lambed", mortalityPercentageEwesLambed, true)  // Lower is better
        ]
    }
    
    /// All metrics combined (for overall performance calculation)
    var allMetrics: [(name: String, stats: StatisticalData, lowerIsBetter: Bool)] {
        return scanningMetrics + lambingMetrics
    }
    
    /// Returns true if benchmark has reliable data (5+ farms)
    var hasReliableData: Bool {
        return totalFarms >= 5
    }
    
    /// Display name for the benchmark
    var displayName: String {
        return "\(breed) - \(province) (\(year))"
    }
    
    // MARK: - Helper Methods
    
    /// Generate benchmark ID from farm details
    static func generateId(breed: SheepBreed, province: SouthAfricanProvince, year: Int) -> String {
        return "\(breed.rawValue)_\(province.rawValue)_\(year)"
            .replacingOccurrences(of: " ", with: "")
    }
    
    /// Generate benchmark ID from string values (for Firestore queries)
    static func generateId(breed: String, province: String, year: Int) -> String {
        return "\(breed)_\(province)_\(year)"
            .replacingOccurrences(of: " ", with: "")
    }
}

// MARK: - Preview Helpers

extension BenchmarkData {
    /// Preview benchmark with good data distribution
    static var preview: BenchmarkData {
        BenchmarkData(
            id: "DohneMerino_WesternCape_2025",
            breed: "Dohne Merino",
            province: "Western Cape",
            year: 2025,
            totalFarms: 47,
            totalRecords: 89,
            conceptionRate: StatisticalData(mean: 82.5, median: 84.0, p90: 92.0, min: 65.0, max: 98.0, count: 47),
            scanningRate: StatisticalData(mean: 94.2, median: 95.5, p90: 98.5, min: 85.0, max: 100.0, count: 47),
            expectedLambsPerEwePregnant: StatisticalData(mean: 1.28, median: 1.30, p90: 1.42, min: 1.05, max: 1.65, count: 47),
            expectedLambsPerEweMated: StatisticalData(mean: 1.08, median: 1.10, p90: 1.25, min: 0.85, max: 1.45, count: 47),
            lambingPercentageMated: StatisticalData(mean: 80.3, median: 82.0, p90: 90.5, min: 65.0, max: 95.0, count: 47),
            lambingPercentageLambed: StatisticalData(mean: 125.8, median: 128.0, p90: 142.0, min: 105.0, max: 165.0, count: 47),
            bornAlivePercentage: StatisticalData(mean: 92.5, median: 93.5, p90: 96.5, min: 85.0, max: 98.5, count: 47),
            mortalityPercentage: StatisticalData(mean: 7.5, median: 6.5, p90: 3.5, min: 1.5, max: 15.0, count: 47),
            dryEwesPercentage: StatisticalData(mean: 19.7, median: 18.0, p90: 9.5, min: 5.0, max: 35.0, count: 47),
            mortalityPercentageEwesLambed: StatisticalData(mean: 9.2, median: 8.5, p90: 4.5, min: 2.0, max: 18.5, count: 47),
            lastUpdated: Date(),
            lastContributingFarm: "F11251A8-E7C1-4138-AD4E-D9910448074D"
        )
    }
    
    /// Preview benchmark with limited data (single farm)
    static var previewLimitedData: BenchmarkData {
        BenchmarkData(
            id: "Dorper_EasternCape_2025",
            breed: "Dorper",
            province: "Eastern Cape",
            year: 2025,
            totalFarms: 1,
            totalRecords: 1,
            conceptionRate: StatisticalData(mean: 86.7, median: 86.7, p90: 86.7, min: 86.7, max: 86.7, count: 1),
            scanningRate: StatisticalData(mean: 97.5, median: 97.5, p90: 97.5, min: 97.5, max: 97.5, count: 1),
            expectedLambsPerEwePregnant: StatisticalData(mean: 1.31, median: 1.31, p90: 1.31, min: 1.31, max: 1.31, count: 1),
            expectedLambsPerEweMated: StatisticalData(mean: 1.10, median: 1.10, p90: 1.10, min: 1.10, max: 1.10, count: 1),
            lambingPercentageMated: StatisticalData(mean: 84.0, median: 84.0, p90: 84.0, min: 84.0, max: 84.0, count: 1),
            lambingPercentageLambed: StatisticalData(mean: 130.9, median: 130.9, p90: 130.9, min: 130.9, max: 130.9, count: 1),
            bornAlivePercentage: StatisticalData(mean: 94.4, median: 94.4, p90: 94.4, min: 94.4, max: 94.4, count: 1),
            mortalityPercentage: StatisticalData(mean: 5.6, median: 5.6, p90: 5.6, min: 5.6, max: 5.6, count: 1),
            dryEwesPercentage: StatisticalData(mean: 16.0, median: 16.0, p90: 16.0, min: 16.0, max: 16.0, count: 1),
            mortalityPercentageEwesLambed: StatisticalData(mean: 7.4, median: 7.4, p90: 7.4, min: 7.4, max: 7.4, count: 1),
            lastUpdated: Date(),
            lastContributingFarm: "preview-farm-id"
        )
    }
}
