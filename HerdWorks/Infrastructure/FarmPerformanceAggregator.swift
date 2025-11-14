//
//  FarmPerformanceAggregator.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/11.
//  Aggregates farm performance data and calculates metrics
//  Matches Cloud Function formulas exactly for consistency
//

import Foundation

// MARK: - Farm Performance Aggregator

/// Aggregates breeding, scanning, and lambing data to calculate performance metrics
/// Uses same SUM strategy and formulas as Cloud Function for consistency
@MainActor
final class FarmPerformanceAggregator {
    private let breedingStore: BreedingEventStore
    private let scanningStore: ScanningEventStore
    private let lambingStore: LambingRecordStore
    
    init(
        breedingStore: BreedingEventStore,
        scanningStore: ScanningEventStore,
        lambingStore: LambingRecordStore
    ) {
        self.breedingStore = breedingStore
        self.scanningStore = scanningStore
        self.lambingStore = lambingStore
    }
    
    // MARK: - Public Methods
    
    /// Calculate performance metrics for a specific lambing season group
    /// - Parameters:
    ///   - groupId: Lambing season group ID
    ///   - farmId: Farm ID
    ///   - farmName: Farm name for display
    ///   - seasonName: Season name for display
    ///   - year: Year for the season
    ///   - userId: User ID for data access
    /// - Returns: FarmPerformance object with calculated metrics
    func calculatePerformance(
        groupId: String,
        farmId: String,
        farmName: String,
        seasonName: String,
        year: Int,
        userId: String
    ) async throws -> FarmPerformance? {
        print("📊 [AGGREGATOR] Calculating performance for group: \(groupId)")
        
        // Fetch all events for this lambing season group
        let breedingEvents = try await fetchBreedingEvents(groupId: groupId, farmId: farmId, userId: userId)
        let scanningEvents = try await fetchScanningEvents(groupId: groupId, farmId: farmId, userId: userId)
        let lambingRecords = try await fetchLambingRecords(groupId: groupId, farmId: farmId, userId: userId)
        
        print("📊 [AGGREGATOR] Found \(breedingEvents.count) breeding, \(scanningEvents.count) scanning, \(lambingRecords.count) lambing events")
        
        // CRITICAL: Must have breeding events for valid calculations
        guard !breedingEvents.isEmpty else {
            print("⚠️ [AGGREGATOR] No breeding events found - skipping calculation")
            return nil
        }
        
        // Aggregate all data using SUM strategy
        let aggregated = aggregateAllEvents(
            breeding: breedingEvents,
            scanning: scanningEvents,
            lambing: lambingRecords
        )
        
        // Calculate all 10 metrics
        let metrics = calculateMetrics(from: aggregated)
        
        print("✅ [AGGREGATOR] Calculated metrics successfully")
        
        return FarmPerformance(
            id: groupId,
            farmId: farmId,
            farmName: farmName,
            seasonName: seasonName,
            year: year,
            totalEwesMated: aggregated.totalEwesMated,
            totalEwesScanned: aggregated.totalEwesScanned,
            totalEwesPregnant: aggregated.totalEwesPregnant,
            totalEwesNotPregnant: aggregated.totalEwesNotPregnant,
            totalEwesWithSingles: aggregated.totalEwesWithSingles,
            totalEwesWithTwins: aggregated.totalEwesWithTwins,
            totalEwesWithTriplets: aggregated.totalEwesWithTriplets,
            totalScannedFetuses: aggregated.totalScannedFetuses,
            totalEwesLambed: aggregated.totalEwesLambed,
            totalLambsBorn: aggregated.totalLambsBorn,
            totalMortality: aggregated.totalMortality,
            totalLambsAlive: aggregated.totalLambsAlive,
            conceptionRate: metrics.conceptionRate,
            scanningRate: metrics.scanningRate,
            expectedLambsPerEwePregnant: metrics.expectedLambsPerEwePregnant,
            expectedLambsPerEweMated: metrics.expectedLambsPerEweMated,
            lambingPercentageMated: metrics.lambingPercentageMated,
            lambingPercentageLambed: metrics.lambingPercentageLambed,
            bornAlivePercentage: metrics.bornAlivePercentage,
            mortalityPercentage: metrics.mortalityPercentage,
            dryEwesPercentage: metrics.dryEwesPercentage,
            mortalityPercentageEwesLambed: metrics.mortalityPercentageEwesLambed,
            calculatedAt: Date()
        )
    }
    
    // MARK: - Private Methods - Data Fetching
    
    private func fetchBreedingEvents(groupId: String, farmId: String, userId: String) async throws -> [BreedingEvent] {
        print("🔵 [AGGREGATOR] Fetching breeding events...")
        let events = try await breedingStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
        print("✅ [AGGREGATOR] Found \(events.count) breeding event(s)")
        return events
    }
    
