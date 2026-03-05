import SwiftUI

// MARK: - 資料模型
struct Contraction: Identifiable, Codable {
    var id = UUID()
    let startTime: Date
    var endTime: Date?
    
    // 計算這次宮縮持續的時間
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
}

// MARK: - 視圖模型 (ViewModel)
class ContractionViewModel: ObservableObject {
    @Published var records: [Contraction] = []
    @Published var isTracking: Bool = false
    @Published var currentDuration: TimeInterval = 0
    
    private var timer: Timer?
    private let saveKey = "ContractionRecords"
    
    init() {
        loadRecords()
    }
    
    // 計算平均持續時間 (只計算已結束的宮縮)
    var averageDuration: TimeInterval? {
        let completedRecords = records.compactMap { $0.duration }
        guard !completedRecords.isEmpty else { return nil }
        let total = completedRecords.reduce(0, +)
        return total / Double(completedRecords.count)
    }
    
    // 計算平均間隔時間
    var averageInterval: TimeInterval? {
        var totalInterval: TimeInterval = 0
        var intervalCount = 0
        
        for i in 0..<records.count {
            if let interval = getInterval(for: i) {
                totalInterval += interval
                intervalCount += 1
            }
        }
        
        guard intervalCount > 0 else { return nil }
        return totalInterval / Double(intervalCount)
    }
    
    // 切換記錄狀態 (開始/停止)
    func toggleTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    private func startTracking() {
        isTracking = true
        let newRecord = Contraction(startTime: Date())
        // 將最新的一筆加在最前面
        records.insert(newRecord, at: 0)
        saveRecords()
        
        // 啟動即時計時器更新 UI
        currentDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.records.first?.startTime else { return }
            self.currentDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil
        
        // 更新第一筆記錄的結束時間
        if !records.isEmpty {
            records[0].endTime = Date()
            saveRecords()
        }
    }
    
    // 刪除單筆/多筆記錄
    func deleteRecords(at offsets: IndexSet) {
        if isTracking, offsets.contains(0) {
            stopTracking()
            records.remove(atOffsets: offsets)
        } else {
            records.remove(atOffsets: offsets)
        }
        saveRecords()
    }
    
    // 清除所有紀錄
    func clearAllRecords() {
        if isTracking {
            stopTracking()
        }
        records.removeAll()
        saveRecords()
    }
    
    // 計算與前一次宮縮的間隔時間
    func getInterval(for index: Int) -> TimeInterval? {
        guard index + 1 < records.count else { return nil }
        let currentStartTime = records[index].startTime
        let previousStartTime = records[index + 1].startTime
        return currentStartTime.timeIntervalSince(previousStartTime)
    }
    
    // MARK: - 資料持久化 (UserDefaults)
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Contraction].self, from: data) {
            self.records = decoded
            
            // 檢查是否有尚未結束的記錄
            if let first = records.first, first.endTime == nil {
                isTracking = true
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self, let startTime = self.records.first?.startTime else { return }
                    self.currentDuration = Date().timeIntervalSince(startTime)
                }
            }
        }
    }
}

// MARK: - 主視圖
struct ContractionTimerView: View {
    @StateObject private var viewModel = ContractionViewModel()
    @State private var showingClearAlert = false
    
    // 控制呼吸燈動畫的狀態
    @State private var pulseAnimation = false
    
