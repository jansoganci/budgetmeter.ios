# Phase 1 Features - Implementation Plan

**Goal:** Add high-value, low-friction features that make the app feel premium and smart
**Timeline:** 1-2 weeks
**Complexity:** Medium (mostly UI and calculations, no external dependencies)

---

## 📋 Overview

### Features to Implement:
1. **Insights Dashboard** - Automated financial insights
2. **Smart Notifications** - Weekly summaries & milestone alerts
3. **Financial Health Details** - Expanded health score with tips

### Core Principles:
✅ Zero additional user input required
✅ All data from existing categories
✅ Beautiful, animated UI
✅ Premium feel
✅ Drives daily engagement

---

## 🏗️ Technical Architecture

### New Services Layer

```
CoreKit/Sources/Services/
├── InsightsService.swift          # Calculate insights from data
├── NotificationService.swift      # Manage notifications
└── HistoricalDataService.swift    # Store & retrieve historical snapshots
```

### New Features Layer

```
Features/
├── InsightsFeature/
│   ├── View/
│   │   ├── InsightsView.swift
│   │   ├── InsightCardView.swift
│   │   └── InsightChartView.swift
│   ├── ViewModel/
│   │   └── InsightsViewModel.swift
│   └── Model/
│       └── Insight.swift
│
└── FinancialHealthFeature/
    └── View/
        ├── FinancialHealthDetailView.swift
        ├── HealthScoreBreakdownView.swift
        └── HealthTipCardView.swift
```

### Data Model Changes

**New Core Data Entity: `FinancialSnapshot`**
```swift
// Stores daily/weekly/monthly aggregates for historical analysis
- id: UUID
- date: Date
- totalIncome: Double
- totalExpense: Double
- balance: Double
- netFlow: Double
- healthScore: Int
- savingsAmount: Double
- snapshotType: String ("daily", "weekly", "monthly")
```

---

## 🎯 Feature 1: Insights Dashboard

### User Stories
- As a user, I want to see what percentage I spend on each category
- As a user, I want to know if I'm spending more/less than last month
- As a user, I want to see my biggest expense category
- As a user, I want to know my savings rate
- As a user, I want to see if my balance is improving

### UI Design

**Navigation:**
- New tab in TabView (5th tab: "Insights")
- Icon: `chart.bar.xaxis`
- Premium badge if not premium user

**Layout:**
```
┌─────────────────────────────┐
│  Insights                   │
│                             │
│  ┌───────────────────────┐  │
│  │ 💰 Spending Breakdown │  │ ← Pie chart + percentages
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ 📊 This Month vs Last │  │ ← Bar chart comparison
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ 🎯 Your Top Insights  │  │ ← 3-4 insight cards
│  │  • You spend 40% on...│  │
│  │  • Balance up $450... │  │
│  │  • Saving $200/mo...  │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ 📈 30-Day Trend       │  │ ← Line chart
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Insights to Calculate

**Category Analysis:**
```swift
// Percentage breakdown
"You spend 40% on Groceries, 30% on Rent, 15% on Transportation..."

// Biggest category
"Your largest expense is Groceries at $450/month"

// Smallest category
"You spend the least on Entertainment"
```

**Trend Analysis:**
```swift
// Month-over-month
"Your spending is down 15% compared to last month"
"Your balance improved by $450 this month"

// Savings rate
"You're saving 20% of your income ($200/month)"

// Balance trend
"Your balance has been positive for 7 days straight! 🎉"
```

**Projections:**
```swift
// Savings goal
"At this rate, you'll reach your $5,000 goal in 3 months"

// Daily average
"You spend an average of $42 per day"

