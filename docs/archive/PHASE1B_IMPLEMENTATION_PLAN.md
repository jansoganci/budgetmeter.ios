# Phase 1B: Insights Dashboard - Implementation Plan

**Timeline:** 3-4 days
**Goal:** Build beautiful Insights Dashboard UI with charts and animations
**Status:** 📋 PLANNING

---

## 🎯 What We're Building

A premium Insights tab that shows users automated financial insights using the data we already collect. Zero new user input required - everything is calculated automatically.

### User Experience Flow:

```
User opens app
  → Taps "Insights" tab (new 5th tab)
    → Sees beautiful dashboard with:
      - Spending breakdown pie chart
      - Month comparison bar chart
      - 30-day balance trend line chart
      - 6 insight cards with trends
      - Pull-to-refresh
    → Taps insight card
      → Sees detail view (future)
    → Premium upsell if free user
```

---

## 🐛 Critical Bugs to Fix FIRST

Before building UI, we must fix blockers from audit:

### 1. Add Missing CalculationEngine Methods

**File:** `CoreKit/Sources/Engine/CalculationEngine.swift`

```swift
// Add these 3 methods:

static func healthScoreText(for score: Int) -> String {
    switch score {
    case 90...100: return "Excellent"
    case 75...89: return "Great"
    case 60...74: return "Good"
    case 40...59: return "Fair"
    case 20...39: return "Needs Improvement"
    default: return "Getting Started"
    }
}

static func calculateHealthScoreBreakdown(
    monthlyIncome: Double,
    monthlyExpense: Double,
    savingsGoal: Double
) -> HealthScoreBreakdown {
    // Calculate individual scores
    let incomeScore = calculateIncomeScore(monthlyIncome)
    let expenseScore = calculateExpenseScore(
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense
    )
    let savingsScore = calculateSavingsScore(
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        savingsGoal: savingsGoal
    )

    let totalScore = incomeScore + expenseScore + savingsScore

    return HealthScoreBreakdown(
        totalScore: totalScore,
        incomeScore: incomeScore,
        expenseScore: expenseScore,
        savingsScore: savingsScore,
        incomeReason: getIncomeReason(score: incomeScore, income: monthlyIncome),
        expenseReason: getExpenseReason(score: expenseScore, income: monthlyIncome, expense: monthlyExpense),
        savingsReason: getSavingsReason(score: savingsScore, goal: savingsGoal)
    )
}

static func generateHealthTips(
    breakdown: HealthScoreBreakdown,
    currentIncome: Double,
    currentExpense: Double,
    savingsGoal: Double
) -> [HealthTip] {
    var tips: [HealthTip] = []

    // Income tips
    if breakdown.incomeScore < 30 {
        tips.append(HealthTip(
            icon: "💰",
            title: "Increase Your Income",
            description: "Add income sources to improve your score",
            impact: "+\(30 - breakdown.incomeScore) points",
            color: .blue
        ))
    }

    // Expense tips
    if breakdown.expenseScore < 30 {
        let reduction = calculateRequiredExpenseReduction(
            income: currentIncome,
            expense: currentExpense
        )
        tips.append(HealthTip(
            icon: "💸",
            title: "Reduce Daily Expenses",
            description: "Cut expenses by \(CurrencyHelper.formatAmount(reduction))/day",
            impact: "+\(30 - breakdown.expenseScore) points",
            color: .orange
        ))
    }

    // Savings tips
    if breakdown.savingsScore < 40 {
        if savingsGoal == 0 {
            tips.append(HealthTip(
                icon: "🎯",
                title: "Set a Savings Goal",
                description: "Goals help you save more effectively",
                impact: "+10 points",
                color: .purple
            ))
        } else {
            tips.append(HealthTip(
                icon: "🏦",
                title: "Increase Savings",
                description: "Save more to maximize your score",
                impact: "+\(40 - breakdown.savingsScore) points",
                color: .green
            ))
        }
    }

    // If score is excellent, congratulate
    if breakdown.totalScore >= 90 {
        tips.append(HealthTip(
            icon: "✨",
            title: "Keep Up the Great Work!",
            description: "You're doing excellent! Maintain your habits",
            impact: "Excellent",
            actionable: false,
            color: .green
        ))
    }

    return tips
}

// Helper methods needed:
private static func calculateIncomeScore(_ income: Double) -> Int
private static func calculateExpenseScore(monthlyIncome: Double, monthlyExpense: Double) -> Int
private static func calculateSavingsScore(monthlyIncome: Double, monthlyExpense: Double, savingsGoal: Double) -> Int
private static func getIncomeReason(score: Int, income: Double) -> String
private static func getExpenseReason(score: Int, income: Double, expense: Double) -> String
private static func getSavingsReason(score: Int, goal: Double) -> String
private static func calculateRequiredExpenseReduction(income: Double, expense: Double) -> Double
```

