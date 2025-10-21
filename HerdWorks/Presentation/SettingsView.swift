//
//  SettingsView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/21.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingSignOutAlert = false
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email ?? "settings.unknown_user".localized()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Language Section
                Section {
                    Picker("settings.language".localized(), selection: $languageManager.currentLanguage) {
                        ForEach(LanguageManager.Language.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                } header: {
                    Text("settings.language_section".localized())
                } footer: {
                    Text("settings.language_footer".localized())
                }
                
                // Account Section
                Section {
                    HStack {
                        Text("settings.email".localized())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(currentUserEmail)
                    }
                } header: {
                    Text("settings.account".localized())
                }
                
                // Sign Out Section
                Section {
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                            Text("settings.sign_out".localized())
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("settings.title".localized())
            .navigationBarTitleDisplayMode(.large)
            .alert("settings.sign_out_alert_title".localized(), isPresented: $showingSignOutAlert) {
                Button("common.cancel".localized(), role: .cancel) { }
                Button("settings.sign_out".localized(), role: .destructive) {
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

#Preview {
    SettingsView()
        .environmentObject(LanguageManager.shared)
}
