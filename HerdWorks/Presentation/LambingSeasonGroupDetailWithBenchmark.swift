//
//  LambingSeasonGroupDetailWithBenchmark.swift
//  HerdWorks
//
//  Phase 2B: Enhanced lambing season detail view with benchmark navigation
//

import SwiftUI
import FirebaseAuth

struct LambingSeasonGroupDetailWithBenchmark: View {
    let farm: Farm
    let group: LambingSeasonGroup
    
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var benchmarkViewModel: BenchmarkComparisonViewModel
    @State private var showingBenchmarkView = false
    @State private var farmPerformance: FarmPerformanceData?
    
    private let benchmarkStore: BenchmarkStore
    private let breedingStore: BreedingEventStore
    private let scanningStore: ScanningEventStore
    private let lambingStore: LambingRecordStore
    
    init(
        farm: Farm,
        group: LambingSeasonGroup,
        benchmarkStore: BenchmarkStore,
        breedingStore: BreedingEventStore,
        scanningStore: ScanningEventStore,
        lambingStore: LambingRecordStore
    ) {
        self.farm = farm
        self.group = group
        self.benchmarkStore = benchmarkStore
        self.breedingStore = breedingStore
        self.scanningStore = scanningStore
        self.lambingStore = lambingStore
        
        let userId = Auth.auth().currentUser?.uid ?? ""
        _benchmarkViewModel = StateObject(wrappedValue: BenchmarkComparisonViewModel(
            benchmarkStore: benchmarkStore,
            breedingStore: breedingStore,
            scanningStore: scanningStore,
            lambingStore: lambingStore,
            userId: userId,
            farmId: farm.id,
            groupId: group.id
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Season Overview Card
                seasonOverviewCard
                
                // Benchmark Summary Card (if data available)
                if benchmarkViewModel.farmPerformance != nil {
                    BenchmarkSummaryCard(
                        farmPerformance: benchmarkViewModel.farmPerformance,
                        benchmarkData: benchmarkViewModel.benchmarkData,
                        onTap: {
                            showingBenchmarkView = true
                        }
                    )
                }
                
                // Data Entry Section
                dataEntrySection
                
                // Season Details
                seasonDetailsCard
            }
            .padding()
        }
        .navigationTitle(group.displayName)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingBenchmarkView) {
            BenchmarkComparisonView(
                farm: farm,
                group: group,
                benchmarkStore: benchmarkStore,
                breedingStore: breedingStore,
                scanningStore: scanningStore,
                lambingStore: lambingStore,
                userId: Auth.auth().currentUser?.uid ?? ""
            )
        }
        .onAppear {
            benchmarkViewModel.startListening(farm: farm, group: group)
        }
        .onDisappear {
            benchmarkViewModel.stopListening()
        }
    }
    
    // MARK: - Season Overview Card
    
    private var seasonOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(farm.name, systemImage: "building.2.fill")
                        .font(.headline)
                    
                    Text("\(farm.breed.displayName) • \(farm.totalProductionEwes) " + "common.ewes".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("lambing.mating_period".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dateRangeFormatted(start: group.matingStart, end: group.matingEnd))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("lambing.lambing_period".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dateRangeFormatted(start: group.lambingStart, end: group.lambingEnd))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusBadge: some View {
        Group {
            if group.isActive {
                Label("lambing.active".localized(), systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .clipShape(Capsule())
            } else {
                Label("lambing.inactive".localized(), systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Data Entry Section
    
    private var dataEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("data_entry.section_title".localized())
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 2) {
                dataEntryRow(
                    title: "breeding.title".localized(),
                    icon: "heart.circle.fill",
                    color: .pink,
                    destination: AnyView(Text("Breeding Event View")) // Placeholder
                )
                
                dataEntryRow(
                    title: "scanning.title".localized(),
                    icon: "camera.viewfinder",
                    color: .blue,
                    destination: AnyView(Text("Scanning Event View")) // Placeholder
                )
                
                dataEntryRow(
                    title: "lambing.title".localized(),
                    icon: "star.circle.fill",
                    color: .orange,
                    destination: AnyView(Text("Lambing Record View")) // Placeholder
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func dataEntryRow<Destination: View>(
        title: String,
        icon: String,
        color: Color,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Season Details Card
    
    private var seasonDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("lambing.season_details".localized())
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(
                    label: "lambing.code".localized(),
                    value: group.code
                )
                
                detailRow(
                    label: "lambing.name".localized(),
                    value: group.name
                )
                
                detailRow(
                    label: "lambing.mating_duration".localized(),
                    value: "\(group.matingDurationDays) " + "common.days".localized()
                )
                
                detailRow(
                    label: "lambing.lambing_duration".localized(),
                    value: "\(group.lambingDurationDays) " + "common.days".localized()
                )
                
                detailRow(
                    label: "lambing.gestation_period".localized(),
                    value: "\(group.gestationDays) " + "common.days".localized()
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Helper Methods
    
    private func dateRangeFormatted(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Preview

struct LambingSeasonGroupDetailWithBenchmark_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LambingSeasonGroupDetailWithBenchmark(
                farm: Farm.preview,
                group: LambingSeasonGroup.preview,
                benchmarkStore: InMemoryBenchmarkStore(),
                breedingStore: InMemoryBreedingEventStore(),
                scanningStore: InMemoryScanningEventStore(),
                lambingStore: InMemoryLambingRecordStore()
            )
            .environmentObject(LanguageManager.shared)
        }
    }
}
