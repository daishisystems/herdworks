//
//  AllLambingSeasonsViewModel.swift
//  HerdWorks
//
//  Created by OpenAI Assistant on 2025/02/15.
//

import Foundation
import Combine

@MainActor
final class AllLambingSeasonsViewModel: ObservableObject {
    
    @Published var groups: [LambingSeasonGroup] = []
    @Published var farms: [Farm] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showNoFarmsAlert = false

    private let lambingStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    private let userId: String
    private var farmNameCache: [String: String] = [:]

    init(lambingStore: LambingSeasonGroupStore, farmStore: FarmStore, userId: String) {
        self.lambingStore = lambingStore
        self.farmStore = farmStore
        self.userId = userId

        print("🔧 [ALL-SEASONS-VM] Initialized for user: \(userId)")
    }

    func loadData() async {
        print("🔵 [ALL-SEASONS-VM] loadData()")
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedFarms = try await farmStore.fetchAll(userId: userId)
            farms = loadedFarms
            updateFarmNameCache()
            print("✅ [ALL-SEASONS-VM] Loaded farms: \(farms.count)")

            let loadedGroups = try await loadAllGroups()
            groups = loadedGroups.sorted { $0.matingStart > $1.matingStart }
            print("✅ [ALL-SEASONS-VM] Loaded groups: \(groups.count)")
        } catch {
            print("❌ [ALL-SEASONS-VM] loadData failed: \(error)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }

    func farmName(for farmId: String) -> String {
        farmNameCache[farmId] ?? "farm.unknown_farm".localized()
    }

    func deleteGroup(_ group: LambingSeasonGroup) async {
        print("🔵 [ALL-SEASONS-VM] Deleting group: \(group.id)")
        do {
            try await lambingStore.delete(userId: userId, farmId: group.farmId, groupId: group.id)
            groups.removeAll { $0.id == group.id }
            print("✅ [ALL-SEASONS-VM] Deleted group: \(group.id)")
        } catch {
            print("❌ [ALL-SEASONS-VM] Failed to delete group: \(error)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }

    private func loadAllGroups() async throws -> [LambingSeasonGroup] {
        var allGroups: [LambingSeasonGroup] = []

        for farm in farms {
            do {
                let farmGroups = try await lambingStore.fetchAll(userId: userId, farmId: farm.id)
                allGroups.append(contentsOf: farmGroups)
                print("📊 [ALL-SEASONS-VM] Farm \(farm.name) groups: \(farmGroups.count)")
            } catch {
                print("⚠️ [ALL-SEASONS-VM] Failed to load farm \(farm.name): \(error)")
            }
        }

        return allGroups
    }

    private func updateFarmNameCache() {
        farmNameCache = Dictionary(uniqueKeysWithValues: farms.map { ($0.id, $0.name) })
        print("🔵 [ALL-SEASONS-VM] Farm name cache entries: \(farmNameCache.count)")
    }
}

