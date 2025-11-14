//
//  BenchmarkComparisonViewModel.swift
//  HerdWorks
//
//  Created by Claude on 2025-11-12.
//  Phase 2A: Benchmark Comparison ViewModel
//

import Foundation
import SwiftUI
import Combine

/// Represents a single metric comparison between farm and benchmark
struct BenchmarkMetricComparison: Identifiable {
    let id = UUID()
    let name: String
    let localizedKey: String
    let farmValue: Double
    let benchmarkMean: Double
    let benchmarkMedian: Double
    let benchmarkP90: Double
    let percentileRank: Int // 0-100
    let performanceTier: PerformanceTier
    let unit: MetricUnit
    
    enum MetricUnit {
        case percentage
        case ratio
        case count
        
        var suffix: String {
            switch self {
            case .percentage: return "%"
            case .ratio: return ""
            case .count: return ""
            }
        }
    }
    
    enum PerformanceTier {
        case excellent   // >= P90 (top 10%)
        case good        // >= Median (top 50%)
        case needsImprovement // < Median
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .orange
            case .needsImprovement: return .red
            }
        }
        
        var iconName: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "checkmark.circle.fill"
            case .needsImprovement: return "arrow.up.circle.fill"
            }
        }
        
        func localizedDescription() -> String {
            switch self {
            case .excellent: return "benchmark.tier.excellent".localized()
            case .good: return "benchmark.tier.good".localized()
            case .needsImprovement: return "benchmark.tier.needs_improvement".localized()
            }
        }
    }
    
    /// Format the value for display
    func formattedFarmValue() -> String {
        switch unit {
        case .percentage:
            return String(format: "%.1f%%", farmValue)
        case .ratio:
            return String(format: "%.2f", farmValue)
        case .count:
            return String(format: "%.0f", farmValue)
        }
    }
    
    func formattedBenchmarkMean() -> String {
        switch unit {
        case .percentage:
            return String(format: "%.1f%%", benchmarkMean)
        case .ratio:
            return String(format: "%.2f", benchmarkMean)
        case .count:
            return String(format: "%.0f", benchmarkMean)
        }
    }
}

/// Aggregated farm performance data (mirrors Cloud Function logic)
struct FarmPerformanceData {
    // From breeding events (summed)
    var totalEwesMated: Int = 0
    
    // From scanning events (summed)
    var totalEwesScanned: Int = 0
    var totalEwesPregnant: Int = 0
    var totalEwesNotPregnant: Int = 0
    var totalEwesWithSingles: Int = 0
    var totalEwesWithTwins: Int = 0
    var totalEwesWithTriplets: Int = 0
    var totalScannedFetuses: Int = 0
    
    // From lambing records (summed)
    var totalEwesLambed: Int = 0
    var totalLambsBorn: Int = 0
    var totalMortality: Int = 0
    var totalLambsAlive: Int = 0
    
    // Computed metrics (exactly matching Cloud Function formulas)
    var conceptionRate: Double {
        guard totalEwesScanned > 0 else { return 0 }
        return (Double(totalEwesPregnant) / Double(totalEwesScanned)) * 100.0
    }
    
    var scanningRate: Double {
        guard totalEwesMated > 0 else { return 0 }
        return (Double(totalEwesScanned) / Double(totalEwesMated)) * 100.0
    }
    
    var expectedLambsPerEwePregnant: Double {
        guard totalEwesPregnant > 0 else { return 0 }
        return Double(totalScannedFetuses) / Double(totalEwesPregnant)
    }
    
    var expectedLambsPerEweMated: Double {
        guard totalEwesMated > 0 else { return 0 }
        return Double(totalScannedFetuses) / Double(totalEwesMated)
    }
    
    var lambingPercentageMated: Double {
        guard totalEwesMated > 0 else { return 0 }
        return (Double(totalEwesLambed) / Double(totalEwesMated)) * 100.0
    }
    
    var lambingPercentageLambed: Double {
        guard totalEwesLambed > 0 else { return 0 }
        return (Double(totalLambsBorn) / Double(totalEwesLambed)) * 100.0
    }
    
    var bornAlivePercentage: Double {
        guard totalLambsBorn > 0 else { return 0 }
        return (Double(totalLambsAlive) / Double(totalLambsBorn)) * 100.0
    }
    
    var mortalityPercentage: Double {
        guard totalLambsBorn > 0 else { return 0 }
        return (Double(totalMortality) / Double(totalLambsBorn)) * 100.0
    }
    
    var dryEwesPercentage: Double {
        guard totalEwesMated > 0 else { return 0 }
        return (Double(totalEwesMated - totalEwesLambed) / Double(totalEwesMated)) * 100.0
    }
    
