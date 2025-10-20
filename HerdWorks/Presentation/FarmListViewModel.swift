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
    }
    
    func loadFarms() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            farms = try await store.fetchAll(userId: userId)
        } catch {
            errorMessage = "Failed to load farms: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func confirmDelete(_ farm: Farm) {
        farmToDelete = farm
        showDeleteConfirmation = true
    }
    
    func deleteFarm() async {
        guard let farm = farmToDelete else { return }
        
        do {
            try await store.delete(farmId: farm.id, userId: userId)
            // Remove from local array
            farms.removeAll { $0.id == farm.id }
            farmToDelete = nil
        } catch {
            errorMessage = "Failed to delete farm: \(error.localizedDescription)"
            showError = true
        }
    }
}