// Best/worst
"Your best day was Monday (saved $25)"
"Your worst category is Dining Out (spent $120 extra)"
```

### Data Requirements

**Need to track:**
- Daily snapshots (for trend analysis)
- Monthly aggregates (for comparisons)
- Category totals over time

**Storage strategy:**
- Store daily snapshot at midnight (BackgroundTasks)
- Store monthly aggregate on 1st of month
- Keep last 90 days of daily data
- Keep last 12 months of monthly data
- Auto-delete old data to save space

### Implementation Tasks

**Backend (Services & Data):**
- [ ] Create `FinancialSnapshot` Core Data entity
- [ ] Create `HistoricalDataService.swift`
  - [ ] `saveDailySnapshot()` - store current state
  - [ ] `getSnapshots(from:to:type:)` - retrieve historical data
  - [ ] `getMonthlyComparison()` - compare this vs last month
  - [ ] `getDailyTrend(days:)` - get X days of data
- [ ] Create `InsightsService.swift`
  - [ ] `calculateSpendingBreakdown()` → [(category, percentage)]
  - [ ] `getBiggestCategory()` → (name, amount)
  - [ ] `getSavingsRate()` → percentage
  - [ ] `getBalanceTrend()` → "improving"/"declining"/"stable"
  - [ ] `getMonthComparison()` → difference %
  - [ ] `generateInsights()` → [Insight]
- [ ] Update `BackgroundProcessingService` to save daily snapshots

**Frontend (UI & ViewModel):**
- [ ] Create `Insight.swift` model
  ```swift
  struct Insight: Identifiable {
      let id = UUID()
      let icon: String
      let title: String
      let value: String
      let trend: Trend? // up/down/neutral
      let color: Color
  }
  ```
- [ ] Create `InsightsViewModel.swift`
  - [ ] Load all insights on appear
  - [ ] Refresh on pull-to-refresh
  - [ ] Premium check
- [ ] Create `InsightCardView.swift`
  - [ ] Icon, title, value display
  - [ ] Trend arrow animation
  - [ ] Gradient background
  - [ ] Haptic feedback on tap
- [ ] Create `InsightChartView.swift`
  - [ ] Pie chart (spending breakdown)
  - [ ] Bar chart (month comparison)
  - [ ] Line chart (30-day trend)
  - [ ] Use SwiftUI Charts
- [ ] Create `InsightsView.swift`
  - [ ] ScrollView with all sections
  - [ ] Pull-to-refresh
  - [ ] Loading states
  - [ ] Empty state (if no data)
  - [ ] Premium upsell (if not premium)
- [ ] Add Insights tab to `ContentView.swift`

**Premium Integration:**
- [ ] Add `hasInsights` to `PremiumManager`
- [ ] Show locked state for free users
- [ ] Add to paywall feature list

---

## 🔔 Feature 2: Smart Notifications

### User Stories
- As a user, I want weekly summaries of my finances
- As a user, I want to celebrate when I hit milestones
- As a user, I want alerts if I'm overspending
- As a user, I want to be reminded of my progress

### Notification Types

**1. Weekly Summary (Every Sunday, 6 PM)**
```
📊 Weekly Summary
You saved $120 this week! Balance: $1,250

Your weekly overview:
• Income: $500
• Expenses: $380
• Net: +$120

Tap to see insights →
```

**2. Milestone Celebrations**
```
🎉 Achievement Unlocked!
Your balance has been positive for 7 days straight!

Keep up the great work!
```

```
🎯 Goal Progress
You're 80% of the way to your $5,000 goal!

Only $1,000 to go!
```

**3. Spending Alerts**
```
⚠️ Spending Alert
You're spending $50/day more than last week

This week: $350 | Last week: $280

Check your expenses →
```

**4. Goal Achievement**
```
💰 Goal Achieved!
Congratulations! You hit your $5,000 savings goal!

Time to set a new goal? →
```

**5. Daily Encouragement (Optional)**
```
💪 Daily Reminder
Your financial health score is 85 - Excellent!

