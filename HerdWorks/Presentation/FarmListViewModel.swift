//
//  FarmListViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth
import Combine

@MainActor
final class FarmListViewModel: ObservableObject {
    @Published var farms: [Farm] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var farmToDelete: Farm?
    @Published var showDeleteConfirmation = false
    
    private let store: FarmStore
    private let userId: String
    
    init(store: FarmStore, userId: String) {
        self.store = store
        self.userId = userId
        
        print("🔵 [LIST] FarmListViewModel initialized")
        print("🔵 [LIST] User ID from init: \(userId)")
        print("🔵 [LIST] Auth current user: \(Auth.auth().currentUser?.uid ?? "NONE")")
        print("🔵 [LIST] User IDs match: \(userId == (Auth.auth().currentUser?.uid ?? ""))")
    }
    
    func loadFarms() async {
        print("🔵 [LIST] loadFarms() called")
        print("🔵 [LIST] User ID: \(userId)")
        
        isLoading = true
        defer {
            isLoading = false
            print("🔵 [LIST] Loading completed, isLoading = false")
        }
        
        do {
            print("🔵 [LIST] Calling store.fetchAll()")
            farms = try await store.fetchAll(userId: userId)
            print("✅ [LIST] Loaded \(farms.count) farms")
            for (index, farm) in farms.enumerated() {
                print("✅ [LIST] Farm \(index): \(farm.name) - \(farm.totalProductionEwes) ewes")
            }
        } catch {
            print("❌ [LIST] Failed to load farms")
            print("❌ [LIST] Error: \(error)")
            print("❌ [LIST] Error description: \(error.localizedDescription)")
            errorMessage = "Failed to load farms: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func confirmDelete(_ farm: Farm) {
        print("🔵 [LIST] confirmDelete() called for: \(farm.name)")
        farmToDelete = farm
        showDeleteConfirmation = true
    }
    
    func deleteFarm() async {
        guard let farm = farmToDelete else {
            print("⚠️ [LIST] deleteFarm() called but farmToDelete is nil")
            return
        }
        
        print("🔵 [LIST] Deleting farm: \(farm.name) (ID: \(farm.id))")
        
        do {
            print("🔵 [LIST] Calling store.delete()")
            try await store.delete(farmId: farm.id, userId: userId)
            print("✅ [LIST] Delete successful, removing from local array")
            // Remove from local array
            farms.removeAll { $0.id == farm.id }
            farmToDelete = nil
            print("✅ [LIST] Farm removed from local array, count now: \(farms.count)")
        } catch {
            print("❌ [LIST] Failed to delete farm")
            print("❌ [LIST] Error: \(error)")
            print("❌ [LIST] Error description: \(error.localizedDescription)")
            errorMessage = "Failed to delete farm: \(error.localizedDescription)"
            showError = true
        }
    }
}
