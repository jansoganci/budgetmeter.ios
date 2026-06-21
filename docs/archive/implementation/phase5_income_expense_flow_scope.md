# Phase 5 — Income / Expense Flow Scope

## 1. Executive Summary

Phase 5 should align Income and Expense entry/display flows with the shared financial summary contract.

Current Income and Expense screens still fetch `FinancialCategory` directly, bucket by `daily` / `monthly` / `yearly`, and compute summary totals in their ViewModels. Expense also adds subscriptions through `SubscriptionManager`, while bills are not visible in the Expense summary even though `FinancialSummaryBuilder` already rolls subscriptions, bills, recurring transactions, recurring categories, and one-time categories into one shared summary.

Recommendation: **Ready for implementation planning, not started.** First safe implementation step: add tests that define Income/Expense summary mapping from `FinancialSummaryBuilder` before changing UI.

## 2. Current Income Flow Summary

Current Income flow:

- `IncomeView` shows a monthly summary card and collapsible Daily, Monthly, and Yearly sections.
- `IncomeViewModel` fetches `FinancialCategory` where `type == "income"`.
- Categories are split by `frequency == "daily"`, `"monthly"`, and `"yearly"`.
- Summary values are computed inside the ViewModel:
  - monthly income via `CalculationEngine.totalMonthlyIncome`
  - daily average via `totalMonthlyIncome / CalculationEngine.daysPerMonth`
  - yearly projection via `totalMonthlyIncome * 12`
- Editing an existing category updates `FinancialCategory.amount`.
- Creating a new custom category is routed through `CreateCategoryModal`.
- Current flow has no explicit one-time income entry path.
- Current flow does not use `FinancialSummaryBuilder`.

## 3. Current Expense Flow Summary

Current Expense flow:

- `ExpenseView` shows a monthly summary card and collapsible Daily, Monthly, Subscriptions, and Yearly sections.
- `ExpenseViewModel` fetches `FinancialCategory` where `type == "expense"`.
- Categories are split by `frequency == "daily"`, `"monthly"`, and `"yearly"`.
- Summary values are computed inside the ViewModel:
  - category monthly expense via `CalculationEngine.totalMonthlyExpense`
  - subscription monthly expense via `SubscriptionManager.getTotalMonthlyCost`
  - daily average via `totalMonthlyExpenses / CalculationEngine.daysPerMonth`
  - yearly projection via `totalMonthlyExpenses * 12`
- Subscription rows are displayed inside Expense through `SubscriptionManager`.
- Bills are not included in the Expense screen summary today.
- Current flow has no explicit surprise/one-time expense entry path.
- Current flow does not use `FinancialSummaryBuilder`.

## 4. Current Subscription / Bill / Recurring Relationship

Subscriptions:

- Stored as `Subscription`.
- Managed by `SubscriptionManager`.
- Expense summary adds active subscription totals separately.
- `FinancialSummaryBuilder` already rolls active, unpaused subscriptions into recurring expense lines.

Bills:

- Stored as `Bill`.
- Managed by `BillManager`.
- Bills UI focuses on due/paid calendar state.
- Expense summary does not include bills today.
- `FinancialSummaryBuilder` already rolls unpaid recurring bills into recurring expense lines.

Recurring transactions:

- Stored as `RecurringTransaction`.
- Managed by `RecurringTransactionsViewModel`.
- Builder treats active recurring transactions as recurring income/expense lines.
- Current processing still creates `FinancialCategory` rows with `frequency = "recurring"`.
- Phase 2 migration reclassifies legacy `frequency == "recurring"` category rows as `entryKind = "oneTime"`.

## 5. Current Data Problems

- `FinancialCategory` is still used as both category and money-line storage.
- Income/Expense screens ignore `entryKind`, `occurrenceDate`, `sourceType`, and `sourceID`.
- One-time income/expense cannot be entered intentionally from current Income/Expense UI.
- Weekly frequency is supported by the builder but not exposed in current Income/Expense sections.
- Expense includes subscriptions manually but not bills, creating summary drift.
- Recurring automation can still create `frequency = "recurring"` category rows.
- Custom category creation is tied to premium UI; basic entry must remain free without changing premium gates in Phase 5.

## 6. Current Calculation Duplication Risks

Duplicated or parallel calculations:

