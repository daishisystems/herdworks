//
//  LambingRecordDetailViewWithSelection.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/11/04.
//

import SwiftUI

struct LambingRecordDetailViewWithSelection: View {
    let recordStore: LambingRecordStore
    let farms: [Farm]
    let groups: [LambingSeasonGroup]
    let userId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFarmId: String = ""
    @State private var selectedGroupId: String = ""
    @State private var ewesLambed: String = ""
    @State private var lambsBorn: String = ""
    @State private var mortality: String = ""
    @State private var birthWeight: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case ewesLambed, lambsBorn, mortality, birthWeight }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Farm and Lambing Group") {
                    Picker("Select Farm", selection: $selectedFarmId) {
                        Text("Select...").tag("")
                        ForEach(farms) { farm in
                            Text(farm.name).tag(farm.id)
                        }
                    }
                    
                    Picker("Select Lambing Group", selection: $selectedGroupId) {
                        Text("Select...").tag("")
                        ForEach(filteredGroups) { group in
                            Text("\(group.code) - \(group.name)").tag(group.id)
                        }
                    }
                    .disabled(selectedFarmId.isEmpty)
                }
                
                Section("Lambing Data") {
                    TextField("Lambing Ewes", text: $ewesLambed)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .ewesLambed)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .lambsBorn }
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = .ewesLambed }
                    
                    TextField("Lambs Born", text: $lambsBorn)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .lambsBorn)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .mortality }
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = .lambsBorn }
                    
                    TextField("Mortality (0-30 days)", text: $mortality)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .mortality)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .birthWeight }
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = .mortality }
                }
                
                Section("Optional") {
                    TextField("Average Birth Weight (kg)", text: $birthWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .birthWeight)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = .birthWeight }
                }
            }
            .navigationTitle("Add Lambing Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveRecord()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var filteredGroups: [LambingSeasonGroup] {
        groups.filter { $0.farmId == selectedFarmId }
    }
    
    private var isValid: Bool {
        !selectedFarmId.isEmpty &&
        !selectedGroupId.isEmpty &&
        !ewesLambed.isEmpty &&
        !lambsBorn.isEmpty &&
        !mortality.isEmpty
    }
    
    private func saveRecord() async {
        guard let ewes = Int(ewesLambed),
              let lambs = Int(lambsBorn),
              let mort = Int(mortality) else {
            errorMessage = "Please enter valid numbers"
            showError = true
            return
        }
        
        let record = LambingRecord(
            userId: userId,
            farmId: selectedFarmId,
            lambingSeasonGroupId: selectedGroupId,
            ewesLambed: ewes,
            lambsBorn: lambs,
            lambsMortality0to30Days: mort,
            averageBirthWeight: Double(birthWeight)
        )
        
        do {
            try await recordStore.create(record)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

