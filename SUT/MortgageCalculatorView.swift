import SwiftUI

struct MortgageCalculatorView: View {
    // MARK: - 輸入變數
    @State private var totalPrice: String = ""       // 房屋總價 (萬)
    @State private var loanRatio: String = "80"      // 貸款成數 (%)
    @State private var loanYears: String = "30"      // 貸款年數
    @State private var interestRate: String = "2.06" // 年利率 (%)
    
    // MARK: - 計算結果
    @State private var resultLoanAmount: Double = 0
    @State private var resultTotalInterest: Double = 0
    @State private var resultMonthlyPayment: Double = 0
    @State private var showResult = false
    
    // 鍵盤焦點控制
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // 輸入區塊
                Section(header: Text("貸款資訊")) {
                    inputRow(title: "房屋總價 (萬元)", placeholder: "請輸入總價", text: $totalPrice)
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
        
        // 1. 確保輸入轉型成功，否則返回
        guard let priceWan = Double(totalPrice),
              let ratio = Double(loanRatio),
              let years = Double(loanYears),
              let ratePercent = Double(interestRate) else { return }
        
        // 2. 基礎數據準備
        let loanAmountWan = priceWan * (ratio / 100)        // 貸款總額 (萬)
        let loanAmount = loanAmountWan * 10000              // 貸款總額 (元)
        let monthRate = (ratePercent / 100) / 12            // 月利率
        let totalMonths = years * 12                        // 總期數 (月)
        
        // 3. 本息平均攤還公式：PMT = P * [ r * (1+r)^n ] / [ (1+r)^n - 1 ]
        // P: 貸款本金, r: 月利率, n: 總月數
        
        let power = pow(1 + monthRate, totalMonths)
        
        // 每月還款金額 (若利率為 0 則直接除以月數)
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
