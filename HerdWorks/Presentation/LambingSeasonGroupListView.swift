//
//  LambingSeasonGroupListView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import SwiftUI
import FirebaseAuth

struct LambingSeasonGroupListView: View {
    @StateObject private var viewModel: LambingSeasonGroupListViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingAddGroup = false
    @State private var selectedGroup: LambingSeasonGroup?
    @Environment(\.dismiss) private var dismiss
    
    private let store: LambingSeasonGroupStore
    private let userId: String
    private let farmId: String
    private let farmName: String
    
    init(store: LambingSeasonGroupStore, farmId: String, farmName: String) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        self.store = store
        self.userId = uid
        self.farmId = farmId
        self.farmName = farmName
        _viewModel = StateObject(wrappedValue: LambingSeasonGroupListViewModel(
            store: store,
            userId: uid,
            farmId: farmId
        ))
    }
    
    var body: some View {
        NavigationStack {
            mainContent
        }
    }
    
    private var mainContent: some View {
        contentView
            .navigationTitle(farmName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .modifier(LambingGroupSheetsModifier(
                showingAddGroup: $showingAddGroup,
                selectedGroup: $selectedGroup,
                store: store,
                userId: userId,
                farmId: farmId,
                onDismissAdd: { Task { await viewModel.loadGroups() } },
                onDismissEdit: { Task { await viewModel.loadGroups() } }
            ))
            .modifier(LambingGroupAlertsModifier(viewModel: viewModel))  // ✅ Renamed
            .task { await viewModel.loadGroups() }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("lambing.loading".localized())
        } else if viewModel.displayedGroups.isEmpty {
            emptyStateView
        } else {
            groupListView
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
            HStack(spacing: 12) {
                if viewModel.hasInactiveGroups {
                    Button {
                        viewModel.toggleActiveFilter()
                    } label: {
                        Image(systemName: viewModel.showActiveOnly ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .font(.body.weight(.medium))
                    }
                }
                
                Button {
                    showingAddGroup = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(viewModel.showActiveOnly ? "lambing.empty_active_title".localized() : "lambing.empty_title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.showActiveOnly ? "lambing.empty_active_subtitle".localized() : "lambing.empty_subtitle".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !viewModel.showActiveOnly {
                Button {
                    showingAddGroup = true
                } label: {
                    Label("lambing.add_first_group".localized(), systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            } else if viewModel.hasInactiveGroups {
                Button {
                    viewModel.showActiveOnly = false
                } label: {
                    Text("lambing.show_all".localized())
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                .padding(.top, 16)
            }
        }
        .padding()
    }
    
    private var groupListView: some View {
        List {
            ForEach(viewModel.displayedGroups) { group in
                LambingSeasonGroupRowView(group: group)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGroup = group
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(group)
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

// MARK: - View Modifiers

private struct LambingGroupSheetsModifier: ViewModifier {
    @Binding var showingAddGroup: Bool
    @Binding var selectedGroup: LambingSeasonGroup?
    let store: LambingSeasonGroupStore
    let userId: String
    let farmId: String
    let onDismissAdd: () -> Void
    let onDismissEdit: () -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingAddGroup) {
                LambingSeasonGroupDetailView(store: store, farmId: farmId)
            }
            .onChange(of: showingAddGroup) { _, newValue in
                if !newValue { onDismissAdd() }
            }
            .sheet(item: $selectedGroup) { group in
                LambingSeasonGroupDetailView(store: store, farmId: farmId, group: group)
            }
            .onChange(of: selectedGroup) { oldValue, newValue in
                if newValue == nil && oldValue != nil { onDismissEdit() }
            }
    }
}

private struct LambingGroupAlertsModifier: ViewModifier {  // ✅ Renamed
    @ObservedObject var viewModel: LambingSeasonGroupListViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("lambing.delete_confirmation_title".localized(), isPresented: $viewModel.showDeleteConfirmation) {
                Button("common.cancel".localized(), role: .cancel) { }
                Button("common.delete".localized(), role: .destructive) {
                    Task { await viewModel.deleteGroup() }
                }
            } message: {
                if let group = viewModel.groupToDelete {
                    Text(String(format: "lambing.delete_confirmation_message".localized(), group.displayName))
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

// MARK: - Row View

struct LambingSeasonGroupRowView: View {
    let group: LambingSeasonGroup
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(group.isActive ? Color.green.gradient : Color.gray.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(group.displayName)
                        .font(.headline)
                    
                    if group.isActive {
                        Text("lambing.active".localized())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green)
                            .clipShape(Capsule())
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                        Text("lambing.mating_short".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(dateFormatter.string(from: group.matingStart)) - \(dateFormatter.string(from: group.matingEnd))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.green)
                        Text("lambing.lambing_short".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(dateFormatter.string(from: group.lambingStart)) - \(dateFormatter.string(from: group.lambingEnd))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

#Preview("With Groups") {
    NavigationStack {
        LambingSeasonGroupListView(
            store: {
                let store = InMemoryLambingSeasonGroupStore()
                Task {
                    for group in LambingSeasonGroup.previews {
                        try? await store.create(group)
                    }
                }
                return store
            }(),
            farmId: "preview-farm",
            farmName: "Preview Farm"
        )
        .environmentObject(LanguageManager.shared)
    }
}

#Preview("Empty") {
    NavigationStack {
        LambingSeasonGroupListView(
            store: InMemoryLambingSeasonGroupStore(),
            farmId: "preview-farm",
            farmName: "Preview Farm"
        )
        .environmentObject(LanguageManager.shared)
    }
}
