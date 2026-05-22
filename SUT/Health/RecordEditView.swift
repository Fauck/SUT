// MARK: - 編輯紀錄視窗
import SwiftUI
import CoreData

struct RecordEditView: View {
    let date: Date
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var weight: String = ""
    @State private var hasExercise: Bool = false
    @State private var exerciseType: String = ""
    @State private var exerciseDuration: String = ""
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
                } header: {
                    Text(viewModel.formatDate(date))
                        .font(.system(.caption, design: .rounded))
                }
                
                Section {
                    Toggle(isOn: $hasExercise) {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(.green.opacity(0.8))
                            Text("今日有運動嗎？")
                                .font(.system(.body, design: .rounded))
                        }
                    }
                    .tint(.green.opacity(0.7))
                    
                    if hasExercise {
                        // 運動類型選擇
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "figure.mixed.cardio")
                                    .foregroundColor(.blue.opacity(0.7))
                                Text("運動類型")
                                    .font(.system(.body, design: .rounded))
                            }
                            
                            // 使用 FlowLayout 排列運動選項
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 70), spacing: 8)
                            ], spacing: 8) {
                                ForEach(ExerciseConfig.shared.types, id: \.self) { option in
                                    Button {
                                        exerciseType = option
                                    } label: {
                                        Text(option)
                                            .font(.system(size: 14, weight: exerciseType == option ? .bold : .regular, design: .rounded))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .frame(minWidth: 60)
                                            .background(exerciseType == option ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08))
                                            .foregroundColor(exerciseType == option ? .blue : .primary)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(exerciseType == option ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // 運動時間
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange.opacity(0.7))
                            Text("運動時間 (分鐘)")
                                .font(.system(.body, design: .rounded))
                            Spacer()
                            TextField("0", text: $exerciseDuration)
                                .keyboardType(.numberPad)
                                .focused($isFocused)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } header: {
                    Text("運動紀錄")
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
                    .listRowBackground(Color.blue.opacity(0.7))
                }
            }
            .navigationTitle("編輯紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
            .onAppear {
                if let record = viewModel.getRecord(for: date) {
                    if record.weight > 0 { weight = String(record.weight) }
                    hasExercise = record.hasExercise
                    exerciseType = record.exerciseType ?? ""
                    if record.exerciseDuration > 0 {
                        exerciseDuration = String(Int(record.exerciseDuration))
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
    
    func save() {
        let w = Double(weight) ?? 0.0
        let duration = Double(exerciseDuration) ?? 0.0
        viewModel.saveRecord(
            date: date,
            weight: w,
            hasExercise: hasExercise,
            exerciseType: hasExercise ? exerciseType : "",
            exerciseDuration: hasExercise ? duration : 0
        )
        dismiss()
    }
}
