import SwiftUI

// MARK: - 主應用程式入口 (Main Tab View)
struct ContentView: View {
    init() {
        // 設定導航欄外觀 (透明背景)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        
        // 設定 TabBar 外觀 (避免內容重疊時看不清楚)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some View {
        TabView {
            // 第一個 Tab：首頁
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
            
            // 第二個 Tab：房貸試算
            MortgageCalculatorView()
                .tabItem {
                    Label("房貸試算", image: "home")
                }
            
            // 第三個 Tab：健康記錄 (原 設定)
            HealthRecordView()
                .tabItem {
                    Label("健康記錄", systemImage: "heart.text.square.fill")
                }
        }
        .accentColor(.indigo) // 設定 TabBar 選中顏色
    }
}

// MARK: - 首頁視圖 (Home View - 原 ContentView)
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("歡迎回來，")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("今天想練習什麼？")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    LazyVStack(spacing: 20) {
                        ForEach(sampleSessions) { session in
                            // 初始化 ViewModel 並傳入 View
                            NavigationLink(destination: PlayerView(viewModel: MeditationViewModel(session: session))) {
                                SessionCard(session: session)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 卡片組件 (Components)
struct SessionCard: View {
    let session: MeditationSession
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(session.color.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: session.icon)
                    .font(.title)
                    .foregroundColor(session.color)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(session.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(Int(session.duration / 60)) 分鐘 • 指引冥想")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.largeTitle)
                .foregroundColor(session.color.opacity(0.8))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}
