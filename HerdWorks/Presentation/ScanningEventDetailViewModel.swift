//
//  ScanningEventDetailViewModel.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation
import Combine

@MainActor
final class ScanningEventDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Input fields (as strings for TextField binding)
    @Published var ewesMated: String = ""
    @Published var ewesScanned: String = ""
    @Published var ewesPregnant: String = ""
    @Published var ewesNotPregnant: String = ""
    @Published var ewesWithSingles: String = ""
    @Published var ewesWithTwins: String = ""
    @Published var ewesWithTriplets: String = ""
    
    // UI State
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var validationWarnings: [String] = []
    
    // MARK: - Private Properties
    
    private let store: ScanningEventStore
    private let userId: String
    private let farmId: String
    private let groupId: String
    private var existingEvent: ScanningEvent?
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        // Ewes mated is required and must be > 0
        guard let mated = Int(ewesMated), mated > 0 else {
            return false
        }
        
        // All other numeric fields must be valid if provided
        let numericFields = [ewesScanned, ewesPregnant, ewesNotPregnant, 
                            ewesWithSingles, ewesWithTwins, ewesWithTriplets]
        
        for field in numericFields where !field.isEmpty {
            if Int(field) == nil {
                return false
            }
            if let value = Int(field), value < 0 {
                return false
            }
        }
        
        return true
    }
    
    var isEditMode: Bool {
        existingEvent != nil
    }
    
    // Calculated values for display
    var conceptionRatio: Double {
        let scanned = Int(ewesScanned) ?? 0
        let pregnant = Int(ewesPregnant) ?? 0
        guard scanned > 0 else { return 0 }
        return (Double(pregnant) / Double(scanned)) * 100
    }
    
    var scannedFetuses: Int {
        let singles = Int(ewesWithSingles) ?? 0
        let twins = Int(ewesWithTwins) ?? 0
        let triplets = Int(ewesWithTriplets) ?? 0
        return singles + (twins * 2) + (triplets * 3)
    }
    
    var expectedLambingPercentagePregnant: Double {
        let pregnant = Int(ewesPregnant) ?? 0
        guard pregnant > 0 else { return 0 }
        return (Double(scannedFetuses) / Double(pregnant)) * 100
    }
    
    var expectedLambingPercentageMated: Double {
        let mated = Int(ewesMated) ?? 0
        guard mated > 0 else { return 0 }
        return (Double(scannedFetuses) / Double(mated)) * 100
    }
    
    // MARK: - Initializer
    
    init(
        store: ScanningEventStore,
        userId: String,
        farmId: String,
        groupId: String,
        event: ScanningEvent? = nil
    ) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.groupId = groupId
        self.existingEvent = event
        
        // Populate fields if editing
        if let event = event {
            self.ewesMated = "\(event.ewesMated)"
            self.ewesScanned = "\(event.ewesScanned)"
            self.ewesPregnant = "\(event.ewesPregnant)"
            self.ewesNotPregnant = "\(event.ewesNotPregnant)"
            self.ewesWithSingles = "\(event.ewesWithSingles)"
            self.ewesWithTwins = "\(event.ewesWithTwins)"
            self.ewesWithTriplets = "\(event.ewesWithTriplets)"
            
            print("🔵 [SCANNING-DETAIL-VM] Initialized in EDIT mode for event: \(event.id)")
        } else {
            print("🔵 [SCANNING-DETAIL-VM] Initialized in CREATE mode")
        }
    }
    
    // MARK: - Public Methods
    
    /// Save the scanning event (create or update)
    func save() async -> Bool {
        guard isValid else {
            print("⚠️ [SCANNING-DETAIL-VM] Cannot save: form is not valid")
            errorMessage = "profile_edit.fill_required_fields".localized()
            showError = true
            return false
        }
        
        // Build the event
        let event = ScanningEvent(
            id: existingEvent?.id ?? UUID().uuidString,
            userId: userId,
            farmId: farmId,
            lambingSeasonGroupId: groupId,
            ewesMated: Int(ewesMated) ?? 0,
            ewesScanned: Int(ewesScanned) ?? 0,
            ewesPregnant: Int(ewesPregnant) ?? 0,
            ewesNotPregnant: Int(ewesNotPregnant) ?? 0,
            ewesWithSingles: Int(ewesWithSingles) ?? 0,
            ewesWithTwins: Int(ewesWithTwins) ?? 0,
            ewesWithTriplets: Int(ewesWithTriplets) ?? 0
        )
        
        // Update validation warnings
        validationWarnings = event.warnings()
        if !validationWarnings.isEmpty {
            print("⚠️ [SCANNING-DETAIL-VM] Validation warnings: \(validationWarnings)")
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            if isEditMode {
                print("🔵 [SCANNING-DETAIL-VM] Updating scanning event: \(event.id)")
                try await store.update(event)
                print("✅ [SCANNING-DETAIL-VM] Updated scanning event successfully")
            } else {
                print("🔵 [SCANNING-DETAIL-VM] Creating new scanning event")
                try await store.create(event)
                print("✅ [SCANNING-DETAIL-VM] Created scanning event successfully")
            }
            return true
        } catch {
            print("❌ [SCANNING-DETAIL-VM] Error saving scanning event: \(error.localizedDescription)")
            errorMessage = "error.failed_to_save".localized() + ": \(error.localizedDescription)"
            showError = true
            return false
        }
    }
}
