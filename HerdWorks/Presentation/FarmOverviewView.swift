//
//  FarmOverviewView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import SwiftUI
import FirebaseAuth

struct FarmOverviewView: View {
    let farm: Farm
    let store: FarmStore
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingLambingSeasons = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Farm Header Card
                farmHeaderCard
                
                // Quick Actions Section
                quickActionsSection
                
                // Details Section
                detailsSection
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(farm.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Text("common.edit".localized())
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            FarmEditView(store: store, farm: farm)
        }
        .sheet(isPresented: $showingLambingSeasons) {
            LambingSeasonGroupListView(
                store: FirestoreLambingSeasonGroupStore(),
                farmId: farm.id,
                farmName: farm.name
            )
        }
    }
    
    // MARK: - Farm Header Card
    
    private var farmHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 6) {
                    if let companyName = farm.companyName {
                        Text(companyName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(farm.breed.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")  // ✅ Or any valid SF Symbol
                        Text("\(farm.totalProductionEwes.formatted()) \("farm.ewes".localized())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Location
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(farm.city)
                        .font(.subheadline)
                    Text(farm.province.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("landing.quick_actions".localized())
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // Lambing Seasons Button
                QuickActionButton(
                    title: "lambing.list_title".localized(),
                    subtitle: "farm.manage_lambing_seasons_subtitle".localized(),
                    icon: "calendar.badge.clock",
                    color: .green,
                    action: { showingLambingSeasons = true }
                )
                
                // Future: Production Stats
                QuickActionButton(
                    title: "farm.production_stats".localized(),
                    subtitle: "farm.production_stats_subtitle".localized(),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange,
                    action: { /* Coming soon */ }
                )
                .opacity(0.5)
                
                // Future: View on Map
                QuickActionButton(
                    title: "farm.view_on_map".localized(),
                    subtitle: "farm.view_on_map_subtitle".localized(),
                    icon: "map",
                    color: .blue,
                    action: { /* Coming soon */ }
                )
                .opacity(0.5)
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("farm.details".localized())
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if let size = farm.sizeHectares {
                    DetailRow(
                        label: "farm.farm_size_hectares".localized(),
                        value: "\(size.formatted()) ha"
                    )
                    Divider()
                }
                
                if let system = farm.productionSystem {
                    DetailRow(
                        label: "farm.production_system".localized(),
                        value: system.displayName
                    )
                    Divider()
                }
                
                if let agent = farm.preferredAgent {
                    DetailRow(
                        label: "farm.preferred_agent".localized(),
                        value: agent.displayName
                    )
                    Divider()
                }
                
                if let abattoir = farm.preferredAbattoir, !abattoir.isEmpty {
                    DetailRow(
                        label: "farm.preferred_abattoir".localized(),
                        value: abattoir
                    )
                    Divider()
                }
                
                if let vet = farm.preferredVeterinarian, !vet.isEmpty {
                    DetailRow(
                        label: "farm.preferred_veterinarian".localized(),
                        value: vet
                    )
                    Divider()
                }
                
                if let coop = farm.coOp {
                    DetailRow(
                        label: "farm.coop".localized(),
                        value: coop.displayName
                    )
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        FarmOverviewView(
            farm: Farm(
                userId: "preview-user",
                name: "Farm 02",
                breed: .dohneMerino,
                totalProductionEwes: 100000,
                city: "Mosselbay",
                province: .westernCape,
                companyName: "Elderberry Investments",
                sizeHectares: 5000,
                productionSystem: ProductionSystem.livestock100,
                preferredAgent: PreferredAgent.bkb
            ),
            store: InMemoryFarmStore()
        )
        .environmentObject(LanguageManager.shared)
    }
}