You're doing great! Keep it up!
```

### Notification Schedule

| Notification | Frequency | Time | Condition |
|--------------|-----------|------|-----------|
| Weekly Summary | Every Sunday | 6:00 PM | Always |
| Milestone - Positive Streak | One-time | Immediate | 7+ days positive |
| Milestone - Goal Progress | Every 25% | Immediate | 25%, 50%, 75%, 100% |
| Spending Alert | Weekly | Monday 9 AM | Spending up >20% |
| Goal Achievement | One-time | Immediate | Goal reached |
| Daily Encouragement | Daily | 9:00 AM | Premium only |

### Implementation Tasks

**Permissions & Setup:**
- [ ] Create `NotificationService.swift`
  - [ ] Request notification permissions
  - [ ] Handle permission states
  - [ ] Schedule/cancel notifications
  - [ ] Deep link handling
- [ ] Add notification permission request to onboarding
- [ ] Add notification settings in Settings tab
  - [ ] Toggle for each notification type
  - [ ] Time picker for weekly summary
  - [ ] Preview notification button

**Notification Logic:**
- [ ] Implement `scheduleWeeklySummary()`
  - [ ] Calculate summary data
  - [ ] Format notification content
  - [ ] Schedule for Sunday 6 PM
- [ ] Implement `checkMilestones()`
  - [ ] Check positive streak
  - [ ] Check goal progress
  - [ ] Prevent duplicate notifications
- [ ] Implement `checkSpendingAlerts()`
  - [ ] Compare this week vs last week
  - [ ] Calculate percentage change
  - [ ] Only alert if >20% increase
- [ ] Implement `sendGoalAchievement()`
  - [ ] Trigger when savings goal reached
  - [ ] Add confetti animation on app open
- [ ] Add background task to check conditions
  - [ ] Daily check at midnight
  - [ ] Update scheduled notifications

**Data Tracking:**
- [ ] Add `NotificationHistory` to Core Data (optional)
  - [ ] Track sent notifications
  - [ ] Prevent duplicate milestones
  - [ ] User can review past notifications
- [ ] Store notification preferences in UserDefaults
  ```swift
  NotificationPreferences {
      weeklySummaryEnabled: Bool
      weeklySummaryTime: Date
      milestonesEnabled: Bool
      spendingAlertsEnabled: Bool
      dailyEncouragementEnabled: Bool
  }
  ```

**UI Components:**
- [ ] Create notification permission prompt view
- [ ] Create notification settings section
  - [ ] Toggle switches
  - [ ] Time picker
  - [ ] Test notification button
- [ ] Handle notification taps (deep linking)
  - [ ] Weekly summary → Insights tab
  - [ ] Goal progress → Home tab
  - [ ] Spending alert → Expenses tab

**Premium Integration:**
- [ ] Make daily encouragement premium-only
- [ ] Add notification customization to premium features
- [ ] Show upsell for locked notification types

---

## 💪 Feature 3: Financial Health Details

### User Stories
- As a user, I want to understand my health score
- As a user, I want to know how to improve my score
- As a user, I want to see my progress over time
- As a user, I want actionable tips

### UI Design

**Current State:**
```swift
// HomeView already shows:
Text("\(financialHealthScore)")
Text(financialHealthText)
```

**New: Tap to see details →**

```
┌─────────────────────────────────┐
│  Financial Health Details       │
│                                  │
│  ┌──────────────────────────┐   │
│  │        85 / 100          │   │ ← Big score with ring
│  │      Excellent!          │   │
│  └──────────────────────────┘   │
│                                  │
│  Score Breakdown:               │
│  ┌──────────────────────────┐   │
│  │ 💰 Income      25 / 30   │   │ ← Progress bars
│  │ 💸 Expenses    20 / 30   │   │
│  │ 🎯 Savings     15 / 40   │   │
│  └──────────────────────────┘   │
│                                  │
│  📈 Your Progress               │
│  ┌──────────────────────────┐   │
│  │ Line chart (30 days)     │   │ ← Score over time
│  └──────────────────────────┘   │
│                                  │
│  💡 Tips to Improve             │
│  ┌──────────────────────────┐   │
│  │ • Reduce daily expenses  │   │
│  │   by $10 to reach 90     │   │
│  │ • Increase savings by    │   │
│  │   $50 to reach Excellent │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