- `IncomeViewModel.totalMonthlyIncome`
- `IncomeViewModel.dailyAverageIncome`
- `IncomeViewModel.yearlyProjectionIncome`
- `ExpenseViewModel.totalMonthlyExpenses`
- `ExpenseViewModel.subscriptionsTotalMonthly`
- `ExpenseViewModel.subscriptionsTotalYearly`
- `ExpenseViewModel.dailyAverageExpenses`
- `ExpenseViewModel.yearlyProjectionExpenses`
- `SubscriptionManager.calculateMonthlyCost`
- `BillManager.getTotalDueThisMonth` and `getTotalPaidThisMonth` for calendar views
- `ViewModelCalculationTests` still assert ViewModel-style formulas instead of summary-consumer behavior

Phase 5 should make Income/Expense summary cards consume shared summary values rather than re-aggregate formulas.

## 7. Required Phase 5 Product Behavior

Phase 5 must support:

- Basic income entry as free.
- Basic expense entry as free.
- Basic recurring income/expense entry as free.
- One-time income/expense entry as free core behavior.
- Recurring automation as premium and separate from basic recurring entry.
- Bills/subscriptions as specialized regular expenses.
- One-time entries included only in their selected/current period.
- One-time entries excluded from permanent long-term pace.
- Income/Expense summary values derived from `FinancialSummaryBuilder`.
- No duplicate financial formulas in Income/Expense ViewModels.

## 8. Files Likely To Touch

Likely implementation files:

- `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift`
- `budgetmeter.ios/Features/IncomesFeature/View/IncomeView.swift`
- `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`
- `budgetmeter.ios/Features/ExpensesFeature/View/ExpenseView.swift`
- `budgetmeter.ios/Features/Shared/FinancialEditSheet.swift`
- `budgetmeter.ios/Features/Shared/CreateCategoryModal.swift`
- `budgetmeter.ios/Features/SubscriptionsFeature/` only for display alignment, not premium behavior
- `budgetmeter.ios/Features/BillsFeature/` only for rollup display alignment, not bill automation behavior
- `budgetmeter.ios/Features/RecurringTransactionsFeature/ViewModel/RecurringTransactionsViewModel.swift` to stop creating new `frequency = "recurring"` category rows
- `budgetmeter.iosTests/FinancialSummaryBuilderTests.swift`
- new focused Income/Expense flow or ViewModel mapping tests
- localization resources only when implementation adds new copy

## 9. Files Not Allowed To Touch

Do not touch in Phase 5:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- CoreData schema/model versions
- Xcode project files
- `budgetmeter.ios/CoreKit/Sources/Auth/**`
- Supabase/Auth files
- `budgetmeter.ios/Widgets/**`
- widget targets or App Group setup
- premium gates, StoreKit, paywall, or entitlement logic
- CloudKit setup/removal behavior
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- calculation formulas in `CalculationEngine.swift`
- broad DesignSystem redesign outside what Phase 4 explicitly scopes

## 10. Required ViewModel Changes

Income ViewModel:

- Keep lists of editable income categories for current section UI.
- Add summary-backed display fields from `FinancialSummaryBuilder`.
- Replace local monthly/daily/yearly summary formulas with shared summary values.
- Filter/edit recurring category entries using `entryKind == "recurring"` and active state.
- Add one-time income write support using `entryKind = "oneTime"` and `occurrenceDate`.
- Set `sourceType`, `sourceID`, `isActive`, and `lastModified` for new/updated rows where appropriate.

Expense ViewModel:

- Keep lists of editable expense categories and subscriptions for current section UI.
- Add summary-backed display fields from `FinancialSummaryBuilder`.
- Replace local category/subscription summary formulas with shared summary values.
- Do not manually add subscription totals to the summary card once using builder output.
- Show bills/subscriptions as specialized regular expense sources without double-counting.
- Add one-time expense write support using `entryKind = "oneTime"` and `occurrenceDate`.
- Set `sourceType`, `sourceID`, `isActive`, and `lastModified` for new/updated rows where appropriate.

Recurring transactions:

- Stop creating new `FinancialCategory` rows with `frequency = "recurring"` in new code.
- Treat automation rules as builder-readable recurring sources or generated one-time period events only when explicitly defined.

## 11. Required UI Flow Changes

Keep UI changes small and task-focused:

- Add an entry kind choice: recurring/regular vs one-time.
- For recurring entries, show frequency selector.
- For one-time entries, show occurrence date.
- Use gentle labels:
  - recurring income
  - one-time income
  - regular expense
  - surprise expense
- Preserve fast editing of existing recurring category amounts.
- Do not redesign the entire screen layout in Phase 5.
- Do not change premium gate presentation in this phase.

## 12. One-Time vs Recurring Handling

Recurring:

- Store as `FinancialCategory.entryKind = "recurring"`.
- Use `frequency` values supported by the builder: daily, weekly, monthly, yearly.
- Include in long-term recurring pace.

