//
//  BenchmarkPerformanceChart.swift
//  HerdWorks
//
//  Phase 2B: Visual chart for benchmark performance metrics
//  Displays farm vs industry performance in a radar/spider chart style
//

import SwiftUI

struct BenchmarkPerformanceChart: View {
    let metrics: [BenchmarkMetricComparison]
    let title: String
    
    @State private var selectedMetric: BenchmarkMetricComparison?
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(title)
                .font(.headline)
            
            // Chart
            GeometryReader { geometry in
                ZStack {
                    // Background circles
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                        Circle()
                            .stroke(Color(.separator), lineWidth: 0.5)
                            .frame(
                                width: geometry.size.width * scale,
                                height: geometry.size.width * scale
                            )
                    }
                    
                    // Axis lines
                    ForEach(0..<metrics.count, id: \.self) { index in
                        axisLine(
                            for: index,
                            in: geometry.size,
                            total: metrics.count
                        )
                    }
                    
                    // Performance polygon
                    performancePolygon(in: geometry.size)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            performancePolygon(in: geometry.size)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    
                    // Data points
                    ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                        dataPoint(
                            for: metric,
                            at: index,
                            in: geometry.size,
                            total: metrics.count
                        )
                    }
                    
                    // Metric labels
                    ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                        metricLabel(
                            for: metric,
                            at: index,
                            in: geometry.size,
                            total: metrics.count
                        )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
                .animation(.easeInOut(duration: 0.5), value: animationProgress)
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Legend
            legendView
            
            // Selected metric detail
            if let selected = selectedMetric {
                selectedMetricDetail(selected)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            animationProgress = 1.0
        }
    }
    
    // MARK: - Chart Components
    
    private func axisLine(for index: Int, in size: CGSize, total: Int) -> some View {
        let angle = angleForIndex(index, total: total)
        let endPoint = pointOnCircle(
            center: CGPoint(x: size.width / 2, y: size.height / 2),
            radius: size.width / 2,
            angle: angle
        )
        
        return Path { path in
            path.move(to: CGPoint(x: size.width / 2, y: size.height / 2))
            path.addLine(to: endPoint)
        }
        .stroke(Color(.separator), lineWidth: 0.5)
    }
    
    private func performancePolygon(in size: CGSize) -> Path {
        Path { path in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            for (index, metric) in metrics.enumerated() {
                let angle = angleForIndex(index, total: metrics.count)
                let value = normalizedValue(for: metric)
                let radius = (size.width / 2) * value * animationProgress
                let point = pointOnCircle(center: center, radius: radius, angle: angle)
                
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            
            path.closeSubpath()
        }
    }
    
    private func dataPoint(
        for metric: BenchmarkMetricComparison,
        at index: Int,
        in size: CGSize,
        total: Int
    ) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let angle = angleForIndex(index, total: total)
        let value = normalizedValue(for: metric)
        let radius = (size.width / 2) * value * animationProgress
        let point = pointOnCircle(center: center, radius: radius, angle: angle)
        
        return Circle()
            .fill(metric.performanceTier.color)
            .frame(width: 8, height: 8)
            .position(point)
            .onTapGesture {
                selectedMetric = selectedMetric?.id == metric.id ? nil : metric
            }
    }
    
    private func metricLabel(
        for metric: BenchmarkMetricComparison,
        at index: Int,
        in size: CGSize,
        total: Int
    ) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let angle = angleForIndex(index, total: total)
        let labelRadius = (size.width / 2) + 20
        let point = pointOnCircle(center: center, radius: labelRadius, angle: angle)
        
        return Text(abbreviatedName(for: metric))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(selectedMetric?.id == metric.id ? .primary : .secondary)
            .position(point)
            .onTapGesture {
                selectedMetric = selectedMetric?.id == metric.id ? nil : metric
            }
    }
    
    // MARK: - Legend View
    
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach([
                ("benchmark.excellent_short".localized(), Color.green),
                ("benchmark.good_short".localized(), Color.orange),
                ("benchmark.needs_work_short".localized(), Color.red)
            ], id: \.0) { label, color in
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Selected Metric Detail
    
    private func selectedMetricDetail(_ metric: BenchmarkMetricComparison) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.localizedKey.localized())
                .font(.caption)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("benchmark.your_value".localized())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(metric.formattedFarmValue())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(metric.performanceTier.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("benchmark.industry_avg".localized())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(metric.formattedBenchmarkMean())
                        .font(.caption)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("benchmark.top_10".localized())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatValue(metric.benchmarkP90, unit: metric.unit))
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Methods
    
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let angleStep = (2 * .pi) / Double(total)
        return (Double(index) * angleStep) - (.pi / 2) // Start at top
    }
    
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(CGFloat(angle)),
            y: center.y + radius * sin(CGFloat(angle))
        )
    }
    
    private func normalizedValue(for metric: BenchmarkMetricComparison) -> CGFloat {
        // Normalize based on percentile rank (0-100 to 0-1)
        return CGFloat(metric.percentileRank) / 100.0
    }
    
    private func abbreviatedName(for metric: BenchmarkMetricComparison) -> String {
        // Create short labels for chart display
        switch metric.name {
        case let name where name.contains("Conception"):
            return "CR"
        case let name where name.contains("Scanning"):
            return "SR"
        case let name where name.contains("Expected") && name.contains("Pregnant"):
            return "L/EP"
        case let name where name.contains("Expected") && name.contains("Mated"):
            return "L/EM"
        case let name where name.contains("Lambing") && name.contains("Mated"):
            return "L%M"
        case let name where name.contains("Lambing") && name.contains("Lambed"):
            return "L%L"
        case let name where name.contains("Born Alive"):
            return "BA%"
        case let name where name.contains("Mortality") && name.contains("Ewe"):
            return "M/EL"
        case let name where name.contains("Mortality"):
            return "M%"
        case let name where name.contains("Dry"):
            return "DE%"
        default:
            return String(metric.name.prefix(3))
        }
    }
    
    private func formatValue(_ value: Double, unit: BenchmarkMetricComparison.MetricUnit) -> String {
        switch unit {
        case .percentage:
            return String(format: "%.1f%%", value)
        case .ratio:
            return String(format: "%.2f", value)
        case .count:
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Alternative Bar Chart View

struct BenchmarkBarChart: View {
    let metrics: [BenchmarkMetricComparison]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(metrics) { metric in
                    barRow(for: metric)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func barRow(for metric: BenchmarkMetricComparison) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.localizedKey.localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(metric.formattedFarmValue())
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                    
                    // Farm performance bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(metric.performanceTier.color.opacity(0.8))
                        .frame(
                            width: geometry.size.width * (CGFloat(metric.percentileRank) / 100.0),
                            height: 20
                        )
                    
                    // Industry average marker
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 2, height: 24)
                        .offset(x: geometry.size.width * 0.5 - 1)
                }
            }
            .frame(height: 20)
        }
    }
}