### Score Breakdown Logic

**Current calculation (in HomeViewModel):**
```swift
// Already exists - just need to expose breakdown
let healthScore = CalculationEngine.calculateFinancialHealthScore(
    monthlyIncome: totalMonthlyIncome,
    monthlyExpense: totalMonthlyExpense,
    savingsGoal: savingsGoal
)
```

**Need to add:**
```swift
struct HealthScoreBreakdown {
    let totalScore: Int        // 0-100
    let incomeScore: Int       // 0-30 points
    let expenseScore: Int      // 0-30 points
    let savingsScore: Int      // 0-40 points

    let incomeReason: String
    let expenseReason: String
    let savingsReason: String
}
```

**Scoring criteria (already in CalculationEngine):**
- Income score (30 points):
  - 30 pts: Income > $2,000/month
  - 20 pts: Income > $1,000/month
  - 10 pts: Income > $0
  - 0 pts: No income

- Expense score (30 points):
  - 30 pts: Expenses < 50% of income
  - 20 pts: Expenses < 70% of income
  - 10 pts: Expenses < 90% of income
  - 0 pts: Expenses >= income

- Savings score (40 points):
  - 40 pts: Has goal + saving >20% of income
  - 30 pts: Has goal + saving >10% of income
  - 20 pts: Has goal + saving >0%
  - 10 pts: Has goal but not saving
  - 0 pts: No goal

### Tips Generation

**Tip logic:**
```swift
func generateHealthTips(breakdown: HealthScoreBreakdown) -> [HealthTip] {
    var tips: [HealthTip] = []

    // Income tips
    if breakdown.incomeScore < 30 {
        tips.append(HealthTip(
            icon: "💰",
            title: "Increase Your Income",
            description: "Add income sources to improve your score",
            impact: "+\(30 - breakdown.incomeScore) points"
        ))
    }

    // Expense tips
    if breakdown.expenseScore < 30 {
        let reduction = calculateRequiredExpenseReduction()
        tips.append(HealthTip(
            icon: "💸",
            title: "Reduce Daily Expenses",
            description: "Cut expenses by $\(reduction)/day to reach Excellent",
            impact: "+\(30 - breakdown.expenseScore) points"
        ))
    }

    // Savings tips
    if breakdown.savingsScore < 40 {
        if savingsGoal == 0 {
            tips.append(HealthTip(
                icon: "🎯",
                title: "Set a Savings Goal",
                description: "Goals help you save more effectively",
                impact: "+10 points"
            ))
        } else {
            let needed = calculateAdditionalSavingsNeeded()
            tips.append(HealthTip(
                icon: "🏦",
                title: "Increase Savings",
                description: "Save an extra $\(needed)/month to maximize score",
                impact: "+\(40 - breakdown.savingsScore) points"
            ))
        }
    }

    return tips
}
```

### Implementation Tasks

**Backend (Calculations):**
- [ ] Extend `CalculationEngine.swift`
  - [ ] `calculateHealthScoreBreakdown()` → HealthScoreBreakdown
  - [ ] `generateHealthTips()` → [HealthTip]
  - [ ] `calculateRequiredExpenseReduction()` → amount
  - [ ] `calculateAdditionalSavingsNeeded()` → amount
- [ ] Store historical health scores in `FinancialSnapshot`
- [ ] Create `HealthTip` model
  ```swift
  struct HealthTip: Identifiable {
      let id = UUID()
      let icon: String
      let title: String
      let description: String
      let impact: String // "+10 points"
      let actionable: Bool
  }
  ```

**Frontend (UI):**
- [ ] Create `FinancialHealthDetailView.swift`
  - [ ] Large score display with animated ring
  - [ ] Breakdown section with progress bars
  - [ ] Historical chart (30 days)
  - [ ] Tips section
  - [ ] "Learn More" explanations
- [ ] Create `HealthScoreBreakdownView.swift`
  - [ ] 3 rows: Income, Expenses, Savings
  - [ ] Progress bars with labels
  - [ ] Score out of max (25/30)
  - [ ] Color coding (green/yellow/red)
