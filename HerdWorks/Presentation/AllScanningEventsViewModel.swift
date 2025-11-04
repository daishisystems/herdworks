//
//  AllScanningEventsViewModel.swift
//  HerdWorks
//
//  Created: Phase 5 - All Scanning Events ViewModel with Real-Time Listeners
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AllScanningEventsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [ScanningEvent] = []
    @Published var farms: [Farm] = []
    @Published var groups: [LambingSeasonGroup] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showNoGroupsAlert = false
    
    // MARK: - Private Properties
    private let scanningStore: ScanningEventStore
    private let groupStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    let userId: String
    
    // Caching
    private var farmNameCache: [String: String] = [:]
    private var groupInfoCache: [String: GroupInfo] = [:]
    
    // Listeners
    private var groupListeners: [String: AnyCancellable] = [:]
    private var eventListeners: [String: AnyCancellable] = [:]
    
    // Debouncing
    private var groupsDebounceTask: Task<Void, Never>?
    private var eventsDebounceTask: Task<Void, Never>?
    
    // Intermediate state
    private var groupsByFarm: [String: [LambingSeasonGroup]] = [:]
    private var eventsByGroup: [String: [ScanningEvent]] = [:]
    
    // Change tracking to suppress redundant work/logs
    private var lastGroupIdSet: Set<String> = []
    private var lastEventsSignature: String = ""
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
        
        var displayName: String {
            "\(code) - \(name)"
        }
    }
    
    // MARK: - Initialization
    init(
        scanningStore: ScanningEventStore,
        groupStore: LambingSeasonGroupStore,
        farmStore: FarmStore,
        userId: String
    ) {
        self.scanningStore = scanningStore
        self.groupStore = groupStore
        self.farmStore = farmStore
        self.userId = userId
        
        print("🔧 [ALL-SCANNING-VM] Initialized for user: \(userId)")
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        print("🔵 [ALL-SCANNING-VM] loadData()")
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
                print("🔵 [ALL-SCANNING-VM] Farm names unchanged; skipping cache update")
            }
            
            print("✅ [ALL-SCANNING-VM] Loaded farms: \(farms.count)")
            
            // Step 2: Attach group listeners (one per farm) only if farms changed
            if farmsChanged {
                attachGroupListeners()
            } else {
                print("🔵 [ALL-SCANNING-VM] Farms unchanged; skipping re-attachment of group listeners")
            }
            
        } catch {
            print("❌ [ALL-SCANNING-VM] loadData failed: \(error)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func farmAndGroupName(for event: ScanningEvent) -> (farm: String, group: String) {
        let groupInfo = groupInfoCache[event.lambingSeasonGroupId]
        return (
            farm: groupInfo?.farmName ?? "scanning.unknown_farm".localized(),
            group: groupInfo?.displayName ?? "scanning.unknown_group".localized()
        )
    }
    
    func deleteEvent(_ event: ScanningEvent) async {
        print("🔵 [ALL-SCANNING-VM] Deleting event: \(event.id)")
        do {
            try await scanningStore.delete(
                userId: userId,
                farmId: event.farmId,
                groupId: event.lambingSeasonGroupId,
                eventId: event.id
            )
            events.removeAll { $0.id == event.id }
            print("✅ [ALL-SCANNING-VM] Deleted event: \(event.id)")
        } catch {
            print("❌ [ALL-SCANNING-VM] Failed to delete event: \(error)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    // MARK: - Private Methods - Listeners
    
    private func attachGroupListeners() {
        print("🔵 [ALL-SCANNING-VM] Attaching group listeners for \(farms.count) farms")
        
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
            print("🔵 [ALL-SCANNING-VM] Removing group listener for removed farm: \(farmId)")
        }

        // Attach listeners for newly added farms
        for farm in farms where addedFarmIds.contains(farm.id) {
            let cancellable = groupStore.listenAll(userId: userId, farmId: farm.id) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }

                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-SCANNING-VM] Group listener error for farm \(farm.name): \(error)")

                    case .success(let farmGroups):
                        print("📡 [ALL-SCANNING-VM] Groups update for farm \(farm.name): \(farmGroups.count) groups")
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
                                // No change in group IDs; avoid redundant logs and re-attaching listeners
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
                                print("🔵 [ALL-SCANNING-VM] Group names unchanged; skipping group info cache update")
                            }

                            print("📡 [ALL-SCANNING-VM] Coalesced groups update: \(sorted.count) total groups")

                            // Now attach event listeners for these groups
                            self.attachEventListeners(for: sorted)
                        }
                    }
                }
            }

            groupListeners[farm.id] = cancellable
            print("🔵 [ALL-SCANNING-VM] Attaching group listener for new farm: \(farm.id)")
        }

        // Update last farm set after attaching/removing as needed
        lastFarmIdSet = currentFarmIds
    }
    
    private func attachEventListeners(for groups: [LambingSeasonGroup]) {
        print("🔵 [ALL-SCANNING-VM] Attaching event listeners for \(groups.count) groups")
        
        // Cancel listeners for groups that no longer exist
        let currentGroupIds = Set(groups.map { $0.id })
        let existingGroupIds = Set(eventListeners.keys)
        let removedGroupIds = existingGroupIds.subtracting(currentGroupIds)
        
        for groupId in removedGroupIds {
            print("🔵 [ALL-SCANNING-VM] Removing listener for deleted group: \(groupId)")
            eventListeners[groupId]?.cancel()
            eventListeners.removeValue(forKey: groupId)
            eventsByGroup.removeValue(forKey: groupId)
        }
        
        // Attach listeners for new groups
        for group in groups {
            guard eventListeners[group.id] == nil else {
                continue // Already listening
            }
            
            let cancellable = scanningStore.listenAll(
                userId: userId,
                farmId: group.farmId,
                groupId: group.id
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }
                    
                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-SCANNING-VM] Event listener error for group \(group.displayName): \(error)")
                        
                    case .success(let groupEvents):
                        print("📡 [ALL-SCANNING-VM] Events update for group \(group.displayName): \(groupEvents.count) events")
                        self.eventsByGroup[group.id] = groupEvents
                        
                        // Debounce event updates
                        self.eventsDebounceTask?.cancel()
                        self.eventsDebounceTask = Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
                            guard let self = self else { return }
                            
                            let allEvents = self.eventsByGroup.values.flatMap { $0 }
                            let sorted = allEvents.sorted { $0.createdAt > $1.createdAt }
                            
                            let signature = sorted.map { "\($0.id):\($0.createdAt.timeIntervalSince1970)" }.joined(separator: "|")
                            guard signature != self.lastEventsSignature else {
                                // No effective change in events ordering/content; skip log and assignment
                                return
                            }
                            self.lastEventsSignature = signature
                            
                            self.events = sorted
                            
                            print("📡 [ALL-SCANNING-VM] Coalesced events update: \(sorted.count) total events")
                        }
                    }
                }
            }
            
            eventListeners[group.id] = cancellable
        }
    }
    
    // MARK: - Private Methods - Caching
    
    private func updateFarmNameCache() {
        farmNameCache = Dictionary(uniqueKeysWithValues: farms.map { ($0.id, $0.name) })
        print("🔵 [ALL-SCANNING-VM] Farm name cache entries: \(farmNameCache.count)")
    }
    
    private func updateGroupInfoCache() {
        groupInfoCache = Dictionary(uniqueKeysWithValues: groups.map { group in
            let farmName = farmNameCache[group.farmId] ?? "Unknown Farm"
            let info = GroupInfo(
                name: group.name,
                code: group.code,
                farmId: group.farmId,
                farmName: farmName
            )
            return (group.id, info)
        })
        print("🔵 [ALL-SCANNING-VM] Group info cache entries: \(groupInfoCache.count)")
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🔵 [ALL-SCANNING-VM] Deallocating, canceling all listeners")
        groupListeners.values.forEach { $0.cancel() }
        eventListeners.values.forEach { $0.cancel() }
        groupsDebounceTask?.cancel()
        eventsDebounceTask?.cancel()
    }
}
