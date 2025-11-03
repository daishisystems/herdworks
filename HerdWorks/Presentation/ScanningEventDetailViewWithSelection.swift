//
//  ScanningEventDetailViewWithSelection.swift
//  HerdWorks
//
//  Created: Phase 5 - Wrapper view for adding scanning events with farm/group selection
//

import SwiftUI
import FirebaseAuth

struct ScanningEventDetailViewWithSelection: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedFarm: Farm?
    @State private var selectedGroup: LambingSeasonGroup?
    @State private var showingEventDetail = false
    
    let scanningStore: ScanningEventStore
    let groupStore: LambingSeasonGroupStore
    let farms: [Farm]
    let groups: [LambingSeasonGroup]
    
    private var availableGroups: [LambingSeasonGroup] {
        guard let farmId = selectedFarm?.id else { return [] }
        return groups.filter { $0.farmId == farmId }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("farm.select_farm".localized(), selection: $selectedFarm) {
                        Text("farm.select_farm_placeholder".localized())
                            .tag(nil as Farm?)
                        
                        ForEach(farms) { farm in
                            Text(farm.name)
                                .tag(farm as Farm?)
                        }
                    }
                    
                    if selectedFarm != nil {
                        Picker("lambing.select_group".localized(), selection: $selectedGroup) {
                            Text("lambing.select_group_placeholder".localized())
                                .tag(nil as LambingSeasonGroup?)
                            
                            ForEach(availableGroups) { group in
                                Text(group.displayName)
                                    .tag(group as LambingSeasonGroup?)
                            }
                        }
                    }
                } header: {
                    Text("breeding.select_farm_and_group".localized())
                } footer: {
                    Text("breeding.select_farm_and_group_footer".localized())
                }
                
                if selectedFarm != nil && selectedGroup != nil {
                    Section {
                        Button {
                            showingEventDetail = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("common.continue".localized())
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("scanning.add_event".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEventDetail) {
                if let farm = selectedFarm, let group = selectedGroup {
                    NavigationStack {
                        ScanningEventDetailView(
                            store: scanningStore,
                            userId: Auth.auth().currentUser?.uid ?? "",
                            farmId: farm.id,
                            groupId: group.id
                        )
                    }
                }
            }
            .onChange(of: selectedFarm) { _, _ in
                // Reset group selection when farm changes
                selectedGroup = nil
            }
        }
    }
}

#Preview {
    ScanningEventDetailViewWithSelection(
        scanningStore: FirestoreScanningEventStore(),
        groupStore: FirestoreLambingSeasonGroupStore(),
        farms: [],
        groups: []
    )
    .environmentObject(LanguageManager.shared)
}