    private func fetchScanningEvents(groupId: String, farmId: String, userId: String) async throws -> [ScanningEvent] {
        print("🔵 [AGGREGATOR] Fetching scanning events...")
        let events = try await scanningStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
        print("✅ [AGGREGATOR] Found \(events.count) scanning event(s)")
        return events
    }
    
    private func fetchLambingRecords(groupId: String, farmId: String, userId: String) async throws -> [LambingRecord] {
        print("🔵 [AGGREGATOR] Fetching lambing records...")
        let records = try await lambingStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
        print("✅ [AGGREGATOR] Found \(records.count) lambing record(s)")
        return records
    }
    
    // MARK: - Private Methods - Data Aggregation
    
    /// Aggregate all events using SUM strategy (matching Cloud Function)
    private func aggregateAllEvents(
        breeding: [BreedingEvent],
        scanning: [ScanningEvent],
        lambing: [LambingRecord]
    ) -> AggregatedData {
        print("📊 [AGGREGATOR] Aggregating data using SUM strategy...")
        
        // SUM all breeding events
        let totalEwesMated = breeding.reduce(0) { $0 + $1.numberOfEwesMated }
        
        // SUM all scanning events
        var totalEwesScanned = 0
        var totalEwesPregnant = 0
        var totalEwesNotPregnant = 0
        var totalEwesWithSingles = 0
        var totalEwesWithTwins = 0
        var totalEwesWithTriplets = 0
        var totalScannedFetuses = 0
        
        for event in scanning {
            totalEwesScanned += event.ewesScanned
            totalEwesPregnant += event.ewesPregnant
            totalEwesNotPregnant += event.ewesNotPregnant
            totalEwesWithSingles += event.ewesWithSingles
            totalEwesWithTwins += event.ewesWithTwins
            totalEwesWithTriplets += event.ewesWithTriplets
            // Calculate scanned fetuses for each event: singles + (twins × 2) + (triplets × 3)
            totalScannedFetuses += event.scannedFetuses
        }
        
        // SUM all lambing records
        var totalEwesLambed = 0
        var totalLambsBorn = 0
        var totalMortality = 0
        
        for record in lambing {
            totalEwesLambed += record.ewesLambed
            totalLambsBorn += record.lambsBorn
            totalMortality += record.lambsMortality0to30Days
        }
        
        let totalLambsAlive = totalLambsBorn - totalMortality
        
        print("📊 [AGGREGATOR] Totals:")
        print("   - Breeding: \(totalEwesMated) ewes mated (from \(breeding.count) events)")
        print("   - Scanning: \(totalEwesScanned) scanned, \(totalEwesPregnant) pregnant (from \(scanning.count) events)")
        print("   - Lambing: \(totalEwesLambed) lambed, \(totalLambsBorn) born, \(totalMortality) mortality (from \(lambing.count) records)")
        
        return AggregatedData(
            totalEwesMated: totalEwesMated,
            totalEwesScanned: totalEwesScanned,
            totalEwesPregnant: totalEwesPregnant,
            totalEwesNotPregnant: totalEwesNotPregnant,
            totalEwesWithSingles: totalEwesWithSingles,
            totalEwesWithTwins: totalEwesWithTwins,
            totalEwesWithTriplets: totalEwesWithTriplets,
            totalScannedFetuses: totalScannedFetuses,
            totalEwesLambed: totalEwesLambed,
            totalLambsBorn: totalLambsBorn,
            totalMortality: totalMortality,
            totalLambsAlive: totalLambsAlive
        )
    }
    
    // MARK: - Private Methods - Metric Calculation
    
