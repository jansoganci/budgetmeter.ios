import WidgetKit
import SwiftUI
import CoreData

// MARK: - Combined Balance & Savings Widget

struct CombinedBalanceSavingsWidget: Widget {
    let kind: String = "CombinedBalanceSavingsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CombinedProvider()) { entry in
            CombinedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Balance & Savings")
        .description("Shows your current balance and savings progress")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Timeline Entry

struct CombinedEntry: TimelineEntry {
    let date: Date
    let balance: Double
    let savingsAmount: Double
    let savingsGoal: Double
    let savingsProgress: Double // 0.0 to 1.0
    let currency: String
    let isPremium: Bool
    let isPositive: Bool // for balance color
}

// MARK: - Timeline Provider

struct CombinedProvider: TimelineProvider {
    func placeholder(in context: Context) -> CombinedEntry {
        CombinedEntry(
            date: Date(),
            balance: 1250.75,
            savingsAmount: 2500.0,
            savingsGoal: 5000.0,
            savingsProgress: 0.5,
            currency: "USD",
            isPremium: true,
            isPositive: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CombinedEntry) -> ()) {
        let entry = CombinedEntry(
            date: Date(),
            balance: 1250.75,
            savingsAmount: 2500.0,
            savingsGoal: 5000.0,
            savingsProgress: 0.5,
            currency: "USD",
            isPremium: true,
            isPositive: true
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CombinedEntry>) -> ()) {
        let currentDate = Date()
        let entry = createCombinedEntry(for: currentDate)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createCombinedEntry(for date: Date) -> CombinedEntry {
        let persistenceService = PersistenceService.shared
        let context = persistenceService.viewContext
        
        do {
            // Fetch financial categories
            let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
            let categories = try context.fetch(request)
            
            let incomeCategories = categories.filter { $0.type == "income" }
            let expenseCategories = categories.filter { $0.type == "expense" }
            
            // Calculate monthly totals using CalculationEngine formulas
            let dailyIncome = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyIncome = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyIncome = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
            
            let dailyExpense = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyExpense = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyExpense = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
            
            // Calculate monthly equivalents
            let totalMonthlyIncome = CalculationEngine.totalMonthlyIncome(
                dailyIncomeTotal: dailyIncome,
                monthlyIncomeTotal: monthlyIncome,
                yearlyIncomeTotal: yearlyIncome
            )
            
            let totalMonthlyExpense = CalculationEngine.totalMonthlyExpense(
                dailyTotal: dailyExpense,
                monthlyTotal: monthlyExpense,
                yearlyTotal: yearlyExpense
            )
            
            let balance = totalMonthlyIncome - totalMonthlyExpense
            let isPositive = balance >= 0
            
            // Get app settings
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try context.fetch(settingsRequest).first
            
            let currency = settings?.preferredCurrencyCode ?? "USD"
            let isPremium = settings?.isPremiumUser ?? false
            let savingsGoal = settings?.savingsGoalAmount ?? 0.0
            
            // Calculate savings
            let savingsAmount = max(0, totalMonthlyIncome - totalMonthlyExpense)
            let savingsProgress = savingsGoal > 0 ? min(1.0, savingsAmount / savingsGoal) : 0.0
            
            return CombinedEntry(
                date: date,
                balance: balance,
                savingsAmount: savingsAmount,
                savingsGoal: savingsGoal,
                savingsProgress: savingsProgress,
                currency: currency,
                isPremium: isPremium,
                isPositive: isPositive
            )
        } catch {
            return CombinedEntry(
                date: date,
                balance: 0.0,
                savingsAmount: 0.0,
                savingsGoal: 0.0,
                savingsProgress: 0.0,
                currency: "USD",
                isPremium: false,
                isPositive: true
            )
        }
    }
}

// MARK: - Widget Entry View

struct CombinedWidgetEntryView: View {
    var entry: CombinedProvider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            // Top section - Balance (flex: 3)
            HStack(alignment: .top) {
                // Left side - Balance data
                VStack(alignment: .leading, spacing: 4) {
                    // Balance label
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Balance amount with color indicator
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(CurrencyHelper.formatAmount(entry.balance))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        Circle()
                            .fill(entry.isPositive ? Color(hex: "2ECC71") : Color(hex: "E74C3C"))
                            .frame(width: 6, height: 6)
                    }
                    
                    // Currency code
                    Text(entry.currency)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Right side - Premium crown
                Circle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(entry.isPremium ? Color(hex: "FFD700") : .clear)
                    )
            }
            
            // Bottom section - Savings (flex: 2)
            VStack(alignment: .leading, spacing: 4) {
                // Top row - Label and percentage
                HStack {
                    Text("Savings")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(Int(entry.savingsProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Savings amount
                Text(CurrencyHelper.formatAmount(entry.savingsAmount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * entry.savingsProgress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "4A90E2"), Color(hex: "357ABD")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Balance: \(CurrencyHelper.formatAmount(entry.balance)), Savings: \(CurrencyHelper.formatAmount(entry.savingsAmount)), \(Int(entry.savingsProgress * 100))% complete")
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    CombinedBalanceSavingsWidget()
} timeline: {
    CombinedEntry(
        date: Date(),
        balance: 1250.75,
        savingsAmount: 2500.0,
        savingsGoal: 5000.0,
        savingsProgress: 0.5,
        currency: "USD",
        isPremium: true,
        isPositive: true
    )
    
    CombinedEntry(
        date: Date(),
        balance: -250.50,
        savingsAmount: 1500.0,
        savingsGoal: 3000.0,
        savingsProgress: 0.5,
        currency: "EUR",
        isPremium: false,
        isPositive: false
    )
}

