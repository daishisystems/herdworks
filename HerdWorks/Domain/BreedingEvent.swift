//
//  BreedingEvent.swift
//  HerdWorks
//
//  Updated: Phase 4 - Corrected data model with proper spelling
//

import Foundation

// MARK: - Mating Type Enum

enum MatingType: String, Codable, CaseIterable {
    case naturalMating = "Natural Mating"
    case cervicalAI = "Cervical AI"
    case laparoscopicAI = "Laparoscopic AI"
    
    var displayName: String {
        return rawValue
    }
    
    // Localized display name for UI
    var localizedName: String {
        switch self {
        case .naturalMating:
            return "breeding.mating_type_natural".localized()
        case .cervicalAI:
            return "breeding.mating_type_cervical".localized()
        case .laparoscopicAI:
            return "breeding.mating_type_laparoscopic".localized()
        }
    }
}

// MARK: - Breeding Event Model

struct BreedingEvent: Identifiable, Codable {
    let id: String
    let userId: String
    let farmId: String
    let lambingSeasonGroupId: String
    
    // REQUIRED FIELDS
    var matingType: MatingType
    var numberOfEwesMated: Int
    
    // NATURAL MATING FIELDS (only if matingType == .naturalMating)
    var naturalMatingStart: Date?
    var naturalMatingDays: Int?  // User enters manually
    
    // AI FIELDS (only if matingType == .cervicalAI or .laparoscopicAI)
    var aiDate: Date?
    
    // FOLLOW-UP RAMS (only for AI types)
    var usedFollowUpRams: Bool
    var followUpRamsIn: Date?
    var followUpRamsOut: Date?
    
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        farmId: String,
        lambingSeasonGroupId: String,
        matingType: MatingType,
        numberOfEwesMated: Int,
        naturalMatingStart: Date? = nil,
        naturalMatingDays: Int? = nil,
        aiDate: Date? = nil,
        usedFollowUpRams: Bool = false,
        followUpRamsIn: Date? = nil,
        followUpRamsOut: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.farmId = farmId
        self.lambingSeasonGroupId = lambingSeasonGroupId
        self.matingType = matingType
        self.numberOfEwesMated = numberOfEwesMated
        self.naturalMatingStart = naturalMatingStart
        self.naturalMatingDays = naturalMatingDays
        self.aiDate = aiDate
        self.usedFollowUpRams = usedFollowUpRams
        self.followUpRamsIn = followUpRamsIn
        self.followUpRamsOut = followUpRamsOut
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Auto-calculated Natural Mating End date
    var naturalMatingEnd: Date? {
        guard let start = naturalMatingStart,
              let days = naturalMatingDays,
              days > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: start)
    }
    
    /// Inclusive follow-up rams duration (today to tomorrow = 1 day)
    var followUpDaysIn: Int? {
        guard usedFollowUpRams,
              let inDate = followUpRamsIn,
              let outDate = followUpRamsOut else { return nil }
        
        let components = Calendar.current.dateComponents([.day], from: inDate, to: outDate)
        let days = components.day ?? 0
        return days + 1  // Inclusive calculation
    }
    
    /// Display date for list rows
    var displayDate: Date? {
        if matingType == .naturalMating {
            return naturalMatingStart
        } else {
            return aiDate
        }
    }
    
    /// Breeding method description for display (localized)
    var breedingMethodDescription: String {
        return matingType.localizedName
    }
    
    /// Year for grouping (derived from relevant date)
    var year: Int {
        let calendar = Calendar.current
        if let date = displayDate {
            return calendar.component(.year, from: date)
        }
        return calendar.component(.year, from: createdAt)
    }
}

// MARK: - Preview Helpers

extension BreedingEvent {
    static var preview: BreedingEvent {
        BreedingEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            matingType: .naturalMating,
            numberOfEwesMated: 300,
            naturalMatingStart: Date(),
            naturalMatingDays: 2
        )
    }
    
    static var previewAI: BreedingEvent {
        BreedingEvent(
            userId: "preview-user",
            farmId: "preview-farm",
            lambingSeasonGroupId: "preview-group",
            matingType: .cervicalAI,
            numberOfEwesMated: 500,
            aiDate: Date(),
            usedFollowUpRams: true,
            followUpRamsIn: Date(),
            followUpRamsOut: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
    }
}
