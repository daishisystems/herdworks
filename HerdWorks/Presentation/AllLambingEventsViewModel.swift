//
//  AllLambingEventsViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import Foundation
import Combine

@MainActor
final class AllLambingEventsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var records: [LambingRecord] = []
    @Published var farms: [Farm] = []
    @Published var groups: [LambingSeasonGroup] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showNoGroupsAlert = false
    
    // MARK: - Internal Properties (accessible from views)
    let recordStore: LambingRecordStore  // ✅ Changed from private
    let userId: String  // ✅ Changed from private
    var groupInfoCache: [String: GroupInfo] = [:]  // ✅ Changed from private
    
    // MARK: - Private Properties
    private let groupStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    let benchmarkStore: BenchmarkStore
    
    // Caching
    private var farmNameCache: [String: String] = [:]
    private var benchmarkCache: [String: BenchmarkData] = [:]
    
    // Listeners
    private var groupListeners: [String: AnyCancellable] = [:]
    private var recordListeners: [String: AnyCancellable] = [:]
    
    // Debouncing
    private var groupsDebounceTask: Task<Void, Never>?
    private var recordsDebounceTask: Task<Void, Never>?
    
    // Intermediate state
    private var groupsByFarm: [String: [LambingSeasonGroup]] = [:]
    private var recordsByGroup: [String: [LambingRecord]] = [:]
    
    // Change tracking
    private var lastGroupIdSet: Set<String> = []
    private var lastRecordsSignature: String = ""
    private var lastFarmIdSet: Set<String> = []
    private var lastFarmsSignature: String = ""
    private var lastFarmNamesSignature: String = ""
    private var lastGroupNamesSignature: String = ""
    
    // MARK: - Nested Types
    struct GroupInfo {
        let name: String
        let code: String
        let farmId: String
        let farmName: String
        let farmBreed: SheepBreed
        let farmProvince: SouthAfricanProvince
        
        var displayName: String {
            "\(code) - \(name)"
        }
    }
    
    // MARK: - Initialization
    init(
        recordStore: LambingRecordStore,
        groupStore: LambingSeasonGroupStore,
        farmStore: FarmStore,
        benchmarkStore: BenchmarkStore,
        userId: String
    ) {
        self.recordStore = recordStore
        self.groupStore = groupStore
        self.farmStore = farmStore
        self.benchmarkStore = benchmarkStore
        self.userId = userId
        
        print("🔧 [ALL-LAMBING-VM] Initialized for user: \(userId)")
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        print("🔵 [ALL-LAMBING-VM] loadData()")
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Step 1: Load farms
            let loadedFarms = try await farmStore.fetchAll(userId: userId)
            farms = loadedFarms
            let newSignature = loadedFarms.map { $0.id }.sorted().joined(separator: "|")
            let farmsChanged = newSignature != lastFarmsSignature
            lastFarmsSignature = newSignature
            
            let newNamesSignature = loadedFarms
                .sorted { $0.id < $1.id }
                .map { "\($0.id)=\($0.name)" }
                .joined(separator: "|")
            let farmNamesChanged = newNamesSignature != lastFarmNamesSignature
            if farmNamesChanged {
                lastFarmNamesSignature = newNamesSignature
            }
            
            if farmNamesChanged {
                updateFarmNameCache()
            } else {
                print("🔵 [ALL-LAMBING-VM] Farm names unchanged; skipping cache update")
            }
            
            print("✅ [ALL-LAMBING-VM] Loaded farms: \(farms.count)")
            
            // Step 2: Attach group listeners (one per farm) only if farms changed
            if farmsChanged {
                attachGroupListeners()
            } else {
                print("🔵 [ALL-LAMBING-VM] Farms unchanged; skipping re-attachment of group listeners")
            }
            
        } catch {
            print("❌ [ALL-LAMBING-VM] loadData failed: \(error)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func farmAndGroupName(for record: LambingRecord) -> (farm: String, group: String) {
        let groupInfo = groupInfoCache[record.lambingSeasonGroupId]
        return (
            farm: groupInfo?.farmName ?? "farm.unknown_farm".localized(),
            group: groupInfo?.displayName ?? "lambing.unknown_group".localized()
        )
    }
    
    func deleteRecord(_ record: LambingRecord) async {
        print("🔵 [ALL-LAMBING-VM] Deleting record: \(record.id)")
        do {
            try await recordStore.delete(
                userId: userId,
                farmId: record.farmId,
                groupId: record.lambingSeasonGroupId,
                recordId: record.id
            )
            records.removeAll { $0.id == record.id }
            print("✅ [ALL-LAMBING-VM] Deleted record: \(record.id)")
        } catch {
            print("❌ [ALL-LAMBING-VM] Failed to delete record: \(error)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func ranking(for record: LambingRecord) async -> String? {
        guard let groupInfo = groupInfoCache[record.lambingSeasonGroupId] else {
            return nil
        }
        
        let benchmarkId = "\(groupInfo.farmBreed.rawValue)_\(groupInfo.farmProvince.rawValue)_\(record.year)"
            .replacingOccurrences(of: " ", with: "")
        
        // Check cache first
        if let cached = benchmarkCache[benchmarkId] {
            let percentile = cached.lambingPercentileRank(for: record.lambingPercentage)
            return "Top \(percentile)%"
        }
        
        // Fetch benchmark
        do {
            if let benchmark = try await benchmarkStore.fetchById(id: benchmarkId) {
                benchmarkCache[benchmarkId] = benchmark
                let percentile = benchmark.lambingPercentileRank(for: record.lambingPercentage)
                return "Top \(percentile)%"
            }
        } catch {
            print("⚠️ [ALL-LAMBING-VM] Failed to fetch benchmark: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Private Methods - Listeners
    
    private func attachGroupListeners() {
        print("🔵 [ALL-LAMBING-VM] Attaching group listeners for \(farms.count) farms")
        
        let currentFarmIds = Set(farms.map { $0.id })
        let removedFarmIds = lastFarmIdSet.subtracting(currentFarmIds)
        let addedFarmIds = currentFarmIds.subtracting(lastFarmIdSet)

        // Cancel listeners for farms that are no longer present
        for farmId in removedFarmIds {
            if let listener = groupListeners[farmId] {
                listener.cancel()
                groupListeners.removeValue(forKey: farmId)
            }
            groupsByFarm.removeValue(forKey: farmId)
            print("🔵 [ALL-LAMBING-VM] Removing group listener for removed farm: \(farmId)")
        }

        // Attach listeners for newly added farms
        for farm in farms where addedFarmIds.contains(farm.id) {
            let cancellable = groupStore.listenAll(userId: userId, farmId: farm.id) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }

                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-LAMBING-VM] Group listener error for farm \(farm.name): \(error)")

                    case .success(let farmGroups):
                        print("📡 [ALL-LAMBING-VM] Groups update for farm \(farm.name): \(farmGroups.count) groups")
                        self.groupsByFarm[farm.id] = farmGroups

                        // Debounce group updates
                        self.groupsDebounceTask?.cancel()
                        self.groupsDebounceTask = Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
                            guard let self = self else { return }

                            let allGroups = self.groupsByFarm.values.flatMap { $0 }
                            let sorted = allGroups.sorted { $0.matingStart > $1.matingStart }

                            let newGroupIdSet = Set(sorted.map { $0.id })
                            guard newGroupIdSet != self.lastGroupIdSet else {
                                return
                            }
                            self.lastGroupIdSet = newGroupIdSet

                            let newGroupNamesSignature = sorted
                                .map { "\($0.id)=\($0.code)-\($0.name)-\($0.farmId)" }
                                .joined(separator: "|")
                            let groupNamesChanged = newGroupNamesSignature != self.lastGroupNamesSignature
                            if groupNamesChanged {
                                self.lastGroupNamesSignature = newGroupNamesSignature
                            }

                            self.groups = sorted
                            if groupNamesChanged {
                                self.updateGroupInfoCache()
                            } else {
                                print("🔵 [ALL-LAMBING-VM] Group names unchanged; skipping group info cache update")
                            }

                            print("📡 [ALL-LAMBING-VM] Coalesced groups update: \(sorted.count) total groups")

                            // Now attach record listeners for these groups
                            self.attachRecordListeners(for: sorted)
                        }
                    }
                }
            }

            groupListeners[farm.id] = cancellable
            print("🔵 [ALL-LAMBING-VM] Attaching group listener for new farm: \(farm.id)")
        }

        // Update last farm set after attaching/removing as needed
        lastFarmIdSet = currentFarmIds
    }
    
    private func attachRecordListeners(for groups: [LambingSeasonGroup]) {
        print("🔵 [ALL-LAMBING-VM] Attaching record listeners for \(groups.count) groups")
        
        // Cancel listeners for groups that no longer exist
        let currentGroupIds = Set(groups.map { $0.id })
        let existingGroupIds = Set(recordListeners.keys)
        let removedGroupIds = existingGroupIds.subtracting(currentGroupIds)
        
        for groupId in removedGroupIds {
            print("🔵 [ALL-LAMBING-VM] Removing listener for deleted group: \(groupId)")
            recordListeners[groupId]?.cancel()
            recordListeners.removeValue(forKey: groupId)
            recordsByGroup.removeValue(forKey: groupId)
        }
        
        // Attach listeners for new groups
        for group in groups {
            guard recordListeners[group.id] == nil else {
                continue // Already listening
            }
            
            let cancellable = recordStore.listenAll(
                userId: userId,
                farmId: group.farmId,
                groupId: group.id
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }
                    
                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-LAMBING-VM] Record listener error for group \(group.displayName): \(error)")
                        
                    case .success(let groupRecords):
                        print("📡 [ALL-LAMBING-VM] Records update for group \(group.displayName): \(groupRecords.count) records")
                        self.recordsByGroup[group.id] = groupRecords
                        
                        // Debounce record updates
                        self.recordsDebounceTask?.cancel()
                        self.recordsDebounceTask = Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
                            guard let self = self else { return }
                            
                            let allRecords = self.recordsByGroup.values.flatMap { $0 }
                            let sorted = allRecords.sorted { $0.createdAt > $1.createdAt }
                            
                            let signature = sorted.map { "\($0.id):\($0.createdAt.timeIntervalSince1970)" }.joined(separator: "|")
                            guard signature != self.lastRecordsSignature else {
                                return
                            }
                            self.lastRecordsSignature = signature
                            
                            self.records = sorted
                            
                            print("📡 [ALL-LAMBING-VM] Coalesced records update: \(sorted.count) total records")
                        }
                    }
                }
            }
            
            recordListeners[group.id] = cancellable
        }
    }
    
    // MARK: - Private Methods - Caching
    
    private func updateFarmNameCache() {
        farmNameCache = Dictionary(uniqueKeysWithValues: farms.map { ($0.id, $0.name) })
        print("🔵 [ALL-LAMBING-VM] Farm name cache entries: \(farmNameCache.count)")
    }
    
    private func updateGroupInfoCache() {
        groupInfoCache = Dictionary(uniqueKeysWithValues: groups.map { group in
            let farm = farms.first { $0.id == group.farmId }
            let farmName = farm?.name ?? "Unknown Farm"
            let farmBreed = farm?.breed ?? .dohneMerino
            let farmProvince = farm?.province ?? .westernCape
            
            let info = GroupInfo(
                name: group.name,
                code: group.code,
                farmId: group.farmId,
                farmName: farmName,
                farmBreed: farmBreed,
                farmProvince: farmProvince
            )
            return (group.id, info)
        })
        print("🔵 [ALL-LAMBING-VM] Group info cache entries: \(groupInfoCache.count)")
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🔵 [ALL-LAMBING-VM] Deallocating, canceling all listeners")
        groupListeners.values.forEach { $0.cancel() }
        recordListeners.values.forEach { $0.cancel() }
        groupsDebounceTask?.cancel()
        recordsDebounceTask?.cancel()
    }
}

