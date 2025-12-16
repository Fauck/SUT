import SwiftUI

struct MortgageCalculatorView: View {
    // MARK: - 輸入變數
    @State private var totalPrice: String = ""       // 房屋總價 (萬)
    @State private var downPayment: String = ""      // 新增：頭期款 (萬)
    @State private var loanRatio: String = "80"      // 貸款成數 (%)
    @State private var loanYears: String = "30"      // 貸款年數
    @State private var interestRate: String = "2.06" // 年利率 (%)
    
    // MARK: - 計算結果
    @State private var resultLoanAmount: Double = 0
    @State private var resultTotalInterest: Double = 0
    @State private var resultMonthlyPayment: Double = 0
    @State private var resultDownPayment: Double = 0 // 新增：顯示最終頭期款
    @State private var showResult = false
    
    // 鍵盤焦點控制
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // 輸入區塊
                Section(header: Text("貸款資訊")) {
                    inputRow(title: "房屋總價 (萬元)", placeholder: "請輸入總價", text: $totalPrice)
                    
                    // 新增：頭期款輸入
                    inputRow(title: "頭期款 (萬元)", placeholder: "選填，若輸入將優先採用", text: $downPayment)
                    
                    inputRow(title: "貸款成數 (%)", placeholder: "例如 80", text: $loanRatio)
                    inputRow(title: "貸款年數 (年)", placeholder: "例如 30", text: $loanYears)
                    inputRow(title: "年利率 (%)", placeholder: "例如 2.06", text: $interestRate)
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
                
                // 結果顯示區塊
                if showResult {
                    Section(header: Text("試算結果 (本息平均攤還)")) {
                        // 新增：顯示自備款
                        ResultRow(title: "自備頭期款", value: formatCurrency(resultDownPayment, suffix: "萬元"))
                        ResultRow(title: "貸款總額", value: formatCurrency(resultLoanAmount, suffix: "萬元"))
                        ResultRow(title: "每月還款", value: formatCurrency(resultMonthlyPayment, suffix: "元"))
                        ResultRow(title: "利息總額", value: formatCurrency(resultTotalInterest, suffix: "元"))
                    }
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
            // 新增：當使用者輸入頭期款時，自動反推成數（提升 UX）
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
    
    // MARK: - 計算邏輯 (本息平均攤還法)
    func calculateMortgage() {
        isInputFocused = false // 收起鍵盤
        
        // 1. 基礎防呆：總價與年利率必須有值
        guard let priceWan = Double(totalPrice),
              let years = Double(loanYears),
              let ratePercent = Double(interestRate) else { return }
        
        // 2. 決定貸款金額 (優先使用頭期款)
        let loanAmountWan: Double
        let finalDownPayment: Double
        
        if let inputDown = Double(downPayment), inputDown < priceWan {
            // 情境 A: 使用者有輸入頭期款
            finalDownPayment = inputDown
            loanAmountWan = priceWan - inputDown
        } else {
            // 情境 B: 使用者沒輸入頭期款 (或輸入不合理)，改用成數計算
            let ratio = Double(loanRatio) ?? 80
            loanAmountWan = priceWan * (ratio / 100)
            finalDownPayment = priceWan - loanAmountWan
        }
        
        // 轉換為實際金額 (元) 與月利率
        let loanAmount = loanAmountWan * 10000
        let monthRate = (ratePercent / 100) / 12
        let totalMonths = years * 12
        
        // 3. 本息平均攤還公式
        let power = pow(1 + monthRate, totalMonths)
        
        let monthlyPayment: Double
        if ratePercent == 0 {
            monthlyPayment = loanAmount / totalMonths
        } else {
            monthlyPayment = loanAmount * (monthRate * power) / (power - 1)
        }
        
        let totalPayment = monthlyPayment * totalMonths
        let totalInterest = totalPayment - loanAmount
        
        // 4. 更新結果狀態
        withAnimation {
            resultDownPayment = finalDownPayment // 更新顯示用的頭期款
            resultLoanAmount = loanAmountWan
            resultMonthlyPayment = monthlyPayment
            resultTotalInterest = totalInterest
            showResult = true
        }
    }
    
    // 格式化數字顯示
    func formatCurrency(_ value: Double, suffix: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: value)) ?? "0") + " " + suffix
    }
}

// 結果列組件
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
                .foregroundColor(.indigo)
        }
    }
}

struct MortgageCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        MortgageCalculatorView()
    }
}
