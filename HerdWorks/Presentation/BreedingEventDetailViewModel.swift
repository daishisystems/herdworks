//
//  BreedingEventDetailViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/24.
//

import SwiftUI
import FirebaseAuth
import Combine

@MainActor
final class BreedingEventDetailViewModel: ObservableObject {
    // ❌ REMOVED THIS LINE - it was breaking SwiftUI's change tracking:
    // var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
    // MARK: - Published Properties (Form Fields)
    
    // AI Breeding
    @Published var useAI: Bool = false
    @Published var aiDate: Date = Date()
    
    // Natural Mating
    @Published var useNaturalMating: Bool = false
    @Published var naturalMatingStart: Date = Date()
    @Published var naturalMatingEnd: Date = Date()
    
    // Follow-Up Rams
    @Published var usedFollowUpRams: Bool = false
    @Published var followUpRamsIn: Date = Date()
    @Published var followUpRamsOut: Date = Date()
    
    // State
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let store: BreedingEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    private let event: BreedingEvent? // nil for create, populated for edit
    
    // MARK: - Computed Properties - Validation
    
    var hasBreedingMethod: Bool {
        useAI || useNaturalMating
    }
    
    var naturalMatingDatesValid: Bool {
        guard useNaturalMating else { return true } // Valid if not used
        return naturalMatingEnd >= naturalMatingStart
    }
    
    var followUpDatesValid: Bool {
        guard usedFollowUpRams else { return true } // Valid if not used
        return followUpRamsOut >= followUpRamsIn
    }
    
    var isValid: Bool {
        hasBreedingMethod &&
        naturalMatingDatesValid &&
        followUpDatesValid
    }
    
    // MARK: - Computed Properties - Calculations
    
    var naturalMatingDays: Int? {
        guard useNaturalMating else { return nil }
        let days = Calendar.current.dateComponents([.day], from: naturalMatingStart, to: naturalMatingEnd).day ?? 0
        return max(0, days)
    }
    
    var followUpDays: Int? {
        guard usedFollowUpRams else { return nil }
        let days = Calendar.current.dateComponents([.day], from: followUpRamsIn, to: followUpRamsOut).day ?? 0
        return max(0, days)
    }
    
    var calculationDate: Date? {
        if useAI {
            return aiDate
        } else if useNaturalMating {
            return naturalMatingStart
        }
        return nil
    }
    
    var year: Int {
        guard let date = calculationDate else {
            return Calendar.current.component(.year, from: Date())
        }
        return Calendar.current.component(.year, from: date)
    }
    
    // MARK: - Computed Properties - Validation Messages
    
    var breedingMethodError: String? {
        guard !hasBreedingMethod else { return nil }
        return "breeding.error.no_breeding_method".localized()
    }
    
    var naturalMatingDatesError: String? {
        guard useNaturalMating && !naturalMatingDatesValid else { return nil }
        return "breeding.error.invalid_mating_dates".localized()
    }
    
    var followUpDatesError: String? {
        guard usedFollowUpRams && !followUpDatesValid else { return nil }
        return "breeding.error.invalid_followup_dates".localized()
    }
    
    // MARK: - Initialization
    
    init(store: BreedingEventStore, userId: String, farmId: String, groupId: String, event: BreedingEvent? = nil) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
        self.event = event
        
        // Populate fields if editing
        if let event = event {
            self.useAI = event.aiDate != nil
            self.aiDate = event.aiDate ?? Date()
            
            self.useNaturalMating = event.naturalMatingStart != nil
            self.naturalMatingStart = event.naturalMatingStart ?? Date()
            self.naturalMatingEnd = event.naturalMatingEnd ?? Date()
            
            self.usedFollowUpRams = event.usedFollowUpRams
            self.followUpRamsIn = event.followUpRamsIn ?? Date()
            self.followUpRamsOut = event.followUpRamsOut ?? Date()
            
            print("🔵 [BREEDING-DETAIL] Editing event: Year \(event.year)")
        } else {
            print("🔵 [BREEDING-DETAIL] Creating new event")
        }
    }
    
    // MARK: - Public Methods
    
    func save() async -> Bool {
        print("🔵 [BREEDING-DETAIL] save() called")
        
        guard isValid else {
            print("⚠️ [BREEDING-DETAIL] Validation failed")
            errorMessage = breedingMethodError ?? naturalMatingDatesError ?? followUpDatesError
            showError = true
            return false
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let breedingEvent = BreedingEvent(
                id: event?.id ?? UUID().uuidString,
                userId: userId,
                farmId: farmId,
                lambingSeasonGroupId: groupId,
                aiDate: useAI ? aiDate : nil,
                naturalMatingStart: useNaturalMating ? naturalMatingStart : nil,
                naturalMatingEnd: useNaturalMating ? naturalMatingEnd : nil,
                usedFollowUpRams: usedFollowUpRams,
                followUpRamsIn: usedFollowUpRams ? followUpRamsIn : nil,
                followUpRamsOut: usedFollowUpRams ? followUpRamsOut : nil,
                createdAt: event?.createdAt ?? Date(),
                updatedAt: Date()
            )
            
            if event != nil {
                // Update existing
                print("🔵 [BREEDING-DETAIL] Updating event: \(breedingEvent.id)")
                try await store.update(breedingEvent)
                print("✅ [BREEDING-DETAIL] Event updated successfully")
            } else {
                // Create new
                print("🔵 [BREEDING-DETAIL] Creating new event: \(breedingEvent.id)")
                try await store.create(breedingEvent)
                print("✅ [BREEDING-DETAIL] Event created successfully")
            }
            
            return true
        } catch {
            print("❌ [BREEDING-DETAIL] Save failed: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_save".localized(), error.localizedDescription)
            showError = true
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    func correctNaturalMatingDates() {
        if useNaturalMating && naturalMatingEnd < naturalMatingStart {
            naturalMatingEnd = Calendar.current.date(byAdding: .day, value: 1, to: naturalMatingStart) ?? naturalMatingStart
            print("🔵 [BREEDING-DETAIL] Auto-corrected natural mating end date")
        }
    }
    
    func correctFollowUpDates() {
        if usedFollowUpRams && followUpRamsOut < followUpRamsIn {
            followUpRamsOut = Calendar.current.date(byAdding: .day, value: 1, to: followUpRamsIn) ?? followUpRamsIn
            print("🔵 [BREEDING-DETAIL] Auto-corrected follow-up rams out date")
        }
    }
}
