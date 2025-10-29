//
//  AllBreedingEventsViewModel.swift
//  HerdWorks
//
//  Created by Claude on 2025/10/24.
//

import Foundation
import Combine

@MainActor
final class AllBreedingEventsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [BreedingEvent] = []
    @Published var farms: [Farm] = []
    @Published var groups: [LambingSeasonGroup] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showNoGroupsAlert = false
    
    // MARK: - Private Properties
    private let eventStore: BreedingEventStore
    private let groupStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    private let userId: String
    
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
    private var eventsByGroup: [String: [BreedingEvent]] = [:]
    
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
        eventStore: BreedingEventStore,
        groupStore: LambingSeasonGroupStore,
        farmStore: FarmStore,
        userId: String
    ) {
        self.eventStore = eventStore
        self.groupStore = groupStore
        self.farmStore = farmStore
        self.userId = userId
        
        print("🔧 [ALL-BREEDING-VM] Initialized for user: \(userId)")
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        print("🔵 [ALL-BREEDING-VM] loadData()")
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
                print("🔵 [ALL-BREEDING-VM] Farm names unchanged; skipping cache update")
            }
            
            print("✅ [ALL-BREEDING-VM] Loaded farms: \(farms.count)")
            
            // Step 2: Attach group listeners (one per farm) only if farms changed
            if farmsChanged {
                attachGroupListeners()
            } else {
                print("🔵 [ALL-BREEDING-VM] Farms unchanged; skipping re-attachment of group listeners")
            }
            
        } catch {
            print("❌ [ALL-BREEDING-VM] loadData failed: \(error)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func farmAndGroupName(for event: BreedingEvent) -> (farm: String, group: String) {
        let groupInfo = groupInfoCache[event.lambingSeasonGroupId]
        return (
            farm: groupInfo?.farmName ?? "farm.unknown_farm".localized(),
            group: groupInfo?.displayName ?? "lambing.unknown_group".localized()
        )
    }
    
    func deleteEvent(_ event: BreedingEvent) async {
        print("🔵 [ALL-BREEDING-VM] Deleting event: \(event.id)")
        do {
            try await eventStore.delete(
                userId: userId,
                farmId: event.farmId,
                groupId: event.lambingSeasonGroupId,
                eventId: event.id
            )
            events.removeAll { $0.id == event.id }
            print("✅ [ALL-BREEDING-VM] Deleted event: \(event.id)")
        } catch {
            print("❌ [ALL-BREEDING-VM] Failed to delete event: \(error)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    // MARK: - Private Methods - Listeners
    
    private func attachGroupListeners() {
        print("🔵 [ALL-BREEDING-VM] Attaching group listeners for \(farms.count) farms")
        
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
            print("🔵 [ALL-BREEDING-VM] Removing group listener for removed farm: \(farmId)")
        }

        // Attach listeners for newly added farms
        for farm in farms where addedFarmIds.contains(farm.id) {
            let cancellable = groupStore.listenAll(userId: userId, farmId: farm.id) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }

                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-BREEDING-VM] Group listener error for farm \(farm.name): \(error)")

                    case .success(let farmGroups):
                        print("📡 [ALL-BREEDING-VM] Groups update for farm \(farm.name): \(farmGroups.count) groups")
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
                                print("🔵 [ALL-BREEDING-VM] Group names unchanged; skipping group info cache update")
                            }

                            print("📡 [ALL-BREEDING-VM] Coalesced groups update: \(sorted.count) total groups")

                            // Now attach event listeners for these groups
                            self.attachEventListeners(for: sorted)
                        }
                    }
                }
            }

            groupListeners[farm.id] = cancellable
            print("🔵 [ALL-BREEDING-VM] Attaching group listener for new farm: \(farm.id)")
        }

        // Update last farm set after attaching/removing as needed
        lastFarmIdSet = currentFarmIds
    }
    
    private func attachEventListeners(for groups: [LambingSeasonGroup]) {
        print("🔵 [ALL-BREEDING-VM] Attaching event listeners for \(groups.count) groups")
        
        // Cancel listeners for groups that no longer exist
        let currentGroupIds = Set(groups.map { $0.id })
        let existingGroupIds = Set(eventListeners.keys)
        let removedGroupIds = existingGroupIds.subtracting(currentGroupIds)
        
        for groupId in removedGroupIds {
            print("🔵 [ALL-BREEDING-VM] Removing listener for deleted group: \(groupId)")
            eventListeners[groupId]?.cancel()
            eventListeners.removeValue(forKey: groupId)
            eventsByGroup.removeValue(forKey: groupId)
        }
        
        // Attach listeners for new groups
        for group in groups {
            guard eventListeners[group.id] == nil else {
                continue // Already listening
            }
            
            let cancellable = eventStore.listenAll(
                userId: userId,
                farmId: group.farmId,
                groupId: group.id
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self else { return }
                    
                    switch result {
                    case .failure(let error):
                        print("⚠️ [ALL-BREEDING-VM] Event listener error for group \(group.displayName): \(error)")
                        
                    case .success(let groupEvents):
                        print("📡 [ALL-BREEDING-VM] Events update for group \(group.displayName): \(groupEvents.count) events")
                        self.eventsByGroup[group.id] = groupEvents
                        
                        // Debounce event updates
                        self.eventsDebounceTask?.cancel()
                        self.eventsDebounceTask = Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
                            guard let self = self else { return }
                            
                            let allEvents = self.eventsByGroup.values.flatMap { $0 }
                            let sorted = allEvents.sorted { event1, event2 in
                                guard let date1 = event1.displayDate,
                                      let date2 = event2.displayDate else {
                                    return false
                                }
                                return date1 > date2
                            }
                            
                            let signature = sorted.map { "\($0.id):\($0.displayDate?.timeIntervalSince1970 ?? 0)" }.joined(separator: "|")
                            guard signature != self.lastEventsSignature else {
                                // No effective change in events ordering/content; skip log and assignment
                                return
                            }
                            self.lastEventsSignature = signature
                            
                            self.events = sorted
                            
                            print("📡 [ALL-BREEDING-VM] Coalesced events update: \(sorted.count) total events")
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
        print("🔵 [ALL-BREEDING-VM] Farm name cache entries: \(farmNameCache.count)")
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
        print("🔵 [ALL-BREEDING-VM] Group info cache entries: \(groupInfoCache.count)")
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🔵 [ALL-BREEDING-VM] Deallocating, canceling all listeners")
        groupListeners.values.forEach { $0.cancel() }
        eventListeners.values.forEach { $0.cancel() }
        groupsDebounceTask?.cancel()
        eventsDebounceTask?.cancel()
    }
}

