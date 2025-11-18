//
//  StatisticalData.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/11.
//  Statistical benchmark data structure matching Cloud Function output
//

import Foundation

// MARK: - Statistical Data Model

/// Statistical benchmark data for a single metric
/// Contains mean, median, P90, and range information aggregated from all contributing farms
struct StatisticalData: Codable, Equatable, Sendable {
    /// Average performance across all farms
    let mean: Double
    
    /// 50th percentile (middle value) - typical performance
    let median: Double
    
    /// 90th percentile - top 10% threshold (excellence benchmark)
    let p90: Double
    
    /// Minimum value observed
    let min: Double
    
    /// Maximum value observed
    let max: Double
    
    /// Number of contributing farms/records
    let count: Int
    
    // Note: 'sum' and 'values' array are omitted in iOS
    // They are only used by Cloud Function for incremental updates
    // iOS only needs the calculated statistics for display
    
    // MARK: - Computed Properties
    
    /// Range of values (max - min)
    var range: Double {
        return max - min
    }
    
    /// Returns true if there's sufficient data for reliable statistics (5+ farms)
    var hasReliableData: Bool {
        return count >= 5
    }
    
    /// Calculate percentile rank for a given value
    /// - Parameters:
    ///   - value: The value to rank
    ///   - lowerIsBetter: If true, lower values get higher percentiles (e.g., mortality rate)
    /// - Returns: Estimated percentile (0-100)
    func percentileRank(for value: Double, lowerIsBetter: Bool = false) -> Int {
        if lowerIsBetter {
            // For metrics where lower is better (e.g., mortality rate)
            if value <= p90 {
                return 90
            } else if value <= median {
                return 50
            } else if value <= mean {
                return 30
            } else {
                return 10
            }
        } else {
            // For metrics where higher is better (e.g., conception rate)
            if value >= p90 {
                return 90
            } else if value >= median {
                return 50
            } else if value >= mean {
                return 30
            } else {
                return 10
            }
        }
    }
    
    /// Performance tier based on percentile rank
    /// - Parameters:
    ///   - value: The value to evaluate
    ///   - lowerIsBetter: If true, lower values are better
    /// - Returns: Performance tier
    func performanceTier(for value: Double, lowerIsBetter: Bool = false) -> PerformanceTier {
        let percentile = percentileRank(for: value, lowerIsBetter: lowerIsBetter)
        
        switch percentile {
        case 90...:
            return .excellent
        case 50..<90:
            return .good
        case 30..<50:
            return .average
        default:
            return .needsWork
        }
    }
    
    /// Difference from mean (positive = above average, negative = below average)
    /// - Parameter value: The value to compare
    /// - Returns: Percentage point difference from mean
    func differenceFromMean(_ value: Double) -> Double {
        return value - mean
    }
    
    /// Percentage difference from mean
    /// - Parameter value: The value to compare
    /// - Returns: Percentage difference (e.g., +5.2% or -3.1%)
    func percentageDifferenceFromMean(_ value: Double) -> Double {
        guard mean > 0 else { return 0 }
        return ((value - mean) / mean) * 100
    }
}

// MARK: - Performance Tier

/// Performance tier classification for visual indicators
enum PerformanceTier: String, Codable, Sendable {
    case excellent = "Excellent"    // Top 10% (P90+)
    case good = "Good"              // Above average (50th-90th percentile)
    case average = "Average"        // Around average (30th-50th percentile)
    case needsWork = "Needs Work"   // Below average (<30th percentile)
    
    /// Display color for UI
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .average: return "orange"
        case .needsWork: return "red"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "arrow.up.circle.fill"
        case .average: return "minus.circle.fill"
        case .needsWork: return "arrow.down.circle.fill"
        }
    }
    
    /// Localized display name
    var localizedName: String {
        switch self {
        case .excellent: return "benchmark.tier_excellent".localized()
        case .good: return "benchmark.tier_good".localized()
        case .average: return "benchmark.tier_average".localized()
        case .needsWork: return "benchmark.tier_needs_work".localized()
        }
    }
}

// MARK: - Preview Helpers

extension StatisticalData {
    /// Preview data with good distribution
    static var preview: StatisticalData {
        StatisticalData(
            mean: 82.5,
            median: 84.0,
            p90: 92.0,
            min: 65.0,
            max: 98.0,
            count: 47
        )
    }
    
    /// Preview data with limited sample size
    static var previewLimitedData: StatisticalData {
        StatisticalData(
            mean: 80.0,
            median: 80.0,
            p90: 80.0,
            min: 80.0,
            max: 80.0,
            count: 1
        )
    }
    
    /// Preview data for mortality (lower is better)
    static var previewMortality: StatisticalData {
        StatisticalData(
            mean: 4.2,
            median: 3.8,
            p90: 2.5,  // P90 is LOWER for mortality (top performers have less mortality)
            min: 1.2,
            max: 12.5,
            count: 47
        )
    }
}
