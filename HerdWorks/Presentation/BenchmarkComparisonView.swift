//
//  BenchmarkComparisonView.swift
//  HerdWorks
//
//  Phase 2B: Benchmark Display Views
//  Displays farm performance compared to industry benchmarks
//

import SwiftUI

struct BenchmarkComparisonView: View {
    @StateObject private var viewModel: BenchmarkComparisonViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    private let farm: Farm
    private let group: LambingSeasonGroup
    
    init(
        farm: Farm,
        group: LambingSeasonGroup,
        benchmarkStore: BenchmarkStore,
        breedingStore: BreedingEventStore,
        scanningStore: ScanningEventStore,
        lambingStore: LambingRecordStore,
        userId: String
    ) {
        self.farm = farm
        self.group = group
        
        _viewModel = StateObject(wrappedValue: BenchmarkComparisonViewModel(
            benchmarkStore: benchmarkStore,
            breedingStore: breedingStore,
            scanningStore: scanningStore,
            lambingStore: lambingStore,
            userId: userId,
            farmId: farm.id,
            groupId: group.id
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingBenchmark || viewModel.isLoadingPerformance {
                    loadingView
                } else if viewModel.benchmarkData == nil || viewModel.farmPerformance == nil {
                    noDataView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header with farm and season info
                            headerSection
                            
                            // Overall Performance Score
                            overallScoreCard
                            
                            // Scanning Metrics
                            if !viewModel.scanningMetrics.isEmpty {
                                metricsSection(
                                    title: "benchmark.section.scanning_metrics".localized(),
                                    metrics: viewModel.scanningMetrics,
                                    icon: "camera.viewfinder"
                                )
                            }
                            
                            // Lambing Metrics
                            if !viewModel.lambingMetrics.isEmpty {
                                metricsSection(
                                    title: "benchmark.section.lambing_metrics".localized(),
                                    metrics: viewModel.lambingMetrics,
                                    icon: "heart.circle.fill"
                                )
                            }
                            
                            // Benchmark Info
                            benchmarkInfoCard
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("benchmark.comparison_title".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportComparison) {
                            Label("benchmark.export".localized(), systemImage: "square.and.arrow.up")
                        }

                        Button(action: refreshData) {
                            Label("common.refresh".localized(), systemImage: "arrow.clockwise")
                        }
                        .accessibility(label: Text("accessibility.button.refresh".localized()))
                        .accessibility(hint: Text("accessibility.button.refresh.hint".localized()))
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("common.error".localized(), isPresented: $viewModel.showError) {
            Button("common.ok".localized(), role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            viewModel.startListening(farm: farm, group: group)
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("benchmark.loading".localized())
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Data View
    
    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("benchmark.no_data_title".localized())
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("benchmark.no_data_message".localized())
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(farm.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(group.displayName) • \(yearString)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            if let benchmark = viewModel.benchmarkData {
                Label(benchmark.displayName, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Overall Score Card
    
    private var overallScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("benchmark.overall_performance".localized())
                    .font(.headline)
                Spacer()
                overallPerformanceBadge
            }
            
            // Performance Summary
            if let performance = calculateOverallPerformance() {
                HStack(spacing: 20) {
                    performanceIndicator(
                        label: "benchmark.excellent_count".localized(),
                        count: performance.excellent,
                        color: .green
                    )
                    
                    performanceIndicator(
                        label: "benchmark.good_count".localized(),
                        count: performance.good,
                        color: .orange
                    )
                    
                    performanceIndicator(
                        label: "benchmark.needs_work_count".localized(),
                        count: performance.needsImprovement,
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func performanceIndicator(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var overallPerformanceBadge: some View {
        Group {
            if let tier = calculateOverallTier() {
                Label(tier.localizedDescription(), systemImage: tier.iconName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tier.color)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Metrics Section
    
    private func metricsSection(title: String, metrics: [BenchmarkMetricComparison], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 2) {
                ForEach(metrics) { metric in
                    MetricComparisonRow(metric: metric)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Benchmark Info Card
    
    private var benchmarkInfoCard: some View {
        Group {
            if let benchmark = viewModel.benchmarkData {
                VStack(alignment: .leading, spacing: 12) {
                    Label("benchmark.info_title".localized(), systemImage: "info.circle.fill")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(
                            label: "benchmark.total_farms".localized(),
                            value: "\(benchmark.totalFarms)"
                        )
                        
                        infoRow(
                            label: "benchmark.total_records".localized(),
                            value: "\(benchmark.totalRecords)"
                        )
                        
                        infoRow(
                            label: "benchmark.last_updated".localized(),
                            value: dateFormatter.string(from: benchmark.lastUpdated)
                        )
                        
                        if !benchmark.hasReliableData {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                
                                Text("benchmark.limited_data_warning".localized())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Helper Methods
    
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: group.lambingStart)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private func calculateOverallPerformance() -> (excellent: Int, good: Int, needsImprovement: Int)? {
        let allMetrics = viewModel.scanningMetrics + viewModel.lambingMetrics
        guard !allMetrics.isEmpty else { return nil }
        
        let excellent = allMetrics.filter { $0.performanceTier == .excellent }.count
        let good = allMetrics.filter { $0.performanceTier == .good }.count
        let needsImprovement = allMetrics.filter { $0.performanceTier == .needsImprovement }.count
        
        return (excellent, good, needsImprovement)
    }
    
    private func calculateOverallTier() -> BenchmarkMetricComparison.PerformanceTier? {
        guard let performance = calculateOverallPerformance() else { return nil }
        
        let total = performance.excellent + performance.good + performance.needsImprovement
        guard total > 0 else { return nil }
        
        let excellentRatio = Double(performance.excellent) / Double(total)
        let goodRatio = Double(performance.good) / Double(total)
        
        if excellentRatio >= 0.5 {
            return .excellent
        } else if goodRatio >= 0.5 {
            return .good
        } else {
            return .needsImprovement
        }
    }
    
    private func refreshData() {
        viewModel.stopListening()
        viewModel.startListening(farm: farm, group: group)
    }
    
    private func exportComparison() {
        // TODO: Implement export functionality in future iteration
        print("📤 Export comparison - not yet implemented")
    }
}

// MARK: - Metric Comparison Row

struct MetricComparisonRow: View {
    let metric: BenchmarkMetricComparison
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 12) {
                    // Performance Tier Icon
                    Image(systemName: metric.performanceTier.iconName)
                        .font(.title3)
                        .foregroundStyle(metric.performanceTier.color)
                        .frame(width: 30)

                    // Metric Name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.localizedKey.localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text(metric.performanceTier.localizedDescription())
                            .font(.caption2)
                            .foregroundStyle(metric.performanceTier.color)
                    }

                    Spacer()

                    // Farm Value
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(metric.formattedFarmValue())
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("vs \(metric.formattedBenchmarkMean())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Expand Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibility(label: Text(String(format: "accessibility.benchmark.metric_row".localized(), metric.localizedKey.localized())))
            .accessibility(hint: Text("accessibility.benchmark.metric_row.hint".localized()))
            .accessibility(value: Text(String(format: "accessibility.benchmark.farm_value".localized(), metric.formattedFarmValue())))
            
            if isExpanded {
                Divider()
                    .padding(.leading, 50)
                
                MetricDetailView(metric: metric)
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Metric Detail View

struct MetricDetailView: View {
    let metric: BenchmarkMetricComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Percentile Rank
            HStack {
                Text("benchmark.percentile_rank".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(String(format: "benchmark.percentile_value".localized(), metric.percentileRank))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // Statistical Breakdown
            VStack(spacing: 8) {
                statRow(
                    label: "benchmark.industry_average".localized(),
                    value: formatValue(metric.benchmarkMean),
                    highlight: false
                )
                
                statRow(
                    label: "benchmark.industry_median".localized(),
                    value: formatValue(metric.benchmarkMedian),
                    highlight: false
                )
                
                statRow(
                    label: "benchmark.top_10_percent".localized(),
                    value: formatValue(metric.benchmarkP90),
                    highlight: metric.performanceTier == .excellent
                )
            }
        }
        .padding(.leading, 42)
    }
    
    private func statRow(label: String, value: String, highlight: Bool) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(highlight ? .semibold : .regular)
                .foregroundStyle(highlight ? metric.performanceTier.color : .primary)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metric.unit {
        case .percentage:
            return String(format: "%.1f%%", value)
        case .ratio:
            return String(format: "%.2f", value)
        case .count:
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Preview

struct BenchmarkComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        BenchmarkComparisonView(
            farm: Farm.preview,
            group: LambingSeasonGroup.preview,
            benchmarkStore: InMemoryBenchmarkStore(),
            breedingStore: InMemoryBreedingEventStore(),
            scanningStore: InMemoryScanningEventStore(),
            lambingStore: InMemoryLambingRecordStore(),
            userId: "preview-user"
        )
        .environmentObject(LanguageManager.shared)
    }
}
