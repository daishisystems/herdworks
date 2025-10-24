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
    private var farmListeners: [String: AnyCancellable] = [:]
    private var groupsByFarm: [String: [LambingSeasonGroup]] = [:]
    private var groupsDebounceTask: Task<Void, Never>?

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

            attachListeners()
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

    private func attachListeners() {
        // Cancel existing listeners
        farmListeners.values.forEach { $0.cancel() }
        farmListeners.removeAll()
        groupsByFarm.removeAll()

        for farm in farms {
            let cancellable = lambingStore.listenAll(userId: userId, farmId: farm.id) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }
                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-SEASONS-VM] Listener error for farm \(farm.name): \(error)")
                    case .success(let farmGroups):
                        self.groupsByFarm[farm.id] = farmGroups

                        // Debounce/coalesce rapid updates from multiple farm listeners
                        self.groupsDebounceTask?.cancel()
                        self.groupsDebounceTask = Task { [weak self] in
                            // Small debounce window (~120ms)
                            try? await Task.sleep(nanoseconds: 120_000_000)
                            guard let self = self else { return }
                            let all = self.groupsByFarm.values.flatMap { $0 }
                            let sorted = all.sorted { $0.matingStart > $1.matingStart }
                            self.groups = sorted
                            print("📡 [ALL-SEASONS-VM] Live update: total groups = \(sorted.count)")
                        }
                    }
                }
            }
            farmListeners[farm.id] = cancellable
        }
    }

    private func updateFarmNameCache() {
        farmNameCache = Dictionary(uniqueKeysWithValues: farms.map { ($0.id, $0.name) })
        print("🔵 [ALL-SEASONS-VM] Farm name cache entries: \(farmNameCache.count)")
    }

    deinit {
        farmListeners.values.forEach { $0.cancel() }
        groupsDebounceTask?.cancel()
    }
}

