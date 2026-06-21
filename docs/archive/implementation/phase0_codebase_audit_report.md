# Phase 0 Codebase Audit Report

Date: 2026-06-16

Scope: current codebase reality only. No Swift, Xcode project, or CoreData model files were modified.

Primary contract references:

- `docs/product_decisions_v1.md`
- `docs/implementation/implementation_planning_index.md`
- `docs/implementation/codebase_audit_plan.md`

## Executive Summary

The app currently builds for an available iOS Simulator, but tests do not run because the Xcode scheme has no test action and the project has no configured test target.

The live app is a local-first SwiftUI/CoreData app with a `TabView` rooted at Home, Income, Expenses, gated Insights, and Settings. CoreData is already configured through `NSPersistentCloudKitContainer`, and the active model version is `BudgetMeter 2.xcdatamodel`.

The current implementation is not yet aligned with the product contract for the redesign phases. Financial data is split across `FinancialCategory`, `RecurringTransaction`, `Subscription`, `Bill`, `BillPayment`, `SavingsGoal`, and `AppSettings`. Home currently reads only `FinancialCategory` plus parts of savings settings/goals, while Expenses also includes subscriptions. That means screens can disagree about financial totals.

Widgets are code-present but not product-functional as shipped: the Xcode project has no widget extension target, and widget files are excluded from the app target. Existing widget code also exceeds v1 scope by including medium/large and lock-screen widgets.

Supabase is already present in the project dependency graph and `CoreKit/Sources/Auth/SupabaseConfig.swift`, but Phase 0 did not evaluate it as an implementation target. It should be treated as existing risky state and left untouched until the later Auth/Supabase phase.

## Build/Test Status

Build command used:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Result: build succeeded.

Important build notes:

- `xcodebuild -list -project budgetmeter.ios.xcodeproj` shows one target: `budgetmeter.ios`.
- The only scheme is `budgetmeter.ios`.
- The scheme did not build on an unavailable `iPhone 16` simulator, but it built successfully on `iPhone 17` with iOS 26.5.
- Build warning: `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.`
- Build warnings show Swift 6 isolation risks around `PremiumManager.shared` in:
  - `budgetmeter.ios/Features/InsightsFeature/ViewModel/HealthDetailsViewModel.swift`
  - `budgetmeter.ios/Features/InsightsFeature/ViewModel/InsightsViewModel.swift`
  - `budgetmeter.ios/Features/SettingsFeature/ViewModels/NotificationSettingsViewModel.swift`
- Build warning: duplicate Copy Bundle Resources entries for `.xcstrings` files in `budgetmeter.ios/Resources/`.
- Build warning: `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift` has an unused `guard let self = self` binding.
- Build warning: `budgetmeter.ios/Features/InsightsFeature/ViewModel/InsightsViewModel.swift` has an unreachable `catch`.
- Build warning: `budgetmeter.ios/Features/BillsFeature/Services/BillManager.swift` has an unused `newBill` value.

Test command used:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

Result: tests do not run.

Reason:

- `xcodebuild` reports: `Scheme budgetmeter.ios is not currently configured for the test action.`
- `xcodebuild -list` shows no test target.
- `budgetmeter.iosTests/README.md` says the tests were created outside Xcode and require manual test target creation/configuration.

Existing test files:

- `budgetmeter.iosTests/CalculationEngineTests.swift`
- `budgetmeter.iosTests/ViewModelCalculationTests.swift`
- `budgetmeter.iosTests/README.md`

## Architecture Findings

Entry point:

- `budgetmeter.ios/budgetmeter_iosApp.swift`

Startup behavior:

- Initializes `BiometricManager.shared`.
- Initializes `ThemeManager.shared`.
- Applies stored theme.
- Runs `DataSeedingService().seedInitialDataIfNeeded()`.
- Runs `CustomCategoryMigrationService().performMigrationIfNeeded()`.
- Schedules background processing through `BackgroundProcessingService.shared.scheduleBackgroundProcessing()`.
- Injects `PersistenceService.shared.viewContext` into `ContentView`.
- Handles deep links for `budgetmeter://home`, `budgetmeter://expenses`, and `budgetmeter://income`.

