import SwiftUI

// 新增：定義計算結果的資料模型 (必須遵循 Identifiable 以便用於 Sheet)
struct MortgageResultData: Identifiable {
    let id = UUID()
    let loanAmount: Double
    let downPayment: Double
    let totalInterest: Double
    let paymentDuringGrace: Double
    let paymentAfterGrace: Double
    let paymentNoGrace: Double
    let gracePeriod: String
}

struct MortgageCalculatorView: View {
    // MARK: - 輸入變數
    @State private var totalPrice: String = ""       // 房屋總價 (萬)
    @State private var downPayment: String = ""      // 頭期款 (萬)
    @State private var loanRatio: String = "85"      // 貸款成數 (%)
    @State private var loanYears: String = "30"      // 貸款年數
    @State private var interestRate: String = "2.00" // 年利率 (%)
    @State private var gracePeriod: String = "5"     // 寬限期 (年)
    
    // MARK: - 計算結果狀態
    // 修改：使用單一 Optional 物件來控制 Sheet 的顯示與資料傳遞
    // 當此變數被賦值時，Sheet 會自動彈出；設為 nil 時，Sheet 關閉
    @State private var calculationResult: MortgageResultData?
    
    // 鍵盤焦點控制
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // 輸入區塊
                Section(header: Text("貸款資訊")) {
                    inputRow(title: "房屋總價 (萬元)", placeholder: "請輸入總價", text: $totalPrice)
                    inputRow(title: "頭期款 (萬元)", placeholder: "選填，優先採用", text: $downPayment)
                    inputRow(title: "貸款成數 (%)", placeholder: "例如 80", text: $loanRatio)
                    inputRow(title: "貸款年數 (年)", placeholder: "例如 30", text: $loanYears)
                    inputRow(title: "年利率 (%)", placeholder: "例如 2.06", text: $interestRate)
                    
                    // 寬限期輸入 (限制 0-5 年)
                    HStack {
                        Text("寬限期 (年)")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("最多 5 年", text: $gracePeriod)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isInputFocused)
                            .onChange(of: gracePeriod) { newValue in
                                if let years = Int(newValue), years > 5 {
                                    gracePeriod = "5"
                                }
                            }
                    }
                    Text("寬限期內只繳利息，不還本金 (上限5年)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 計算按鈕
                Section {
                    Button(action: calculateMortgage) {
                        HStack {
                            Spacer()
                            Text("開始試算")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.indigo)
                }
            }
            .navigationTitle("房貸試算")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputFocused = false
                    }
                }
            }
            // 修改：使用 item 而非 isPresented，確保資料傳遞正確
            .sheet(item: $calculationResult) { result in
                MortgageResultView(data: result)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            // 連動：輸入頭期款自動反推成數
            .onChange(of: downPayment) { newValue in
                if let price = Double(totalPrice), let down = Double(newValue), price > 0 {
                    let ratio = ((price - down) / price) * 100
                    loanRatio = String(format: "%.0f", ratio)
                }
            }
        }
    }
    
    // MARK: - 自定義輸入列
    private func inputRow(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($isInputFocused)
        }
    }
    
    // MARK: - 計算邏輯
    func calculateMortgage() {
        isInputFocused = false
        
        guard let priceWan = Double(totalPrice),
              let years = Double(loanYears),
              let ratePercent = Double(interestRate) else { return }
        
        let graceYears = Double(gracePeriod) ?? 0
        
        // 1. 計算貸款總額 (萬)
        let loanAmountWan: Double
        let finalDownPayment: Double
        
        if let inputDown = Double(downPayment), inputDown < priceWan {
            finalDownPayment = inputDown
            loanAmountWan = priceWan - inputDown
        } else {
            let ratio = Double(loanRatio) ?? 80
            loanAmountWan = priceWan * (ratio / 100)
            finalDownPayment = priceWan - loanAmountWan
        }
        
        let loanAmount = loanAmountWan * 10000
        let monthRate = (ratePercent / 100) / 12
        let totalMonths = years * 12
        let graceMonths = graceYears * 12
        
        // --- 計算 A: 不使用寬限期 (本息平均攤還) ---
        let noGracePMT = calculatePMT(principal: loanAmount, monthRate: monthRate, totalMonths: totalMonths)
        
        // --- 計算 B: 使用寬限期 ---
        // 1. 寬限期內 (只繳息)
        let duringGracePMT = loanAmount * monthRate
        
        // 2. 寬限期後 (本息攤還，年限變短)
        let remainingMonths = totalMonths - graceMonths
        let afterGracePMT: Double
        
        if remainingMonths > 0 {
            afterGracePMT = calculatePMT(principal: loanAmount, monthRate: monthRate, totalMonths: remainingMonths)
        } else {
            afterGracePMT = 0
        }
        
        // --- 總利息計算 ---
        let totalPayment: Double
        if graceYears > 0 {
            let gracePeriodTotal = duringGracePMT * graceMonths
            let afterGraceTotal = afterGracePMT * remainingMonths
            totalPayment = gracePeriodTotal + afterGraceTotal
        } else {
            totalPayment = noGracePMT * totalMonths
        }
        let totalInterest = totalPayment - loanAmount
        
        // 修改：打包結果並賦值給 calculationResult，這會觸發 Sheet 顯示
        let result = MortgageResultData(
            loanAmount: loanAmountWan,
            downPayment: finalDownPayment,
            totalInterest: totalInterest,
            paymentDuringGrace: graceYears > 0 ? duringGracePMT : 0,
            paymentAfterGrace: graceYears > 0 ? afterGracePMT : 0,
            paymentNoGrace: noGracePMT,
            gracePeriod: gracePeriod
        )
        
        withAnimation {
            calculationResult = result
        }
    }
    
    func calculatePMT(principal: Double, monthRate: Double, totalMonths: Double) -> Double {
        if monthRate == 0 {
            return principal / totalMonths
        }
        let power = pow(1 + monthRate, totalMonths)
        return principal * (monthRate * power) / (power - 1)
    }
}

// MARK: - 獨立的結果視圖 (Sheet)
struct MortgageResultView: View {
    @Environment(\.dismiss) var dismiss
    
    // 修改：直接接收打包好的資料模型
    let data: MortgageResultData
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("資金規劃概覽")) {
                    ResultRow(title: "自備頭期款", value: formatCurrency(data.downPayment, suffix: "萬元"))
                    ResultRow(title: "貸款總額", value: formatCurrency(data.loanAmount, suffix: "萬元"))
                    ResultRow(title: "總利息支出", value: formatCurrency(data.totalInterest, suffix: "元"))
                }
                
                Section(header: Text("每月還款分析")) {
                    if data.paymentDuringGrace > 0 {
                        // 有使用寬限期的情況
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                Text("方案 A：使用 \(data.gracePeriod) 年寬限期")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            ResultRow(title: "• 寬限期內 (只繳息)", value: formatCurrency(data.paymentDuringGrace, suffix: "元"))
                                .foregroundColor(.green)
                            ResultRow(title: "• 寬限期後 (本息攤)", value: formatCurrency(data.paymentAfterGrace, suffix: "元"))
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("方案 B：不使用寬限期")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            ResultRow(title: "• 每月平均繳款", value: formatCurrency(data.paymentNoGrace, suffix: "元"))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        
                    } else {
                        // 沒有使用寬限期
                        ResultRow(title: "每月平均繳款", value: formatCurrency(data.paymentNoGrace, suffix: "元"))
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("試算結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func formatCurrency(_ value: Double, suffix: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: value)) ?? "0") + " " + suffix
    }
}

// 共用的結果列組件
struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