// MARK: - Preview

struct BenchmarkPerformanceChart_Previews: PreviewProvider {
    static var previews: some View {
        let metrics = [
            BenchmarkMetricComparison(
                name: "Conception Rate",
                localizedKey: "benchmark.metric.conception_rate",
                farmValue: 86.7,
                benchmarkMean: 82.5,
                benchmarkMedian: 84.0,
                benchmarkP90: 92.0,
                percentileRank: 65,
                performanceTier: .good,
                unit: .percentage
            ),
            BenchmarkMetricComparison(
                name: "Scanning Rate",
                localizedKey: "benchmark.metric.scanning_rate",
                farmValue: 97.5,
                benchmarkMean: 94.2,
                benchmarkMedian: 95.5,
                benchmarkP90: 98.5,
                percentileRank: 85,
                performanceTier: .good,
                unit: .percentage
            ),
            BenchmarkMetricComparison(
                name: "Lambing % (Mated)",
                localizedKey: "benchmark.metric.lambing_percentage_mated",
                farmValue: 84.0,
                benchmarkMean: 80.3,
                benchmarkMedian: 82.0,
                benchmarkP90: 90.5,
                percentileRank: 60,
                performanceTier: .good,
                unit: .percentage
            ),
            BenchmarkMetricComparison(
                name: "Mortality %",
                localizedKey: "benchmark.metric.mortality_percentage",
                farmValue: 5.6,
                benchmarkMean: 7.5,
                benchmarkMedian: 6.5,
                benchmarkP90: 3.5,
                percentileRank: 70,
                performanceTier: .good,
                unit: .percentage
            )
        ]
        
        ScrollView {
            VStack(spacing: 20) {
                BenchmarkPerformanceChart(
                    metrics: metrics,
                    title: "Performance Overview"
                )
                
                BenchmarkBarChart(
                    metrics: metrics,
                    title: "Performance Breakdown"
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
