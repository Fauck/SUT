import SwiftUI
import Combine

// MARK: - ViewModel (控制層)
class MeditationViewModel: ObservableObject {
    // 被 View 觀察的屬性 (@Published)
    @Published var timeRemaining: TimeInterval
    @Published var totalDuration: TimeInterval // 新增：紀錄總時間，用於計算進度或重置
    @Published var isActive = false
    @Published var isBreathing = false
    @Published var showCompletion = false
    
    let session: MeditationSession
    private var timer: AnyCancellable?
    
    init(session: MeditationSession) {
        self.session = session
        self.timeRemaining = session.duration
        self.totalDuration = session.duration
    }
    
    // MARK: - 用戶意圖 (User Intents)
    
    // 用戶修改倒數時間
    func updateDuration(_ seconds: TimeInterval) {
        guard !isActive else { return } // 只有在暫停或未開始時允許修改
        self.timeRemaining = seconds
        self.totalDuration = seconds
        HapticManager.shared.impact(style: .light)
    }
    
    // 用戶點擊播放/暫停
    func toggleSession() {
        HapticManager.shared.impact(style: .medium)
        isActive.toggle()
        
        if isActive {
            startTimer()
            isBreathing = true
            SoundManager.shared.playStart()
            UIApplication.shared.isIdleTimerDisabled = true // 保持螢幕常亮
        } else {
            stopTimer()
            isBreathing = false
            SoundManager.shared.playPause()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - 內部邏輯 (Internal Logic)
    
    private func startTimer() {
        // 防止重複建立 Timer
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    // 每一秒觸發的邏輯
    private func tick() {
        guard isActive else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
            // 呼吸引導震動 (每 4 秒一次)
            if Int(timeRemaining) % 4 == 0 {
                HapticManager.shared.impact(style: .light)
            }
        } else {
            finishSession()
        }
    }
    
    // 結束邏輯
    private func finishSession() {
        isActive = false
        isBreathing = false
        stopTimer()
        
        // 觸發結束反饋
        HapticManager.shared.notification(type: .success)
        SoundManager.shared.playComplete() // 這裡會播放結束音效
        
        showCompletion = true
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // 格式化時間字串
    func formattedTime() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 清理資源
    deinit {
        stopTimer()
    }
}
