//
//  Dashboard4View.swift
//  YourApp
//

import SwiftUI
import Charts

struct Dashboard4View: View {
    // MARK: - Injected Properties
    let profile: Profile
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.colorScheme) var colorScheme

    // MARK: - State Variables
    @State private var isBalanceBreakdownPresented = false
    @State private var selectedTab = 0

    @State private var balanceBreakdown: [String: Double] = [
        "Bank": 1500.0,
        "WeChat": 500.0,
        "Alipay": 300.0,
        "Cash": 200.0,
        "Others": 100.0
    ]
    
    @State private var transactions: [Transaction] = []
    
    @State private var isLoggingTransaction = false
    @State private var transactionType: TransactionType = .expenditure
    @State private var transactionAmount: String = ""
    @State private var transactionMethod: PaymentMethod = .bank
    
    @State private var isEditingMode = false
    @State private var isEditViewPresented = false

    // Daily limit used for calculating saving status
    @State private var dailyExpenditureLimit: Double = 70.0
    @State private var isEditingDailyLimit: Bool = false
    
    @State private var affectsSaving: Bool = true // Added affectsSaving state

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

    struct Transaction: Identifiable, Equatable {
        var id: UUID
        let type: TransactionType
        var amount: Double
        var method: PaymentMethod
        let date: Date
        var note: String
        
        init(id: UUID = UUID(), type: TransactionType, amount: Double, method: PaymentMethod, date: Date, note: String) {
            self.id = id
            self.type = type
            self.amount = amount
            self.method = method
            self.date = date
            self.note = note
        }
    }
    
    // MARK: - Computed Properties for Savings

    private var todaysExpenditure: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return transactions.filter {
            $0.type == .expenditure && calendar.isDate($0.date, inSameDayAs: today) && (affectsSaving || $0.note != "Affects Savings")
        }
        .reduce(0, { $0 + $1.amount })
    }
    
    private var todaysSaving: Double {
        dailyExpenditureLimit - todaysExpenditure
    }
    
    private var pastSavingRecords: [(date: Date, delta: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expenditure && (affectsSaving || $0.note != "Affects Savings") },
                                  by: { calendar.startOfDay(for: $0.date) })
        let records = grouped.map { (date, trans) -> (date: Date, delta: Double) in
            let total = trans.reduce(0, { $0 + $1.amount })
            return (date: date, delta: dailyExpenditureLimit - total)
        }
        let today = calendar.startOfDay(for: Date())
        return records.filter { $0.date != today }
                      .sorted { $0.date > $1.date }
    }
    
    private var overallSaving: Double {
        todaysSaving + pastSavingRecords.map { $0.delta }.reduce(0, +)
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
                    if selectedTab == 3 {
                        savingsTabView
                    } else {
                        transactionList
                        spendingGraph
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onAppear { loadDashboardData() }
            .onChange(of: transactions) { oldValue, newValue in
                saveDashboardData()
            }
            .onChange(of: balanceBreakdown) { oldValue, newValue in
                saveDashboardData()
            }
            
            floatingActionButtons
        }
        .sheet(isPresented: $isLoggingTransaction) {
            LogTransactionView(
                transactionType: transactionType,
                transactionAmount: $transactionAmount,
                transactionMethod: $transactionMethod,
                balanceBreakdown: $balanceBreakdown,
                transactions: $transactions,
                affectsSaving: $affectsSaving // <-- Pass the binding here
            )
        }
        .sheet(isPresented: $isBalanceBreakdownPresented) {
            BalanceBreakdownView(balanceBreakdown: $balanceBreakdown)
        }
        .sheet(isPresented: $isEditViewPresented) {
            EditTransactionView(
                balanceBreakdown: $balanceBreakdown,
                transactions: $transactions
            )
        }
        .sheet(isPresented: $isEditingDailyLimit) {
            EditDailyLimitView(dailyLimit: $dailyExpenditureLimit)
        }
    }
    
    // MARK: - UI Components

    private var balanceHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(radius: 10)
            VStack(alignment: .leading, spacing: 5) {
                Text("Current Overall Balance")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                Button(action: { isBalanceBreakdownPresented.toggle() }) {
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
    
    private var transactionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                tabButton(title: "Expenditures", tag: 0)
                tabButton(title: "Incomes", tag: 1)
                tabButton(title: "All", tag: 2)
                tabButton(title: "Savings", tag: 3)
            }
            .padding(8)
        }
    }
    
    private func tabButton(title: String, tag: Int) -> some View {
        Button {
            withAnimation { selectedTab = tag }
        } label: {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Capsule().fill(selectedTab == tag ? Color.blue : Color.clear))
                .foregroundColor(selectedTab == tag ? .white : .primary)
        }
    }

    private var transactionList: some View {
        VStack(spacing: 15) {
            ForEach(filteredTransactions) { transaction in
                if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                    TransactionRow(
                        transaction: $transactions[index],
                        isEditingMode: $isEditingMode,
                        onDelete: { deleteTransaction(at: index) }
                    )
                }
            }
        }
    }

    private var savingsTabView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Overall Saving")
                    .font(.headline)
                Text("¥\(overallSaving, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(overallSaving >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
            
            VStack(spacing: 10) {
                Text("Today's Saving")
                    .font(.headline)
                Text("¥\(todaysSaving, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(todaysSaving >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Past Saving Records")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        isEditingDailyLimit = true
                    }) {
                        Image(systemName: "pencil")
                    }
                }
                ForEach(pastSavingRecords, id: \.date) { record in
                    HStack {
                        Text(record.date, style: .date)
                            .font(.subheadline)
                        Spacer()
                        Text("¥\(record.delta, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(record.delta >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding(.top, 10)
    }

    private var spendingGraph: some View {
        VStack(alignment: .leading) {
            Text("Spending Graph")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 5)
            SpendingChartView(transactions: transactions, selectedTab: selectedTab)
                .frame(height: 200)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1)))
    }
    
    private var floatingActionButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    transactionType = .expenditure
                    isLoggingTransaction.toggle()
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
                .padding(.trailing, 10)
                Button {
                    transactionType = .income
                    isLoggingTransaction.toggle()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
                .padding(.trailing, 10)
                Button {
                    isEditViewPresented.toggle()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }

    var filteredTransactions: [Transaction] {
        switch selectedTab {
        case 0:
            return transactions.filter { $0.type == .expenditure && (affectsSaving || $0.note != "Affects Savings") }
        case 1:
            return transactions.filter { $0.type == .income }
        default:
            return transactions
        }
    }
    
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
// Other code (CSV persistence, SpendingChartView, LogTransactionView, etc.) remains the same...

// MARK: - CSV Persistence (Save & Load)
// In addition to transactions and balance breakdown, we now persist the daily saving limit.
extension Dashboard4View {
    private func saveDashboardData() {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let folderURL = docsURL.appendingPathComponent(profile.id)
        saveTransactionsCSV(at: folderURL)
        saveBalanceBreakdownCSV(at: folderURL)
        saveSavingData(at: folderURL)
    }
    
    private func saveTransactionsCSV(at folder: URL) {
        let fileURL = folder.appendingPathComponent("transactions.csv")
        var csv = "id,type,amount,method,date,note\n"
        let dateFormatter = ISO8601DateFormatter()
        for t in transactions {
            let note = t.note.replacingOccurrences(of: ",", with: " ")
            csv += "\(t.id.uuidString),\(t.type.rawValue),\(String(format: "%.2f", t.amount)),\(t.method.rawValue),\(dateFormatter.string(from: t.date)),\(note)\n"
        }
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved transactions to \(fileURL.path)")
        } catch {
            print("Error saving transactions CSV: \(error)")
        }
    }
    
    private func saveBalanceBreakdownCSV(at folder: URL) {
        let fileURL = folder.appendingPathComponent("balance_breakdown.csv")
        var csv = "wallet,amount\n"
        for (wallet, amount) in balanceBreakdown {
            let safeWallet = wallet.replacingOccurrences(of: ",", with: " ")
            csv += "\(safeWallet),\(String(format: "%.2f", amount))\n"
        }
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved balance breakdown to \(fileURL.path)")
        } catch {
            print("Error saving balance breakdown CSV: \(error)")
        }
    }
    
    private func saveSavingData(at folder: URL) {
        let fileURL = folder.appendingPathComponent("savings.csv")
        let csv = "dailyLimit\n\(dailyExpenditureLimit)"
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved savings data to \(fileURL.path)")
        } catch {
            print("Error saving savings data: \(error)")
        }
    }
    
    private func loadDashboardData() {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let folderURL = docsURL.appendingPathComponent(profile.id)
        loadTransactionsCSV(from: folderURL)
        loadBalanceBreakdownCSV(from: folderURL)
        loadSavingData(from: folderURL)
    }
    
    private func loadTransactionsCSV(from folder: URL) {
        let fileURL = folder.appendingPathComponent("transactions.csv")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")
            var loaded: [Transaction] = []
            let dateFormatter = ISO8601DateFormatter()
            for line in lines.dropFirst() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let columns = line.components(separatedBy: ",")
                if columns.count >= 6,
                   let uuid = UUID(uuidString: columns[0]),
                   let amount = Double(columns[2]),
                   let date = dateFormatter.date(from: columns[4]) {
                    let type: TransactionType = (columns[1] == TransactionType.income.rawValue) ? .income : .expenditure
                    let method: PaymentMethod = PaymentMethod.allCases.first { $0.rawValue == columns[3] } ?? .others
                    let transaction = Transaction(id: uuid, type: type, amount: amount, method: method, date: date, note: columns[5])
                    loaded.append(transaction)
                }
            }
            transactions = loaded
        } catch {
            print("Error loading transactions CSV: \(error)")
        }
    }
    
    private func loadBalanceBreakdownCSV(from folder: URL) {
        let fileURL = folder.appendingPathComponent("balance_breakdown.csv")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")
            var loaded: [String: Double] = [:]
            for line in lines.dropFirst() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let columns = line.components(separatedBy: ",")
                if columns.count >= 2, let amount = Double(columns[1]) {
                    loaded[columns[0]] = amount
                }
            }
            balanceBreakdown = loaded
        } catch {
            print("Error loading balance breakdown CSV: \(error)")
        }
    }
    
    private func loadSavingData(from folder: URL) {
        let fileURL = folder.appendingPathComponent("savings.csv")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")
            if lines.count >= 2, let limit = Double(lines[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                dailyExpenditureLimit = limit
            }
        } catch {
            print("Error loading savings data: \(error)")
        }
    }
}

