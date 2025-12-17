import SwiftUI
import Charts // 需要 iOS 16+

struct WeightTrendView: View {
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) var dismiss
    
    // 計算屬性：取得當月有體重紀錄的資料，並按日期排序
    var chartData: [DailyRecord] {
        let calendar = Calendar.current
        // 從 ViewModel 的字典中過濾
        // 1. 確保日期屬於當前月份
        // 2. 確保體重 > 0
        let currentMonthRecords = viewModel.records.values.filter { record in
            guard let date = record.date, record.weight > 0 else { return false }
            return calendar.isDate(date, equalTo: viewModel.currentMonth, toGranularity: .month)
        }
        // 3. 按日期排序
        return currentMonthRecords.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }
    
    // 計算 Y 軸的範圍 (讓曲線不要貼底，上下保留一點空間)
    var yAxisDomain: ClosedRange<Double> {
        let weights = chartData.map { $0.weight }
        guard let min = weights.min(), let max = weights.max() else { return 0...100 }
        return (min - 2)...(max + 2)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                if chartData.isEmpty {
                    emptyStateView
                } else {
                    chartView
                }
            }
            .padding()
            .navigationTitle("本月體重趨勢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 修改：將關閉按鈕移至左側 (Leading)，避免與右側的「最新紀錄」重疊
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
            }
        }
    }
    
    // MARK: - 圖表組件
    var chartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 統計摘要
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading) {
                    Text("平均體重")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let avg = chartData.map(\.weight).reduce(0, +) / Double(chartData.count)
                    Text(String(format: "%.1f", avg))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                Text("kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 顯示最新一筆 (靠右對齊，現在上方不會有關閉按鈕了)
                if let last = chartData.last {
                    VStack(alignment: .trailing) {
                        Text("最新紀錄")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", last.weight))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // 核心圖表
            Chart {
                ForEach(chartData) { record in
                    if let date = record.date {
                        // 線條
                        LineMark(
                            x: .value("日期", date, unit: .day),
                            y: .value("體重", record.weight)
                        )
                        .interpolationMethod(.catmullRom) // 平滑曲線
                        .foregroundStyle(Color.blue.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        // 資料點
                        PointMark(
                            x: .value("日期", date, unit: .day),
                            y: .value("體重", record.weight)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(40)
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", record.weight))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisDomain) // 動態設定 Y 軸範圍
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        let day = Calendar.current.component(.day, from: date)
                        // 修改：只顯示 1, 5, 10, 15, 20, 30 這幾天的標籤與網格線
                        if [1, 5, 10, 15, 20, 30].contains(day) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.day())
                        }
                    }
                }
            }
            .frame(height: 300)
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - 空狀態
    var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            Text("本月尚無體重紀錄")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("請點擊日曆上的日期來新增資料")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
    }
}
