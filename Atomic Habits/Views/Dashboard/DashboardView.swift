import SwiftUI

// MARK: - Data Model
struct AtomicStreak: Identifiable {
    let id = UUID()
    let name: String
    var count: Int
    var lastPressed: Date
    let icon: String
    var isGlowing: Bool = false
}

// To reuse Dashboard4View's Transaction type.
typealias Transaction = Dashboard4View.Transaction

// MARK: - Main View
struct DashboardView: View {
    let profile: Profile
    let animationNamespace: Namespace.ID
    @State private var selectedTab: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var streaks: [AtomicStreak] = []
    @State private var showingAddStreak = false

    // MARK: - Shared Data (Simulated from Dashboard4View)
    @State private var balanceBreakdown: [String: Double] = [
        "Bank": 1500.0,
        "WeChat": 500.0,
        "Alipay": 300.0,
        "Cash": 200.0,
        "Others": 100.0
    ]
    // In practice, these transactions would be updated by Dashboard4View.
    @State private var transactions: [Transaction] = [
        Transaction(type: .expenditure, amount: 50.0, method: .cash, date: Date().addingTimeInterval(-3600), note: "Lunch"),
        Transaction(type: .income, amount: 200.0, method: .bank, date: Date().addingTimeInterval(-7200), note: "Salary"),
        Transaction(type: .expenditure, amount: 30.0, method: .alipay, date: Date().addingTimeInterval(-10800), note: "Coffee"),
        Transaction(type: .expenditure, amount: 15.0, method: .wechat, date: Date().addingTimeInterval(-14400), note: "Snacks"),
        Transaction(type: .expenditure, amount: 80.0, method: .cash, date: Date().addingTimeInterval(-18000), note: "Groceries"),
        Transaction(type: .income, amount: 100.0, method: .bank, date: Date().addingTimeInterval(-21600), note: "Refund")
    ]
    @State private var dailyExpenditureLimit: Double = 70.0

    // MARK: - Computed Properties (Shared with Dashboard4View)
    private var balance: Double {
        balanceBreakdown.values.reduce(0, +)
    }
    
    private var todaysExpenditure: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return transactions.filter {
            $0.type == .expenditure && calendar.isDate($0.date, inSameDayAs: today)
        }
        .reduce(0, { $0 + $1.amount })
    }
    
    private var todaysSaving: Double {
        dailyExpenditureLimit - todaysExpenditure
    }
    
    private var pastSavingRecords: [(date: Date, delta: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expenditure },
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
    
    private var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
                .overlay(Material.regular.opacity(0.7))
            
            ScrollView {
                VStack(spacing: 30) {
                    headerView
                    streakView
                    tabView
                    contentView
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddStreak) {
            AddStreakView { newStreak in
                streaks.append(newStreak)
            }
        }
        // In a real app, you would load/update shared data here.
    }
    
    // MARK: - Header Section
    private var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .matchedGeometryEffect(id: profile.id, in: animationNamespace)
            
            VStack {
                Text("Welcome")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                Text(profile.name)
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 150)
        .shadow(radius: 10)
    }
    
    // MARK: - Streaks Section
    private var streakView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Streaks")
                .font(.headline)
                .padding(.leading, 5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(streaks) { streak in
                        StreakButton(streak: streak) {
                            pressStreak(streak)
                        }
                    }
                    addStreakButton
                }
                .padding(.horizontal, 15)
            }
        }
        .frame(height: 120)
    }
    
    private var addStreakButton: some View {
        Button(action: { showingAddStreak = true }) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: "plus")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
    }
    
    // MARK: - Tab Section
    private var tabView: some View {
        HStack {
            // Changed "Overview" to "Balance"
            tabButton(title: "Balance", tag: 0)
            tabButton(title: "Activity", tag: 1)
            tabButton(title: "Settings", tag: 2)
        }
        .background(Capsule().fill(Color.gray.opacity(0.2)))
        .padding(.horizontal)
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
    
    // MARK: - Content Section
    private var contentView: some View {
        VStack {
            switch selectedTab {
            case 0: overviewContent
            case 1: activityContent
            case 2: settingsContent
            default: Text("Dashboard content here...")
                        .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Tab Contents
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header now reads "Balance"
            Text("Balance")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack {
                statCard(title: "Balance", value: "¥" + String(format: "%.2f", balance))
                statCard(title: "Savings", value: "¥" + String(format: "%.2f", overallSaving))
            }
            
            Text("Recent Transactions")
                .font(.subheadline)
            
            // Use the TransactionRowPreview to mimic the "All" tab formatting.
            ForEach(recentTransactions, id: \.id) { txn in
                TransactionRowPreview(transaction: txn)
            }
        }
        .padding(15)
    }
    
    private var activityContent: some View {
        Text("Activity content here...")
            .foregroundColor(.gray)
    }
    
    private var settingsContent: some View {
        Text("Settings content here...")
            .foregroundColor(.gray)
    }
    
    // MARK: - Helper Views
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15).fill(Color.blue.opacity(0.1))
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            actionButton(title: "Send", icon: "paperplane.fill")
            actionButton(title: "Request", icon: "arrow.down.app.fill")
            actionButton(title: "More", icon: "ellipsis")
        }
    }
    
    private func actionButton(title: String, icon: String) -> some View {
        Button(action: {}) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
            )
        }
    }
    
    // MARK: - Streak Logic
    private func pressStreak(_ streak: AtomicStreak) {
        if let index = streaks.firstIndex(where: { $0.id == streak.id }) {
            streaks[index].lastPressed = Date()
            streaks[index].count += 1
            // Trigger glow animation
            DispatchQueue.main.async {
                streaks[index].isGlowing = true
            }
            // Auto-disable glow after 24 hours
            DispatchQueue.main.asyncAfter(deadline: .now() + 86400) {
                streaks[index].isGlowing = false
            }
        }
    }
}