    var mortalityPercentageEwesLambed: Double {
        guard totalEwesLambed > 0 else { return 0 }
        return (Double(totalMortality) / Double(totalEwesLambed)) * 100.0
    }
}

@MainActor
final class BenchmarkComparisonViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var benchmarkData: BenchmarkData?
    @Published var farmPerformance: FarmPerformanceData?
    @Published var scanningMetrics: [BenchmarkMetricComparison] = []
    @Published var lambingMetrics: [BenchmarkMetricComparison] = []
    
    @Published var isLoadingBenchmark: Bool = false
    @Published var isLoadingPerformance: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let benchmarkStore: BenchmarkStore
    private let breedingStore: BreedingEventStore
    private let scanningStore: ScanningEventStore
    private let lambingStore: LambingRecordStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    
    // MARK: - Private Properties
    
    private var benchmarkCancellable: AnyCancellable?
    private var farm: Farm?
    private var group: LambingSeasonGroup?
    
    // MARK: - Initialization
    
    init(
        benchmarkStore: BenchmarkStore,
        breedingStore: BreedingEventStore,
        scanningStore: ScanningEventStore,
        lambingStore: LambingRecordStore,
        userId: String,
        farmId: String,
        groupId: String
    ) {
        self.benchmarkStore = benchmarkStore
        self.breedingStore = breedingStore
        self.scanningStore = scanningStore
        self.lambingStore = lambingStore
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
    }

    deinit {
        print("🔵 [BENCHMARK-VM] Deallocating - cancelling listeners")
        benchmarkCancellable?.cancel()
    }

    // MARK: - Public Methods
    
    /// Start listening to benchmark data and load farm performance
    func startListening(farm: Farm, group: LambingSeasonGroup) {
        self.farm = farm
        self.group = group
        
        // Start real-time benchmark listener
        listenToBenchmark(breed: farm.breed, province: farm.province, year: extractYear(from: group.matingStart))
        
        // Load farm performance data
        Task {
            await loadFarmPerformance()
        }
    }
    
    /// Stop listening to benchmark updates
    func stopListening() {
        benchmarkCancellable?.cancel()
        benchmarkCancellable = nil
    }
    
    /// Manually refresh all data
    func refresh() async {
        await loadFarmPerformance()
    }
    
    // MARK: - Private Methods - Benchmark Listening
    
    private func listenToBenchmark(breed: SheepBreed, province: SouthAfricanProvince, year: Int) {
        // Cancel existing listener first to prevent memory leaks
        benchmarkCancellable?.cancel()
        benchmarkCancellable = nil

        isLoadingBenchmark = true

        print("📊 [BENCHMARK-VM] Starting listener for: \(breed.rawValue)_\(province.rawValue)_\(year)")

        benchmarkCancellable = benchmarkStore.listen(breed: breed, province: province, year: year)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoadingBenchmark = false
                
                if case .failure(let error) = completion {
                    print("❌ [BENCHMARK-VM] Listener error: \(error.localizedDescription)")
                    self.errorMessage = "benchmark.error.failed_to_load".localized()
                    self.showError = true
                }
            } receiveValue: { [weak self] benchmark in
                guard let self = self else { return }
                
                print("✅ [BENCHMARK-VM] Received benchmark data: \(benchmark?.totalRecords ?? 0) records")
                self.benchmarkData = benchmark
                self.isLoadingBenchmark = false
                
                // Recalculate comparisons when benchmark updates
                if let farmPerf = self.farmPerformance {
                    self.calculateComparisons(farmPerformance: farmPerf, benchmark: benchmark)
                }
            }
    }
    
    // MARK: - Private Methods - Farm Performance Aggregation
    
    private func loadFarmPerformance() async {
        isLoadingPerformance = true
        defer { isLoadingPerformance = false }
        
        print("📊 [BENCHMARK-VM] Loading farm performance for group: \(groupId)")
        
        do {
            // Fetch all events for this lambing season group (SUM strategy)
            let breedingEvents = try await breedingStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            let scanningEvents = try await scanningStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            let lambingRecords = try await lambingStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
            
            print("📊 [BENCHMARK-VM] Fetched: \(breedingEvents.count) breeding, \(scanningEvents.count) scanning, \(lambingRecords.count) lambing")
            
            // Check if we have breeding data (required for valid calculations)
            guard !breedingEvents.isEmpty else {
                print("⚠️ [BENCHMARK-VM] No breeding events found - skipping calculations")
                self.farmPerformance = nil
                self.scanningMetrics = []
                self.lambingMetrics = []
                return
            }
            
            // Aggregate data using SUM strategy (matching Cloud Function)
            let performance = aggregateEvents(
                breeding: breedingEvents,
                scanning: scanningEvents,
                lambing: lambingRecords
            )
            
            print("✅ [BENCHMARK-VM] Aggregated farm performance")
            print("   - Total Ewes Mated: \(performance.totalEwesMated)")
            print("   - Total Ewes Scanned: \(performance.totalEwesScanned)")
            print("   - Total Ewes Pregnant: \(performance.totalEwesPregnant)")
            print("   - Total Ewes Lambed: \(performance.totalEwesLambed)")
            print("   - Total Lambs Born: \(performance.totalLambsBorn)")
            
            self.farmPerformance = performance
            
            // Calculate comparisons if we have benchmark data
            if let benchmark = benchmarkData {
                calculateComparisons(farmPerformance: performance, benchmark: benchmark)
            }
            
        } catch {
            print("❌ [BENCHMARK-VM] Error loading farm performance: \(error.localizedDescription)")
            errorMessage = "benchmark.error.failed_to_load_performance".localized()
            showError = true
        }
    }
    
    private func aggregateEvents(
        breeding: [BreedingEvent],
        scanning: [ScanningEvent],
        lambing: [LambingRecord]
    ) -> FarmPerformanceData {
        var performance = FarmPerformanceData()
        
        // Sum all breeding events
        performance.totalEwesMated = breeding.reduce(0) { $0 + $1.numberOfEwesMated }
        
        // Sum all scanning events
        performance.totalEwesScanned = scanning.reduce(0) { $0 + $1.ewesScanned }
        performance.totalEwesPregnant = scanning.reduce(0) { $0 + $1.ewesPregnant }
        performance.totalEwesNotPregnant = scanning.reduce(0) { $0 + $1.ewesNotPregnant }
        performance.totalEwesWithSingles = scanning.reduce(0) { $0 + $1.ewesWithSingles }
        performance.totalEwesWithTwins = scanning.reduce(0) { $0 + $1.ewesWithTwins }
        performance.totalEwesWithTriplets = scanning.reduce(0) { $0 + $1.ewesWithTriplets }
        
        // Calculate scanned fetuses (Excel formula: H = I + (J*2) + (K*3))
        performance.totalScannedFetuses = performance.totalEwesWithSingles +
                                         (performance.totalEwesWithTwins * 2) +
                                         (performance.totalEwesWithTriplets * 3)
        
        // Sum all lambing records
        performance.totalEwesLambed = lambing.reduce(0) { $0 + $1.ewesLambed }
        performance.totalLambsBorn = lambing.reduce(0) { $0 + $1.lambsBorn }
        performance.totalMortality = lambing.reduce(0) { $0 + $1.lambsMortality0to30Days }
        
        // Calculate lambs alive (Excel formula: F = D - E)
        performance.totalLambsAlive = performance.totalLambsBorn - performance.totalMortality
        
        return performance
    }
    
    // MARK: - Private Methods - Comparison Calculations
    
    private func calculateComparisons(farmPerformance: FarmPerformanceData, benchmark: BenchmarkData?) {
        guard let benchmark = benchmark else {
            print("⚠️ [BENCHMARK-VM] No benchmark data available for comparison")
            scanningMetrics = []
            lambingMetrics = []
            return
        }
        
        print("📊 [BENCHMARK-VM] Calculating comparisons...")
        
        // Scanning Metrics (4 metrics)
        scanningMetrics = [
            createComparison(
                name: "Conception Rate",
                localizedKey: "benchmark.metric.conception_rate",
                farmValue: farmPerformance.conceptionRate,
                benchmarkStats: benchmark.conceptionRate,
                unit: .percentage
            ),
            createComparison(
                name: "Scanning Rate",
                localizedKey: "benchmark.metric.scanning_rate",
                farmValue: farmPerformance.scanningRate,
                benchmarkStats: benchmark.scanningRate,
                unit: .percentage
            ),
            createComparison(
                name: "Expected Lambs/Ewe Pregnant",
                localizedKey: "benchmark.metric.expected_lambs_pregnant",
                farmValue: farmPerformance.expectedLambsPerEwePregnant,
                benchmarkStats: benchmark.expectedLambsPerEwePregnant,
                unit: .ratio
            ),
            createComparison(
                name: "Expected Lambs/Ewe Mated",
                localizedKey: "benchmark.metric.expected_lambs_mated",
                farmValue: farmPerformance.expectedLambsPerEweMated,
                benchmarkStats: benchmark.expectedLambsPerEweMated,
                unit: .ratio
            )
        ]
        
        // Lambing Metrics (6 metrics)
        lambingMetrics = [
            createComparison(
                name: "Lambing % (Mated)",
                localizedKey: "benchmark.metric.lambing_percentage_mated",
                farmValue: farmPerformance.lambingPercentageMated,
                benchmarkStats: benchmark.lambingPercentageMated,
                unit: .percentage
            ),
            createComparison(
                name: "Lambing % (Lambed)",
                localizedKey: "benchmark.metric.lambing_percentage_lambed",
                farmValue: farmPerformance.lambingPercentageLambed,
                benchmarkStats: benchmark.lambingPercentageLambed,
                unit: .percentage
            ),
            createComparison(
                name: "Born Alive %",
                localizedKey: "benchmark.metric.born_alive_percentage",
                farmValue: farmPerformance.bornAlivePercentage,
                benchmarkStats: benchmark.bornAlivePercentage,
                unit: .percentage
            ),
            createComparison(
                name: "Mortality %",
                localizedKey: "benchmark.metric.mortality_percentage",
                farmValue: farmPerformance.mortalityPercentage,
                benchmarkStats: benchmark.mortalityPercentage,
                unit: .percentage,
                isInverted: true // Lower is better for mortality
            ),
            createComparison(
                name: "Dry Ewes %",
                localizedKey: "benchmark.metric.dry_ewes_percentage",
                farmValue: farmPerformance.dryEwesPercentage,
                benchmarkStats: benchmark.dryEwesPercentage,
                unit: .percentage,
                isInverted: true // Lower is better for dry ewes
            ),
            createComparison(
                name: "Mortality/Ewe Lambed",
                localizedKey: "benchmark.metric.mortality_per_ewe_lambed",
                farmValue: farmPerformance.mortalityPercentageEwesLambed,
                benchmarkStats: benchmark.mortalityPercentageEwesLambed,
                unit: .percentage,
                isInverted: true // Lower is better for mortality
            )
        ]
        
        print("✅ [BENCHMARK-VM] Calculated \(scanningMetrics.count) scanning + \(lambingMetrics.count) lambing comparisons")
    }
    
    private func createComparison(
        name: String,
        localizedKey: String,
        farmValue: Double,
        benchmarkStats: StatisticalData,
        unit: BenchmarkMetricComparison.MetricUnit,
        isInverted: Bool = false
    ) -> BenchmarkMetricComparison {
        // Calculate percentile rank using statistical thresholds
        let percentile = calculatePercentileRank(
            value: farmValue,
            mean: benchmarkStats.mean,
            median: benchmarkStats.median,
            p90: benchmarkStats.p90,
            isInverted: isInverted
        )
        
        // Determine performance tier
        let tier = determinePerformanceTier(
            value: farmValue,
            median: benchmarkStats.median,
            p90: benchmarkStats.p90,
            isInverted: isInverted
        )
        
        return BenchmarkMetricComparison(
            name: name,
            localizedKey: localizedKey,
            farmValue: farmValue,
            benchmarkMean: benchmarkStats.mean,
            benchmarkMedian: benchmarkStats.median,
            benchmarkP90: benchmarkStats.p90,
            percentileRank: percentile,
            performanceTier: tier,
            unit: unit
        )
    }
    
    private func calculatePercentileRank(value: Double, mean: Double, median: Double, p90: Double, isInverted: Bool) -> Int {
        // Estimate percentile using mean/median/p90 thresholds
        // This is more efficient than storing all values
        
        if isInverted {
            // For mortality/dry ewes: lower is better
            if value <= p90 {
                return 90 // Bottom 10% (excellent)
            } else if value <= median {
                return 70 // Below median
            } else if value <= mean {
                return 40 // Around mean
            } else {
                return 20 // Above mean (needs improvement)
            }
        } else {
            // For most metrics: higher is better
            if value >= p90 {
                return 90 // Top 10%
            } else if value >= median {
                return 70 // Above median
            } else if value >= mean {
                return 40 // Around mean
            } else {
                return 20 // Below mean
            }
        }
    }
    
    private func determinePerformanceTier(
        value: Double,
        median: Double,
        p90: Double,
        isInverted: Bool
    ) -> BenchmarkMetricComparison.PerformanceTier {
        if isInverted {
            // For mortality/dry ewes: lower is better
            if value <= p90 {
                return .excellent // Bottom 10% (best performers)
            } else if value <= median {
                return .good // Below median
            } else {
                return .needsImprovement // Above median
            }
        } else {
            // For most metrics: higher is better
            if value >= p90 {
                return .excellent // Top 10%
            } else if value >= median {
                return .good // Above median
            } else {
                return .needsImprovement // Below median
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractYear(from date: Date) -> Int {
        Calendar.current.component(.year, from: date)
    }
}
