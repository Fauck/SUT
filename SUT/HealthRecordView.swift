import SwiftUI

// MARK: - 主畫面：健康記錄日曆
struct HealthRecordView: View {
    @StateObject private var viewModel = HealthViewModel()
    @State private var selectedDate: Date? = nil
    @State private var showEditSheet = false
    @State private var showTrendChart = false
    
    // UI 配色
    let highlightColor = Color.blue.opacity(0.8)
    let bgColor = Color(red: 0.98, green: 0.98, blue: 0.99)
    let softGreen = Color(red: 0.5, green: 0.85, blue: 0.5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // --- 月份切換標頭 (固定在頂部) ---
                    HStack {
                        changeMonthButton(icon: "chevron.left", by: -1)
                        Spacer()
                        Text(viewModel.monthYearString)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary.opacity(0.8))
                        Spacer()
                        changeMonthButton(icon: "chevron.right", by: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // --- 日曆主體 (可捲動，避免 6 週月份溢出) ---
                    ScrollView {
                        VStack(spacing: 12) {
                            // 星期標頭
                            HStack {
                                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                                    Text(day)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            // 日期網格
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(0..<viewModel.offsetDays, id: \.self) { _ in
                                    Color.clear.frame(height: 62)
                                }
                                
                                ForEach(viewModel.daysInMonth, id: \.self) { date in
                                    dayCell(for: date)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollIndicators(.hidden)
                    
                    // --- 底部圖例說明 ---
                    legendView
                        .padding(.top, 8)
                }
            }
            .navigationTitle("健康記錄")
            .sheet(isPresented: $showEditSheet) {
                if let date = selectedDate {
                    RecordEditView(date: date, viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                        .presentationCornerRadius(30)
                }
            }
            .sheet(isPresented: $showTrendChart) {
                WeightTrendView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                viewModel.fetchRecords()
            }
        }
    }
    
    // MARK: - 子視圖組件
    
    func changeMonthButton(icon: String, by value: Int) -> some View {
        Button(action: {
            withAnimation { viewModel.changeMonth(by: value) }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
                .padding(10)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }
    
    func dayCell(for date: Date) -> some View {
        let record = viewModel.getRecord(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = selectedDate == date
        
        let weight = record?.weight ?? 0.0
        let hasExercise = record?.hasExercise ?? false
        let exerciseType = record?.exerciseType ?? ""
        
        return Button {
            selectedDate = date
            showEditSheet = true
        } label: {
            VStack(spacing: 2) {
                // 日期
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(isToday ? .white : .gray.opacity(0.7))
                    .frame(width: 20, height: 20)
                    .background(isToday ? Circle().fill(highlightColor) : nil)
                
                // 體重
                if weight > 0 {
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Text("-")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.clear)
                }
                
                // 運動類型圖示
                if hasExercise && !exerciseType.isEmpty {
                    Text(ExerciseConfig.shared.emoji(for: exerciseType))
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text(" ")
                        .font(.system(size: 10))
                }
            }
            .padding(.vertical, 2)
            .frame(height: 62)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hasExercise ? softGreen : (isSelected ? highlightColor : Color.clear),
                        lineWidth: hasExercise ? 3 : (isSelected ? 2 : 0)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    var legendView: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(softGreen, lineWidth: 3)
                    .frame(width: 16, height: 16)
                Text("已運動")
            }
            .padding(8).background(Color.white).cornerRadius(15).shadow(radius: 1)
            
            HStack(spacing: 6) {
                Image(systemName: "scalemass").foregroundColor(.gray)
                Text("體重紀錄")
            }
            .padding(8).background(Color.white).cornerRadius(15).shadow(radius: 1)
            
            Button(action: {
                showTrendChart = true
            }) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.indigo)
                    .padding(10)
                    .background(Color.indigo.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
        }
        .font(.system(size: 12, design: .rounded))
        .foregroundColor(.gray)
        .padding(.bottom, 30)
    }
}

// 按鈕縮放特效
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
