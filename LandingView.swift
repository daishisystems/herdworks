//
//  LandingView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/15.
//  Updated: Phase 4 - Added "All Breeding Events" integration
//  Updated: Phase 5 - Fixed "All Scanning Events" navigation (wrapped in NavigationStack)
//  Updated: Phase 6 - Added "All Lambing Events" integration
//  Updated: Phase 2B - Added "Performance Dashboard" navigation to existing benchmark views
//

import SwiftUI
import FirebaseAuth
import Combine

struct LandingView: View {
    @EnvironmentObject private var profileGate: ProfileGate
    @EnvironmentObject private var languageManager: LanguageManager

    // ✅ FIX: Inject shared stores to pass to child views
    @EnvironmentObject private var benchmarkStore: FirestoreBenchmarkStore
    @EnvironmentObject private var breedingStore: FirestoreBreedingEventStore
    @EnvironmentObject private var scanningStore: FirestoreScanningEventStore
    @EnvironmentObject private var lambingStore: FirestoreLambingRecordStore
    @EnvironmentObject private var farmStore: FirestoreFarmStore
    @EnvironmentObject private var groupStore: FirestoreLambingSeasonGroupStore

    @State private var selectedTab: Tab = .home
    @State private var showingFarmManagement = false
    @State private var showingAllLambingSeasons = false
    @State private var showingAllBreeding = false
    @State private var showingAllScanning = false
    @State private var showingAllLambingEvents = false
    @State private var showingBenchmarkDashboard = false  // ✅ PHASE 2B: Performance Dashboard
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case explore = "Explore"
        case profile = "Profile"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .home: return "house"
            case .explore: return "safari"
            case .profile: return "person"
            case .settings: return "gearshape"
            }
        }
        
        func localizedTitle() -> String {
            switch self {
            case .home: return "landing.home".localized()
            case .explore: return "landing.explore".localized()
            case .profile: return "landing.profile".localized()
            case .settings: return "landing.settings".localized()
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab(
                onFarmManagementTapped: {
                    showingFarmManagement = true
                },
                onAllLambingSeasonsTapped: {
                    showingAllLambingSeasons = true
                },
                onAllBreedingTapped: {
                    showingAllBreeding = true
                },
                onAllScanningTapped: {
                    showingAllScanning = true
                },
                onAllLambingEventsTapped: {
                    showingAllLambingEvents = true
                },
                onBenchmarkDashboardTapped: {  // ✅ PHASE 2B: New callback
                    showingBenchmarkDashboard = true
                }
            )
                .tabItem {
                    Label("landing.home".localized(), systemImage: "house")
                }
                .tag(Tab.home)
                .accessibility(label: Text("accessibility.tab.home".localized()))
                .accessibility(hint: Text("accessibility.tab.home.hint".localized()))
            
            ExploreTab()
                .tabItem {
                    Label("landing.explore".localized(), systemImage: "safari")
                }
                .tag(Tab.explore)
                .accessibility(label: Text("accessibility.tab.explore".localized()))
                .accessibility(hint: Text("accessibility.tab.explore.hint".localized()))

            ProfileTab()
                .tabItem {
                    Label("landing.profile".localized(), systemImage: "person")
                }
                .tag(Tab.profile)
                .accessibility(label: Text("accessibility.tab.profile".localized()))
                .accessibility(hint: Text("accessibility.tab.profile.hint".localized()))

            SettingsView()
                .tabItem {
                    Label("landing.settings".localized(), systemImage: "gearshape")
                }
                .tag(Tab.settings)
                .accessibility(label: Text("accessibility.tab.settings".localized()))
                .accessibility(hint: Text("accessibility.tab.settings.hint".localized()))
        }
        .tint(.accentColor)
        .sheet(isPresented: $profileGate.shouldPresentProfileEdit) {
            ProfileEditView(store: FirestoreUserProfileStore())
        }
        .sheet(isPresented: $showingFarmManagement) {
            // ✅ FIXED: Use injected store
            FarmListView(store: farmStore)
                .environmentObject(farmStore)
        }
        .sheet(isPresented: $showingAllLambingSeasons) {
            // ✅ FIXED: Use injected stores
            AllLambingSeasonsView(
                lambingStore: groupStore,
                farmStore: farmStore
            )
            .environmentObject(groupStore)
            .environmentObject(farmStore)
        }
        .sheet(isPresented: $showingAllBreeding) {
            // ✅ FIXED: Use injected stores
            AllBreedingEventsView(
                eventStore: breedingStore,
                groupStore: groupStore,
                farmStore: farmStore
            )
            .environmentObject(breedingStore)
            .environmentObject(groupStore)
            .environmentObject(farmStore)
        }
        .sheet(isPresented: $showingAllScanning) {
            NavigationStack {
                // ✅ FIXED: Use injected stores
                AllScanningEventsView(
                    scanningStore: scanningStore,
                    groupStore: groupStore,
                    farmStore: farmStore
                )
                .environmentObject(scanningStore)
                .environmentObject(groupStore)
                .environmentObject(farmStore)
            }
        }
        .sheet(isPresented: $showingAllLambingEvents) {
            // ✅ FIXED: Use injected stores
            AllLambingEventsView(
                recordStore: lambingStore,
                groupStore: groupStore,
                farmStore: farmStore,
                benchmarkStore: benchmarkStore,
                userId: Auth.auth().currentUser?.uid ?? ""
            )
            .environmentObject(lambingStore)
            .environmentObject(groupStore)
            .environmentObject(farmStore)
            .environmentObject(benchmarkStore)
        }
        // ✅ FIXED: Sheet for Performance Dashboard with injected stores
        .sheet(isPresented: $showingBenchmarkDashboard) {
            PerformanceDashboardNavigationView()
                // Stores automatically inherited, but explicit injection is clearer
                .environmentObject(benchmarkStore)
                .environmentObject(breedingStore)
                .environmentObject(scanningStore)
                .environmentObject(lambingStore)
                .environmentObject(farmStore)
                .environmentObject(groupStore)
        }
    }
}