Current root navigation:

- `budgetmeter.ios/ContentView.swift`
- Root is a SwiftUI `TabView`.
- Tabs:
  - `HomeView`
  - `IncomeView`
  - `ExpenseView`
  - `PremiumFeatureView(premiumFeature: .spendingInsights) { InsightsView() }`
  - `SettingsView`

Current module layout:

- Feature code lives under `budgetmeter.ios/Features/`.
- Shared services and core logic live under `budgetmeter.ios/CoreKit/Sources/`.
- Design components live under `budgetmeter.ios/DesignSystem/`.
- Resources live under `budgetmeter.ios/Resources/`.
- Widgets live under `budgetmeter.ios/Widgets/`, but are not backed by an extension target.

Architecture pattern:

- Most feature screens use SwiftUI Views plus `ObservableObject` ViewModels.
- Several ViewModels and managers fetch CoreData directly.
- `PersistenceService.shared` is the central CoreData stack, but there is not one shared financial read model for Home, savings, widgets, and charts.

Highest-risk architecture files:

- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.ios/Features/PremiumFeature/Services/PremiumManager.swift`
- `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift`

## Data/Persistence Findings

CoreData stack:

- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- Uses `NSPersistentCloudKitContainer(name: "BudgetMeter")`.
- Enables persistent history tracking.
- Enables remote change notifications.
- Sets `viewContext.automaticallyMergesChangesFromParent = true`.
- Attempts to place the SQLite store in App Group `group.com.budgetmeter.shared`.
- Exposes `viewContext`, `save()`, `resetData()`, `fetchAppSettings()`, and CloudKit availability state.

Active CoreData version:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/.xccurrentversion`
- Current version is `BudgetMeter 2.xcdatamodel`.

CoreData model files:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/BudgetMeter.xcdatamodel/contents`
- `budgetmeter.ios/BudgetMeter.xcdatamodeld/BudgetMeter 2.xcdatamodel/contents`

CloudKit model status:

- Both model versions include `usedWithCloudKit="YES"`.

Entities in active model:

- `AppSettings`
- `FinancialCategory`
- `RecurringTransaction`
- `FinancialSnapshot`
- `Subscription`
- `Bill`
- `BillPayment`
- `SavingsGoal`

Income and expenses today:

- `FinancialCategory` is the main income/expense category/value entity.
- Type is stored as string values such as `income` and `expense`.
- Frequency is stored as string values such as `daily`, `monthly`, and `yearly`.
- Existing Home, Income, and Expense flows treat category amount as recurring frequency amount, not as a transaction ledger.
- There is no clean, centralized one-time income/expense model in the current main flow.

Recurring data today:

- `RecurringTransaction` is a separate entity with its own frequency, schedule, due date, active state, and processing fields.
- `RecurringTransactionsViewModel` can process due transactions by creating `FinancialCategory` rows with `frequency = "recurring"`.
- Home/Income/Expense calculations mostly filter to `daily`, `monthly`, and `yearly`, so recurring-generated `FinancialCategory` rows risk being excluded from totals.

Bills/subscriptions today:

- `Subscription` and `Bill` are separate entities.
- `ExpenseViewModel` includes active subscriptions in total monthly expenses.
- Home does not include subscriptions or bills in the same way.
- Bills are managed separately through `BillManager` and are not clearly part of Home's financial total pipeline.

Savings today:

- `AppSettings.savingsGoalAmount` stores a legacy/single savings target.
- `SavingsGoal` stores multiple richer goals with target/current amounts, target date, color, image, category, contribution, and archive/completion fields.
- Home reads both `AppSettings.savingsGoalAmount` and the first active `SavingsGoal` from `SavingsGoalManager`.
- This creates a dual-source savings state that can diverge.

CloudKit configuration:

- CoreData is configured through `NSPersistentCloudKitContainer`.
- The model is marked `usedWithCloudKit="YES"`.
- `PersistenceService.isCloudKitAvailable` checks `FileManager.default.ubiquityIdentityToken`.
- No `.entitlements` file was found under `budgetmeter.ios/`.
- The project has generated Info.plist settings, but no explicit CloudKit/App Group entitlement file was found during Phase 0.
- The code attempts to use App Group storage at `group.com.budgetmeter.shared`, which needs entitlement verification before widget or shared-storage work.

Supabase existing state:

- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseConfig.swift` exists.
- `budgetmeter.ios.xcodeproj/project.pbxproj` includes Supabase package products.
- `xcodebuild -list` resolves `supabase-swift` at `2.47.2`.
- This is current project state, but it is out of scope for Phase 0 implementation and must not be expanded before the later Auth/Supabase phase.

