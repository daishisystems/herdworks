//
//  AllScanningEventsViewModel.swift
//  HerdWorks
//
//  Created: Phase 5 - All Scanning Events ViewModel
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AllScanningEventsViewModel: ObservableObject {
    @Published var events: [ScanningEvent] = []
    @Published var farms: [Farm] = []
    @Published var groups: [LambingSeasonGroup] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showNoGroupsAlert: Bool = false
    
    private let scanningStore: ScanningEventStore
    private let groupStore: LambingSeasonGroupStore
    private let farmStore: FarmStore
    let userId: String
    
    private var farmNameCache: [String: String] = [:]
    private var groupNameCache: [String: String] = [:]
    
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
    
    func loadData() async {
        print("🔵 [ALL-SCANNING-VM] loadData()")
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load farms first
            farms = try await farmStore.fetchAll(userId: userId)
            print("✅ [ALL-SCANNING-VM] Loaded \(farms.count) farms")
            
            // Build farm name cache
            for farm in farms {
                farmNameCache[farm.id] = farm.name
            }
            
            // Load all groups across all farms
            var allGroups: [LambingSeasonGroup] = []
            for farm in farms {
                let farmGroups = try await groupStore.fetchAll(userId: userId, farmId: farm.id)
                allGroups.append(contentsOf: farmGroups)
            }
            groups = allGroups
            print("✅ [ALL-SCANNING-VM] Loaded \(groups.count) lambing groups")
            
            // Build group name cache
            for group in groups {
                groupNameCache[group.id] = group.displayName
            }
            
            // Load all scanning events across all farms and groups
            var allEvents: [ScanningEvent] = []
            for farm in farms {
                let farmGroups = groups.filter { $0.farmId == farm.id }
                for group in farmGroups {
                    let farmEvents = try await scanningStore.fetchAll(
                        userId: userId,
                        farmId: farm.id,
                        groupId: group.id
                    )
                    allEvents.append(contentsOf: farmEvents)
                }
            }
            
            // Sort by scan date (newest first)
            events = allEvents.sorted(by: { (event1: ScanningEvent, event2: ScanningEvent) -> Bool in
                return event1.createdAt > event2.createdAt
            })
            print("✅ [ALL-SCANNING-VM] Loaded \(events.count) total scanning events")
            
        } catch {
            print("❌ [ALL-SCANNING-VM] Error loading data: \(error)")
            errorMessage = String(format: "error.failed_to_load".localized(), error.localizedDescription)
            showError = true
        }
    }
    
    func farmAndGroupName(for event: ScanningEvent) -> (farm: String, group: String) {
        let farm = farmNameCache[event.farmId] ?? "scanning.unknown_farm".localized()
        let group = groupNameCache[event.lambingSeasonGroupId] ?? "scanning.unknown_group".localized()
        return (farm, group)
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
            
            // Remove from local array
            events.removeAll { $0.id == event.id }
            print("✅ [ALL-SCANNING-VM] Successfully deleted event")
            
        } catch {
            print("❌ [ALL-SCANNING-VM] Error deleting event: \(error)")
            errorMessage = String(format: "error.failed_to_delete".localized(), error.localizedDescription)
            showError = true
        }
    }
}
