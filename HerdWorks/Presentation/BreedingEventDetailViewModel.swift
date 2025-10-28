//
//  BreedingEventDetailViewModel.swift
//  HerdWorks
//
//  Updated: Phase 4 - Corrected validation and auto-calculations
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class BreedingEventDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var matingType: MatingType = .naturalMating
    @Published var numberOfEwesMated: String = ""
    
    // Natural Mating fields
    @Published var naturalMatingStart: Date = Date()
    @Published var naturalMatingDays: String = ""
    
    // AI fields
    @Published var aiDate: Date = Date()
    
    // Follow-up rams (AI only)
    @Published var usedFollowUpRams: Bool = false
    @Published var followUpRamsIn: Date = Date()
    @Published var followUpRamsOut: Date = Date()
    
    // UI State
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let store: BreedingEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    private let existingEvent: BreedingEvent?
    
    // MARK: - Computed Properties
    
    var isEditing: Bool {
        existingEvent != nil
    }
    
    var navigationTitle: String {
        isEditing ? "breeding.edit_event".localized() : "breeding.add_event".localized()
    }
    
    // Auto-calculated Natural Mating End
    var naturalMatingEnd: Date? {
        guard let days = Int(naturalMatingDays), days > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: naturalMatingStart)
    }
    
    // Auto-calculated Follow-up Days In (inclusive)
    var followUpDaysInCalculated: Int? {
        guard usedFollowUpRams else { return nil }
        let components = Calendar.current.dateComponents([.day], from: followUpRamsIn, to: followUpRamsOut)
        let days = components.day ?? 0
        return days + 1  // Inclusive calculation
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        // Base validation
        guard let ewes = Int(numberOfEwesMated), ewes > 0 else { return false }
        
        // Type-specific validation
        switch matingType {
        case .naturalMating:
            // Natural mating requires: start date and days
            guard let days = Int(naturalMatingDays), days > 0 else { return false }
            return true
            
        case .cervicalAI, .laparoscopicAI:
            // AI types require: AI date
            // If follow-up rams used, validate those dates too
            if usedFollowUpRams {
                // Follow-up dates must be valid and out > in
                return followUpRamsOut > followUpRamsIn
            }
            return true
        }
    }
    
    var numberOfEwesMatedError: String? {
        guard !numberOfEwesMated.isEmpty else {
            return "breeding.ewes_required".localized()
        }
        guard let ewes = Int(numberOfEwesMated), ewes > 0 else {
            return "breeding.ewes_must_be_positive".localized()
        }
        return nil
    }
    
    var naturalMatingDaysError: String? {
        guard matingType == .naturalMating else { return nil }
        guard !naturalMatingDays.isEmpty else {
            return "breeding.days_required".localized()
        }
        guard let days = Int(naturalMatingDays), days > 0 else {
            return "breeding.days_must_be_positive".localized()
        }
        return nil
    }
    
    var followUpDatesValid: Bool {
        guard usedFollowUpRams else { return true }
        return followUpRamsOut > followUpRamsIn
    }
    
    var followUpDatesError: String? {
        guard usedFollowUpRams else { return nil }
        guard followUpRamsOut > followUpRamsIn else {
            return "breeding.rams_out_must_be_after_in".localized()
        }
        return nil
    }
    
    // MARK: - Initializer
    
    init(
        store: BreedingEventStore,
        userId: String,
        farmId: String,
        groupId: String,
        event: BreedingEvent? = nil
    ) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
        self.existingEvent = event
        
        if let event = event {
            loadExistingEvent(event)
        }
    }
    
    // MARK: - Methods
    
    private func loadExistingEvent(_ event: BreedingEvent) {
        matingType = event.matingType
        numberOfEwesMated = String(event.numberOfEwesMated)
        
        if let start = event.naturalMatingStart {
            naturalMatingStart = start
        }
        if let days = event.naturalMatingDays {
            naturalMatingDays = String(days)
        }
        if let ai = event.aiDate {
            aiDate = ai
        }
        
        usedFollowUpRams = event.usedFollowUpRams
        if let ramsIn = event.followUpRamsIn {
            followUpRamsIn = ramsIn
        }
        if let ramsOut = event.followUpRamsOut {
            followUpRamsOut = ramsOut
        }
    }
    
    func correctFollowUpDates() {
        guard usedFollowUpRams else { return }
        if followUpRamsOut <= followUpRamsIn {
            followUpRamsOut = Calendar.current.date(byAdding: .day, value: 1, to: followUpRamsIn) ?? followUpRamsIn
        }
    }
    
    func save() async -> Bool {
        guard isValid else {
            errorMessage = "error.fill_required_fields".localized()
            showError = true
            return false
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let ewes = Int(numberOfEwesMated) ?? 0
            
            let event = BreedingEvent(
                id: existingEvent?.id ?? UUID().uuidString,
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                matingType: matingType,
                numberOfEwesMated: ewes,
                naturalMatingStart: matingType == .naturalMating ? naturalMatingStart : nil,
                naturalMatingDays: matingType == .naturalMating ? Int(naturalMatingDays) : nil,
                aiDate: matingType != .naturalMating ? aiDate : nil,
                usedFollowUpRams: matingType != .naturalMating ? usedFollowUpRams : false,
                followUpRamsIn: (matingType != .naturalMating && usedFollowUpRams) ? followUpRamsIn : nil,
                followUpRamsOut: (matingType != .naturalMating && usedFollowUpRams) ? followUpRamsOut : nil
            )
            
            if isEditing {
                try await store.update(event)
                print("✅ [BREEDING-DETAIL] Event updated successfully")
            } else {
                try await store.create(event)
                print("✅ [BREEDING-DETAIL] Event created successfully")
            }
            
            return true
            
        } catch {
            print("❌ [BREEDING-DETAIL] Save error: \(error)")
            errorMessage = String(format: "error.failed_to_save".localized(), error.localizedDescription)
            showError = true
            return false
        }
    }
}
