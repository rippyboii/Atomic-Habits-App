import SwiftUI
import Charts

struct Dashboard4View: View {
    // For light/dark mode checking (like DashboardView)
    @Environment(\.colorScheme) var colorScheme

    // MARK: - State Variables
    @State private var isBalanceBreakdownPresented = false
    @State private var selectedTab = 0

    @State private var balanceBreakdown = [
        "Bank": 1500.0,
        "WeChat": 500.0,
        "Alipay": 300.0,
        "Cash": 200.0,
        "Others": 100.0
    ]

    // Store all transactions
    @State private var transactions: [Transaction] = []

    // For logging new transactions
    @State private var isLoggingTransaction = false
    @State private var transactionType: TransactionType = .expenditure
    @State private var transactionAmount: String = ""
    @State private var transactionMethod: PaymentMethod = .bank

    // For editing
    @State private var isEditingMode = false
    @State private var isEditViewPresented = false

    // MARK: - Data Model
    enum TransactionType: String {
        case income = "Income"
        case expenditure = "Expenditure"
    }

    enum PaymentMethod: String, CaseIterable {
        case bank = "Bank"
        case wechat = "WeChat"
        case alipay = "Alipay"
        case cash = "Cash"
        case others = "Others"
    }

    struct Transaction: Identifiable {
        let id = UUID()
        let type: TransactionType
        var amount: Double
        var method: PaymentMethod
        let date: Date
        var note: String
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
                .overlay(Material.regular.opacity(0.7))

            ScrollView {
                VStack(spacing: 30) {
                    balanceHeader
                    transactionTabs
                    transactionList
                    spendingGraph
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }

            floatingActionButtons
        }
        .sheet(isPresented: $isLoggingTransaction) {
            LogTransactionView(
                transactionType: transactionType,
                transactionAmount: $transactionAmount,
                transactionMethod: $transactionMethod,
                balanceBreakdown: $balanceBreakdown,
                transactions: $transactions
            )
        }
        .sheet(isPresented: $isBalanceBreakdownPresented) {
            BalanceBreakdownView(balanceBreakdown: $balanceBreakdown)
        }
        .sheet(isPresented: $isEditViewPresented) {
            // Use our new custom EditTransactionView here
            EditTransactionView(
                balanceBreakdown: $balanceBreakdown,
                transactions: $transactions
            )
        }
    }

    // MARK: - Computed Property: Filtered Transactions
    var filteredTransactions: [Transaction] {
        switch selectedTab {
        case 0:
            // Expenditures only
            return transactions.filter { $0.type == .expenditure }
        case 1:
            // Incomes only
            return transactions.filter { $0.type == .income }
        default:
            // All transactions
            return transactions
        }
    }

    // MARK: - UI Components

