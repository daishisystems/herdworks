//
//  FarmPerformance.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/12.
//

import Foundation

// MARK: - Farm Performance Model

/// Calculated performance metrics for a specific farm's lambing season
/// Used to compare against industry benchmarks
struct FarmPerformance: Identifiable {
    let id: String  // Lambing season group ID
    let farmId: String
    let farmName: String
    let seasonName: String
    let year: Int
    
    // MARK: - Raw Aggregated Data
    
    // From breeding events (summed)
    let totalEwesMated: Int
    
    // From scanning events (summed)
    let totalEwesScanned: Int
    let totalEwesPregnant: Int
    let totalEwesNotPregnant: Int
    let totalEwesWithSingles: Int
    let totalEwesWithTwins: Int
    let totalEwesWithTriplets: Int
    let totalScannedFetuses: Int
    
    // From lambing records (summed)
    let totalEwesLambed: Int
    let totalLambsBorn: Int
    let totalMortality: Int
    let totalLambsAlive: Int
    
    // MARK: - Calculated Metrics (10 total)
    
    // Scanning Metrics (4)
    let conceptionRate: Double          // (Ewes Pregnant / Ewes Scanned) × 100
    let scanningRate: Double            // (Ewes Scanned / Ewes Mated) × 100
    let expectedLambsPerEwePregnant: Double  // Scanned Fetuses / Ewes Pregnant
    let expectedLambsPerEweMated: Double     // Scanned Fetuses / Ewes Mated
    
    // Lambing Metrics (6)
    let lambingPercentageMated: Double       // (Ewes Lambed / Ewes Mated) × 100
    let lambingPercentageLambed: Double      // (Lambs Born / Ewes Lambed) × 100
    let bornAlivePercentage: Double          // (Lambs Alive / Lambs Born) × 100
    let mortalityPercentage: Double          // (Mortality / Lambs Born) × 100
    let dryEwesPercentage: Double            // ((Ewes Mated - Ewes Lambed) / Ewes Mated) × 100
    let mortalityPercentageEwesLambed: Double // (Mortality / Ewes Lambed) × 100
    
    let calculatedAt: Date
    
    // MARK: - Computed Properties
    
    /// All scanning metrics as a tuple array for easy iteration
    var scanningMetrics: [(name: String, value: Double?, lowerIsBetter: Bool)] {
        return [
            ("Conception Rate", conceptionRate, false),
            ("Scanning Rate", scanningRate, false),
            ("Expected Lambs/Ewe (Pregnant)", expectedLambsPerEwePregnant, false),
            ("Expected Lambs/Ewe (Mated)", expectedLambsPerEweMated, false)
        ]
    }
    
    /// All lambing metrics as a tuple array for easy iteration
    var lambingMetrics: [(name: String, value: Double?, lowerIsBetter: Bool)] {
        return [
            ("Lambing % (Mated)", lambingPercentageMated, false),
            ("Lambing % (Lambed)", lambingPercentageLambed, false),
            ("Born Alive %", bornAlivePercentage, false),
            ("Mortality %", mortalityPercentage, true),  // Lower is better
            ("Dry Ewes %", dryEwesPercentage, true),     // Lower is better
            ("Mortality/Ewe Lambed", mortalityPercentageEwesLambed, true)  // Lower is better
        ]
    }
    
    /// All metrics combined
    var allMetrics: [(name: String, value: Double?, lowerIsBetter: Bool)] {
        return scanningMetrics + lambingMetrics
    }
    
    /// Returns true if farm has complete data for all metrics
    var hasCompleteData: Bool {
        return totalEwesMated > 0 && totalEwesScanned > 0 && totalEwesLambed > 0
    }
    
    /// Returns true if scanning data is available
    var hasScanningData: Bool {
        return totalEwesScanned > 0
    }
    
    /// Returns true if lambing data is available
    var hasLambingData: Bool {
        return totalEwesLambed > 0
    }
    
    /// Display name for the performance record
    var displayName: String {
        return "\(farmName) - \(seasonName) (\(year))"
    }
    
    // MARK: - Helper Methods
    
    /// Get value for a specific metric by name
    func getValue(for metricName: String) -> Double? {
        let metric = allMetrics.first { $0.name == metricName }
        return metric?.value
    }
    