    // 溫暖的自定義主題色
    let themeBg = Color.pink.opacity(0.06)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 全域溫柔背景色
                themeBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // --- 上半部：計時器與按鈕 ---
                    // 縮小間距以騰出更多空間給列表
                    VStack(spacing: 20) {
                        
                        // 計時器顯示區 (縮小尺寸)
                        ZStack {
                            if viewModel.isTracking {
                                Circle()
                                    .fill(Color.pink.opacity(0.15))
                                    .frame(width: 170, height: 170)
                                    .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                                    .onAppear { pulseAnimation = true }
                                    .onDisappear { pulseAnimation = false }
                            }
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 140, height: 140)
                                .shadow(color: Color.pink.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 2) {
                                Text(viewModel.isTracking ? "持續中" : "準備好囉")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(viewModel.isTracking ? .pink : .gray)
                                
                                Text(timeString(time: viewModel.isTracking ? viewModel.currentDuration : 0))
                                    .font(.system(size: 40, weight: .light, design: .rounded))
                                    .foregroundColor(viewModel.isTracking ? .pink : .primary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // 開始/停止大按鈕 (稍微降低高度)
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.toggleTracking()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isTracking ? "stop.fill" : "heart.fill")
                                    .font(.headline)
                                Text(viewModel.isTracking ? "停止記錄" : "開始宮縮")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: viewModel.isTracking ? [Color.red.opacity(0.8), Color.pink] : [Color.pink.opacity(0.8), Color.orange.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(26)
                            .shadow(color: (viewModel.isTracking ? Color.red : Color.pink).opacity(0.3), radius: 8, x: 0, y: 5)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 15)
                    
                    // --- 中段：統計平均時間區塊 ---
                    if !viewModel.records.isEmpty {
                        HStack(spacing: 12) {
                            StatBox(icon: "hourglass", title: "平均持續", time: viewModel.averageDuration, color: .pink)
                            StatBox(icon: "arrow.left.and.right", title: "平均間隔", time: viewModel.averageInterval, color: .orange)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                    
                    // --- 下半部：歷史紀錄列表 ---
                    List {
                        if viewModel.records.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.title)
                                    .foregroundColor(.pink.opacity(0.3))
                                Text("目前還沒有紀錄唷")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            
                        } else {
                            // 緊湊型的卡片列
                            ForEach(Array(viewModel.records.enumerated()), id: \.element.id) { index, record in
                                RecordRow(
                                    record: record,
                                    interval: viewModel.getInterval(for: index),
                                    isTracking: viewModel.isTracking && index == 0,
                                    currentDuration: viewModel.currentDuration
                                )
                                .padding(.vertical, 3)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete(perform: viewModel.deleteRecords)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("宮縮記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(viewModel.records.isEmpty ? .gray.opacity(0.5) : .red.opacity(0.7))
                    }
                    .disabled(viewModel.records.isEmpty)
                }
            }
            .alert("清除所有紀錄", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) { }
                Button("確定清除", role: .destructive) {
                    withAnimation {
                        viewModel.clearAllRecords()
                    }
                }
            } message: {
                Text("確定要清除所有的宮縮紀錄嗎？此動作無法復原。")
            }
        }
    }
    
    // 格式化時間 (MM:SS)
    private func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 統計小方塊視圖
struct StatBox: View {
    let icon: String
    let title: String
    let time: TimeInterval?
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                if let time = time, time > 0 {
                    Text(formatDuration(time))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分 \(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - 列表單行視圖 (緊湊版卡片)
struct RecordRow: View {
    let record: Contraction
    let interval: TimeInterval?
    let isTracking: Bool
    let currentDuration: TimeInterval
    
    var body: some View {
        HStack {
            // 左側：時間標籤
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isTracking ? Color.pink : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(formatDate(record.startTime))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                if isTracking {
                    Text("記錄中...")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.pink)
                        .padding(.leading, 12)
                }
            }
            .frame(width: 90, alignment: .leading)
            
            Spacer()
            
            // 中間：持續時間
            VStack(alignment: .center, spacing: 2) {
                Text("持續")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                if isTracking {
                    Text(formatDuration(currentDuration))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.pink)
                } else if let duration = record.duration {
                    Text(formatDuration(duration))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 80, alignment: .center)
            
            Spacer()
            
            // 右側：間隔時間
            VStack(alignment: .trailing, spacing: 2) {
                Text("間隔")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                if let interval = interval {
                    Text(formatDuration(interval))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
    
    // 格式化日期時間 (例如：14:30)
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 格式化持續時間
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒" // 拿掉空格更節省空間
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - 預覽
struct ContractionTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ContractionTimerView()
    }
}
