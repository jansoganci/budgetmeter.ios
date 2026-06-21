# Phase 3 — Home Dashboard Scope

## 1. Phase 3 Goal

Redesign Home into the main financial pace dashboard: a dark-first, momentum-focused screen that answers, "Am I financially moving forward or slowing down, and how fast?"

Phase 3 must make Home consume the shared `FinancialSummaryBuilder` output before changing the visual hierarchy.

## 2. Current Home Problem Summary

Current Home still calculates from its own local pipeline:

- `HomeViewModel` fetches `FinancialCategory` directly.
- Home manually buckets daily/monthly/yearly income and expenses.
- Home does not yet use `FinancialSummaryBuilder`.
- Home can disagree with subscriptions, bills, recurring automation, savings, charts, and widgets.
- Home still has mock chart/trend generation.
- Savings display mixes legacy `AppSettings.savingsGoalAmount` with `SavingsGoalManager`.

This conflicts with the product decision that Home, savings, charts, and widgets must read one shared financial summary.

## 3. Required First Step

Before UI redesign, migrate `HomeViewModel` to use `FinancialSummaryBuilder`.

Home should treat `FinancialSummary` as the source for:

- net daily pace
- net minute pace
- pace status
- monthly recurring income/expense/net display
- biggest drain
- savings remaining and time-to-goal
- live session net, where needed

Do not start the momentum hero/ring until this data source migration is complete.

## 4. Files Allowed To Touch

Phase 3 implementation may touch:

- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- `budgetmeter.ios/Features/HomeFeature/View/HomeView.swift`
- `budgetmeter.ios/Features/HomeFeature/View/QuickSavingsGoalInputView.swift` only if needed for current Home savings entry compatibility
- `budgetmeter.ios/DesignSystem/Components/Cards/` for Home-specific reusable card components
- `budgetmeter.ios/DesignSystem/Components/Indicators/` for a momentum ring/pace indicator
- `budgetmeter.iosTests/FinancialSummaryBuilderTests.swift`
- a new focused Home ViewModel test file, if needed
- localization resources only for new Home copy, if the implementation step requires it

## 5. Files Not Allowed To Touch

Phase 3 must not touch:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- CoreData schema/model versions
- `budgetmeter.ios/CoreKit/Sources/Auth/**`
- Supabase/Auth files
- `budgetmeter.ios/Widgets/**`
- widget targets or App Group setup
- premium gates, StoreKit, paywall, or entitlement logic
- CloudKit setup/removal behavior
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryBuilder.swift`, unless a small tested display-only gap is explicitly required
- `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryModels.swift`, unless a small tested display-only gap is explicitly required

## 6. Step-By-Step Implementation Sequence

1. Add/adjust tests that prove Home display values can be derived from `FinancialSummary`.
2. Update `HomeViewModel` to build a `FinancialSummary` for the default period.
3. Preserve existing published fields temporarily while backing them from `FinancialSummary`.
4. Add new Home display fields for pace hero data.
5. Replace savings ETA display with `FinancialSummary.savingsRemaining` and `savingsTimeToGoal`.
6. Add biggest-drain display state from `FinancialSummary.biggestDrain`.
7. Add the momentum hero/ring component.
8. Update `HomeView` section order around the new hero.
9. Clean up old daily-budget-first layout pieces that no longer fit the Home hierarchy.
10. Remove mock chart/trend generation from the active Home path.
11. Run the agreed build/test checkpoints.

## 7. Home Display Fields Needed

`HomeViewModel` should expose display-ready state for:

- `netDailyPace`: from `FinancialSummary.netPacePerDay`
- `netMinutePace`: from `FinancialSummary.netPacePerMinute`
- `paceStatus`: from `FinancialSummary.paceStatus`
- `paceStatusCopy`: examples: "Moving forward +$12/day", "Slowing down -$8/day"
- `biggestDrain`: from `FinancialSummary.biggestDrain`
- `savingsRemaining`: from `FinancialSummary.savingsRemaining`
- `savingsTimeToGoal`: from `FinancialSummary.savingsTimeToGoal`
- `currencyCode` / `currencySymbol`
- monthly recurring income, expense, and net, while the old summary cards remain

## 8. UI Sequence

Implementation order must be:

1. Data source first: move Home to `FinancialSummaryBuilder`.
2. Hero display fields: expose daily pace, minute pace, status, biggest drain, and savings state.
3. Momentum hero/ring: add the visual component and bind it to real summary values.
4. Layout cleanup: make Home hero-first and keep quick actions accessible.
5. Remove mock chart/trend logic from Home's active dashboard path.

## 9. Tests Required

Required test coverage:

- Home or builder-backed mapping uses daily pace as the default Home value.
- Minute pace derives from the same daily pace.
- Pace status copy maps positive, negative, neutral, and insufficient-data states.
- Biggest drain comes from the shared summary.
- Savings remaining and time-to-goal use the shared summary.
- One-time entries do not alter recurring pace.
- Home does not require subscriptions, bills, recurring transactions, or widgets to calculate separately.

## 10. Build/Test Checkpoints

Run checkpoints after each small implementation step:

1. After data-source migration: relevant Home/builder tests.
2. After hero display fields: relevant Home/builder tests.
3. After UI component work: full test suite if practical.
4. Before Phase 3 completion: app build.

Expected commands:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Known existing warnings/test drift should be documented separately from Phase 3 regressions.

## 11. Success Criteria

Phase 3 is complete when:

- Home uses `FinancialSummaryBuilder` as its financial data source.
- Home no longer independently aggregates `FinancialCategory` for pace totals.
- The first visible Home dashboard state is momentum pace, not daily budget.
- Default pace unit is day.
- Minute pace is present as a secondary live metric.
- Positive/negative copy is gentle and clear.
- Biggest drain and basic savings state come from the shared summary.
- Mock chart/trend values are removed from the active Home path.
- Build passes.
- Required tests pass or any pre-existing failures are explicitly documented.

## 12. Postponed

Do not include in Phase 3:

- CoreData schema changes
- Supabase/Auth work
- CloudKit removal or sync changes
- widgets
- premium gate changes
- StoreKit cleanup
- advanced forecasting
- full weekly recap
- awareness streak implementation unless it is display-only and backed by existing safe state
- advanced charts/history
- Pulsey-heavy Home presence
- income/expense entry-flow redesign
- savings multi-goal redesign
