//
//  LandingView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/15.
//

import SwiftUI
import FirebaseAuth

struct LandingView: View {
    @EnvironmentObject private var profileGate: ProfileGate
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedTab: Tab = .home
    @State private var showingFarmManagement = false
    
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
            HomeTab(onFarmManagementTapped: {
                showingFarmManagement = true
            })
                .tabItem {
                    Label("landing.home".localized(), systemImage: "house")
                }
                .tag(Tab.home)
            
            ExploreTab()
                .tabItem {
                    Label("landing.explore".localized(), systemImage: "safari")
                }
                .tag(Tab.explore)
            
            ProfileTab()
                .tabItem {
                    Label("landing.profile".localized(), systemImage: "person")
                }
                .tag(Tab.profile)
            
            SettingsView()
                .tabItem {
                    Label("landing.settings".localized(), systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(.accentColor)
        .sheet(isPresented: $profileGate.shouldPresentProfileEdit) {
            ProfileEditView(store: FirestoreUserProfileStore())
        }
        .sheet(isPresented: $showingFarmManagement) {
            FarmListView(store: FirestoreFarmStore())
        }
    }
}

// MARK: - Home Tab
private struct HomeTab: View {
    @EnvironmentObject private var profileGate: ProfileGate
    @EnvironmentObject private var languageManager: LanguageManager
    let onFarmManagementTapped: () -> Void
    
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
                                title: "quick_action.get_started".localized(),
                                subtitle: "quick_action.get_started_subtitle".localized(),
                                systemImage: "play.circle",
                                color: .blue,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                            
                            QuickActionCard(
                                title: "quick_action.learn_more".localized(),
                                subtitle: "quick_action.learn_more_subtitle".localized(),
                                systemImage: "book.circle",
                                color: .green,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                            
                            QuickActionCard(
                                title: "quick_action.settings".localized(),
                                subtitle: "quick_action.settings_subtitle".localized(),
                                systemImage: "gearshape.circle",
                                color: .orange,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                            
                            QuickActionCard(
                                title: "quick_action.support".localized(),
                                subtitle: "quick_action.support_subtitle".localized(),
                                systemImage: "questionmark.circle",
                                color: .purple,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.vertical)
            }
            .navigationTitle("HerdWorks")
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
    }
}

#Preview {
    LandingView()
        .environmentObject(LanguageManager.shared)
}