### 2. Add Premium Check

**File:** `CoreKit/Sources/Premium/PremiumManager.swift`

```swift
// Add this computed property:
var hasInsights: Bool {
    return isPremium
}

var hasAdvancedNotifications: Bool {
    return isPremium
}
```

**Estimated Time:** 1-2 hours

---

## 📁 Files to Create

### Day 1: ViewModel & Basic Views (8 files)

```
budgetmeter.ios/Features/InsightsFeature/
├── View/
│   ├── InsightsView.swift                    (300 lines) ← Main view
│   ├── InsightCardView.swift                 (100 lines) ← Card component
│   ├── SpendingBreakdownView.swift           (150 lines) ← Pie chart
│   ├── MonthComparisonView.swift             (150 lines) ← Bar chart
│   └── BalanceTrendView.swift                (150 lines) ← Line chart
├── ViewModel/
│   └── InsightsViewModel.swift               (200 lines) ← Logic
└── Components/
    ├── ChartLegendView.swift                 (80 lines)  ← Chart legend
    └── EmptyInsightsView.swift               (100 lines) ← Empty state
```

**Total:** ~1,230 lines

---

## 🎨 Feature Breakdown

### 1. InsightsViewModel.swift (200 lines)

**Responsibilities:**
- Load insights from InsightsService
- Load chart data from HistoricalDataService
- Handle refresh logic
- Premium state management
- Loading states

**Key Properties:**
```swift
@MainActor
final class InsightsViewModel: ObservableObject {
    // Published State
    @Published var insights: [Insight] = []
    @Published var spendingBreakdown: [(String, Double, Double)] = []
    @Published var monthComparison: (current: Double, previous: Double)?
    @Published var balanceTrend: [(Date, Double)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPremium = false

    // Services
    private let insightsService: InsightsService
    private let historicalService: HistoricalDataService
    private let premiumManager: PremiumManager

    // Methods
    func loadInsights()
    func refresh()
    func checkPremiumStatus()
}
```

**Testing:**
- Load insights successfully
- Handle empty data
- Handle errors
- Premium check works

---

### 2. InsightsView.swift (300 lines)

**The main dashboard view**

**Layout:**
```swift
NavigationView {
    ScrollView {
        VStack(spacing: 24) {
            // Header with last updated time
            headerView()

            if isPremium {
                // PREMIUM CONTENT

                // Spending Breakdown Section
                SectionHeader("Spending Breakdown")
                SpendingBreakdownView(data: spendingBreakdown)

                // Month Comparison Section
                SectionHeader("This Month vs Last Month")
                MonthComparisonView(current: current, previous: previous)

                // Balance Trend Section
                SectionHeader("30-Day Balance Trend")
                BalanceTrendView(data: balanceTrend)

                // Insights Cards
                SectionHeader("Your Insights")
                LazyVGrid(columns: 2) {
                    ForEach(insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            } else {
                // FREE USER - LOCKED STATE
                premiumUpsellView()
            }
        }
        .padding()
    }
    .navigationTitle("Insights")
    .refreshable {
        await viewModel.refresh()
    }
}
.onAppear {
    viewModel.loadInsights()
}
```

**States:**
- Loading state (skeleton/shimmer)
- Loaded state (shows charts & insights)
- Empty state (no data yet)
- Error state (failed to load)
- Premium upsell (free users)