// MARK: - New SpendingChartView using Swift Charts

struct SpendingChartView: View {
    let transactions: [Dashboard4View.Transaction]
    /// selectedTab: 0 for Expenditure only, 1 for Income only, 2 for All (both lines), 3 for Savings (ignored here)
    let selectedTab: Int
    
    private var dailyIncome: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let incomeTrans = transactions.filter { $0.type == .income }
        let grouped = Dictionary(grouping: incomeTrans, by: { calendar.startOfDay(for: $0.date) })
        let results = grouped.map { (date, trans) in
            (date: date, total: trans.reduce(0) { $0 + $1.amount })
        }
        return results.sorted { $0.date < $1.date }
    }
    
    private var dailyExpenditure: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let expTrans = transactions.filter { $0.type == .expenditure }
        let grouped = Dictionary(grouping: expTrans, by: { calendar.startOfDay(for: $0.date) })
        let results = grouped.map { (date, trans) in
            (date: date, total: trans.reduce(0) { $0 + $1.amount })
        }
        return results.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        Chart {
            if selectedTab == 0 {
                ForEach(dailyExpenditure, id: \.date) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Expenditure", record.total)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())
                }
            } else if selectedTab == 1 {
                ForEach(dailyIncome, id: \.date) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Income", record.total)
                    )
                    .foregroundStyle(.green)
                    .symbol(Circle())
                }
            } else if selectedTab == 2 {
                ForEach(dailyIncome, id: \.date) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Income", record.total)
                    )
                    .foregroundStyle(.green)
                    .symbol(Circle())
                }
                ForEach(dailyExpenditure, id: \.date) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Expenditure", record.total)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                if value.as(Date.self) != nil {
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
        }
        .chartYAxis {
            AxisMarks()
        }
    }
}

