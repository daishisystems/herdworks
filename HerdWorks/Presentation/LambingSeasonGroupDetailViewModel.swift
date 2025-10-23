//
//  LambingSeasonGroupDetailViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import SwiftUI
import Combine

@MainActor
final class LambingSeasonGroupDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var code: String = ""
    @Published var name: String = ""
    @Published var matingStart: Date = Date()
    @Published var matingEnd: Date = Date().addingTimeInterval(86400 * 30) // +30 days
    @Published var lambingStart: Date = Date().addingTimeInterval(86400 * 150) // +150 days
    @Published var lambingEnd: Date = Date().addingTimeInterval(86400 * 180) // +180 days
    @Published var isActive: Bool = true
    
    // UI State
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let store: LambingSeasonGroupStore
    private let userId: String
    private let farmId: String
    private let existingGroup: LambingSeasonGroup?
    
    // MARK: - Computed Properties
    var isValid: Bool {
        !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        matingEnd > matingStart &&
        lambingStart > matingEnd &&
        lambingEnd > lambingStart
    }
    
    var navigationTitle: String {
        existingGroup == nil ? "lambing.add_group".localized() : "lambing.edit_group".localized()
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("lambing.error_code_required".localized())
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("lambing.error_name_required".localized())
        }
        
        if matingEnd <= matingStart {
            errors.append("lambing.error_mating_end".localized())
        }
        
        if lambingStart <= matingEnd {
            errors.append("lambing.error_lambing_start".localized())
        }
        
        if lambingEnd <= lambingStart {
            errors.append("lambing.error_lambing_end".localized())
        }
        
        return errors
    }
    
    // Computed date ranges for display
    var matingDurationDays: Int {
        Calendar.current.dateComponents([.day], from: matingStart, to: matingEnd).day ?? 0
    }
    
    var lambingDurationDays: Int {
        Calendar.current.dateComponents([.day], from: lambingStart, to: lambingEnd).day ?? 0
    }
    
    var gestationDays: Int {
        Calendar.current.dateComponents([.day], from: matingStart, to: lambingStart).day ?? 0
    }
    
    var gestationWarning: String? {
        let days = gestationDays
        if days < 140 {
            return "lambing.gestation_warning_short".localized()
        } else if days > 160 {
            return "lambing.gestation_warning_long".localized()
        }
        return nil
    }
    
    // MARK: - Initialization
    init(store: LambingSeasonGroupStore, userId: String, farmId: String, group: LambingSeasonGroup? = nil) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        self.existingGroup = group
        
        print("🔵 [LSG-VIEWMODEL] LambingSeasonGroupDetailViewModel initialized")
        print("🔵 [LSG-VIEWMODEL] User ID: \(userId)")
        print("🔵 [LSG-VIEWMODEL] Farm ID: \(farmId)")
        print("🔵 [LSG-VIEWMODEL] Is editing: \(group != nil)")
        
        if let group = group {
            loadGroup(group)
        }
    }
    
    // MARK: - Private Methods
    private func loadGroup(_ group: LambingSeasonGroup) {
        print("🔵 [LSG-VIEWMODEL] Loading existing group: \(group.displayName)")
        code = group.code
        name = group.name
        matingStart = group.matingStart
        matingEnd = group.matingEnd
        lambingStart = group.lambingStart
        lambingEnd = group.lambingEnd
        isActive = group.isActive
    }
    
    // MARK: - Public Methods
    func saveGroup() async -> Bool {
        print("🔵 [LSG-VIEWMODEL] saveGroup() called")
        print("🔵 [LSG-VIEWMODEL] Code: \(code)")
        print("🔵 [LSG-VIEWMODEL] Name: \(name)")
        print("🔵 [LSG-VIEWMODEL] Mating: \(matingStart) to \(matingEnd)")
        print("🔵 [LSG-VIEWMODEL] Lambing: \(lambingStart) to \(lambingEnd)")
        print("🔵 [LSG-VIEWMODEL] Active: \(isActive)")
        
        guard isValid else {
            print("⚠️ [LSG-VIEWMODEL] Validation failed")
            errorMessage = validationErrors.joined(separator: "\n")
            showError = true
            return false
        }
        
        print("✅ [LSG-VIEWMODEL] Validation passed")
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let group: LambingSeasonGroup
            
            if let existing = existingGroup {
                print("🔵 [LSG-VIEWMODEL] Updating existing group")
                // Update existing
                group = LambingSeasonGroup(
                    id: existing.id,
                    userId: userId,
                    farmId: farmId,
                    code: code.trimmingCharacters(in: .whitespacesAndNewlines),
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    matingStart: matingStart,
                    matingEnd: matingEnd,
                    lambingStart: lambingStart,
                    lambingEnd: lambingEnd,
                    isActive: isActive,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
                print("🔵 [LSG-VIEWMODEL] Calling store.update()")
                try await store.update(group)
                print("✅ [LSG-VIEWMODEL] store.update() completed")
            } else {
                print("🔵 [LSG-VIEWMODEL] Creating new group")
                // Create new
                group = LambingSeasonGroup(
                    userId: userId,
                    farmId: farmId,
                    code: code.trimmingCharacters(in: .whitespacesAndNewlines),
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    matingStart: matingStart,
                    matingEnd: matingEnd,
                    lambingStart: lambingStart,
                    lambingEnd: lambingEnd,
                    isActive: isActive
                )
                print("🔵 [LSG-VIEWMODEL] Group object created with ID: \(group.id)")
                print("🔵 [LSG-VIEWMODEL] Calling store.create()")
                try await store.create(group)
                print("✅ [LSG-VIEWMODEL] store.create() completed successfully")
            }
            
            print("✅ [LSG-VIEWMODEL] Save completed, returning true")
            return true
        } catch {
            print("❌ [LSG-VIEWMODEL] Save failed with error")
            print("❌ [LSG-VIEWMODEL] Error: \(error)")
            print("❌ [LSG-VIEWMODEL] Error type: \(type(of: error))")
            print("❌ [LSG-VIEWMODEL] Error description: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_save".localized(), error.localizedDescription)
            showError = true
            return false
        }
    }
    
    // Helper to auto-calculate lambing dates from mating dates
    func calculateLambingDatesFromMating() {
        print("🔵 [LSG-VIEWMODEL] Auto-calculating lambing dates")
        // Standard sheep gestation: 147-150 days, we'll use 150
        lambingStart = Calendar.current.date(byAdding: .day, value: 150, to: matingStart) ?? matingStart
        lambingEnd = Calendar.current.date(byAdding: .day, value: 150, to: matingEnd) ?? matingEnd
        print("🔵 [LSG-VIEWMODEL] Calculated lambing: \(lambingStart) to \(lambingEnd)")
    }
}
