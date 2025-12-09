import SwiftUI

// MARK: - Meditation Model
struct MeditationSession: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let duration: TimeInterval // 秒數
}

// 模擬資料數據庫
let sampleSessions = [
    MeditationSession(title: "晨間喚醒", description: "用 5 分鐘的正念呼吸開始新的一天", icon: "sun.max.fill", color: .orange, duration: 300),
    MeditationSession(title: "深度放鬆", description: "釋放壓力，讓身心平靜下來", icon: "leaf.fill", color: .green, duration: 600),
    MeditationSession(title: "專注力提升", description: "為工作或學習做好準備", icon: "brain.head.profile", color: .blue, duration: 900),
    MeditationSession(title: "助眠冥想", description: "睡前放鬆，改善睡眠品質", icon: "moon.stars.fill", color: .indigo, duration: 1200)
]
