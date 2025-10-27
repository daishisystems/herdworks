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
            updateFarmNameCache()
            print("✅ [ALL-BREEDING-VM] Loaded farms: \(farms.count)")
            
            // Step 2: Attach group listeners (one per farm)
            attachGroupListeners()
            
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
        
        // Cancel existing listeners
        groupListeners.values.forEach { $0.cancel() }
        groupListeners.removeAll()
        groupsByFarm.removeAll()
        
        for farm in farms {
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
                            self.groups = sorted
                            self.updateGroupInfoCache()
                            
                            print("📡 [ALL-BREEDING-VM] Coalesced groups update: \(sorted.count) total groups")
                            
                            // Now attach event listeners for these groups
                            self.attachEventListeners(for: sorted)
                        }
                    }
                }
            }
            
            groupListeners[farm.id] = cancellable
        }
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
