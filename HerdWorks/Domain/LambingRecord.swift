//
//  LambingRecord.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation

// MARK: - Lambing Record Model

struct LambingRecord: Identifiable, Codable {
    let id: String
    let userId: String
    let farmId: String
    let lambingSeasonGroupId: String
    
    // USER INPUTS (Required)
    var ewesLambed: Int
    var lambsBorn: Int
    var lambsMortality0to30Days: Int
    
    // USER INPUTS (Optional)
    var averageBirthWeight: Double?
    
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        farmId: String,
        lambingSeasonGroupId: String,
        ewesLambed: Int = 0,
        lambsBorn: Int = 0,
        lambsMortality0to30Days: Int = 0,
        averageBirthWeight: Double? = nil
    ) {
        self.id = id
        self.userId = userId
        self.farmId = farmId
        self.lambingSeasonGroupId = lambingSeasonGroupId
        self.ewesLambed = ewesLambed
        self.lambsBorn = lambsBorn
        self.lambsMortality0to30Days = lambsMortality0to30Days
        self.averageBirthWeight = averageBirthWeight
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties (Calculated Metrics)
    
    /// Lambing Percentage: (Lambs Born / Ewes Lambed) × 100
    var lambingPercentage: Double {
        guard ewesLambed > 0 else { return 0 }
        return (Double(lambsBorn) / Double(ewesLambed)) * 100
    }
    
    /// Mortality Rate: (Lambs Dead / Lambs Born) × 100
    var mortalityRate: Double {
        guard lambsBorn > 0 else { return 0 }
        return (Double(lambsMortality0to30Days) / Double(lambsBorn)) * 100
    }
    
    /// Survival Rate: 100 - Mortality Rate
    var survivalRate: Double {
        return 100 - mortalityRate
    }
    
    /// Lambs Survived: Lambs Born - Lambs Dead
    var lambsSurvived: Int {
        return lambsBorn - lambsMortality0to30Days
    }
    
    // MARK: - Validation Helpers
    
    /// Returns true if mortality exceeds lambs born
    var hasMortalityExceedsBorn: Bool {
        return lambsMortality0to30Days > lambsBorn
    }
    
    /// Returns true if lambing percentage is unusually high (>200%)
    var hasUnusuallyHighLambingPercentage: Bool {
        return lambingPercentage > 200
    }
    
    /// Returns warning messages for data inconsistencies
    func warnings() -> [String] {
        var warnings: [String] = []
        
        if hasMortalityExceedsBorn {
            warnings.append("lambing.warning_mortality_exceeds_born".localized())
        }
        
        if hasUnusuallyHighLambingPercentage {
            warnings.append("lambing.warning_unusually_high_lambing".localized())
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

extension LambingRecord {
    static var preview: LambingRecord {
        LambingRecord(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            ewesLambed: 460,
            lambsBorn: 545,
            lambsMortality0to30Days: 75,
            averageBirthWeight: 3.5
        )
    }
    
    static var previewHighPerformance: LambingRecord {
        LambingRecord(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            ewesLambed: 500,
            lambsBorn: 625,
            lambsMortality0to30Days: 50,
            averageBirthWeight: 4.2
        )
    }
}