// MARK: - New View for Editing Daily Saving Limit

struct EditDailyLimitView: View {
    @Binding var dailyLimit: Double
    @Environment(\.dismiss) var dismiss
    @State private var tempLimit: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Daily Saving Limit")
                    .font(.headline)
                TextField("Enter new limit", text: $tempLimit)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                Button("Save") {
                    if let newLimit = Double(tempLimit) {
                        dailyLimit = newLimit
                    }
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Daily Limit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                tempLimit = String(format: "%.2f", dailyLimit)
            }
        }
    }
}

// MARK: - Other Views (BalanceBreakdownView, LogTransactionView, TransactionRowPreview, TransactionRow, etc.)
// (They remain largely unchanged.)

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
                ForEach(balanceBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { wallet, amount in
                    HStack {
                        Text(wallet)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("¥\(amount, specifier: "%.2f")")
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

struct LogTransactionView: View {
    let transactionType: Dashboard4View.TransactionType
    @Binding var transactionAmount: String
    @Binding var transactionMethod: Dashboard4View.PaymentMethod
    @Binding var balanceBreakdown: [String: Double]
    @Binding var transactions: [Dashboard4View.Transaction]
    @Binding var affectsSaving: Bool
    
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
                
                Toggle(isOn: $affectsSaving) {
                    Text("Affects Savings")
                }
                .padding()
                .foregroundColor(.white)
                
                Button {
                    validateAndSaveTransaction()
                } label: {
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
            alertMessage = "Enter a valid amount."
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
            note: affectsSaving ? "Affects Savings" : note
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

struct EditTransactionView: View {
    @Binding var balanceBreakdown: [String: Double]
    @Binding var transactions: [Dashboard4View.Transaction]
    @Environment(\.dismiss) var dismiss

    // MARK: - Export State Variables
    @State private var isExporting = false
    @State private var exportedFileURL: URL? = nil
    @State private var isLoadingExport = false

    private func binding(for wallet: String) -> Binding<String> {
        Binding(
            get: { String(format: "%.2f", balanceBreakdown[wallet, default: 0]) },
            set: { newValue in
                if let value = Double(newValue) {
                    balanceBreakdown[wallet] = value
                }
            }
        )
    }
    
    private func generateCSV() -> String {
        var csv = "Type,Amount,Method,Date,Note\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        for transaction in transactions {
            let type = transaction.type.rawValue
            let amount = String(format: "%.2f", transaction.amount)
            let method = transaction.method.rawValue
            let date = dateFormatter.string(from: transaction.date)
            let note = transaction.note.replacingOccurrences(of: ",", with: " ")
            csv += "\(type),\(amount),\(method),\(date),\(note)\n"
        }
        return csv
    }
    
    private func exportData() {
        isLoadingExport = true
        DispatchQueue.global(qos: .userInitiated).async {
            let csv = generateCSV()
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent("TransactionsExport.csv")
            do {
                try csv.write(to: fileURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    exportedFileURL = fileURL
                    isLoadingExport = false
                    isExporting = true
                }
            } catch {
                DispatchQueue.main.async {
                    isLoadingExport = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
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
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)))
                .padding(.horizontal)
                
                Divider().padding()
                
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { exportData() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .overlay(
            Group {
                if isLoadingExport {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Preparing export...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
            }
        )
        .sheet(isPresented: $isExporting, onDismiss: { exportedFileURL = nil }) {
            if let fileURL = exportedFileURL {
                ShareSheet(activityItems: [fileURL])
            }
        }
    }
    
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
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
    }
}

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
                    TextField("Amount", value: $transaction.amount, formatter: NumberFormatter())
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
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
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

struct LineChartView: View {
    let transactions: Dashboard4View.Transaction
    
    var body: some View {
        Text("Swift Charts Placeholder")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

#Preview {
    let dummyProfile = Profile(id: "dummy-profile-id", name: "Demo Profile")
    Dashboard4View(profile: dummyProfile)
        .environmentObject(ProfileManager())
}
