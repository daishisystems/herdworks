//
//  FarmSelectorView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/23.
//

import SwiftUI
import FirebaseAuth

struct FarmSelectorView: View {
    @StateObject private var viewModel: FarmListViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    
    let onFarmSelected: (Farm) -> Void
    
    init(store: FarmStore, onFarmSelected: @escaping (Farm) -> Void) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: FarmListViewModel(store: store, userId: uid))
        self.onFarmSelected = onFarmSelected
    }
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("lambing.select_farm".localized())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel".localized()) {
                            dismiss()
                        }
                    }
                }
                .task { await viewModel.loadFarms() }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("farm.loading".localized())
        } else if viewModel.farms.isEmpty {
            emptyStateView
        } else {
            farmsList
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("lambing.no_farms_title".localized())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("lambing.no_farms_subtitle".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var farmsList: some View {
        List {
            ForEach(viewModel.farms) { farm in
                Button {
                    onFarmSelected(farm)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Image(systemName: "building.2.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(farm.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("\(farm.breed.displayName) • \(farm.totalProductionEwes.formatted()) \("farm.ewes".localized())")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    FarmSelectorView(store: InMemoryFarmStore()) { farm in
        print("Selected: \(farm.name)")
    }
    .environmentObject(LanguageManager.shared)
}