## Calculation Findings

Shared calculation file:

- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`

Current behavior:

- Provides stateless formulas for daily, monthly, weekly, hourly, and yearly income/expense/net flow.
- Uses constants:
  - `daysPerMonth = 30.4375`
  - `daysPerYear = 365.25`
  - `hoursPerDay = 24`
- Monthly totals are normalized from daily/monthly/yearly inputs.
- Daily totals are normalized from daily/monthly/yearly inputs.
- Savings target time is calculated from `targetAmount / netHourlyFlow`.
- Health score has multiple APIs, including a 10-point ratio score and a 0-100 score with breakdowns/tips.

Current gaps against the product contract:

- There is no single shared Home financial summary/read model used by Home, savings, widgets, and charts.
- Home has additional calculation and mock/trend logic inside `HomeViewModel`.
- Expense and Home totals can disagree because subscriptions are included in Expenses but not Home.
- Widget code reads CoreData and calculates independently.
- Some health-score display strings and insight/tip content are hardcoded English.

Home calculation files:

- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`

Mock calculation/data risks:

- `HomeViewModel.generateChartData()` creates mock historical chart data.
- `HomeViewModel.calculateTrendPercentage()` uses mock/random trend behavior.
- These are not safe as product-contract financial outputs.

## Feature Findings

Home:

- `budgetmeter.ios/Features/HomeFeature/View/HomeView.swift`
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- Home loads all `FinancialCategory` rows and filters by:
  - type: `income` / `expense`
  - frequency: `daily` / `monthly` / `yearly`
- Home does not include `Subscription`, `Bill`, or `RecurringTransaction` data in the same pipeline.
- Home saves a legacy savings target through `AppSettings.savingsGoalAmount`.
- Home separately loads a primary `SavingsGoal`.
- Home imports WidgetKit and triggers widget reloads.

Income:

- `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift`
- Income reads `FinancialCategory` where `type == "income"`.
- It groups by `daily`, `monthly`, and `yearly`.
- It updates category amounts directly and saves through CoreData.
- It uses `CalculationEngine.totalMonthlyIncome`.
- Some currency formatting/parsing uses `Locale(identifier: "en_US")`, which is a localization risk.

Expenses:

- `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`
- Expenses reads `FinancialCategory` where `type == "expense"`.
- It groups by `daily`, `monthly`, and `yearly`.
- It also loads active subscriptions from `SubscriptionManager` and adds them to monthly expense totals.
- It does not clearly include bills in the same total pipeline.
- This differs from Home's data source.

Savings goals:

- `budgetmeter.ios/Features/SavingsGoalsFeature/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/ViewModels/SavingsGoalsViewModel.swift`
- Supports multiple goals, current amount, target amount, target date, image/color/emoji, priority, archiving, and completion.
- Current code supports more than the v1 product contract's basic free savings scope.
- Premium boundaries for one free goal vs multiple premium goals are not centralized at the data/service layer.

