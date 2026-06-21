# Localization Audit Task for BudgetMeter iOS

## Goal
Create a comprehensive audit document at `docs/hardcoded_strings_audit.md` that catalogs ALL hardcoded, non-localized English strings across the entire BudgetMeter codebase.

## How to proceed

1. First, read `docs/implementation/implementation_planning_index.md` to understand the project context.

2. Then, scan EVERY .swift file in the project for hardcoded English strings that are user-facing but NOT properly localized. Look for:
   - `Text("English text")` without .xcstrings key
   - `Text("English text", comment: "...")` where the string doesn't exist as a key in any .xcstrings file
   - `String(localized: "key", defaultValue: "English")` that are fine (already localized)
   - `Text("string")` in preview code (#Preview) — skip those, they're preview-only
   - Strings in CoreKit/ that are user-facing

3. Read the existing .xcstrings files to understand what's already covered:
   - `Resources/UI.xcstrings` (contains savings keys like `savings.target_date`, `savings.pace.ahead`, etc.)
   - `Resources/Localizable.xcstrings`
   - `Resources/Home.xcstrings`
   - `Resources/Settings.xcstrings`
   - Other xcstrings files

4. For each hardcoded string found, note:
   - File path and line number
   - The exact hardcoded text
   - Whether an existing key in .xcstrings could replace it
   - Severity (user-facing screen vs dev-only)

5. Write the audit document to `docs/hardcoded_strings_audit.md` with:
   - Overview/summary
   - Per-file breakdown with table (file, line, string, existing key?, severity)
   - Prioritized fix list (what needs fixing first)
   - Screens that are ALREADY fully localized (for reference)

## Key files to check (must read at minimum):
- `Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift`
- `Features/SavingsGoalsFeature/View/SavingsGoalsView.swift`
- `Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`
- `CoreKit/Sources/Services/SavingsGoalManager.swift` (the SavingsGoalPaceStatus enum)
- `Features/HomeFeature/View/HomeView.swift`
- `Features/HomeFeature/ViewModel/HomeDisplayMapping.swift`
- `Features/ExpensesFeature/View/ExpenseView.swift`
- `Features/IncomesFeature/View/IncomeView.swift`
- `Features/SettingsFeature/` (all views)
- `DesignSystem/Components/` (all card components)
- `Features/Shared/` (CreateCategoryModal, FinancialEditSheet, etc.)
- `Features/BillsFeature/`
- `Features/SubscriptionsFeature/`
- `Features/InsightsFeature/`
- `Features/RecurringTransactionsFeature/`
- `Features/PremiumFeature/`

## Output
Create `docs/hardcoded_strings_audit.md` with the full audit results, structured so we can work through the fixes systematically.
