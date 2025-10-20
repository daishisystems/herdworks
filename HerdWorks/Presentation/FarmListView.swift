//
//  FarmListView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth

struct FarmListView: View {
    @StateObject private var viewModel: FarmListViewModel
    @State private var showingAddFarm = false
    @State private var selectedFarm: Farm?
    
    init(store: FarmStore) {
        let userId = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: FarmListViewModel(store: store, userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.farms.isEmpty {
                    ProgressView("Loading farms...")
                } else if viewModel.farms.isEmpty {
                    emptyStateView
                } else {
                    farmListView
                }
            }
            .navigationTitle("Farms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFarm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingAddFarm) {
                FarmDetailView(store: FirestoreFarmStore())
            }
            .sheet(item: $selectedFarm) { farm in
                FarmDetailView(store: FirestoreFarmStore(), farm: farm)
            }
            .alert("Delete Farm?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteFarm()
                    }
                }
            } message: {
                if let farm = viewModel.farmToDelete {
                    Text("This will permanently delete '\(farm.name)'. This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .task {
                await viewModel.loadFarms()
            }
            .refreshable {
                await viewModel.loadFarms()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Farms Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first farm to start managing your livestock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                showingAddFarm = true
            } label: {
                Label("Add Your First Farm", systemImage: "plus")
                    .font(.headline)
                    .frame(minHeight: 50)
                    .padding(.horizontal, 32)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var farmListView: some View {
        List {
            ForEach(viewModel.farms) { farm in
                FarmRowView(farm: farm)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFarm = farm
                    }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    viewModel.confirmDelete(viewModel.farms[index])
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Farm Row View

private struct FarmRowView: View {
    let farm: Farm
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(farm.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("\(farm.breed.displayName) • \(farm.totalProductionEwes.formatted()) ewes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("\(farm.city), \(farm.province.displayName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

#Preview("Empty") {
    FarmListView(store: InMemoryFarmStore())
}

#Preview("With Farms") {
    let store = InMemoryFarmStore()
    
    Task {
        let farm1 = Farm(
            userId: "preview-user",
            name: "Lamont Boerdery",
            breed: .dohneMerino,
            totalProductionEwes: 2700,
            city: "Saldanha",
            province: .westernCape
        )
        
        let farm2 = Farm(
            userId: "preview-user",
            name: "Riverside Farm",
            breed: .dorper,
            totalProductionEwes: 1500,
            city: "Cradock",
            province: .easternCape
        )
        
        try? await store.create(farm1)
        try? await store.create(farm2)
    }
    
    return FarmListView(store: store)
}