Bills:

- `budgetmeter.ios/Features/BillsFeature/Services/BillManager.swift`
- Separate bill entity and notification/reminder behavior.
- Not clearly integrated into Home's financial pace.

Subscriptions:

- `budgetmeter.ios/Features/SubscriptionsFeature/Services/SubscriptionManager.swift`
- Separate subscription entity and monthly cost calculation.
- Included in Expense total but not Home total.
- Uses its own monthly conversion logic instead of a single calculation contract.

Recurring transactions:

- `budgetmeter.ios/Features/RecurringTransactionsFeature/ViewModels/RecurringTransactionsViewModel.swift`
- Separate recurring entity and processing pipeline.
- Processed transactions can become `FinancialCategory` records with `frequency = "recurring"`, which current main totals may ignore.

## Premium/Widget Findings

Premium:

- `budgetmeter.ios/Features/PremiumFeature/Services/PremiumManager.swift`
- Uses StoreKit.
- Product ID: `com.budgetmeter.premium.lifetime`.
- Entitlement state is cached in CoreData through `AppSettings.isPremiumUser` and `AppSettings.premiumPurchaseDate`.
- Purchase/restore logic exists.
- Current `PremiumFeature` cases include:
  - custom categories
  - subscription tracking
  - bill reminders
  - savings goals
  - recurring transactions
  - data export
  - widgets
  - spending insights
  - biometric lock
  - premium themes

Premium risks:

- Current premium matrix does not yet match `docs/product_decisions_v1.md`.
- Feature names/descriptions are hardcoded English.
- StoreKit actor-isolation warnings should be resolved before Swift 6 migration.
- `PremiumPaywallView` includes placeholder legal links and hardcoded/default pricing text.
- Insights tab is gated through `PremiumFeatureView` in `ContentView`, but other premium boundaries are distributed across features.

Widgets:

- `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift`
- `budgetmeter.ios/Widgets/CombinedBalanceSavingsWidget.swift`
- `budgetmeter.ios/Widgets/LockScreenWidgets.swift`
- `WIDGET_GUIDE.md`
- `CLAUDE.md`

Widget target status:

- `xcodebuild -list` shows no widget extension target.
- `budgetmeter.ios.xcodeproj/project.pbxproj` has only the app target.
- Widget Swift files are excluded from the app target through membership exceptions.
- `WIDGET_GUIDE.md` describes widget extension setup as still required.

Widget functionality conclusion:

- Widgets are code-present/planned, not currently functional as a shipped extension target.

Widget scope risks:

- Existing widget code includes system medium/large and lock-screen widgets.
- Product contract v1 calls for a premium Home Screen `systemSmall` widget only.
- Existing widgets read CoreData directly instead of a shared Home summary.
- Existing widget code does not enforce the planned locked teaser behavior as a central premium state.

## Risk List

1. Test target is not configured, so calculation and ViewModel tests cannot currently protect refactors.
2. CoreData model is CloudKit-enabled, but entitlements/App Group configuration need verification before persistence or widget work.
3. Home, Expenses, Widgets, Bills, Subscriptions, and Recurring Transactions do not share one financial summary pipeline.
4. Home financial data excludes subscriptions, bills, and recurring transactions that other features model separately.
5. Savings state has two sources: `AppSettings.savingsGoalAmount` and `SavingsGoal`.
6. Widget code exists but no extension target exists; treating widgets as functional would be incorrect.
7. Existing widget scope exceeds v1 product scope.
8. Premium gates are broad and distributed; they do not yet match the product decision matrix.
9. Supabase dependency/config is already present even though Auth/Supabase work should be later-phase only.
10. Localization risk exists from hardcoded strings in premium, widgets, insights, notifications, charts, and legal/privacy copy.
11. Duplicate `.xcstrings` resource build warnings suggest Xcode resource configuration needs later cleanup.
12. Some currency parsing/formatting uses `en_US` directly.
13. `SettingsView` privacy/legal copy appears stale relative to planned Supabase and one-time premium purchase decisions.
14. CoreData schema changes are high risk because live users may already have CloudKit-backed data.
15. Project/test/widget target changes are high risk and must be isolated to later approved phases.