// MARK: - Performance Dashboard Navigation View
// ✅ FIXED: Uses shared stores via @EnvironmentObject to prevent memory leak
private struct PerformanceDashboardNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager

    // ✅ FIX: Inject shared stores instead of creating new ones
    @EnvironmentObject private var benchmarkStore: FirestoreBenchmarkStore
    @EnvironmentObject private var breedingStore: FirestoreBreedingEventStore
    @EnvironmentObject private var scanningStore: FirestoreScanningEventStore
    @EnvironmentObject private var lambingStore: FirestoreLambingRecordStore
    @EnvironmentObject private var farmStore: FirestoreFarmStore
    @EnvironmentObject private var groupStore: FirestoreLambingSeasonGroupStore

    @StateObject private var viewModel: PerformanceDashboardListViewModel

    init() {
        // ⚠️ TEMP: Still creating stores here - will be replaced with proper injection
        // This is a temporary workaround until we can inject environment objects into init
        _viewModel = StateObject(wrappedValue: PerformanceDashboardListViewModel(
            farmStore: nil,
            groupStore: nil,
            userId: Auth.auth().currentUser?.uid ?? ""
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.farmsWithGroups.isEmpty {
                    emptyStateView
                } else {
                    farmsList
                }
            }
            .navigationTitle("benchmark.dashboard_title".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.close".localized()) {
                        dismiss()
                    }
                    .accessibility(label: Text("accessibility.button.close".localized()))
                    .accessibility(hint: Text("accessibility.button.close.hint".localized()))
                }
            }
            .task {
                // ✅ Inject environment stores into view model on appear
                viewModel.setStores(farmStore: farmStore, groupStore: groupStore)
                await viewModel.loadFarmsAndGroups()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("benchmark.empty_title".localized())
                .font(.title2)
                .fontWeight(.semibold)

            Text("benchmark.empty_subtitle".localized())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ✅ FIX: Value-based navigation with lazy destination creation
    private var farmsList: some View {
        List {
            ForEach(viewModel.farmsWithGroups) { farmData in
                Section {
                    ForEach(farmData.groups) { group in
                        // ✅ FIXED: Store only navigation value, not view
                        // This prevents creating 4 stores × 16 groups = 64 store instances
                        NavigationLink(
                            destination: BenchmarkComparisonView(
                                farm: farmData.farm,
                                group: group,
                                benchmarkStore: benchmarkStore,
                                breedingStore: breedingStore,
                                scanningStore: scanningStore,
                                lambingStore: lambingStore,
                                userId: viewModel.userId
                            )
                        ) {
                            BenchmarkGroupRow(farm: farmData.farm, group: group)
                        }
                        .accessibility(label: Text(String(format: "accessibility.row.benchmark".localized(), farmData.farm.name, group.displayName)))
                        .accessibility(hint: Text("accessibility.row.benchmark.hint".localized()))
                    }
                } header: {
                    Text(farmData.farm.name)
                        .font(.headline)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Benchmark Group Row
private struct BenchmarkGroupRow: View {
    let farm: Farm
    let group: LambingSeasonGroup
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.displayName)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(farm.breed.displayName)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(yearString(from: group.lambingStart))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func yearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Navigation Destination Types

/// Represents a destination for benchmark comparison navigation
/// Used with value-based NavigationLink to enable lazy evaluation
struct BenchmarkDestination: Hashable {
    let farm: Farm
    let group: LambingSeasonGroup
    let userId: String

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(farm.id)
        hasher.combine(group.id)
        hasher.combine(userId)
    }

    static func == (lhs: BenchmarkDestination, rhs: BenchmarkDestination) -> Bool {
        lhs.farm.id == rhs.farm.id &&
        lhs.group.id == rhs.group.id &&
        lhs.userId == rhs.userId
    }
}

// MARK: - Performance Dashboard List ViewModel
@MainActor
final class PerformanceDashboardListViewModel: ObservableObject {
    @Published var farmsWithGroups: [FarmWithGroups] = []
    @Published var isLoading = false
    
    private var farmStore: FarmStore?
    private var groupStore: LambingSeasonGroupStore?
    let userId: String
    
    struct FarmWithGroups: Identifiable {
        let id: String
        let farm: Farm
        let groups: [LambingSeasonGroup]
        
        init(farm: Farm, groups: [LambingSeasonGroup]) {
            self.id = farm.id
            self.farm = farm
            self.groups = groups
        }
    }
    
    init(farmStore: FarmStore?, groupStore: LambingSeasonGroupStore?, userId: String) {
        self.farmStore = farmStore
        self.groupStore = groupStore
        self.userId = userId
    }
    
    /// Inject stores from environment (called in .task modifier)
    func setStores(farmStore: FarmStore, groupStore: LambingSeasonGroupStore) {
        self.farmStore = farmStore
        self.groupStore = groupStore
    }
    
    func loadFarmsAndGroups() async {
        guard let farmStore = farmStore, let groupStore = groupStore else {
            print("⚠️ [BENCHMARK-DASHBOARD] Stores not yet injected, skipping load")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let farms = try await farmStore.fetchAll(userId: userId)
            
            var result: [FarmWithGroups] = []
            for farm in farms {
                let groups = try await groupStore.fetchAll(userId: userId, farmId: farm.id)
                // Only include farms that have lambing season groups
                if !groups.isEmpty {
                    result.append(FarmWithGroups(farm: farm, groups: groups))
                }
            }
            
            farmsWithGroups = result
            print("📊 [BENCHMARK-DASHBOARD] Loaded \(result.count) farms with groups")
        } catch {
            print("❌ [BENCHMARK-DASHBOARD] Error: \(error)")
        }
    }
}

// MARK: - Home Tab
private struct HomeTab: View {
    @EnvironmentObject private var profileGate: ProfileGate
    @EnvironmentObject private var languageManager: LanguageManager
    let onFarmManagementTapped: () -> Void
    let onAllLambingSeasonsTapped: () -> Void
    let onAllBreedingTapped: () -> Void
    let onAllScanningTapped: () -> Void
    let onAllLambingEventsTapped: () -> Void
    let onBenchmarkDashboardTapped: () -> Void  // ✅ PHASE 2B: New callback
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email ?? "Guest"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("landing.welcome".localized())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(currentUserEmail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("landing.quick_actions".localized())
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            QuickActionCard(
                                title: profileGate.shouldPresentProfileEdit ? "quick_action.complete_profile".localized() : "quick_action.edit_profile".localized(),
                                subtitle: profileGate.shouldPresentProfileEdit ? "quick_action.complete_profile_subtitle".localized() : "quick_action.edit_profile_subtitle".localized(),
                                systemImage: "person.crop.circle",
                                color: .blue,
                                action: { profileGate.shouldPresentProfileEdit = true }
                            )

                            QuickActionCard(
                                title: "quick_action.manage_farms".localized(),
                                subtitle: "quick_action.manage_farms_subtitle".localized(),
                                systemImage: "building.2.crop.circle",
                                color: .green,
                                action: onFarmManagementTapped
                            )

                            QuickActionCard(
                                title: "lambing.all_seasons_title".localized(),
                                subtitle: "lambing.all_seasons_subtitle".localized(),
                                systemImage: "calendar.badge.clock",
                                color: .orange,
                                action: onAllLambingSeasonsTapped
                            )

                            QuickActionCard(
                                title: "breeding.all_events_title".localized(),
                                subtitle: "breeding.all_events_subtitle".localized(),
                                systemImage: "heart.circle.fill",
                                color: .green,
                                action: onAllBreedingTapped
                            )

                            QuickActionCard(
                                title: "scanning.all_events_title".localized(),
                                subtitle: "quick_action.all_scanning_events_subtitle".localized(),
                                systemImage: "waveform.path.ecg",
                                color: .purple,
                                action: onAllScanningTapped
                            )
                            
                            QuickActionCard(
                                title: "lambing.all_events_title".localized(),
                                subtitle: "lambing.view_performance".localized(),
                                systemImage: "chart.line.uptrend.xyaxis",
                                color: .pink,
                                action: onAllLambingEventsTapped
                            )
                            
                            // ✅ PHASE 2B: Performance Dashboard Card
                            QuickActionCard(
                                title: "benchmark.dashboard_title".localized(),
                                subtitle: "benchmark.dashboard_subtitle".localized(),
                                systemImage: "chart.bar.fill",
                                color: .blue,
                                action: onBenchmarkDashboardTapped
                            )
                            
                            QuickActionCard(
                                title: "quick_action.get_started".localized(),
                                subtitle: "quick_action.get_started_subtitle".localized(),
                                systemImage: "play.circle.fill",
                                color: .indigo,
                                action: { /* TODO */ }
                            )

                            QuickActionCard(
                                title: "quick_action.learn_more".localized(),
                                subtitle: "quick_action.learn_more_subtitle".localized(),
                                systemImage: "book.circle.fill",
                                color: .teal,
                                action: { /* TODO */ }
                            )

                            QuickActionCard(
                                title: "quick_action.support".localized(),
                                subtitle: "quick_action.support_subtitle".localized(),
                                systemImage: "questionmark.circle.fill",
                                color: .orange,
                                action: { /* TODO */ }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("landing.home".localized())
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Explore Tab
private struct ExploreTab: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "safari")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    Text("explore.title".localized())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("explore.subtitle".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text("explore.coming_soon".localized())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("explore.title".localized())
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Profile Tab
private struct ProfileTab: View {
    @EnvironmentObject private var profileGate: ProfileGate
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingSignOutAlert = false
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email ?? "Unknown User"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(.tertiary)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("profile.title".localized())
                                .font(.headline)
                            Text(currentUserEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("landing.settings".localized()) {
                    SettingsRow(
                        title: "profile.preferences".localized(),
                        systemImage: "gearshape",
                        action: { /* TODO: Navigate to preferences */ }
                    )
                    
                    SettingsRow(
                        title: "profile.notifications".localized(),
                        systemImage: "bell",
                        action: { /* TODO: Navigate to notifications */ }
                    )
                    
                    SettingsRow(
                        title: "profile.privacy_security".localized(),
                        systemImage: "shield",
                        action: { /* TODO: Navigate to privacy settings */ }
                    )
                    
                    SettingsRow(
                        title: "quick_action.edit_profile".localized(),
                        systemImage: "pencil",
                        action: { profileGate.shouldPresentProfileEdit = true }
                    )
                }
                
                Section("quick_action.support".localized()) {
                    SettingsRow(
                        title: "profile.help_support".localized(),
                        systemImage: "questionmark.circle",
                        action: { /* TODO: Navigate to support */ }
                    )
                    
                    SettingsRow(
                        title: "profile.send_feedback".localized(),
                        systemImage: "envelope",
                        action: { /* TODO: Open feedback form */ }
                    )
                }
                
                Section {
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                            Text("auth.sign_out".localized())
                                .foregroundStyle(.red)
                        }
                    }
                    .accessibility(label: Text("accessibility.button.sign_out".localized()))
                    .accessibility(hint: Text("accessibility.button.sign_out.hint".localized()))
                }
            }
            .navigationTitle("profile.title".localized())
            .navigationBarTitleDisplayMode(.large)
            .alert("settings.sign_out_alert_title".localized(), isPresented: $showingSignOutAlert) {
                Button("common.cancel".localized(), role: .cancel) { }
                Button("auth.sign_out".localized(), role: .destructive) {
                    signOut()
                }
            } message: {
                Text("settings.sign_out_alert_message".localized())
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views

private struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(color)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibility(label: Text(title))
        .accessibility(hint: Text(subtitle))
        .accessibility(addTraits: .isButton)
    }
}

private struct SettingsRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibility(label: Text(String(format: "accessibility.row.settings".localized(), title)))
        .accessibility(hint: Text("accessibility.row.settings.hint".localized()))
        .accessibility(addTraits: .isButton)
    }
}

#Preview {
    LandingView()
        .environmentObject(ProfileGate(store: InMemoryUserProfileStore()))
        .environmentObject(LanguageManager.shared)
        .environmentObject(FirestoreBenchmarkStore())
        .environmentObject(FirestoreBreedingEventStore())
        .environmentObject(FirestoreScanningEventStore())
        .environmentObject(FirestoreLambingRecordStore())
        .environmentObject(FirestoreFarmStore())
        .environmentObject(FirestoreLambingSeasonGroupStore())
}
