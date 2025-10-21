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
    
    // ✅ Extract everything into mainContent
    private var mainContent: some View {
        contentView
            .navigationTitle("Farms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .modifier(SheetsModifier(
                showingAddFarm: $showingAddFarm,
                selectedFarm: $selectedFarm,
                store: store,
                userId: userId,
                onDismissAdd: { Task { await viewModel.loadFarms() } },
                onDismissEdit: { Task { await viewModel.loadFarms() } }
            ))
            .modifier(AlertsModifier(viewModel: viewModel))
            .task { await viewModel.loadFarms() }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("Loading farms...")
        } else if viewModel.farms.isEmpty {
            emptyStateView
        } else {
            farmListView
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Done") {
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
                Text("No Farms Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first farm to get started")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddFarm = true
            } label: {
                Label("Add Your First Farm", systemImage: "plus.circle.fill")
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
                FarmRowView(farm: farm)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFarm = farm
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(farm)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - View Modifiers

struct SheetsModifier: ViewModifier {
    @Binding var showingAddFarm: Bool
    @Binding var selectedFarm: Farm?
    let store: FarmStore
    let userId: String
    let onDismissAdd: () -> Void
    let onDismissEdit: () -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingAddFarm) {
                FarmDetailView(store: store)
            }
            .onChange(of: showingAddFarm) { _, newValue in
                if !newValue { onDismissAdd() }
            }
            .sheet(item: $selectedFarm) { farm in
                FarmDetailView(store: store, farm: farm)
            }
            .onChange(of: selectedFarm) { oldValue, newValue in
                if newValue == nil && oldValue != nil { onDismissEdit() }
            }
    }
}

struct AlertsModifier: ViewModifier {
    @ObservedObject var viewModel: FarmListViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("Delete Farm", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteFarm() }
                }
            } message: {
                if let farm = viewModel.farmToDelete {
                    Text("Are you sure you want to delete \(farm.name)?")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
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
                    Text("\(farm.totalProductionEwes.formatted()) ewes")
                }
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

#Preview {
    FarmListView(store: InMemoryFarmStore())
}
