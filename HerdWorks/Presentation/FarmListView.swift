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
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingAddFarm = false
    @State private var selectedFarm: Farm?
    @Environment(\.dismiss) private var dismiss
    
    private let store: FarmStore
    private let userId: String
    
    init(store: FarmStore) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        self.store = store
        self.userId = uid
        _viewModel = StateObject(wrappedValue: FarmListViewModel(store: store, userId: uid))
    }
    
    var body: some View {
        NavigationStack {
            mainContent
        }
    }
    
    private var mainContent: some View {
        contentView
            .navigationTitle("farm.list_title".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAddFarm) {
                // Create new farm - use edit view
                FarmEditView(store: store)
            }
            .onChange(of: showingAddFarm) { _, newValue in
                if !newValue { Task { await viewModel.loadFarms() } }
            }
            .modifier(AlertsModifier(viewModel: viewModel))
            .task { await viewModel.loadFarms() }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("farm.loading".localized())
        } else if viewModel.farms.isEmpty {
            emptyStateView
        } else {
            farmListView
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("common.done".localized()) {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAddFarm = true
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("farm.empty_title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("farm.empty_subtitle".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddFarm = true
            } label: {
                Label("farm.add_first_farm".localized(), systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .padding()
    }
    
    private var farmListView: some View {
        List {
            ForEach(viewModel.farms) { farm in
                NavigationLink(destination: FarmOverviewView(farm: farm, store: store)) {
                    FarmRowView(farm: farm)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.confirmDelete(farm)
                    } label: {
                        Label("common.delete".localized(), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - View Modifiers

struct AlertsModifier: ViewModifier {
    @ObservedObject var viewModel: FarmListViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("farm.delete_confirmation_title".localized(), isPresented: $viewModel.showDeleteConfirmation) {
                Button("common.cancel".localized(), role: .cancel) { }
                Button("common.delete".localized(), role: .destructive) {
                    Task { await viewModel.deleteFarm() }
                }
            } message: {
                if let farm = viewModel.farmToDelete {
                    Text(String(format: "farm.delete_confirmation_message".localized(), farm.name))
                }
            }
            .alert("common.error".localized(), isPresented: $viewModel.showError) {
                Button("common.ok".localized(), role: .cancel) { }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
    }
}

// MARK: - Farm Row View

struct FarmRowView: View {
    let farm: Farm
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.blue.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(farm.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(farm.breed.displayName)
                    Text("•")
                    Text("\(farm.totalProductionEwes.formatted()) \("farm.ewes".localized())")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                Text("\(farm.city), \(farm.province.displayName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FarmListView(store: InMemoryFarmStore())
        .environmentObject(LanguageManager.shared)
}
