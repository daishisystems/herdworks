//
//  BenchmarkSummaryCard.swift
//  HerdWorks
//
//  Phase 2B: Compact benchmark display component
//  Shows a quick overview of farm performance vs benchmarks
//

import SwiftUI

struct BenchmarkSummaryCard: View {
    let farmPerformance: FarmPerformanceData?
    let benchmarkData: BenchmarkData?
    let onTap: () -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label("benchmark.summary_title".localized(), systemImage: "chart.bar.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    if let tier = overallTier {
                        performanceBadge(tier: tier)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Content
                if let performance = farmPerformance,
                   let benchmark = benchmarkData {
                    VStack(spacing: 8) {
                        // Top 3 Key Metrics
                        keyMetricRow(
                            label: "benchmark.conception_rate_short".localized(),
                            farmValue: performance.conceptionRate,
                            benchmarkValue: benchmark.conceptionRate.mean,
                            unit: .percentage
                        )
                        
                        keyMetricRow(
                            label: "benchmark.lambing_rate_short".localized(),
                            farmValue: performance.lambingPercentageMated,
                            benchmarkValue: benchmark.lambingPercentageMated.mean,
                            unit: .percentage
                        )
                        
                        keyMetricRow(
                            label: "benchmark.mortality_rate_short".localized(),
                            farmValue: performance.mortalityPercentage,
                            benchmarkValue: benchmark.mortalityPercentage.mean,
                            unit: .percentage,
                            lowerIsBetter: true
                        )
                    }
                    
                    // Summary text
                    if let summary = performanceSummary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                } else if farmPerformance == nil {
                    // No data state
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("benchmark.no_farm_data".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if benchmarkData == nil {
                    // No benchmark state
                    HStack {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundStyle(.gray)
                        Text("benchmark.no_benchmark_data".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Footer
                if benchmarkData?.hasReliableData == false {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        
                        Text("benchmark.limited_data".localized())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Key Metric Row
    
    private func keyMetricRow(
        label: String,
        farmValue: Double,
        benchmarkValue: Double,
        unit: MetricUnit,
        lowerIsBetter: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                // Farm value
                Text(formatValue(farmValue, unit: unit))
                    .font(.caption)
                    .fontWeight(.medium)
                
                // Comparison indicator
                comparisonIndicator(
                    farmValue: farmValue,
                    benchmarkValue: benchmarkValue,
                    lowerIsBetter: lowerIsBetter
                )
            }
        }
    }
    
    private func comparisonIndicator(
        farmValue: Double,
        benchmarkValue: Double,
        lowerIsBetter: Bool
    ) -> some View {
        let isGood = lowerIsBetter ?
            farmValue <= benchmarkValue :
            farmValue >= benchmarkValue
        
        let icon = lowerIsBetter ?
            (farmValue < benchmarkValue ? "arrow.down" : "arrow.up") :
            (farmValue > benchmarkValue ? "arrow.up" : "arrow.down")
        
        return Image(systemName: icon)
            .font(.caption2)
            .foregroundStyle(isGood ? .green : .red)
    }
    
    private func performanceBadge(tier: PerformanceTier) -> some View {
        HStack(spacing: 2) {
            Image(systemName: tier.iconName)
                .font(.caption2)
            
            Text(tier.localizedName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(tierColor(tier))
    }
    
    // MARK: - Computed Properties
    
    private var overallTier: PerformanceTier? {
        guard let performance = farmPerformance,
              let benchmark = benchmarkData else { return nil }
        
        var excellentCount = 0
        var goodCount = 0
        var totalMetrics = 0
        
        // Check key metrics
        let metrics: [(Double, StatisticalData, Bool)] = [
            (performance.conceptionRate, benchmark.conceptionRate, false),
            (performance.lambingPercentageMated, benchmark.lambingPercentageMated, false),
            (performance.mortalityPercentage, benchmark.mortalityPercentage, true),
            (performance.bornAlivePercentage, benchmark.bornAlivePercentage, false)
        ]
        
        for (value, stats, lowerIsBetter) in metrics {
            totalMetrics += 1
            let tier = stats.performanceTier(for: value, lowerIsBetter: lowerIsBetter)
            
            switch tier {
            case .excellent:
                excellentCount += 1
            case .good:
                goodCount += 1
            default:
                break
            }
        }
        
        let excellentRatio = Double(excellentCount) / Double(totalMetrics)
        let goodRatio = Double(excellentCount + goodCount) / Double(totalMetrics)
        
        if excellentRatio >= 0.5 {
            return .excellent
        } else if goodRatio >= 0.5 {
            return .good
        } else if goodRatio >= 0.25 {
            return .average
        } else {
            return .needsWork
        }
    }
    
    private var performanceSummary: String? {
        guard let tier = overallTier else { return nil }
        
        switch tier {
        case .excellent:
            return "benchmark.summary.excellent".localized()
        case .good:
            return "benchmark.summary.good".localized()
        case .average:
            return "benchmark.summary.average".localized()
        case .needsWork:
            return "benchmark.summary.needs_work".localized()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatValue(_ value: Double, unit: MetricUnit) -> String {
        switch unit {
        case .percentage:
            return String(format: "%.1f%%", value)
        case .ratio:
            return String(format: "%.2f", value)
        }
    }
    
    private func tierColor(_ tier: PerformanceTier) -> Color {
        switch tier {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .needsWork: return .red
        }
    }
    
    enum MetricUnit {
        case percentage
        case ratio
    }
}

// MARK: - Preview

struct BenchmarkSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // With data
            BenchmarkSummaryCard(
                farmPerformance: FarmPerformanceData.preview,
                benchmarkData: BenchmarkData.preview,
                onTap: {}
            )
            
            // No farm data
            BenchmarkSummaryCard(
                farmPerformance: nil,
                benchmarkData: BenchmarkData.preview,
                onTap: {}
            )
            
            // No benchmark data
            BenchmarkSummaryCard(
                farmPerformance: FarmPerformanceData.preview,
                benchmarkData: nil,
                onTap: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview Extensions

extension FarmPerformanceData {
    static var preview: FarmPerformanceData {
        var data = FarmPerformanceData()
        data.totalEwesMated = 810
        data.totalEwesScanned = 790
        data.totalEwesPregnant = 685
        data.totalEwesWithSingles = 500
        data.totalEwesWithTwins = 160
        data.totalEwesWithTriplets = 25
        data.totalScannedFetuses = 895
        data.totalEwesLambed = 680
        data.totalLambsBorn = 890
        data.totalMortality = 50
        data.totalLambsAlive = 840
        return data
    }
}
