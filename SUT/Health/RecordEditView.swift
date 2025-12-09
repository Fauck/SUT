//
//  Untitled.swift
//  SUT
//
//  Created by bokmacdev on 2025/12/10.
//
// MARK: - 3. 編輯視窗 test
import SwiftUI
import CoreData
struct RecordEditView: View {
    let date: Date
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var weight: String = ""
    @State private var hasExercise: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.purple.opacity(0.6))
                        Text("當日體重 (kg)")
                            .font(.system(.body, design: .rounded))
                        Spacer()
                        TextField("尚未輸入", text: $weight)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle(isOn: $hasExercise) {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(.green.opacity(0.8))
                            Text("今日有運動嗎？")
                                .font(.system(.body, design: .rounded))
                        }
                    }
                    .tint(.pink.opacity(0.6))
                } header: {
                    Text(viewModel.formatDate(date))
                        .font(.system(.caption, design: .rounded))
                }
                
                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Text("儲存紀錄").fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.pink.opacity(0.7))
                }
            }
            .navigationTitle("編輯紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let record = viewModel.getRecord(for: date) {
                    if record.weight > 0 { weight = String(record.weight) }
                    hasExercise = record.hasExercise
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
    
    func save() {
        let w = Double(weight) ?? 0.0
        viewModel.saveRecord(date: date, weight: w, hasExercise: hasExercise)
        dismiss()
    }
}
