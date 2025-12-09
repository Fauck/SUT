import SwiftUI

// MARK: - 播放畫面 (Player View)
struct PlayerView: View {
    @StateObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(gradient: Gradient(colors: [viewModel.session.color.opacity(0.4), .white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // 標題
                VStack(spacing: 12) {
                    Text(viewModel.session.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text(viewModel.session.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 動畫區 (根據 ViewModel 狀態改變)
                ZStack {
                    // 呼吸光暈
                    Circle()
                        .fill(viewModel.session.color.opacity(0.3))
                        .frame(width: 280, height: 280)
                        .scaleEffect(viewModel.isBreathing ? 1.2 : 0.85)
                        .animation(
                            viewModel.isActive ? Animation.easeInOut(duration: 4).repeatForever(autoreverses: true) : .default,
                            value: viewModel.isBreathing
                        )
                    
                    // 核心圓圈
                    Circle()
                        .fill(Material.ultraThinMaterial)
                        .frame(width: 220, height: 220)
                        .shadow(color: viewModel.session.color.opacity(0.3), radius: 20, x: 0, y: 10)
                        .overlay(Circle().stroke(viewModel.session.color.opacity(0.5), lineWidth: 1))
                    
                    // 時間顯示 (改為可點擊的選單)
                    Menu {
                        Text("設定時間")
                        Button("1 分鐘") { viewModel.updateDuration(60) }
                        Button("3 分鐘") { viewModel.updateDuration(180) }
                        Button("5 分鐘") { viewModel.updateDuration(300) }
                        Button("10 分鐘") { viewModel.updateDuration(600) }
                        Button("15 分鐘") { viewModel.updateDuration(900) }
                        Button("20 分鐘") { viewModel.updateDuration(1200) }
                        Button("30 分鐘") { viewModel.updateDuration(1800) }
                    } label: {
                        VStack(spacing: 0) {
                            Text(viewModel.formattedTime())
                                .font(.system(size: 48, weight: .medium).monospacedDigit())
                                .foregroundColor(viewModel.session.color)
                                .contentTransition(.numericText())
                            
                            if !viewModel.isActive {
                                Text("點擊修改")
                                    .font(.caption)
                                    .foregroundColor(viewModel.session.color.opacity(0.6))
                                    .padding(.top, 5)
                            }
                        }
                    }
                    .disabled(viewModel.isActive) // 開始計時後鎖定修改功能
                }
                
                Spacer()
                
                // 控制按鈕
                HStack(spacing: 60) {
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    Button {
                        viewModel.toggleSession()
                    } label: {
                        Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(viewModel.session.color)
                            .clipShape(Circle())
                            .shadow(color: viewModel.session.color.opacity(0.4), radius: 10, x: 0, y: 10)
                            .scaleEffect(viewModel.isActive ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isActive)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $viewModel.showCompletion) {
            CompletionView(session: viewModel.session) {
                dismiss()
            }
        }
        .onDisappear {
            if viewModel.isActive { viewModel.toggleSession() }
        }
        // 隱藏 TabBar，當進入播放畫面時，避免底部太雜亂
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
    }
}

// MARK: - 完成畫面 (Completion View)
struct CompletionView: View {
    let session: MeditationSession
    let onDismiss: () -> Void
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 30) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(session.color)
                    .scaleEffect(appearAnimation ? 1.0 : 0.5)
                    .opacity(appearAnimation ? 1.0 : 0.0)
                
                VStack(spacing: 10) {
                    Text("練習完成")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("做得好！你已經完成了\n\(session.title)")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .opacity(appearAnimation ? 1.0 : 0.0)
                .offset(y: appearAnimation ? 0 : 20)
                Spacer()
                Button(action: onDismiss) {
                    Text("完成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(session.color)
                        .cornerRadius(15)
                        .shadow(color: session.color.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                .opacity(appearAnimation ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
}
