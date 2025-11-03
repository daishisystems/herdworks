//
//  AllScanningEventsViewModel.swift
//  HerdWorks
//
//  Created on October 31, 2025.
//

import Foundation
import Combine

@MainActor
final class AllScanningEventsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var groupedEvents: [(group: LambingSeasonGroup, farm: Farm, events: [ScanningEvent])] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let scanningStore: ScanningEventStore
    private let farmStore: FarmStore
    private let groupStore: LambingSeasonGroupStore
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        scanningStore: ScanningEventStore,
        farmStore: FarmStore,
        groupStore: LambingSeasonGroupStore,
        userId: String
    ) {
        self.scanningStore = scanningStore
        self.farmStore = farmStore
        self.groupStore = groupStore
        self.userId = userId
        
        print("🔵 [ALL-SCANNING-VM] Initialized")
    }
    
    // MARK: - Public Methods
    
    /// Load all scanning events across all farms and groups
    func loadAllEvents() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔵 [ALL-SCANNING-VM] Loading all scanning events across all farms")
            
            // 1. Load all farms
            let farms = try await farmStore.fetchAll(userId: userId)
            print("🔵 [ALL-SCANNING-VM] Loaded \(farms.count) farms")
            
            var allGroupedEvents: [(group: LambingSeasonGroup, farm: Farm, events: [ScanningEvent])] = []
            
            // 2. For each farm, load lambing groups and their scanning events
            for farm in farms {
                let groups = try await groupStore.fetchAll(userId: userId, farmId: farm.id)
                print("🔵 [ALL-SCANNING-VM] Farm '\(farm.name)' has \(groups.count) lambing groups")
                
                for group in groups {
                    let events = try await scanningStore.fetchAll(
                        userId: userId,
                        farmId: farm.id,
                        groupId: group.id
                    )
                    
                    if !events.isEmpty {
                        allGroupedEvents.append((group: group, farm: farm, events: events))
                        print("🔵 [ALL-SCANNING-VM] Group '\(group.displayName)' has \(events.count) scanning events")
                    }
                }
            }
            
            // Sort by most recent events first
            allGroupedEvents.sort { tuple1, tuple2 in
                let date1 = tuple1.events.first?.createdAt ?? Date.distantPast
                let date2 = tuple2.events.first?.createdAt ?? Date.distantPast
                return date1 > date2
            }
            
            groupedEvents = allGroupedEvents
            
            let totalEvents = allGroupedEvents.reduce(0) { $0 + $1.events.count }
            print("✅ [ALL-SCANNING-VM] Loaded \(totalEvents) total scanning events from \(allGroupedEvents.count) groups")
            
        } catch {
            print("❌ [ALL-SCANNING-VM] Error loading all scanning events: \(error.localizedDescription)")
            errorMessage = "error.failed_to_load".localized() + ": \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Get farm name for a scanning event
    func getFarmName(for event: ScanningEvent) -> String {
        // Find in our grouped data
        for groupData in groupedEvents {
            if groupData.farm.id == event.farmId {
                return groupData.farm.name
            }
        }
        return "scanning.unknown_farm".localized()
    }
    
    /// Get lambing group display name for a scanning event
    func getGroupName(for event: ScanningEvent) -> String {
        // Find in our grouped data
        for groupData in groupedEvents {
            if groupData.group.id == event.lambingSeasonGroupId {
                return groupData.group.displayName
            }
        }
        return "scanning.unknown_group".localized()
    }
}