    /// Calculate all 10 metrics using exact Excel formulas (matching Cloud Function)
    private func calculateMetrics(from data: AggregatedData) -> CalculatedMetrics {
        print("📊 [AGGREGATOR] Calculating metrics using Excel formulas...")
        
        // SCANNING METRICS (4)
        
        // 1. Conception Rate: (Ewes Pregnant / Ewes Scanned) × 100
        let conceptionRate: Double = {
            guard data.totalEwesScanned > 0 else { return 0 }
            return (Double(data.totalEwesPregnant) / Double(data.totalEwesScanned)) * 100
        }()
        
        // 2. Scanning Rate: (Ewes Scanned / Ewes Mated) × 100
        let scanningRate: Double = {
            guard data.totalEwesMated > 0 else { return 0 }
            return (Double(data.totalEwesScanned) / Double(data.totalEwesMated)) * 100
        }()
        
        // 3. Expected Lambs per Ewe Pregnant: Scanned Fetuses / Ewes Pregnant
        let expectedLambsPerEwePregnant: Double = {
            guard data.totalEwesPregnant > 0 else { return 0 }
            return Double(data.totalScannedFetuses) / Double(data.totalEwesPregnant)
        }()
        
        // 4. Expected Lambs per Ewe Mated: Scanned Fetuses / Ewes Mated
        let expectedLambsPerEweMated: Double = {
            guard data.totalEwesMated > 0 else { return 0 }
            return Double(data.totalScannedFetuses) / Double(data.totalEwesMated)
        }()
        
        // LAMBING METRICS (6)
        
        // 5. Lambing % (of Mated): (Ewes Lambed / Ewes Mated) × 100
        let lambingPercentageMated: Double = {
            guard data.totalEwesMated > 0 else { return 0 }
            return (Double(data.totalEwesLambed) / Double(data.totalEwesMated)) * 100
        }()
        
        // 6. Lambing % (of Lambed): (Lambs Born / Ewes Lambed) × 100
        let lambingPercentageLambed: Double = {
            guard data.totalEwesLambed > 0 else { return 0 }
            return (Double(data.totalLambsBorn) / Double(data.totalEwesLambed)) * 100
        }()
        
        // 7. Born Alive %: (Lambs Alive / Lambs Born) × 100
        let bornAlivePercentage: Double = {
            guard data.totalLambsBorn > 0 else { return 0 }
            return (Double(data.totalLambsAlive) / Double(data.totalLambsBorn)) * 100
        }()
        
        // 8. Mortality %: (Mortality / Lambs Born) × 100
        let mortalityPercentage: Double = {
            guard data.totalLambsBorn > 0 else { return 0 }
            return (Double(data.totalMortality) / Double(data.totalLambsBorn)) * 100
        }()
        
        // 9. Dry Ewes %: ((Ewes Mated - Ewes Lambed) / Ewes Mated) × 100
        let dryEwesPercentage: Double = {
            guard data.totalEwesMated > 0 else { return 0 }
            return (Double(data.totalEwesMated - data.totalEwesLambed) / Double(data.totalEwesMated)) * 100
        }()
        
        // 10. Mortality % per Ewe Lambed: (Mortality / Ewes Lambed) × 100
        let mortalityPercentageEwesLambed: Double = {
            guard data.totalEwesLambed > 0 else { return 0 }
            return (Double(data.totalMortality) / Double(data.totalEwesLambed)) * 100
        }()
        
        print("✅ [AGGREGATOR] Calculated metrics:")
        print("   Scanning:")
        print("     - Conception Rate: \(String(format: "%.1f", conceptionRate))%")
        print("     - Scanning Rate: \(String(format: "%.1f", scanningRate))%")
        print("     - Expected Lambs/Ewe (Pregnant): \(String(format: "%.2f", expectedLambsPerEwePregnant))")
        print("     - Expected Lambs/Ewe (Mated): \(String(format: "%.2f", expectedLambsPerEweMated))")
        print("   Lambing:")
        print("     - Lambing % (Mated): \(String(format: "%.1f", lambingPercentageMated))%")
        print("     - Lambing % (Lambed): \(String(format: "%.1f", lambingPercentageLambed))%")
        print("     - Born Alive %: \(String(format: "%.1f", bornAlivePercentage))%")
        print("     - Mortality %: \(String(format: "%.1f", mortalityPercentage))%")
        print("     - Dry Ewes %: \(String(format: "%.1f", dryEwesPercentage))%")
        print("     - Mortality/Ewe Lambed: \(String(format: "%.1f", mortalityPercentageEwesLambed))%")
        
        return CalculatedMetrics(
            conceptionRate: conceptionRate,
            scanningRate: scanningRate,
            expectedLambsPerEwePregnant: expectedLambsPerEwePregnant,
            expectedLambsPerEweMated: expectedLambsPerEweMated,
            lambingPercentageMated: lambingPercentageMated,
            lambingPercentageLambed: lambingPercentageLambed,
            bornAlivePercentage: bornAlivePercentage,
            mortalityPercentage: mortalityPercentage,
            dryEwesPercentage: dryEwesPercentage,
            mortalityPercentageEwesLambed: mortalityPercentageEwesLambed
        )
    }
}

// MARK: - Supporting Types

/// Aggregated raw data from all events (before metric calculation)
private struct AggregatedData {
    let totalEwesMated: Int
    let totalEwesScanned: Int
    let totalEwesPregnant: Int
    let totalEwesNotPregnant: Int
    let totalEwesWithSingles: Int
    let totalEwesWithTwins: Int
    let totalEwesWithTriplets: Int
    let totalScannedFetuses: Int
    let totalEwesLambed: Int
    let totalLambsBorn: Int
    let totalMortality: Int
    let totalLambsAlive: Int
}

/// Calculated metrics (all 10)
private struct CalculatedMetrics {
    let conceptionRate: Double
    let scanningRate: Double
    let expectedLambsPerEwePregnant: Double
    let expectedLambsPerEweMated: Double
    let lambingPercentageMated: Double
    let lambingPercentageLambed: Double
    let bornAlivePercentage: Double
    let mortalityPercentage: Double
    let dryEwesPercentage: Double
    let mortalityPercentageEwesLambed: Double
}
