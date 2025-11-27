import WidgetKit
import SwiftUI
import CoreData

@main
struct BudgetMeterWidgets: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        BalanceWidget()
        SpendingWidget()
        SavingsWidget()
        CombinedBalanceSavingsWidget()

        // Lock Screen Widgets (iOS 16+)
        if #available(iOS 16.0, *) {
            LockScreenBalanceCircular()
            LockScreenBalanceRectangular()
            LockScreenBalanceInline()
        }
    }
}

// MARK: - Balance Widget

struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceProvider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.balance.title".localized(defaultValue: "Balance"))
        .description("widget.balance.description".localized(defaultValue: "Shows your current balance"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BalanceEntry: TimelineEntry {
    let date: Date
    let balance: Double
    let currency: String
    let isPremium: Bool
}

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), balance: 1250.75, currency: "USD", isPremium: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> ()) {
        let entry = BalanceEntry(date: Date(), balance: 1250.75, currency: "USD", isPremium: true)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> ()) {
        let currentDate = Date()
        let entry = createBalanceEntry(for: currentDate)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createBalanceEntry(for date: Date) -> BalanceEntry {
        let persistenceService = PersistenceService.shared
        let context = persistenceService.viewContext
        
        // Fetch financial categories
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        do {
            let categories = try context.fetch(request)
            let totalIncome = categories.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
            let totalExpenses = categories.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
            let balance = totalIncome - totalExpenses
            
            // Get currency from app settings
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try context.fetch(settingsRequest).first
            let currency = settings?.preferredCurrencyCode ?? "USD"
            let isPremium = settings?.isPremiumUser ?? false
            
            return BalanceEntry(date: date, balance: balance, currency: currency, isPremium: isPremium)
        } catch {
            return BalanceEntry(date: date, balance: 0.0, currency: "USD", isPremium: false)
        }
    }
}

struct BalanceWidgetEntryView: View {
    var entry: BalanceProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallBalanceView(entry: entry)
        case .systemMedium:
            MediumBalanceView(entry: entry)
        default:
            SmallBalanceView(entry: entry)
        }
    }
}

struct SmallBalanceView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)

                Spacer()

                if entry.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("widget.balance.label".localized(defaultValue: "Balance"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Text(CurrencyHelper.formatAmount(entry.balance))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "4A90E2"), Color(hex: "357ABD")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .widgetURL(URL(string: "budgetmeter://home"))
    }
}

struct MediumBalanceView: View {
    let entry: BalanceEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.white)
                        .font(.title)
                    
                    Spacer()
                    
                    if entry.isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("widget.balance.label".localized(defaultValue: "Current Balance"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(CurrencyHelper.formatAmount(entry.balance))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("widget.balance.currency".localized(defaultValue: "Currency"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(entry.currency)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "4A90E2"), Color(hex: "357ABD")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .widgetURL(URL(string: "budgetmeter://home"))
    }
}

// MARK: - Spending Widget

struct SpendingWidget: Widget {
    let kind: String = "SpendingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingProvider()) { entry in
            SpendingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.spending.title".localized(defaultValue: "Monthly Spending"))
        .description("widget.spending.description".localized(defaultValue: "Shows your monthly spending breakdown"))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SpendingEntry: TimelineEntry {
    let date: Date
    let monthlySpending: Double
    let currency: String
    let topCategories: [(String, Double)]
    let isPremium: Bool
}

struct SpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingEntry {
        SpendingEntry(
            date: Date(),
            monthlySpending: 2450.50,
            currency: "USD",
            topCategories: [
                ("Groceries", 450.0),
                ("Rent", 1200.0),
                ("Transportation", 300.0)
            ],
            isPremium: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SpendingEntry) -> ()) {
        let entry = SpendingEntry(
            date: Date(),
            monthlySpending: 2450.50,
            currency: "USD",
            topCategories: [
                ("Groceries", 450.0),
                ("Rent", 1200.0),
                ("Transportation", 300.0)
            ],
            isPremium: true
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingEntry>) -> ()) {
        let currentDate = Date()
        let entry = createSpendingEntry(for: currentDate)
        
        // Update every 6 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: currentDate) ?? currentDate.addingTimeInterval(21600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createSpendingEntry(for date: Date) -> SpendingEntry {
        let persistenceService = PersistenceService.shared
        let context = persistenceService.viewContext
        
        do {
            // Fetch expense categories
            let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@", "expense")
            let categories = try context.fetch(request)
            
            let monthlySpending = categories.reduce(0) { $0 + $1.amount }
            let topCategories = categories
                .sorted { $0.amount > $1.amount }
                .prefix(3)
                .map { ($0.uniqueID ?? "Unknown", $0.amount) }
            
            // Get currency from app settings
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try context.fetch(settingsRequest).first
            let currency = settings?.preferredCurrencyCode ?? "USD"
            let isPremium = settings?.isPremiumUser ?? false
            
            return SpendingEntry(
                date: date,
                monthlySpending: monthlySpending,
                currency: currency,
                topCategories: topCategories,
                isPremium: isPremium
            )
        } catch {
            return SpendingEntry(
                date: date,
                monthlySpending: 0.0,
                currency: "USD",
                topCategories: [],
                isPremium: false
            )
        }
    }
}

struct SpendingWidgetEntryView: View {
    var entry: SpendingProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            MediumSpendingView(entry: entry)
        case .systemLarge:
            LargeSpendingView(entry: entry)
        default:
            MediumSpendingView(entry: entry)
        }
    }
}