    // 1) Balance Header
    private var balanceHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 10)

            VStack(alignment: .leading, spacing: 5) {
                Text("Current Overall Balance")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Button(action: {
                    isBalanceBreakdownPresented.toggle()
                }) {
                    Text("¥\(balanceBreakdown.values.reduce(0, +), specifier: "%.2f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .frame(height: 150)
    }

    // 2) Transaction Tabs
    private var transactionTabs: some View {
        HStack {
            tabButton(title: "Expenditures", tag: 0)
            tabButton(title: "Incomes", tag: 1)
            tabButton(title: "All", tag: 2)
        }
        .padding(8)
        .background(
            Capsule().fill(Color.gray.opacity(0.2))
        )
    }

    private func tabButton(title: String, tag: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tag
            }
        }) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule().fill(selectedTab == tag ? Color.blue : Color.clear)
                )
        }
        .foregroundColor(selectedTab == tag ? .white : .primary)
    }

    // 3) Transaction List
    private var transactionList: some View {
        VStack(spacing: 15) {
            ForEach(filteredTransactions) { transaction in
                if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                    TransactionRow(
                        transaction: $transactions[index],
                        isEditingMode: $isEditingMode
                    ) {
                        deleteTransaction(at: index)
                    }
                }
            }
        }
    }

    // 4) Spending Graph
    private var spendingGraph: some View {
        VStack(alignment: .leading) {
            Text("Spending Graph")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 5)

            LineChartView(transactions: transactions)
                .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // 5) Floating Action Buttons
    private var floatingActionButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                Button(action: {
                    transactionType = .expenditure
                    isLoggingTransaction.toggle()
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
                .padding(.trailing, 10)

                Button(action: {
                    transactionType = .income
                    isLoggingTransaction.toggle()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
                .padding(.trailing, 10)

                Button(action: {
                    isEditViewPresented.toggle()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Functions
    private func deleteTransaction(at index: Int) {
        let transaction = transactions[index]
        if transaction.type == .income {
            balanceBreakdown[transaction.method.rawValue, default: 0] -= transaction.amount
        } else {
            balanceBreakdown[transaction.method.rawValue, default: 0] += transaction.amount
        }
        transactions.remove(at: index)
    }
}

// MARK: - Balance Breakdown View
struct BalanceBreakdownView: View {
    @Binding var balanceBreakdown: [String: Double]

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Balance Breakdown")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 40)

                ForEach(balanceBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("¥\(value, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Log Transaction View
struct LogTransactionView: View {
    let transactionType: Dashboard4View.TransactionType
    @Binding var transactionAmount: String
    @Binding var transactionMethod: Dashboard4View.PaymentMethod
    @Binding var balanceBreakdown: [String: Double]
    @Binding var transactions: [Dashboard4View.Transaction]

    @State private var note: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(transactionType == .income ? "Log Income" : "Log Expenditure")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                TextField("Amount (¥)", text: $transactionAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)

                Picker("Payment Method", selection: $transactionMethod) {
                    ForEach(Dashboard4View.PaymentMethod.allCases, id: \.self) { method in
                        Text(method.rawValue)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .labelsHidden()
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)

                if let amount = Double(transactionAmount), amount > 20 {
                    VStack(alignment: .leading) {
                        Text("Please provide a note (required for amount > 20):")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        TextField("Where did you spend/get it?", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(5)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .leading) {
                        Text("Note (optional):")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        TextField("Where did you spend/get it?", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(5)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    validateAndSaveTransaction()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(transactionType == .income ? Color.green : Color.red)
                        .cornerRadius(12)
                }
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func validateAndSaveTransaction() {
        guard let amount = Double(transactionAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount."
            showAlert = true
            return
        }

        if amount > 20 && note.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "A note is required for amounts over 20."
            showAlert = true
            return
        }

        let newTransaction = Dashboard4View.Transaction(
            type: transactionType,
            amount: amount,
            method: transactionMethod,
            date: Date(),
            note: note
        )

        if transactionType == .income {
            balanceBreakdown[transactionMethod.rawValue, default: 0] += amount
        } else {
            balanceBreakdown[transactionMethod.rawValue, default: 0] -= amount
        }

        transactions.insert(newTransaction, at: 0)
        transactionAmount = ""
        note = ""
    }
}

// MARK: - Updated Edit Transaction View
struct EditTransactionView: View {
    @Binding var balanceBreakdown: [String: Double]
    @Binding var transactions: [Dashboard4View.Transaction]
    @Environment(\.dismiss) var dismiss

    // Create a binding for a wallet amount (formatted as a String)
    private func binding(for wallet: String) -> Binding<String> {
        Binding(
            get: {
                String(format: "%.2f", balanceBreakdown[wallet, default: 0])
            },
            set: { newValue in
                if let value = Double(newValue) {
                    balanceBreakdown[wallet] = value
                }
            }
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                // Top section: Edit Wallet Amounts
                VStack(alignment: .leading, spacing: 15) {
                    Text("Edit Wallet Amounts")
                        .font(.headline)
                        .foregroundColor(.white)
                    ForEach(Dashboard4View.PaymentMethod.allCases, id: \.rawValue) { method in
                        HStack {
                            Text(method.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            TextField("", text: binding(for: method.rawValue))
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                )
                .padding(.horizontal)

                Divider()
                    .padding()

                // Bottom section: List of Transactions with Swipe-to-Delete
                List {
                    ForEach(transactions) { transaction in
                        TransactionRowPreview(transaction: transaction)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                                        deleteTransaction(at: index)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.black.opacity(0.8))
            }
            .navigationTitle("Edit Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color.black.opacity(0.8).ignoresSafeArea())
        }
    }

    /// Revert the effect of a transaction and remove it.
    private func deleteTransaction(at index: Int) {
        let transaction = transactions[index]
        if transaction.type == .income {
            balanceBreakdown[transaction.method.rawValue, default: 0] -= transaction.amount
        } else {
            balanceBreakdown[transaction.method.rawValue, default: 0] += transaction.amount
        }
        transactions.remove(at: index)
    }
}

// MARK: - Helper: Read-Only Transaction Row for Edit View
struct TransactionRowPreview: View {
    let transaction: Dashboard4View.Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label {
                    Text(transaction.method.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "yensign.circle.fill")
                        .foregroundColor(.white)
                }
                Spacer()
                HStack {
                    Text(transaction.type == .income ? "+¥" : "-¥")
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    Text(String(format: "%.2f", transaction.amount))
                        .font(.body)
                        .foregroundColor(.white)
                }
            }
            HStack {
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                if !transaction.note.isEmpty {
                    Text("Note: \(transaction.note)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
    }
}

// MARK: - Transaction Row (Used in Main View)
struct TransactionRow: View {
    @Binding var transaction: Dashboard4View.Transaction
    @Binding var isEditingMode: Bool
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label {
                    Text(transaction.method.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "yensign.circle.fill")
                        .foregroundColor(.white)
                }
                Spacer()
                if isEditingMode {
                    TextField(
                        "Amount",
                        value: $transaction.amount,
                        formatter: NumberFormatter()
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                } else {
                    HStack {
                        Text(transaction.type == .income ? "+¥" : "-¥")
                            .foregroundColor(transaction.type == .income ? .green : .red)
                        Text(String(format: "%.2f", transaction.amount))
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
            HStack {
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                if !transaction.note.isEmpty {
                    Text("Note: \(transaction.note)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
        .overlay(
            Group {
                if isEditingMode {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        )
    }
}

// MARK: - Placeholder Line Chart
struct LineChartView: View {
    let transactions: [Dashboard4View.Transaction]

    var body: some View {
        Text("Swift Charts Placeholder")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview {
    Dashboard4View()
}
