import SwiftUI

// MARK: - 主應用程式入口 (Main Tab View)
struct ContentView: View {
    init() {
        // 設定導航欄外觀 (透明背景)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        
        // 設定 TabBar 外觀
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some View {
        TabView {
            // 第一個 Tab：健康記錄 (首頁)
            HealthRecordView()
                .tabItem {
                    Label("健康記錄", systemImage: "heart.text.square.fill")
                }
            
            // 第二個 Tab：房貸試算
            MortgageCalculatorView()
                .tabItem {
                    Label("房貸試算", image: "home")
                }
        }
        .dismissKeyboardOnTap()
        .accentColor(.indigo)
    }
}