- [ ] Create `HealthTipCardView.swift`
  - [ ] Icon, title, description
  - [ ] Impact badge
  - [ ] Action button (optional)
  - [ ] Gradient background
- [ ] Update `HomeView.swift`
  - [ ] Make health score tappable
  - [ ] Navigate to detail view
  - [ ] Add chevron indicator
- [ ] Create score history chart
  - [ ] Line chart showing last 30 days
  - [ ] Highlight improvements
  - [ ] Show trend arrow

**Premium Integration:**
- [ ] Make detailed breakdown premium-only
- [ ] Show basic score to all users
- [ ] Premium users get:
  - [ ] Full score breakdown
  - [ ] Historical chart
  - [ ] Actionable tips
  - [ ] Benchmarking
- [ ] Add upsell prompt for free users

---

## 📊 Data Model Changes

### New Core Data Entity

```swift
// FinancialSnapshot.xcdatamodeld
entity FinancialSnapshot {
    // Identity
    id: UUID (primary key)
    date: Date (indexed)
    snapshotType: String // "daily", "weekly", "monthly"

    // Financial Data
    totalIncome: Double
    totalExpense: Double
    balance: Double
    netFlow: Double
    savingsAmount: Double

    // Calculated Values
    healthScore: Int16
    savingsRate: Double // percentage

    // Category Breakdown (JSON string)
    categoryBreakdown: String // JSON: {category: amount}

    // Metadata
    createdAt: Date
}
```

### Updated Entities

**AppSettings** (already exists, just add):
```swift
// Notification preferences
weeklySummaryEnabled: Bool (default: true)
weeklySummaryTime: Date (default: 18:00)
milestonesEnabled: Bool (default: true)
spendingAlertsEnabled: Bool (default: true)
dailyEncouragementEnabled: Bool (default: false)

// Last notification timestamps (prevent duplicates)
lastWeeklySummary: Date?
lastMilestoneCheck: Date?
```

---

## 🏗️ File Structure

### New Files to Create

```
budgetmeter.ios/
├── CoreKit/Sources/
│   ├── Services/
│   │   ├── InsightsService.swift          (✨ NEW - 250 lines)
│   │   ├── NotificationService.swift      (✨ NEW - 350 lines)
│   │   └── HistoricalDataService.swift    (✨ NEW - 200 lines)
│   └── Models/
│       ├── Insight.swift                   (✨ NEW - 30 lines)
│       ├── HealthScoreBreakdown.swift      (✨ NEW - 40 lines)
│       └── HealthTip.swift                 (✨ NEW - 25 lines)
│
├── Features/
│   ├── InsightsFeature/
│   │   ├── View/
│   │   │   ├── InsightsView.swift         (✨ NEW - 300 lines)
│   │   │   ├── InsightCardView.swift      (✨ NEW - 100 lines)
│   │   │   └── InsightChartView.swift     (✨ NEW - 200 lines)
│   │   └── ViewModel/
│   │       └── InsightsViewModel.swift    (✨ NEW - 200 lines)
│   │
│   └── FinancialHealthFeature/
│       └── View/
│           ├── FinancialHealthDetailView.swift       (✨ NEW - 300 lines)
│           ├── HealthScoreBreakdownView.swift        (✨ NEW - 150 lines)
│           └── HealthTipCardView.swift               (✨ NEW - 80 lines)
│
└── BudgetMeter.xcdatamodeld
    └── FinancialSnapshot.swift             (✨ NEW entity)
```

### Files to Modify

```
├── CoreKit/Sources/Engine/
│   └── CalculationEngine.swift            (📝 ADD score breakdown methods)
│
├── CoreKit/Sources/Services/
│   └── BackgroundProcessingService.swift  (📝 ADD daily snapshot task)
│
├── CoreKit/Sources/Premium/
│   └── PremiumManager.swift               (📝 ADD insights feature check)
│
├── Features/HomeFeature/
│   ├── View/HomeView.swift                (📝 ADD health score tap navigation)
│   └── ViewModel/HomeViewModel.swift      (📝 ADD health breakdown property)
│
└── ContentView.swift                      (📝 ADD Insights tab)
```