struct MediumSpendingView: View {
    let entry: SpendingEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("widget.spending.title".localized(defaultValue: "Monthly Spending"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if entry.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(CurrencyHelper.formatAmount(entry.monthlySpending))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !entry.topCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(entry.topCategories.prefix(2).enumerated()), id: \.offset) { index, category in
                            HStack {
                                Text(category.0)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(CurrencyHelper.formatAmount(category.1))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "10B981"), Color(hex: "059669")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .widgetURL(URL(string: "budgetmeter://expenses"))
    }
}

struct LargeSpendingView: View {
    let entry: SpendingEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("widget.spending.title".localized(defaultValue: "Monthly Spending"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if entry.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(CurrencyHelper.formatAmount(entry.monthlySpending))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !entry.topCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("widget.spending.top_categories".localized(defaultValue: "Top Categories"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ForEach(Array(entry.topCategories.enumerated()), id: \.offset) { index, category in
                            HStack {
                                Text(category.0)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(CurrencyHelper.formatAmount(category.1))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "10B981"), Color(hex: "059669")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .widgetURL(URL(string: "budgetmeter://expenses"))
    }
}

// MARK: - Savings Widget

struct SavingsWidget: Widget {
    let kind: String = "SavingsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavingsProvider()) { entry in
            SavingsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.savings.title".localized(defaultValue: "Savings Goal"))
        .description("widget.savings.description".localized(defaultValue: "Shows your savings progress"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SavingsEntry: TimelineEntry {
    let date: Date
    let currentSavings: Double
    let savingsGoal: Double
    let currency: String
    let progress: Double
    let isPremium: Bool
}

struct SavingsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SavingsEntry {
        SavingsEntry(
            date: Date(),
            currentSavings: 2500.0,
            savingsGoal: 5000.0,
            currency: "USD",
            progress: 0.5,
            isPremium: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SavingsEntry) -> ()) {
        let entry = SavingsEntry(
            date: Date(),
            currentSavings: 2500.0,
            savingsGoal: 5000.0,
            currency: "USD",
            progress: 0.5,
            isPremium: true
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SavingsEntry>) -> ()) {
        let currentDate = Date()
        let entry = createSavingsEntry(for: currentDate)
        
        // Update every 12 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate) ?? currentDate.addingTimeInterval(43200)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createSavingsEntry(for date: Date) -> SavingsEntry {
        let persistenceService = PersistenceService.shared
        let context = persistenceService.viewContext
        
        do {
            // Get app settings for savings goal
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try context.fetch(settingsRequest).first
            
            let savingsGoal = settings?.savingsGoalAmount ?? 0.0
            let currency = settings?.preferredCurrencyCode ?? "USD"
            let isPremium = settings?.isPremiumUser ?? false
            
            // Calculate current savings (income - expenses)
            let categoriesRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
            let categories = try context.fetch(categoriesRequest)
            
            let totalIncome = categories.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
            let totalExpenses = categories.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
            let currentSavings = max(0, totalIncome - totalExpenses)
            
            let progress = savingsGoal > 0 ? min(1.0, currentSavings / savingsGoal) : 0.0
            
            return SavingsEntry(
                date: date,
                currentSavings: currentSavings,
                savingsGoal: savingsGoal,
                currency: currency,
                progress: progress,
                isPremium: isPremium
            )
        } catch {
            return SavingsEntry(
                date: date,
                currentSavings: 0.0,
                savingsGoal: 0.0,
                currency: "USD",
                progress: 0.0,
                isPremium: false
            )
        }
    }
}

struct SavingsWidgetEntryView: View {
    var entry: SavingsProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallSavingsView(entry: entry)
        case .systemMedium:
            MediumSavingsView(entry: entry)
        default:
            SmallSavingsView(entry: entry)
        }
    }
}

struct SmallSavingsView: View {
    let entry: SavingsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Spacer()
                
                if entry.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("widget.savings.label".localized(defaultValue: "Savings"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(CurrencyHelper.formatAmount(entry.currentSavings))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * entry.progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "8B5CF6"), Color(hex: "7C3AED")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .widgetURL(URL(string: "budgetmeter://home"))
    }
}

struct MediumSavingsView: View {
    let entry: SavingsEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.white)
                        .font(.title)
                    
                    Spacer()
                    
                    if entry.isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("widget.savings.label".localized(defaultValue: "Savings Goal"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(CurrencyHelper.formatAmount(entry.currentSavings))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * entry.progress, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("widget.savings.goal".localized(defaultValue: "Goal"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(CurrencyHelper.formatAmount(entry.savingsGoal))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(Int(entry.progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "8B5CF6"), Color(hex: "7C3AED")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .widgetURL(URL(string: "budgetmeter://home"))
    }
}
