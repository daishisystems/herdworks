//
//  LambingRecordDetailView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import SwiftUI

struct LambingRecordDetailView: View {
    let recordStore: LambingRecordStore
    let benchmarkStore: BenchmarkStore
    let record: LambingRecord
    let farmBreed: SheepBreed
    let farmProvince: SouthAfricanProvince
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Your Results") {
                    LabeledContent("Lambing Ewes", value: "\(record.ewesLambed)")
                    LabeledContent("Lambs Born", value: "\(record.lambsBorn)")
                    LabeledContent("Mortality", value: "\(record.lambsMortality0to30Days)")
                    if let weight = record.averageBirthWeight {
                        LabeledContent("Avg Birth Weight", value: String(format: "%.1f kg", weight))
                    }
                }
                
                Section("Calculated Metrics") {
                    LabeledContent("Lambing %", value: String(format: "%.1f%%", record.lambingPercentage))
                    LabeledContent("Mortality Rate", value: String(format: "%.1f%%", record.mortalityRate))
                    LabeledContent("Survival Rate", value: String(format: "%.1f%%", record.survivalRate))
                }
            }
            .navigationTitle("Lambing Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