**Estimated Total:** ~2,200 new lines + ~150 modified lines

---

## 📅 Implementation Phases

### Phase 1A: Data Foundation (2-3 days)

**Day 1: Data Models**
- [ ] Create `FinancialSnapshot` Core Data entity
- [ ] Create `Insight`, `HealthScoreBreakdown`, `HealthTip` models
- [ ] Create `HistoricalDataService.swift`
- [ ] Test snapshot saving/loading

**Day 2: Services**
- [ ] Create `InsightsService.swift`
- [ ] Implement all calculation methods
- [ ] Create `NotificationService.swift`
- [ ] Test service methods

**Day 3: Background Tasks**
- [ ] Update `BackgroundProcessingService`
- [ ] Add daily snapshot task
- [ ] Add notification scheduling
- [ ] Test background execution

### Phase 1B: Insights Dashboard (3-4 days)

**Day 4: ViewModel & Logic**
- [ ] Create `InsightsViewModel.swift`
- [ ] Implement data loading
- [ ] Implement refresh logic
- [ ] Add premium checks

**Day 5: UI Components**
- [ ] Create `InsightCardView.swift`
- [ ] Create basic charts
- [ ] Test animations

**Day 6: Main View**
- [ ] Create `InsightsView.swift`
- [ ] Integrate all components
- [ ] Add pull-to-refresh
- [ ] Add loading/empty states

**Day 7: Integration**
- [ ] Add Insights tab to ContentView
- [ ] Test navigation
- [ ] Polish UI
- [ ] Add premium upsell

### Phase 1C: Smart Notifications (2-3 days)

**Day 8: Permission & Settings**
- [ ] Add notification permission request
- [ ] Create settings UI
- [ ] Test permissions

**Day 9: Notification Logic**
- [ ] Implement all notification types
- [ ] Schedule notifications
- [ ] Test scheduling

**Day 10: Testing & Polish**
- [ ] Test all notification triggers
- [ ] Test deep linking
- [ ] Add notification history (optional)

### Phase 1D: Financial Health Details (2 days)

**Day 11: Backend**
- [ ] Extend CalculationEngine
- [ ] Implement tip generation
- [ ] Store historical scores

**Day 12: Frontend**
- [ ] Create detail view
- [ ] Create breakdown view
- [ ] Create tip cards
- [ ] Integrate with HomeView

### Phase 1E: Testing & Polish (1-2 days)

**Day 13-14:**
- [ ] Full app testing
- [ ] Fix bugs
- [ ] Performance optimization
- [ ] UI polish
- [ ] Animations
- [ ] Haptic feedback
- [ ] Accessibility
- [ ] Dark mode testing

**Total: 12-14 days**

---

## ✅ Testing Checklist

### Insights Dashboard
- [ ] Pie chart displays correct percentages
- [ ] Month comparison shows accurate data
- [ ] Trend chart displays 30 days correctly
- [ ] Insights update when data changes
- [ ] Pull-to-refresh works
- [ ] Loading states display correctly
- [ ] Empty state shows when no data
- [ ] Premium upsell shows for free users
- [ ] Premium users see all features
- [ ] Works in dark mode
- [ ] Animations are smooth
- [ ] Charts are readable on small screens

### Smart Notifications
- [ ] Permission request appears correctly
- [ ] Weekly summary sends on Sunday 6 PM
- [ ] Milestone notifications trigger correctly
- [ ] Spending alerts detect overspending
- [ ] Goal achievement notification sends
- [ ] Notifications don't duplicate
- [ ] Deep links navigate correctly
- [ ] Settings toggles work
- [ ] Custom time picker works
- [ ] Test notification button works
- [ ] Notifications respect user preferences
- [ ] Works with Do Not Disturb

