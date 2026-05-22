import SwiftUI
import CoreData

// MARK: - HealthViewModel (健康記錄邏輯核心)
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
        return AppFormatters.shared.monthYearFormatter.string(from: currentMonth)
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
        return AppFormatters.shared.fullDateFormatter.string(from: date)
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
    
    func saveRecord(date: Date, weight: Double, hasExercise: Bool, exerciseType: String = "", exerciseDuration: Double = 0) {
        let startOfDay = calendar.startOfDay(for: date)
        
        let record: DailyRecord
        if let existing = records[startOfDay] {
            record = existing
        } else {
            record = DailyRecord(context: context)
            record.date = startOfDay
        }
        
        record.weight = weight
        record.hasExercise = hasExercise
        record.exerciseType = exerciseType
        record.exerciseDuration = exerciseDuration
        
        do {
            try context.save()
            fetchRecords()
        } catch {
            print("❌ Save Error: \(error)")
        }
    }
}
