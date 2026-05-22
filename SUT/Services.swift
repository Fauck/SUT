import UIKit
import AVFoundation
import SwiftUI

// MARK: - Haptic Service (觸覺回饋)
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Sound Service (音效管理)
class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    func playSound(soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    // 1004: Tock, 1003: Tink, 1022: Confirmation
    func playStart() { playSound(soundID: 1004) }
    func playPause() { playSound(soundID: 1003) }
    func playComplete() { playSound(soundID: 1022) }
}

// MARK: - App Formatters (共用格式化工具)
// 避免重複建立 DateFormatter / NumberFormatter，提升效能
class AppFormatters {
    static let shared = AppFormatters()
    
    private init() {}
    
    // 月份年份：「2025年 04月」
    lazy var monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年 MM月"
        return f
    }()
    
    // 完整日期（中文）：「2025年4月14日 星期一」
    lazy var fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.locale = Locale(identifier: "zh_TW")
        return f
    }()
    
    // 整數貨幣格式：「1,234,567」
    lazy var currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
    
    func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Exercise Config (運動類型設定)
// 統一管理運動類型選項與對應的 emoji 圖示
class ExerciseConfig {
    static let shared = ExerciseConfig()
    
    private init() {}
    
    // 所有可選的運動類型
    let types: [String] = ["跑步", "走路", "瑜伽", "游泳", "重訓", "騎車", "有氧", "球類", "其他"]
    
    // 運動類型對應的 emoji
    private let emojiMap: [String: String] = [
        "跑步": "🏃",
        "走路": "🚶",
        "瑜伽": "🧘",
        "游泳": "🏊",
        "重訓": "🏋️",
        "騎車": "🚴",
        "有氧": "💪",
        "球類": "⚽",
        "其他": "🏅"
    ]
    
    func emoji(for type: String) -> String {
        return emojiMap[type] ?? "✅"
    }
}

// MARK: - Keyboard Dismiss (鍵盤收起)
// 將 UITapGestureRecognizer 加到所在的 UIWindow 上
// cancelsTouchesInView = false 確保不攔截按鈕等互動元件
struct KeyboardDismissView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = KeyboardDismissUIView()
        view.backgroundColor = .clear
        // 需要等 view 被加入 window 後才能加手勢
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// 自動在加入 window 時安裝全域鍵盤收起手勢
private class KeyboardDismissUIView: UIView {
    private static var installedWindows = NSHashTable<UIWindow>.weakObjects()
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window,
              !KeyboardDismissUIView.installedWindows.contains(window) else { return }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        window.addGestureRecognizer(tap)
        KeyboardDismissUIView.installedWindows.add(window)
    }
    
    @objc private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

extension View {
    /// 點擊任意空白處收起鍵盤（不影響按鈕點擊）
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissView())
    }
}
