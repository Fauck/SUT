import SwiftUI

// MARK: - 主畫面：健康記錄日曆
struct HealthRecordView: View {
    @StateObject private var viewModel = HealthViewModel()
    @State private var selectedDate: Date? = nil
    @State private var showEditSheet = false
    
    // UI 配色
    // 將原本的粉紅色改為柔和的藍色作為選中/今日的強調色
    let highlightColor = Color.blue.opacity(0.8)
    let bgColor = Color(red: 0.98, green: 0.98, blue: 0.99)
    // 柔和綠色 (用於運動邊框) - 保留
    let softGreen = Color(red: 0.5, green: 0.85, blue: 0.5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // --- 月份切換標頭 ---
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
                    
                    // --- 日曆主體 ---
                    VStack(spacing: 15) {
                        // 星期標頭
                        HStack {
                            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    // 修改週末的顏色，不再使用粉紅色
                                    .foregroundColor(day == "日" || day == "六" ? .gray : .gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // 日期網格
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                            ForEach(0..<viewModel.offsetDays, id: \.self) { _ in
                                Text("").frame(maxWidth: .infinity)
                            }
                            
                            ForEach(viewModel.daysInMonth, id: \.self) { date in
                                dayCell(for: date)
                            }
                        }
                    }
                    .padding()
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // --- 底部圖例說明 ---
                    legendView
                }
            }
            .navigationTitle("健康記錄")
            .sheet(isPresented: $showEditSheet) {
                if let date = selectedDate {
                    RecordEditView(date: date, viewModel: viewModel)
                        .presentationDetents([.height(350)])
                        .presentationCornerRadius(30)
                }
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
        
        // 直接使用 DailyRecord 的屬性
        let weight = record?.weight ?? 0.0
        let hasExercise = record?.hasExercise ?? false
        
        return Button {
            selectedDate = date
            showEditSheet = true
        } label: {
            VStack(spacing: 2) { // 縮小內部間距
                // 1. 日期：縮小並置頂
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(isToday ? .white : .gray.opacity(0.7))
                    .frame(width: 20, height: 20) // 稍微縮小日期圓圈
                    .background(isToday ? Circle().fill(highlightColor) : nil)
                
                // 2. 體重：變大並加粗 (取代原本的星星位置)
                if weight > 0 {
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 16, weight: .black, design: .rounded)) // 字體微調適配高度
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(1) // 強制單行顯示，不折行
                        .minimumScaleFactor(0.6) // 空間不足時自動縮小字體
                } else {
                    // 佔位符保持版面高度一致
                    Text("-")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.clear)
                }
            }
            .padding(.vertical, 4)
            .frame(height: 60) // 高度從 75 減小到 60
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
            // 3. 邊框邏輯：有運動顯示綠框，被選中顯示強調色框 (運動優先顯示，或者兩者共存)
            // 這裡設定：若有運動，顯示柔和綠框；若僅被選中，顯示強調色框
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
            // 更新圖例：綠色框框代表已運動
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