    /// Compare this farm's metric against benchmark statistics
    func comparison(
        for metricName: String,
        against stats: StatisticalData,
        lowerIsBetter: Bool
    ) -> MetricComparison? {
        guard let farmValue = getValue(for: metricName) else { return nil }
        
        let percentile = stats.percentileRank(for: farmValue, lowerIsBetter: lowerIsBetter)
        let tier = stats.performanceTier(for: farmValue, lowerIsBetter: lowerIsBetter)
        let difference = stats.differenceFromMean(farmValue)
        
        return MetricComparison(
            name: metricName,
            farmValue: farmValue,
            industryMean: stats.mean,
            industryMedian: stats.median,
            industryP90: stats.p90,
            percentile: percentile,
            tier: tier,
            differenceFromMean: difference,
            lowerIsBetter: lowerIsBetter
        )
    }
}

// MARK: - Metric Comparison

/// Comparison of a single metric between farm and industry benchmark
struct MetricComparison: Identifiable {
    let id = UUID()
    let name: String
    let farmValue: Double
    let industryMean: Double
    let industryMedian: Double
    let industryP90: Double
    let percentile: Int
    let tier: PerformanceTier
    let differenceFromMean: Double
    let lowerIsBetter: Bool
    
    /// Formatted farm value for display
    var farmValueFormatted: String {
        if name.contains("Lambs/Ewe") {
            return String(format: "%.2f", farmValue)
        } else {
            return String(format: "%.1f%%", farmValue)
        }
    }
    
    /// Formatted industry average for display
    var avgValueFormatted: String {
        if name.contains("Lambs/Ewe") {
            return String(format: "%.2f", industryMean)
        } else {
            return String(format: "%.1f%%", industryMean)
        }
    }
    
    /// Formatted difference from average
    var differenceFormatted: String {
        let prefix = differenceFromMean > 0 ? "+" : ""
        if name.contains("Lambs/Ewe") {
            return "\(prefix)\(String(format: "%.2f", differenceFromMean))"
        } else {
            return "\(prefix)\(String(format: "%.1f", differenceFromMean))pp"
        }
    }
    
    /// Icon for comparison direction
    var comparisonIcon: String {
        if lowerIsBetter {
            return differenceFromMean < 0 ? "arrow.down" : "arrow.up"
        } else {
            return differenceFromMean > 0 ? "arrow.up" : "arrow.down"
        }
    }
    
    /// Is this a good result?
    var isGood: Bool {
        if lowerIsBetter {
            return farmValue <= industryMean
        } else {
            return farmValue >= industryMean
        }
    }
}

// MARK: - Preview Helpers

extension FarmPerformance {
    /// Preview data with complete metrics
    static var preview: FarmPerformance {
        FarmPerformance(
            id: "preview-group",
            farmId: "preview-farm",
            farmName: "Preview Farm",
            seasonName: "LB25",
            year: 2025,
            totalEwesMated: 810,
            totalEwesScanned: 790,
            totalEwesPregnant: 685,
            totalEwesNotPregnant: 105,
            totalEwesWithSingles: 500,
            totalEwesWithTwins: 160,
            totalEwesWithTriplets: 25,
            totalScannedFetuses: 895,
            totalEwesLambed: 680,
            totalLambsBorn: 890,
            totalMortality: 50,
            totalLambsAlive: 840,
            conceptionRate: 86.7,
            scanningRate: 97.5,
            expectedLambsPerEwePregnant: 1.31,
            expectedLambsPerEweMated: 1.10,
            lambingPercentageMated: 84.0,
            lambingPercentageLambed: 130.9,
            bornAlivePercentage: 94.4,
            mortalityPercentage: 5.6,
            dryEwesPercentage: 16.0,
            mortalityPercentageEwesLambed: 7.4,
            calculatedAt: Date()
        )
    }
    
    /// Preview data with high performance
    static var previewHighPerformance: FarmPerformance {
        FarmPerformance(
            id: "preview-group-high",
            farmId: "preview-farm",
            farmName: "Top Farm",
            seasonName: "LB25",
            year: 2025,
            totalEwesMated: 500,
            totalEwesScanned: 495,
            totalEwesPregnant: 475,
            totalEwesNotPregnant: 20,
            totalEwesWithSingles: 150,
            totalEwesWithTwins: 250,
            totalEwesWithTriplets: 75,
            totalScannedFetuses: 725,
            totalEwesLambed: 470,
            totalLambsBorn: 710,
            totalMortality: 25,
            totalLambsAlive: 685,
            conceptionRate: 95.9,
            scanningRate: 99.0,
            expectedLambsPerEwePregnant: 1.53,
            expectedLambsPerEweMated: 1.45,
            lambingPercentageMated: 94.0,
            lambingPercentageLambed: 151.1,
            bornAlivePercentage: 96.5,
            mortalityPercentage: 3.5,
            dryEwesPercentage: 6.0,
            mortalityPercentageEwesLambed: 5.3,
            calculatedAt: Date()
        )
    }
}
