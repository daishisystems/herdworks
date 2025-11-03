//
//  ScanningEvent.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation

// MARK: - Scanning Event Model

struct ScanningEvent: Identifiable, Codable {
    let id: String
    let userId: String
    let farmId: String
    let lambingSeasonGroupId: String
    
    // REQUIRED FIELDS
    var ewesMated: Int
    
    // SCANNING RESULTS
    var ewesScanned: Int
    var ewesPregnant: Int
    var ewesNotPregnant: Int
    
    // FETUS DISTRIBUTION
    var ewesWithSingles: Int
    var ewesWithTwins: Int
    var ewesWithTriplets: Int
    
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        farmId: String,
        lambingSeasonGroupId: String,
        ewesMated: Int = 0,
        ewesScanned: Int = 0,
        ewesPregnant: Int = 0,
        ewesNotPregnant: Int = 0,
        ewesWithSingles: Int = 0,
        ewesWithTwins: Int = 0,
        ewesWithTriplets: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.farmId = farmId
        self.lambingSeasonGroupId = lambingSeasonGroupId
        self.ewesMated = ewesMated
        self.ewesScanned = ewesScanned
        self.ewesPregnant = ewesPregnant
        self.ewesNotPregnant = ewesNotPregnant
        self.ewesWithSingles = ewesWithSingles
        self.ewesWithTwins = ewesWithTwins
        self.ewesWithTriplets = ewesWithTriplets
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties (Auto-calculated)
    
    /// Conception Ratio: (Ewes Pregnant / Ewes Scanned) × 100
    var conceptionRatio: Double {
        guard ewesScanned > 0 else { return 0 }
        return (Double(ewesPregnant) / Double(ewesScanned)) * 100
    }
    
    /// Scanned Fetuses: Singles + (Twins × 2) + (Triplets × 3)
    var scannedFetuses: Int {
        return ewesWithSingles + (ewesWithTwins * 2) + (ewesWithTriplets * 3)
    }
    
    /// Expected Lambing % of Ewes Pregnant: (Scanned Fetuses / Ewes Pregnant) × 100
    var expectedLambingPercentagePregnant: Double {
        guard ewesPregnant > 0 else { return 0 }
        return (Double(scannedFetuses) / Double(ewesPregnant)) * 100
    }
    
    /// Expected Lambing % of Ewes Mated: (Scanned Fetuses / Ewes Mated) × 100
    var expectedLambingPercentageMated: Double {
        guard ewesMated > 0 else { return 0 }
        return (Double(scannedFetuses) / Double(ewesMated)) * 100
    }
    
    // MARK: - Validation Helpers
    
    /// Returns true if scanned count exceeds mated count
    var hasScannedExceedsMated: Bool {
        return ewesScanned > ewesMated
    }
    
    /// Returns true if pregnant + not pregnant exceeds scanned
    var hasPregnancyCountMismatch: Bool {
        return (ewesPregnant + ewesNotPregnant) > ewesScanned
    }
    
    /// Returns true if fetus distribution exceeds pregnant count
    var hasFetusDistributionMismatch: Bool {
        return (ewesWithSingles + ewesWithTwins + ewesWithTriplets) > ewesPregnant
    }
    
    /// Returns warning messages for data inconsistencies
    func warnings() -> [String] {
        var warnings: [String] = []
        
        if hasScannedExceedsMated {
            warnings.append("scanning.warning_scanned_exceeds_mated".localized())
        }
        
        if hasPregnancyCountMismatch {
            warnings.append("scanning.warning_pregnancy_count_mismatch".localized())
        }
        
        if hasFetusDistributionMismatch {
            warnings.append("scanning.warning_fetus_distribution_mismatch".localized())
        }
        
        return warnings
    }
    
    /// Year for grouping (derived from creation date)
    var year: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: createdAt)
    }
}

// MARK: - Preview Helpers

extension ScanningEvent {
    static var preview: ScanningEvent {
        ScanningEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            ewesMated: 300,
            ewesScanned: 295,
            ewesPregnant: 275,
            ewesNotPregnant: 20,
            ewesWithSingles: 100,
            ewesWithTwins: 150,
            ewesWithTriplets: 25
        )
    }
    
    static var previewHighConception: ScanningEvent {
        ScanningEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            ewesMated: 500,
            ewesScanned: 482,
            ewesPregnant: 465,
            ewesNotPregnant: 17,
            ewesWithSingles: 150,
            ewesWithTwins: 250,
            ewesWithTriplets: 65
        )
    }
}
