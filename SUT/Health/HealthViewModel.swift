//
//  Untitled.swift
//  SUT
//
//  Created by bokmacdev on 2025/12/10.
//
import SwiftUI
import CoreData
//// MARK: - 獨立的 Core Data 管理器
//class SimplePersistence {
//    static let shared = SimplePersistence()
//    let container: NSPersistentContainer
//    
//    // ⚠️ 請確認您的 Data Model 檔案名稱 (不含 .xcdatamodeld)
//    // 如果您的檔案名稱不同 (例如 Model.xcdatamodeld)，請在此修改
//    let containerName = "MeditationApp"
//
//    init() {
//        container = NSPersistentContainer(name: containerName)
//        container.loadPersistentStores { (storeDescription, error) in
//            if let error = error as NSError? {
//                print("❌ 資料庫載入失敗: \(error)")
//            } else {
//                print("✅ 資料庫載入成功")
//            }
//        }
//        // 自動合併策略，避免多執行緒衝突
//        container.viewContext.automaticallyMergesChangesFromParent = true
//        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//    }
//}
// MARK: - 4. ViewModel (邏輯核心)
class HealthViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    // 改回使用 [Date: DailyRecord]
    @Published var records: [Date: DailyRecord] = [:]
    
    private let calendar = Calendar.current
    private var context: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    // --- 日曆邏輯 ---
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 MM月"
        return formatter.string(from: currentMonth)
    }
    
    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
    }
    
    var offsetDays: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }
    
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
            fetchRecords()
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
    
    // --- Core Data 操作 ---
    
    func fetchRecords() {
        // 使用 DailyRecord 泛型
        let request = NSFetchRequest<DailyRecord>(entityName: "DailyRecord")
        
        do {
            let results = try context.fetch(request)
            var newRecords: [Date: DailyRecord] = [:]
            
            for record in results {
                if let date = record.date {
                    let startOfDay = calendar.startOfDay(for: date)
                    newRecords[startOfDay] = record
                }
            }
            
            DispatchQueue.main.async {
                self.records = newRecords
            }
        } catch {
            print("❌ Fetch Error: \(error)")
        }
    }
    
    func getRecord(for date: Date) -> DailyRecord? {
        return records[calendar.startOfDay(for: date)]
    }
    
    func saveRecord(date: Date, weight: Double, hasExercise: Bool) {
        let startOfDay = calendar.startOfDay(for: date)
        
        let record: DailyRecord
        if let existing = records[startOfDay] {
            record = existing
        } else {
            // 直接初始化 DailyRecord
            record = DailyRecord(context: context)
            record.date = startOfDay
        }
        
        record.weight = weight
        record.hasExercise = hasExercise
        
        do {
            try context.save()
            fetchRecords()
        } catch {
            print("❌ Save Error: \(error)")
        }
    }
}
