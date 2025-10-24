//
//  BreedingEvent.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/24.
//

import Foundation

/// Represents a breeding event for a specific lambing season group
/// Tracks AI and/or natural mating, plus follow-up ram usage
struct BreedingEvent: Identifiable, Codable {
    // MARK: - Identity
    let id: String // UUID
    let userId: String
    let farmId: String
    let lambingSeasonGroupId: String
    
    // MARK: - Breeding Methods
    /// Artificial insemination date (optional)
    var aiDate: Date?
    
    /// Natural mating start date (optional)
    var naturalMatingStart: Date?
    
    /// Natural mating end date (optional)
    var naturalMatingEnd: Date?
    
    // MARK: - Follow-Up Rams
    /// Whether follow-up rams were used
    var usedFollowUpRams: Bool
    
    /// Date follow-up rams were introduced (required if usedFollowUpRams is true)
    var followUpRamsIn: Date?
    
    /// Date follow-up rams were removed (required if usedFollowUpRams is true)
    var followUpRamsOut: Date?
    
    // MARK: - Timestamps
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Duration of natural mating period in days
    var naturalMatingDays: Int? {
        guard let start = naturalMatingStart,
              let end = naturalMatingEnd else {
            return nil
        }
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(0, days) // Ensure non-negative
    }
    
    /// Duration of follow-up ram period in days
    var followUpDays: Int? {
        guard let ramsIn = followUpRamsIn,
              let ramsOut = followUpRamsOut else {
            return nil
        }
        let days = Calendar.current.dateComponents([.day], from: ramsIn, to: ramsOut).day ?? 0
        return max(0, days) // Ensure non-negative
    }
    
    /// The reference date used for year calculation
    /// Uses AI date if available, otherwise natural mating start
    var calculationDate: Date? {
        aiDate ?? naturalMatingStart
    }
    
    /// The year of the breeding event (calculated from the reference date)
    var year: Int {
        guard let date = calculationDate else {
            return Calendar.current.component(.year, from: Date())
        }
        return Calendar.current.component(.year, from: date)
    }
    
    /// Whether this event has valid breeding data (at least one method specified)
    var hasBreedingData: Bool {
        aiDate != nil || naturalMatingStart != nil
    }
    
    /// Display date for sorting and UI (uses calculation date)
    var displayDate: Date? {
        calculationDate
    }
    
    /// Display text for breeding method
    var breedingMethodDescription: String {
        var methods: [String] = []
        
        if aiDate != nil {
            methods.append("breeding.method_ai".localized())
        }
        
        if naturalMatingStart != nil {
            methods.append("breeding.method_natural".localized())
        }
        
        if methods.isEmpty {
            return "breeding.method_none".localized()
        }
        
        return methods.joined(separator: ", ")
    }
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        farmId: String,
        lambingSeasonGroupId: String,
        aiDate: Date? = nil,
        naturalMatingStart: Date? = nil,
        naturalMatingEnd: Date? = nil,
        usedFollowUpRams: Bool = false,
        followUpRamsIn: Date? = nil,
        followUpRamsOut: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.farmId = farmId
        self.lambingSeasonGroupId = lambingSeasonGroupId
        self.aiDate = aiDate
        self.naturalMatingStart = naturalMatingStart
        self.naturalMatingEnd = naturalMatingEnd
        self.usedFollowUpRams = usedFollowUpRams
        self.followUpRamsIn = followUpRamsIn
        self.followUpRamsOut = followUpRamsOut
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Validation Helpers

extension BreedingEvent {
    /// Validates that at least one breeding method is specified
    var hasValidBreedingMethod: Bool {
        hasBreedingData
    }
    
    /// Validates that natural mating dates are in correct order
    var hasValidNaturalMatingDates: Bool {
        guard let start = naturalMatingStart,
              let end = naturalMatingEnd else {
            // If one is nil, the other should be nil too for validity
            return naturalMatingStart == nil && naturalMatingEnd == nil
        }
        return end >= start
    }
    
    /// Validates that follow-up ram dates are in correct order
    var hasValidFollowUpDates: Bool {
        // If not using follow-up rams, dates should be nil
        guard usedFollowUpRams else {
            return followUpRamsIn == nil && followUpRamsOut == nil
        }
        
        // If using follow-up rams, both dates must be provided
        guard let ramsIn = followUpRamsIn,
              let ramsOut = followUpRamsOut else {
            return false
        }
        
        return ramsOut >= ramsIn
    }
    
    /// Overall validation status
    var isValid: Bool {
        hasValidBreedingMethod &&
        hasValidNaturalMatingDates &&
        hasValidFollowUpDates
    }
}

// MARK: - Display Formatting

extension BreedingEvent {
    /// Formatted year string for display
    var yearString: String {
        String(year)
    }
    
    /// Formatted natural mating duration for display
    var naturalMatingDaysString: String? {
        guard let days = naturalMatingDays else { return nil }
        return "\(days) \("lambing.days".localized())"
    }
    
    /// Formatted follow-up ram duration for display
    var followUpDaysString: String? {
        guard let days = followUpDays else { return nil }
        return "\(days) \("lambing.days".localized())"
    }
}