**Animations:**
- Fade in on appear
- Skeleton shimmer while loading
- Pull-to-refresh
- Card tap animations

---

### 3. InsightCardView.swift (100 lines)

**Individual insight card component**

**Design:**
```swift
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Image(systemName: insight.icon)
            .font(.title2)
            .foregroundColor(insight.color)

        Spacer()

        if let trend = insight.trend {
            Image(systemName: trend.iconName)
                .foregroundColor(trend.color)
                .font(.caption)
        }
    }

    Text(insight.title)
        .font(.caption)
        .foregroundColor(.secondary)

    Text(insight.value)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)

    if let description = insight.description {
        Text(description)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(2)
    }
}
.padding()
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(insight.color.opacity(0.1))
)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(insight.color.opacity(0.3), lineWidth: 1)
)
```

**Features:**
- Color-coded by type
- Shows trend arrow if applicable
- Tap to see detail (future)
- Haptic feedback on tap
- Smooth animations

---

### 4. SpendingBreakdownView.swift (150 lines)

**Pie chart showing spending by category**

**Using:** SwiftUI Charts framework

```swift
Chart(data) { item in
    SectorMark(
        angle: .value("Amount", item.amount),
        innerRadius: .ratio(0.5), // Donut chart
        angularInset: 2
    )
    .foregroundStyle(by: .value("Category", item.category))
    .cornerRadius(4)
}
.chartLegend(position: .bottom, alignment: .leading)
.frame(height: 300)
```

**Features:**
- Donut chart style
- Color-coded categories
- Percentage labels
- Legend at bottom
- Animated appearance
- Tap to highlight category

**Data format:**
```swift
struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
}
```

---

### 5. MonthComparisonView.swift (150 lines)

**Bar chart comparing this month vs last month**

**Using:** SwiftUI Charts

```swift
Chart {
    BarMark(
        x: .value("Period", "Last Month"),
        y: .value("Amount", previousMonth)
    )
    .foregroundStyle(.gray.opacity(0.5))

    BarMark(
        x: .value("Period", "This Month"),
        y: .value("Amount", currentMonth)
    )
    .foregroundStyle(currentMonth < previousMonth ? .green : .red)
}
.chartYAxis {
    AxisMarks(position: .leading)
}
.frame(height: 200)
```

**Features:**
- Side-by-side bars
- Color indicates improvement (green) or increase (red)
- Shows percentage change
- Animated height transitions
- Y-axis with currency formatting

---

### 6. BalanceTrendView.swift (150 lines)

**Line chart showing 30-day balance trend**

**Using:** SwiftUI Charts

```swift
Chart(data) { item in
    LineMark(
        x: .value("Date", item.date),
        y: .value("Balance", item.balance)
    )
    .foregroundStyle(
        .linearGradient(
            colors: [.blue, .cyan],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

    AreaMark(
        x: .value("Date", item.date),
        y: .value("Balance", item.balance)
    )
    .foregroundStyle(
        .linearGradient(
            colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}
.chartXAxis {
    AxisMarks(values: .stride(by: .day, count: 7)) { value in
        AxisValueLabel(format: .dateTime.month().day())
    }
}
.frame(height: 250)
```

**Features:**
- Smooth line with gradient
- Filled area under line
- X-axis shows dates (every 7 days)
- Y-axis shows currency
- Shows positive/negative clearly
- Animated line drawing

---

### 7. ChartLegendView.swift (80 lines)

**Reusable legend component for charts**

```swift
struct ChartLegendView: View {
    let items: [(String, Color)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.1)
                        .frame(width: 12, height: 12)

                    Text(item.0)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
    }
}
```

---

### 8. EmptyInsightsView.swift (100 lines)

**Shown when no data available**

```swift
VStack(spacing: 20) {
    Image(systemName: "chart.bar.xaxis")
        .font(.system(size: 80))
        .foregroundColor(.secondary.opacity(0.3))

    Text("No Insights Yet")
        .font(.title2)
        .fontWeight(.semibold)

    Text("Add income and expenses to see automated insights about your finances")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

    NavigationLink(destination: ExpensesView()) {
        Label("Add Expenses", systemImage: "plus.circle.fill")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(12)
    }
    .padding(.top)
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

---

## 🎨 Design System

### Colors

```swift
// Insight types
.blue   // Balance, general
.green  // Savings, positive trends
.orange // Spending, warnings
.purple // Goals, milestones
.red    // Overspending, negative