## Safe-To-Reuse List

Safe to reuse as references/contracts, with targeted refactor later:

- `docs/product_decisions_v1.md`
- `docs/implementation/implementation_planning_index.md`
- `docs/implementation/codebase_audit_plan.md`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift`
- `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/Features/PremiumFeature/Services/PremiumManager.swift`
- `budgetmeter.ios/Resources/*.xcstrings`
- `budgetmeter.iosTests/CalculationEngineTests.swift`
- `budgetmeter.iosTests/ViewModelCalculationTests.swift`

Safe to reuse cautiously as implementation examples, not as product truth:

- `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift`
- `budgetmeter.ios/Widgets/CombinedBalanceSavingsWidget.swift`
- `budgetmeter.ios/Widgets/LockScreenWidgets.swift`
- `budgetmeter.ios/Features/BillsFeature/Services/BillManager.swift`
- `budgetmeter.ios/Features/SubscriptionsFeature/Services/SubscriptionManager.swift`
- `budgetmeter.ios/Features/RecurringTransactionsFeature/ViewModels/RecurringTransactionsViewModel.swift`

## Risky Files

Do not edit without an explicit later-phase prompt and migration/test plan:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/`
- `budgetmeter.ios.xcodeproj/project.pbxproj`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.ios/Features/PremiumFeature/Services/PremiumManager.swift`
- `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift`
- `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/Features/BillsFeature/Services/BillManager.swift`
- `budgetmeter.ios/Features/SubscriptionsFeature/Services/SubscriptionManager.swift`
- `budgetmeter.ios/Features/RecurringTransactionsFeature/ViewModels/RecurringTransactionsViewModel.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseConfig.swift`
- `budgetmeter.ios/Widgets/`

## Must Not Be Touched Before Later Phases

Before Phase 1:

- Do not modify Swift app code.
- Do not modify `budgetmeter.ios.xcodeproj/project.pbxproj`.
- Do not modify `budgetmeter.ios/BudgetMeter.xcdatamodeld/`.
- Do not implement UI redesign.
- Do not add or change Supabase/Auth behavior.
- Do not add widget targets or change widget scope.
- Do not change premium gates.
- Do not change persistence or migration behavior.

Before a data-model safety phase:

- Do not add/remove CoreData entities.
- Do not rename attributes.
- Do not change CloudKit-backed model configuration.
- Do not migrate `FinancialCategory`, `SavingsGoal`, `Bill`, `Subscription`, or `RecurringTransaction`.

Before a widget phase:

- Do not create a widget extension target.
- Do not enable App Groups.
- Do not promote current widget code as functional v1 behavior.

Before an Auth/Supabase phase:

- Do not expand `CoreKit/Sources/Auth/`.
- Do not connect sign-in flows.
- Do not migrate local/CoreData/CloudKit data to Supabase.
- Do not remove or disable CloudKit.

## Phase 1 Readiness Recommendation

Phase 1 can proceed only as a documentation-backed calculation contract phase.

Recommended Phase 1 scope:

- Define a shared financial summary contract for Home, savings, charts, and widgets.
- Map current inputs from `FinancialCategory`, `Subscription`, `Bill`, and `RecurringTransaction` without changing the schema yet.
- Decide which current values are included in net daily pace, monthly totals, savings time, and widget state.
- Convert existing calculation tests into an executable test target only when Xcode project edits are explicitly allowed.
- Do not change CoreData, CloudKit, Supabase/Auth, widgets, premium gates, or UI in Phase 1.

Phase 1 should not begin with implementation until the team accepts the current risk that Home and Expenses currently calculate from different data sources.
