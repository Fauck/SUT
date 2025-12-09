import UIKit
import AVFoundation

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