### Financial Health Details
- [ ] Score breakdown calculates correctly
- [ ] Progress bars display accurately
- [ ] Historical chart shows 30 days
- [ ] Tips are relevant and actionable
- [ ] Impact calculations are correct
- [ ] Tapping health score opens detail
- [ ] Navigation works smoothly
- [ ] Premium upsell shows for free users
- [ ] Updates when data changes
- [ ] Works in dark mode
- [ ] Ring animation is smooth

### General
- [ ] No crashes
- [ ] No memory leaks
- [ ] Good performance (60 FPS)
- [ ] Works offline
- [ ] CloudKit sync works
- [ ] Widgets update correctly
- [ ] Localization works (all 10 languages)
- [ ] Accessibility labels present
- [ ] VoiceOver works
- [ ] Dynamic Type supported

---

## 🎨 Design Guidelines

### Colors
```swift
// Insight cards
.blue   // Balance, income
.green  // Savings, positive trends
.orange // Warnings, alerts
.purple // Goals, milestones
.red    // Overspending, negative

// Gradients
LinearGradient([.blue, .cyan])      // Insights
LinearGradient([.green, .mint])     // Health
LinearGradient([.purple, .pink])    // Goals
```

### Animations
```swift
// Card appearance
.transition(.scale.combined(with: .opacity))
.animation(.spring(response: 0.4, dampingFraction: 0.7))

// Number counting
.contentTransition(.numericText())

// Chart appearance
.animation(.easeInOut(duration: 0.8))
```

### Typography
```swift
// Insight value
.font(.system(size: 32, weight: .bold, design: .rounded))

// Insight label
.font(.subheadline)

// Tips
.font(.body)

// Impact
.font(.caption).fontWeight(.semibold)
```

---

## 💎 Premium vs Free Split

### Free Users Get:
✅ Basic financial health score (number only)
✅ Weekly summary notification
✅ Goal achievement notification
❌ Insights Dashboard (locked)
❌ Score breakdown (locked)
❌ Health tips (locked)
❌ Historical charts (locked)
❌ Daily encouragement (locked)
❌ Customized notifications (locked)

### Premium Users Get:
✅ Everything from free
✅ Full Insights Dashboard
✅ Complete score breakdown
✅ Actionable health tips
✅ 30-day trend charts
✅ All notification types
✅ Notification customization
✅ Historical data (12 months)

### Upsell Moments:
1. Tap Insights tab → "Premium Feature"
2. Tap health score → Show basic, blur details
3. Open notifications settings → Lock advanced options
4. After 7 days → "Unlock insights to see your progress!"

---

## 🚀 Launch Checklist

Before releasing Phase 1:
- [ ] All features tested
- [ ] No critical bugs
- [ ] Performance optimized
- [ ] Premium paywall working
- [ ] App Store screenshots updated
- [ ] App Store description updated
- [ ] Privacy policy updated (notifications)
- [ ] TestFlight beta tested
- [ ] Analytics events added
- [ ] Crash reporting configured
- [ ] App version incremented
- [ ] Release notes written

---

## 📈 Success Metrics

Track these after launch:
- **Engagement:** Daily active users
- **Retention:** 7-day retention rate
- **Premium:** Conversion rate to premium
- **Notifications:** Open rate, click rate
- **Insights:** Tab views, time spent
- **Health:** Detail view opens

**Target Goals:**
- 50%+ 7-day retention
- 10%+ premium conversion
- 30%+ notification open rate
- 2+ minutes in Insights tab

---

## 🎯 Next Steps

**To proceed:**
1. Review this plan
2. Approve or request changes
3. I'll start with Phase 1A (Data Foundation)
4. We'll go step-by-step, committing after each major component

**Questions to answer:**
1. Should Insights be a new tab or in Settings?
2. What notification time works best (currently Sunday 6 PM)?
3. Any specific insights you want prioritized?
4. Should we do TestFlight beta before full release?

---

**Ready to start? Let me know and I'll begin with the data models!** 🚀