One-time:

- Store as `FinancialCategory.entryKind = "oneTime"`.
- Set `occurrenceDate`.
- Use `frequency = "once"` or a documented non-recurring value.
- Include in selected/current period totals.
- Exclude from recurring pace.

Legacy:

- Existing rows without `entryKind` are migrated to recurring.
- Existing `frequency = "recurring"` rows are migrated to one-time automation artifacts.

## 13. Bills / Subscriptions Rollup Behavior

Subscriptions:

- Continue specialized subscription management in `SubscriptionsFeature`.
- Summary totals should come from `FinancialSummaryBuilder`, not `SubscriptionManager.getTotalMonthlyCost`.
- Builder includes active, unpaused subscriptions as recurring expense lines.

Bills:

- Continue specialized bill management in `BillsFeature`.
- Calendar due/paid totals remain separate bill-management metrics.
- Builder includes recurring unpaid bills as recurring expense lines.
- Phase 5 should document any visible Expense summary inclusion so users understand bills are regular expenses.

Dedupe:

- Do not count a subscription/bill and a linked category row twice.
- Use existing `sourceType` / `sourceID` fields for new linked/mirrored rows where needed.
- Avoid adding new schema.

## 14. Premium / Free Boundary

Free:

- Basic income entry.
- Basic expense entry.
- Basic recurring income/regular expense entry.
- One-time income/surprise expense entry.
- Core summary values.

Premium:

- Recurring automation.
- Advanced bill/subscription management, reminders, renewal tracking, and automation.
- Custom categories, if already premium.
- Advanced insights/history/forecasting.

Phase 5 must not change premium gate implementation. It may document and route around boundaries so core entry remains usable.

## 15. Test Requirements

Required tests:

- Income summary display derives from `FinancialSummary.recurringIncomeMonthly`.
- Expense summary display derives from `FinancialSummary.recurringExpenseMonthly`.
- Expense summary includes subscriptions and bills through builder rollup.
- Expense summary does not manually double-count subscriptions.
- One-time income appears in period totals but does not change recurring income pace.
- One-time expense appears in period totals/biggest drain but does not change recurring expense pace.
- New recurring category writes set `entryKind = "recurring"`, `isActive = true`, and `lastModified`.
- New one-time category writes set `entryKind = "oneTime"` and `occurrenceDate`.
- Recurring automation no longer emits new `frequency = "recurring"` baseline rows.
- Free core entry paths do not require premium entitlement.

## 16. Step-By-Step Phase 5 Implementation Sequence

1. Add tests for Income/Expense summary mapping from `FinancialSummaryBuilder`.
2. Add tests for one-time income/expense write mapping.
3. Add tests for subscription/bill rollup in Expense summary.
4. Refactor Income summary display fields to use `FinancialSummaryBuilder`.
5. Refactor Expense summary display fields to use `FinancialSummaryBuilder`.
6. Preserve existing category list/edit behavior while filtering recurring rows correctly.
7. Add minimal one-time entry support for income.
8. Add minimal one-time entry support for expenses.
9. Stop new `frequency = "recurring"` category creation from recurring automation.
10. Update UI labels/sections only as needed for the new entry kind.
11. Run focused tests and build.

## 17. What To Postpone

- CoreData schema changes.
- Supabase/Auth.
- Widgets.
- Premium gate implementation changes.
- Full Income/Expense visual redesign.
- Advanced recurring automation.
- Bill reminders/renewal behavior changes.
- Subscription reminder/renewal behavior changes.
- Advanced category management.
- Historical analytics/charts.
- Bank sync.
- Export changes.

## 18. Success Criteria

Phase 5 is complete when:

- Income summary display comes from `FinancialSummaryBuilder`.
- Expense summary display comes from `FinancialSummaryBuilder`.
- Income/Expense ViewModels no longer duplicate financial formulas for summary totals.
- Basic recurring entries remain editable.
- One-time income/expense can be represented with `entryKind` and `occurrenceDate`.
- One-time entries do not change recurring pace.
- Subscriptions and bills are included through shared summary rollup.
- Recurring automation no longer creates new `frequency = "recurring"` category rows.
- Premium/free boundary is preserved.
- Build passes.
- Required tests pass or pre-existing failures are documented separately.

## 19. Recommendation

Status: **Ready for implementation planning, not started.**

Not ready for a broad UI rewrite. The first safe implementation step is test-first: define Income/Expense summary mapping tests against `FinancialSummaryBuilder`, then refactor summary display values while preserving current editing UI.
