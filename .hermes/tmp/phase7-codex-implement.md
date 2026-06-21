Implement premium gates for the 2 identified gaps in BudgetMeter iOS.

The project is at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Context
Phase 7 implemented BudgetMeterCapability matrix. Two premium capabilities are NOT gated in code:
- subscriptionTracking (Expense screen subscriptions section)
- recurringAutomation (BackgroundProcessingService + RecurringTransactionsViewModel)

## Changes to make

### Fix 1: BackgroundProcessingService.swift
File: budgetmeter.ios/CoreKit/Sources/Background/BackgroundProcessingService.swift

In the `processRecurringTransactions()` method, add a premium guard at the TOP (before fetching RecurringTransaction records):

```swift
private func processRecurringTransactions() async {
    let canProcess = await MainActor.run {
        PremiumManager.shared.hasAccess(to: BudgetMeterCapability.recurringAutomation)
    }
    guard canProcess else {
        print("BackgroundProcessingService: Recurring automation skipped; premium required")
        return
    }
    // ... existing code
}
```

### Fix 2: RecurringTransactionsViewModel.swift
File: budgetmeter.ios/Features/RecurringTransactionsFeature/ViewModel/RecurringTransactionsViewModel.swift

In the `processDueTransactions()` method, add a premium guard at the TOP (before the loop):

```swift
func processDueTransactions() async {
    guard PremiumManager.shared.hasAccess(to: BudgetMeterCapability.recurringAutomation) else {
        print("RecurringTransactionsViewModel: Recurring automation skipped; premium required")
        return
    }
    // ... existing code
}
```

### Fix 3: ExpenseView.swift
File: budgetmeter.ios/Features/ExpensesFeature/View/ExpenseView.swift

- Import PremiumManager if not already imported
- Add `@StateObject private var premiumManager = PremiumManager.shared` 
- Add `@State private var showingSubscriptionPaywall = false`
- Replace the always-rendered `subscriptionsSection` with a premium gate:
  - If premium, show subscriptionsSection
  - If not premium, show a locked state message
- Add a `.sheet` for the paywall

Follow the EXACT patterns used in SavingsGoalsView.swift (lines 19-20 and 64-69 for premium gate + paywall).

## Build & Verify
After changes:
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

IMPORTANT: Only modify the 3 files listed above. Do NOT touch any other files.
