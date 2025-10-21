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
    @State private var selectedTab: Tab = .home
    @State private var showingFarmManagement = false  // ✅ ADD THIS
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case explore = "Explore"
        case profile = "Profile"
        
        var systemImage: String {
            switch self {
            case .home: return "house"
            case .explore: return "safari"
            case .profile: return "person"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab(onFarmManagementTapped: {  // ✅ MODIFY THIS LINE
                showingFarmManagement = true
            })
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)
            
            ExploreTab()
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }
                .tag(Tab.explore)
            
            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(Tab.profile)
        }
        .tint(.accentColor)
        .sheet(isPresented: $profileGate.shouldPresentProfileEdit) {
            ProfileEditView(store: FirestoreUserProfileStore())
        }
        // ✅ ADD THIS SHEET
        .sheet(isPresented: $showingFarmManagement) {
            FarmListView(store: FirestoreFarmStore())
        }
    }
}

// MARK: - Home Tab
private struct HomeTab: View {
    @EnvironmentObject private var profileGate: ProfileGate
    let onFarmManagementTapped: () -> Void  // ✅ ADD THIS PARAMETER
    
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
                                Text("Welcome to HerdWorks")
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
                            Text("Quick Actions")
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            QuickActionCard(
                                title: profileGate.shouldPresentProfileEdit ? "Complete Profile" : "Edit Profile",
                                subtitle: profileGate.shouldPresentProfileEdit ? "Finish setup to continue" : "Update your details",
                                systemImage: "person.crop.circle",
                                color: .blue,
                                action: { profileGate.shouldPresentProfileEdit = true }
                            )
                            
                            // ✅ ADD THIS FARM MANAGEMENT CARD
                            QuickActionCard(
                                title: "Manage Farms",
                                subtitle: "Add and edit your farms",
                                systemImage: "building.2.crop.circle",
                                color: .green,
                                action: onFarmManagementTapped
                            )
                            
                            QuickActionCard(
                                title: "Get Started",
                                subtitle: "Begin your journey",
                                systemImage: "play.circle",
                                color: .blue,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                            
                            QuickActionCard(
                                title: "Learn More",
                                subtitle: "Discover features",
                                systemImage: "book.circle",
                                color: .green,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                            
                            QuickActionCard(
                                title: "Settings",
                                subtitle: "Customize your experience",
                                systemImage: "gearshape.circle",
                                color: .orange,
                                action: {
                                    // TODO: Add action for each quick action
                                }
                            )
                            
                            QuickActionCard(
                                title: "Support",
                                subtitle: "Get help when needed",
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
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "safari")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    Text("Explore")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Discover new features and content")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text("More content coming soon")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Profile Tab
private struct ProfileTab: View {
    @EnvironmentObject private var profileGate: ProfileGate
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
                            Text("Profile")
                                .font(.headline)
                            Text(currentUserEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Settings") {
                    SettingsRow(
                        title: "Preferences",
                        systemImage: "gearshape",
                        action: { /* TODO: Navigate to preferences */ }
                    )
                    
                    SettingsRow(
                        title: "Notifications",
                        systemImage: "bell",
                        action: { /* TODO: Navigate to notifications */ }
                    )
                    
                    SettingsRow(
                        title: "Privacy & Security",
                        systemImage: "shield",
                        action: { /* TODO: Navigate to privacy settings */ }
                    )
                    
                    SettingsRow(
                        title: "Edit Profile",
                        systemImage: "pencil",
                        action: { profileGate.shouldPresentProfileEdit = true }
                    )
                }
                
                Section("Support") {
                    SettingsRow(
                        title: "Help & Support",
                        systemImage: "questionmark.circle",
                        action: { /* TODO: Navigate to support */ }
                    )
                    
                    SettingsRow(
                        title: "Send Feedback",
                        systemImage: "envelope",
                        action: { /* TODO: Open feedback form */ }
                    )
                }
                
                Section {
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                            Text("Sign Out")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
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
}
