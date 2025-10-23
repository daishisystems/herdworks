//
//  LambingSeasonGroupListViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import SwiftUI
import Combine

@MainActor
final class LambingSeasonGroupListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [LambingSeasonGroup] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation: Bool = false
    @Published var showActiveOnly: Bool = false
    
    // MARK: - Private Properties
    private let store: LambingSeasonGroupStore
    private let userId: String
    private let farmId: String
    var groupToDelete: LambingSeasonGroup?
    
    // MARK: - Computed Properties
    var displayedGroups: [LambingSeasonGroup] {
        if showActiveOnly {
            return groups.filter { $0.isActive }
        }
        return groups
    }
    
    var hasActiveGroups: Bool {
        groups.contains { $0.isActive }
    }
    
    var hasInactiveGroups: Bool {
        groups.contains { !$0.isActive }
    }
    
    // MARK: - Initialization
    init(store: LambingSeasonGroupStore, userId: String, farmId: String) {
        self.store = store
        self.userId = userId
        self.farmId = farmId
        
        print("🔵 [LSG-LIST] LambingSeasonGroupListViewModel initialized")
        print("🔵 [LSG-LIST] User ID: \(userId)")
        print("🔵 [LSG-LIST] Farm ID: \(farmId)")
    }
    
    // MARK: - Public Methods
    func loadGroups() async {
        print("🔵 [LSG-LIST] loadGroups() called")
        print("🔵 [LSG-LIST] User ID: \(userId)")
        print("🔵 [LSG-LIST] Farm ID: \(farmId)")
        print("🔵 [LSG-LIST] Calling store.fetchAll()")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            groups = try await store.fetchAll(userId: userId, farmId: farmId)
            print("✅ [LSG-LIST] Loaded \(groups.count) groups")
            
            for (index, group) in groups.enumerated() {
                print("✅ [LSG-LIST] Group \(index): \(group.displayName) - \(group.isActive ? "Active" : "Inactive")")
            }
            
            print("🔵 [LSG-LIST] Loading completed, isLoading = false")
        } catch {
            print("❌ [LSG-LIST] Error loading groups: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func confirmDelete(_ group: LambingSeasonGroup) {
        print("🔵 [LSG-LIST] Confirm delete: \(group.displayName)")
        groupToDelete = group
        showDeleteConfirmation = true
    }
    
    func deleteGroup() async {
        guard let group = groupToDelete else {
            print("⚠️ [LSG-LIST] No group to delete")
            return
        }
        
        print("🔵 [LSG-LIST] deleteGroup() called")
        print("🔵 [LSG-LIST] Group: \(group.displayName)")
        print("🔵 [LSG-LIST] Group ID: \(group.id)")
        
        do {
            try await store.delete(userId: userId, farmId: farmId, groupId: group.id)
            print("✅ [LSG-LIST] Group deleted successfully")
            
            // Remove from local array
            groups.removeAll { $0.id == group.id }
            print("✅ [LSG-LIST] Removed from local array, now have \(groups.count) groups")
            
            groupToDelete = nil
        } catch {
            print("❌ [LSG-LIST] Error deleting group: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func toggleActiveFilter() {
        showActiveOnly.toggle()
        print("🔵 [LSG-LIST] Active filter toggled: \(showActiveOnly)")
    }
}