// Chart gradients
LinearGradient([.blue, .cyan])      // Balance trend
LinearGradient([.green, .mint])     // Positive metrics
LinearGradient([.orange, .yellow])  // Spending
LinearGradient([.purple, .pink])    // Goals
```

### Typography

```swift
// Section headers
.font(.headline)
.fontWeight(.semibold)

// Insight values
.font(.title2)
.fontWeight(.bold)

// Insight labels
.font(.caption)
.foregroundColor(.secondary)

// Descriptions
.font(.caption2)
.foregroundColor(.secondary)
```

### Spacing

```swift
// Between sections
.padding(.vertical, 24)

// Between cards
.spacing(16)

// Card padding
.padding(16)

// Corner radius
.cornerRadius(16) // Cards
.cornerRadius(12) // Buttons
```

### Animations

```swift
// Card appearance
.transition(.scale.combined(with: .opacity))
.animation(.spring(response: 0.4, dampingFraction: 0.7))

// Number counting
.contentTransition(.numericText())
.animation(.default)

// Chart drawing
.animation(.easeInOut(duration: 0.8))

// Shimmer loading
.redacted(reason: .placeholder)
.shimmering()
```

---

## 🔌 Integration

### Add Insights Tab to ContentView.swift

```swift
TabView {
    // ... existing tabs ...

    // NEW: Insights tab
    InsightsView()
        .tabItem {
            Label("Insights", systemImage: "chart.bar.xaxis")
        }
        .tag(4)
}
```

### Add to Navigation (if using sidebar on iPad)

```swift
NavigationLink {
    InsightsView()
} label: {
    Label("Insights", systemImage: "chart.bar.xaxis")
}
```

---

## 🎯 Premium Upsell

### Free User Experience

When free users tap Insights tab:

```swift
VStack(spacing: 24) {
    // Preview blurred charts
    ZStack {
        SpendingBreakdownView(data: sampleData)
            .blur(radius: 8)

        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Unlock Insights")
                .font(.title)
                .fontWeight(.bold)

            Text("Get automated insights about your spending, savings, and financial health")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Upgrade to Premium") {
                // Show paywall
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // Feature list
    VStack(alignment: .leading, spacing: 12) {
        FeatureRow(icon: "chart.pie.fill", text: "Spending breakdown by category")
        FeatureRow(icon: "chart.bar.fill", text: "Month-over-month comparisons")
        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "30-day balance trends")
        FeatureRow(icon: "lightbulb.fill", text: "Automated financial insights")
        FeatureRow(icon: "target", text: "Goal progress tracking")
    }
    .padding()
}
```

---

## 📅 Day-by-Day Implementation

### Day 1: Foundation & Fixes (4-5 hours)

**Morning:**
- [ ] Fix CalculationEngine missing methods (2 hours)
- [ ] Add premium checks to PremiumManager (15 min)
- [ ] Test that services don't crash (30 min)

**Afternoon:**
- [ ] Create InsightsViewModel (1.5 hours)
- [ ] Create basic InsightsView structure (1 hour)
- [ ] Test data loading works (30 min)

**End of Day 1:**
- ✅ No crashes
- ✅ ViewModel loads data
- ✅ Basic view displays (no charts yet)

---

### Day 2: Charts & Components (6-7 hours)

**Morning:**
- [ ] Create SpendingBreakdownView with pie chart (2 hours)
- [ ] Create MonthComparisonView with bar chart (2 hours)

**Afternoon:**
- [ ] Create BalanceTrendView with line chart (2 hours)
- [ ] Create ChartLegendView (30 min)
- [ ] Integrate all charts into InsightsView (1 hour)

**End of Day 2:**
- ✅ All 3 charts working
- ✅ Charts display real data
- ✅ Animations work

---

### Day 3: Insight Cards & Polish (6-7 hours)

**Morning:**
- [ ] Create InsightCardView component (1.5 hours)
- [ ] Integrate insight cards into InsightsView (1 hour)
- [ ] Add loading states (shimmer/skeleton) (1 hour)

**Afternoon:**
- [ ] Create EmptyInsightsView (1 hour)
- [ ] Add premium upsell view (1.5 hours)
- [ ] Add pull-to-refresh (30 min)
- [ ] Polish animations & transitions (1 hour)

**End of Day 3:**
- ✅ Complete Insights tab
- ✅ Premium upsell working
- ✅ All states handled

---

### Day 4: Integration & Testing (4-5 hours)

**Morning:**
- [ ] Add Insights tab to ContentView (30 min)
- [ ] Test with real data (1 hour)
- [ ] Test with no data (empty state) (30 min)
- [ ] Test premium vs free (1 hour)

**Afternoon:**
- [ ] Fix bugs found (1-2 hours)
- [ ] Performance optimization (30 min)
- [ ] Final polish (30 min)
- [ ] Commit & push (15 min)

**End of Day 4:**
- ✅ Insights fully integrated
- ✅ Tested on device
- ✅ No crashes
- ✅ Ready for Phase 1C

---

## ✅ Testing Checklist

### Functional Tests:

- [ ] Insights load successfully with data
- [ ] Charts display correctly
- [ ] Pie chart shows accurate percentages
- [ ] Bar chart shows month comparison
- [ ] Line chart shows 30-day trend
- [ ] Insight cards show 6 insights
- [ ] Pull-to-refresh works
- [ ] Empty state shows when no data
- [ ] Premium upsell shows for free users
- [ ] Premium users see all content
- [ ] Tapping insight card has haptic feedback
- [ ] All animations smooth (60 FPS)

### Edge Cases:

- [ ] No income/expense data
- [ ] Only 1 day of data
- [ ] Large amounts (formatting)
- [ ] Negative balance
- [ ] All expenses in one category
- [ ] No snapshots yet
- [ ] Offline mode

### UI Tests:

- [ ] Looks good on iPhone SE (small)
- [ ] Looks good on iPhone Pro Max (large)
- [ ] Looks good on iPad
- [ ] Works in dark mode
- [ ] Works with accessibility (VoiceOver)
- [ ] Works with Dynamic Type
- [ ] Charts are readable
- [ ] Colors are distinct

---

## 🎯 Success Criteria

Phase 1B is complete when:

✅ Insights tab visible in navigation
✅ All 3 charts display correctly
✅ 6 insight cards show real data
✅ Premium upsell works
✅ Empty state works
✅ Loading states work
✅ Pull-to-refresh works
✅ No crashes
✅ Tested on device
✅ Code committed & pushed

---

## 📊 Estimated Effort

| Task | Time |
|------|------|
| Bug fixes | 2-3 hours |
| ViewModel | 1.5 hours |
| Main view structure | 1 hour |
| Pie chart | 2 hours |
| Bar chart | 2 hours |
| Line chart | 2 hours |
| Insight cards | 1.5 hours |
| Empty state | 1 hour |
| Premium upsell | 1.5 hours |
| Integration | 1 hour |
| Testing | 2 hours |
| Bug fixes | 2 hours |
| Polish | 1 hour |

**Total:** 20-22 hours = 3-4 days

---

## 🚀 Next Steps

**After Phase 1B Complete:**

Move to Phase 1C: Smart Notifications UI
- Notification permission request
- Notification settings screen
- Toggle switches
- Time picker for weekly summary

**Or:**

Move to Phase 1D: Financial Health Details
- Detail view for health score
- Score breakdown display
- Tips list
- History chart

---

## 💡 Notes

**SwiftUI Charts:**
- Available iOS 16+
- Need to check deployment target
- Beautiful out of the box
- Highly customizable

**Performance:**
- Charts may be heavy - optimize rendering
- Use lazy loading for insight cards
- Cache chart data in ViewModel
- Test on older devices

**Premium Strategy:**
- Show blurred preview to entice upgrade
- Highlight value proposition
- Make upgrade button prominent
- Track conversion rate

---

**Ready to start? Let me know and I'll begin with Day 1!** 🚀
