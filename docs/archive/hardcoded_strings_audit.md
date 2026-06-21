# Hardcoded Strings Audit — BudgetMeter iOS

> Generated: 2026-06-18 | Scope: all `.swift` files in `budgetmeter.ios/` and `BudgetMeterWidgets/`

## Overview

This audit catalogs user-facing English strings that are **not properly localized** for the app's 10-language support (EN, TR, DE, FR, ES, IT, PT, JA, ZH, AR).

### Summary counts

| Category | Count | Impact |
|----------|------:|--------|
| Valid keys in `.xcstrings` catalogs | 592 | Resolve correctly at runtime |
| **Truly hardcoded** (no localization wrapper) | 115 | English-only; won't translate |
| **Keys used in code but missing from catalogs** | 197 | Falls back to `defaultValue` English |
| **Keys in catalog file but structurally broken** | 139 | Exist in `UI.xcstrings` but nested incorrectly; **won't resolve** |
| **Keys orphaned outside `strings` dict** | 8 | In `UI.xcstrings` root; **won't resolve** |

### Critical catalog issue

`UI.xcstrings` has a **structural corruption**: the `strings` dictionary closes prematurely at ~line 719. Roughly 150+ keys (savings, bills, subscriptions, category modal, health errors, etc.) were appended as siblings but ended up **nested inside `income.summary.yearly`** due to missing braces. These keys appear in the file and may even have full translations, but **the app cannot look them up at runtime**.

**Example:** `savings.target_date` exists at file line 3059 but resolves at JSON path `/income.summary.yearly/savings.target_date` — not at `strings.savings.target_date`.

**Fix:** Repair `UI.xcstrings` structure first (move all keys into the `strings` dict) before adding new translations.

### Issue types

| Type | Description |
|------|-------------|
| `hardcoded` | `Text("...")`, `return "..."`, or `navigationTitle("...")` with no `.localized()` / `String(localized:)` |
| `missing` | Key used in code but not present in any `.xcstrings` file |
| `broken-nested` | Key exists in `UI.xcstrings` but is nested incorrectly; runtime lookup fails |
| `orphaned` | Key at root of `UI.xcstrings`, outside the `strings` dict |
| `in-catalog` | Key properly in a catalog (not listed as a gap) |

### Severity

| Severity | Meaning |
|----------|---------|
| **user-facing** | Shown in production UI, widgets, or error messages |
| **preview-only** | Inside `#Preview` blocks only — skipped in fix priority |
| **dev-only** | `DebugView`, test harness views — low priority |

## Prioritized fix list

### P0 — Ship blockers (Home, Widget, core pace copy)

1. **Repair `UI.xcstrings` structure** — unblocks 139+ broken-nested keys including all `savings.*`, `bill.*`, `subscriptions.*` entries already translated in file
2. **`HomeDisplayMapping.swift`** — pace status copy is fully hardcoded:
   - `Moving forward …/day` (L19)
   - `Slowing down …/day` (L21)
   - `Holding steady …/day` (L23)
   - Add keys: `home.pace.moving_forward`, `home.pace.slowing_down`, `home.pace.holding_steady`
3. **`MomentumHeroCard.swift` L50** — `Live: %@` hardcoded prefix
4. **Widget strings** — add `widget.pace.title`, `widget.pace.description`, `widget.locked.cta` to catalogs; fix `WidgetsSetupView` hardcoded nav title `Widgets`
5. **`SavingsGoalDetailView.swift`** — `Text("Add Money")`, `Text("Withdraw")`, `Text("Notes")` use comment-only localization (L208, L221, L240); keys exist in `Localizable.xcstrings` as English-text keys but should use semantic keys

### P1 — Phase 9 Auth/Backup + Premium paywall

- Add 14 `account.*` + 23 `backup.*` + 5 `auth.*` keys (currently English-only via `defaultValue`)
- Add 34 `premium.*` keys for paywall, restore, purchase errors (`PremiumPaywallView`, `PremiumManager.PremiumFeature`)
- `PremiumManager` hardcoded `PurchaseError` messages (L324–328) and feature title/description strings (L458–501)

### P2 — Feature screens with missing keys

- `savings_goals.*` (5 keys) — list screen titles/empty states
- `settings.*` section labels (14 keys) — partially in catalogs, some missing
- `export.*` (22 keys) — `DataExportView` + hardcoded bullet list (L136–139)
- `edit_recurring.*` + `recurring.*` (33 keys)
- `widgets.setup.*` (8 keys)

### P3 — Legacy / secondary surfaces

- **`PremiumThemesView.swift`** — entirely hardcoded (6 strings); nav title `Themes`
- **`HealthScoreCard.swift`**, **`HealthScoreDetailCard.swift`**, **`HealthBreakdownRow.swift`** — health score labels and feedback copy
- **`CalculationEngine.swift`** — health rating labels: Excellent, Great, Good, Fair, Needs Improvement, Getting Started
- **`BiometricManager.swift`** — 10+ error/display strings
- **`ThemeManager.swift`** — theme display names (Default, Ocean, Forest, etc.)
- **`BillsView.swift` / `BillRowView.swift`** — inline `due`, `AutoPay`, `✓ Paid` hardcoded text
- **`EmptyStateRow.swift`** — empty state messages with interpolated frequency

### P4 — Low priority

- DesignSystem preview strings in `TrendIndicator.swift`, `MiniBarChart.swift` (preview `#Preview` blocks)
- `DebugView.swift`, `CustomCategoryTestView.swift`, `CustomCategoryFlowTest.swift`
- Dynamic numeric-only text (`\(score)%`, `\(score)`, bullet `•`)

## Screens already using localization wrappers

These views use `.localized()` or `String(localized:)` for **all** user-facing strings (no raw `Text("English")`). They may still show English if keys are missing/broken in catalogs, but the code pattern is correct:

- **Income tab** — `IncomeView.swift` — navigation, alerts, loading state
- **Expense tab** — `ExpenseView.swift` — navigation, alerts, loading state
- **Insights tab** — `InsightsView.swift`, chart subviews
- **Settings pickers** — `LanguagePickerView.swift`, `CurrencyPickerView.swift`, `AppearancePickerView.swift`
- **Quick savings input** — `QuickSavingsGoalInputView.swift`
- **Health details shell** — `HealthDetailsView.swift` (ViewModel errors use keys)
- **Tab bar** — `ContentView.swift` — all 5 tab labels use `tab.*.title` keys (in catalog)
- **Category input** — `CategoryInputCard.swift`
- **Financial edit** — `FinancialEditSheet.swift` — uses `String(localized:)` throughout
- **Create category** — `CreateCategoryModal.swift` — wrapper pattern correct; many keys broken-nested in UI.xcstrings
- **Account & Backup** — `AccountBackupSettingsView.swift` — wrapper pattern correct; keys not yet in catalogs
- **Settings main** — `SettingsView.swift` — extensive `.localized()` usage including privacy/terms content

### Screens with mixed or poor localization

- **Home** — `HomeView.swift` mostly localized; `HomeDisplayMapping` pace copy hardcoded; `MomentumHeroCard` Live prefix hardcoded
- **Savings** — Views use `String(localized:table:"UI")` but UI.xcstrings structure breaks lookup; detail view has comment-only Text
- **Premium Themes** — Fully hardcoded English in `PremiumThemesView.swift`
- **Bills** — ViewModels use keys (broken/missing); views have hardcoded `due`, `AutoPay`, `Paid`
- **Premium Paywall** — Uses `.localized()` keys but none in catalogs yet
- **Widgets** — Mix of localized keys (missing) + hardcoded nav title

## Per-file breakdown

### CoreKit / Engine

#### `CoreKit/Sources/Engine/CalculationEngine.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 549 | Excellent | hardcoded | `home.health.excellent` | user-facing |
| 551 | Great | hardcoded | — | user-facing |
| 553 | Good | hardcoded | `home.health.good` | user-facing |
| 555 | Fair | hardcoded | `home.health.fair` | user-facing |
| 557 | Needs Improvement | hardcoded | — | user-facing |
| 559 | Getting Started | hardcoded | — | user-facing |

### CoreKit / Services & Premium

#### `CoreKit/Sources/Premium/PremiumManager.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 99 | Premium is not available right now. Please try again la… | `premium.error.product_unavailable` (missing) | — | user-facing |
| 121 | Purchase cancelled. | `premium.error.purchase_cancelled` (missing) | — | user-facing |
| 127 | Purchase pending approval. | `premium.error.purchase_pending` (missing) | — | user-facing |
| 133 | Purchase could not be completed. | `premium.error.purchase_unknown` (missing) | — | user-facing |
| 139 | Purchase failed: %@ | `premium.error.purchase_failed` (missing) | — | user-facing |
| 162 | No previous BudgetMeter Premium purchase was found. | `premium.restore.none_found` (missing) | — | user-facing |
| 168 | Restore failed: %@ | `premium.error.restore_failed` (missing) | — | user-facing |
| 324 | Transaction could not be verified | hardcoded | — | user-facing |
| 326 | Premium product is not available | hardcoded | — | user-facing |
| 328 | Purchase failed | hardcoded | — | user-facing |
| 458 | Custom Categories | hardcoded | `• Custom categories` | user-facing |
| 460 | Subscription Tracking | hardcoded | — | user-facing |
| 462 | Bill Reminders | hardcoded | — | user-facing |
| 464 | Savings Goals | hardcoded | — | user-facing |
| 466 | Recurring Transactions | hardcoded | `• Recurring transactions` | user-facing |
| 468 | Data Export | hardcoded | — | user-facing |
| 470 | Widgets | hardcoded | `Widgets` | user-facing |
| 472 | Spending Insights | hardcoded | — | user-facing |
| 474 | Biometric Lock | hardcoded | — | user-facing |
| 476 | Premium Themes | hardcoded | `Premium Themes` | user-facing |
| 483 | Create unlimited custom income and expense categories w… | hardcoded | — | user-facing |
| 485 | Track unlimited subscriptions with renewal reminders an… | hardcoded | — | user-facing |
| 487 | Track bills, due dates, and payment history with smart … | hardcoded | — | user-facing |
| 489 | Create and track multiple savings goals with visual pro… | hardcoded | — | user-facing |
| 491 | Automate repeating bills, salaries, and subscriptions | hardcoded | — | user-facing |
| 493 | Export your data in PDF, CSV, or JSON format | hardcoded | — | user-facing |
| 495 | Home Screen widget with your net daily pace | hardcoded | — | user-facing |
| 497 | Visual charts and insights into your spending patterns | hardcoded | — | user-facing |
| 499 | Protect your financial data with Face ID or Touch ID | hardcoded | — | user-facing |
| 501 | Unlock beautiful color themes and custom app icons | hardcoded | — | user-facing |
| 510 | creditcard | hardcoded | — | user-facing |
| 514 | target | hardcoded | `home.target.message.negative` | user-facing |
| 516 | repeat | hardcoded | — | user-facing |
| 524 | faceid | hardcoded | — | user-facing |

#### `CoreKit/Sources/Security/BiometricManager.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 71 | Biometric lock requires BudgetMeter Premium. | `security.error.premium_required` (missing) | — | user-facing |
| 195 | None | hardcoded | — | user-facing |
| 197 | Face ID | hardcoded | — | user-facing |
| 199 | Touch ID | hardcoded | — | user-facing |
| 201 | Optic ID | hardcoded | — | user-facing |
| 208 | lock | hardcoded | `Premium feature. Unlock to see all tips` | user-facing |
| 210 | faceid | hardcoded | — | user-facing |
| 212 | touchid | hardcoded | — | user-facing |
| 214 | opticid | hardcoded | — | user-facing |
| 236 | Biometric authentication is not available on this devic… | hardcoded | — | user-facing |
| 238 | No biometric data is enrolled. Please set up Face ID or… | hardcoded | — | user-facing |
| 240 | Biometric authentication is locked out. Please use your… | hardcoded | — | user-facing |
| 242 | Authentication failed. Please try again | hardcoded | — | user-facing |
| 244 | Authentication was cancelled by the user | hardcoded | — | user-facing |
| 246 | Authentication was cancelled by the system | hardcoded | — | user-facing |
| 248 | Passcode is not set. Please set up a passcode in Settin… | hardcoded | — | user-facing |
| 250 | Biometric authentication is not available | hardcoded | — | user-facing |

#### `CoreKit/Sources/Premium/ThemeManager.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 161 | Default | hardcoded | — | user-facing |
| 162 | Ocean | hardcoded | — | user-facing |
| 163 | Forest | hardcoded | — | user-facing |
| 164 | Sunset | hardcoded | — | user-facing |
| 165 | Purple | hardcoded | `color.purple` | user-facing |
| 166 | Midnight | hardcoded | — | user-facing |
| 219 | paintbrush | hardcoded | — | user-facing |
| 223 | sparkles | hardcoded | — | user-facing |
| 234 | AppIcon-Ocean | hardcoded | — | user-facing |
| 235 | AppIcon-Forest | hardcoded | — | user-facing |
| 236 | AppIcon-Sunset | hardcoded | — | user-facing |
| 237 | AppIcon-Purple | hardcoded | — | user-facing |
| 238 | AppIcon-Midnight | hardcoded | — | user-facing |

#### `CoreKit/Sources/Backup/BackupService.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 25 | Cloud backup is not configured. | `backup.error.not_configured` (missing) | — | user-facing |
| 27 | Sign in to use cloud backup. | `backup.error.not_authenticated` (missing) | — | user-facing |
| 29 | Cloud backup requires BudgetMeter Premium. | `backup.error.premium_required` (missing) | — | user-facing |
| 31 | Cloud backup is unavailable offline. | `backup.error.offline` (missing) | — | user-facing |
| 33 | Backup failed. Your local data is safe. | `backup.error.failed` (missing) | — | user-facing |
| 35 | Restore failed. Your previous data was preserved. | `backup.error.restore_failed` (missing) | — | user-facing |
| 37 | No cloud backup found for this account. | `backup.error.no_cloud_backup` (missing) | — | user-facing |
| 39 | Restore will replace local data on this device. | `backup.error.confirm_restore` (missing) | — | user-facing |

#### `CoreKit/Sources/Auth/AuthService.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 22 | Cloud sign-in is not configured. | `auth.error.not_configured` (missing) | — | user-facing |
| 24 | You are not signed in. | `auth.error.not_authenticated` (missing) | — | user-facing |
| 26 | Sign in failed. Please try again. | `auth.error.sign_in_failed` (missing) | — | user-facing |
| 28 | Sign out failed. Please try again. | `auth.error.sign_out_failed` (missing) | — | user-facing |
| 30 | Account deletion failed. Please try again. | `auth.error.delete_failed` (missing) | — | user-facing |

#### `CoreKit/Sources/Export/DataExportService.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 15 | PDF Report | `export.format.pdf` (missing) | — | user-facing |
| 16 | CSV Data | `export.format.csv` (missing) | — | user-facing |
| 17 | JSON Data | `export.format.json` (missing) | — | user-facing |

#### `CoreKit/Sources/Services/SavingsGoalManager.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 499 | Ahead of pace! | `savings.pace.ahead` (broken-nested) | In file, broken structure | user-facing |
| 501 | On pace | `savings.pace.on_pace` (broken-nested) | In file, broken structure | user-facing |
| 503 | Behind pace | `savings.pace.behind` (broken-nested) | In file, broken structure | user-facing |

### Home Feature

#### `Features/HomeFeature/View/HomeView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 359 | Daily Budget | `home.daily_budget.info.title` (missing) | — | user-facing |
| 376 | How It Works | `home.daily_budget.info.how_title` (missing) | — | user-facing |
| 392 | Color Guide | `home.daily_budget.info.colors_title` (missing) | — | user-facing |

#### `Features/HomeFeature/ViewModel/HomeDisplayMapping.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 19 | Moving forward \(signedDailyAmount(netDailyPace, curren… | hardcoded | — | user-facing |
| 21 | Slowing down \(signedDailyAmount(netDailyPace, currency… | hardcoded | — | user-facing |
| 23 | Holding steady \(signedDailyAmount(netDailyPace, curren… | hardcoded | — | user-facing |

### Income / Expense

#### `Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 65 | Monthly | `expenses.summary.monthly` (orphaned) | — | user-facing |
| 69 | Daily Avg | `expenses.summary.daily_avg` (orphaned) | — | user-facing |
| 73 | Yearly | `expenses.summary.yearly` (orphaned) | — | user-facing |
| 77 | Expense Overview | `expenses.summary.title` (orphaned) | — | user-facing |

#### `Features/IncomesFeature/ViewModel/IncomeViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 52 | Monthly | `income.summary.monthly` (orphaned) | — | user-facing |
| 56 | Daily Avg | `income.summary.daily_avg` (orphaned) | — | user-facing |
| 60 | Yearly | `income.summary.yearly` (orphaned) | — | user-facing |
| 64 | Income Overview | `income.summary.title` (orphaned) | — | user-facing |

### Savings Feature

#### `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 56 | Edit Goal | `savings.title.edit` (broken-nested) | In file, broken structure | user-facing |
| 56 | Add Goal | `savings.title.add` (broken-nested) | In file, broken structure | user-facing |
| 75 | Save %@ immediately | `savings.save_immediately` (broken-nested) | In file, broken structure | user-facing |
| 78 | To reach your goal by %@, save %@/month | `savings.monthly_required` (broken-nested) | In file, broken structure | user-facing |
| 111 | Goal Name * | `savings.goal_name` (broken-nested) | In file, broken structure | user-facing |
| 116 | Vacation Fund, New Car, etc. | `savings.goal_name_placeholder` (broken-nested) | In file, broken structure | user-facing |
| 127 | Choose Emoji (optional) | `savings.choose_emoji` (broken-nested) | In file, broken structure | user-facing |
| 155 | Target Amount * | `savings.target_amount` (broken-nested) | In file, broken structure | user-facing |
| 179 | Current Amount | `savings.current_amount` (broken-nested) | In file, broken structure | user-facing |
| 205 | Set Target Date | `savings.set_target_date` (broken-nested) | In file, broken structure | user-facing |
| 210 | Track your progress toward a deadline | `savings.target_date_description` (broken-nested) | In file, broken structure | user-facing |
| 219 | Target Date | `savings.target_date` (broken-nested) | In file, broken structure | user-facing |
| 244 | Category | `form.category` (broken-nested) | In file, broken structure | user-facing |
| 262 | Notes (optional) | `form.notes_optional` (broken-nested) | In file, broken structure | user-facing |
| 277 | Save Changes | `form.save_changes` (broken-nested) | In file, broken structure | user-facing |
| 277 | Create Goal | `savings.create_goal` (broken-nested) | In file, broken structure | user-facing |
| 294 | Delete Goal | `savings.delete_goal` (broken-nested) | In file, broken structure | user-facing |
| 309 | Cancel | `form.cancel` (broken-nested) | In file, broken structure | user-facing |
| 316 | Done | `form.done` (broken-nested) | In file, broken structure | user-facing |
| 323 | Delete Goal? | `savings.delete_confirm_title` (broken-nested) | In file, broken structure | user-facing |
| 324 | Cancel | `form.cancel` (broken-nested) | In file, broken structure | user-facing |
| 325 | Delete Goal | `savings.delete_goal` (broken-nested) | In file, broken structure | user-facing |
| 329 | This will permanently delete this savings goal. This ac… | `savings.delete_confirm_message` (broken-nested) | In file, broken structure | user-facing |
| 362 | Please enter a valid target amount | `savings.error.invalid_target` (broken-nested) | In file, broken structure | user-facing |
| 369 | Please enter a goal name | `savings.error.enter_name` (broken-nested) | In file, broken structure | user-facing |
| 409 | Failed to update goal | `savings.error.failed_update` (broken-nested) | In file, broken structure | user-facing |
| 429 | Failed to create goal | `savings.error.failed_create` (broken-nested) | In file, broken structure | user-facing |
| 444 | Failed to delete goal | `savings.error.failed_delete` (broken-nested) | In file, broken structure | user-facing |

#### `Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 208 | Add Money | hardcoded (`Text` + comment only) | `Add Money` in Localizable.xcstrings (English-as-key) | user-facing |
| 221 | Withdraw | hardcoded (`Text` + comment only) | `Withdraw` in Localizable.xcstrings | user-facing |
| 240 | Notes | hardcoded (`Text` + comment only) | — | user-facing |
| 294 | Add Money to Goal | hardcoded (`Text` + comment only) | `Add Money to Goal` in Localizable.xcstrings | user-facing |
| 316 | Add | hardcoded (`Text` + comment only) | — | user-facing |
| 355 | Withdraw from Goal | hardcoded (`Text` + comment only) | `Withdraw from Goal` in Localizable.xcstrings | user-facing |
| 381 | Withdraw | hardcoded (`Text` + comment only) | `Withdraw` in Localizable.xcstrings | user-facing |
| 62 | Unknown | `savings.unknown` (broken-nested) | In file, broken structure | user-facing |
| 98 | of %@ | `savings.of_amount` (broken-nested) | In file, broken structure | user-facing |
| 104 | %@ to go | `savings.to_go` (broken-nested) | In file, broken structure | user-facing |
| 108 | Goal reached! 🎉 | `savings.goal_reached_message` (broken-nested) | In file, broken structure | user-facing |
| 152 | Target Date | `savings.target_date` (broken-nested) | In file, broken structure | user-facing |
| 178 | Required Monthly | `savings.required_monthly` (broken-nested) | In file, broken structure | user-facing |
| 359 | Available: %@ | `savings.available_amount` (broken-nested) | In file, broken structure | user-facing |
| 451 | Target date passed | `savings.target_date_passed` (broken-nested) | In file, broken structure | user-facing |
| 457 | \(months) month\(months == 1 ?  | `savings.months_remaining` (broken-nested) | In file, broken structure | user-facing |
| 460 | \(days) day\(days == 1 ?  | `savings.days_remaining` (broken-nested) | In file, broken structure | user-facing |
| 463 | Due today | `savings.due_today` (broken-nested) | In file, broken structure | user-facing |

#### `Features/SavingsGoalsFeature/View/SavingsGoalsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 45 | Savings Goals | `savings_goals.title` (missing) | — | user-facing |
| 92 | Active Goals | `savings_goals.active` (missing) | — | user-facing |
| 124 | Completed | `savings_goals.completed` (missing) | — | user-facing |
| 165 | No Savings Goals Yet | `savings_goals.empty.title` (missing) | — | user-facing |
| 169 | Tap + to create your first savings goal | `savings_goals.empty.subtitle` (missing) | — | user-facing |
| 243 | of %@ | `savings.of_amount` (broken-nested) | In file, broken structure | user-facing |
| 255 | Target: %@ | `savings.target_label` (broken-nested) | In file, broken structure | user-facing |
| 363 | Completed %@ | `savings.completed_label` (broken-nested) | In file, broken structure | user-facing |

#### `Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 178 | No target date | `savings.no_target_date` (broken-nested) | In file, broken structure | user-facing |
| 185 | Target date passed | `savings.target_date_passed` (broken-nested) | In file, broken structure | user-facing |
| 191 | \(months) month\(months == 1 ?  | `savings.months_remaining` (broken-nested) | In file, broken structure | user-facing |
| 194 | \(days) day\(days == 1 ?  | `savings.days_remaining` (broken-nested) | In file, broken structure | user-facing |
| 197 | Due today | `savings.due_today` (broken-nested) | In file, broken structure | user-facing |
| 211 | Save %@/month | `savings.save_month` (broken-nested) | In file, broken structure | user-facing |
| 226 | to go | `savings.to_go` (broken-nested) | In file, broken structure | user-facing |

### Settings Feature

#### `Features/SettingsFeature/View/AccountBackupSettingsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 32 | Account & Backup | `account.title` (missing) | — | user-facing |
| 38 | Restore Cloud Backup | `backup.restore.confirm.title` (missing) | — | user-facing |
| 41 | Cancel | `common.cancel` (missing) | — | user-facing |
| 42 | Restore | `backup.restore.confirm.action` (missing) | — | user-facing |
| 46 | This replaces local data on this device with your cloud… | `backup.restore.confirm.message` (missing) | — | user-facing |
| 49 | Delete Account | `account.delete.title` (missing) | — | user-facing |
| 52 | Cancel | `common.cancel` (missing) | — | user-facing |
| 53 | Delete | `account.delete.confirm` (missing) | — | user-facing |
| 57 | This deletes your cloud account and backup. Local data … | `account.delete.message` (missing) | — | user-facing |
| 73 | Signed in | `account.signed_in` (missing) | — | user-facing |
| 87 | Sign Out | `account.sign_out` (missing) | — | user-facing |
| 98 | Sign in with Apple | `account.sign_in_apple` (missing) | — | user-facing |
| 101 | Account | `account.section.title` (missing) | — | user-facing |
| 103 | Sign in is free. Cloud backup requires Premium. | `account.footer` (missing) | — | user-facing |
| 116 | Upgrade for Cloud Backup | `backup.premium_required` (missing) | — | user-facing |
| 121 | Sign in to back up or restore. | `backup.sign_in_required` (missing) | — | user-facing |
| 125 | This device and your cloud backup both contain data. Ch… | `backup.overlap.message` (missing) | — | user-facing |
| 131 | Last backup: \(formattedDate(lastBackup)) | `backup.last_backup` (missing) | — | user-facing |
| 135 | No cloud backup yet | `backup.never` (missing) | — | user-facing |
| 141 | Cloud backup: \(cloudSummary.recordCount) records, \(fo… | `backup.cloud_summary` (missing) | — | user-facing |
| 151 | Back Up Now | `backup.now` (missing) | — | user-facing |
| 161 | Restore from Cloud | `backup.restore` (missing) | — | user-facing |
| 181 | Cloud Backup | `backup.section.title` (missing) | — | user-facing |
| 183 | Backup is manual in v1. Local data is snapshotted befor… | `backup.footer` (missing) | — | user-facing |
| 192 | Delete Account | `account.delete.title` (missing) | — | user-facing |
| 219 | Signed in successfully. | `account.sign_in_success` (missing) | — | user-facing |
| 225 | Sign in cancelled. | `account.sign_in_cancelled` (missing) | — | user-facing |
| 234 | Signed out. | `account.sign_out_success` (missing) | — | user-facing |
| 246 | Backup completed. | `backup.success` (missing) | — | user-facing |
| 260 | Restore completed. | `backup.restore.success` (missing) | — | user-facing |
| 271 | Account deleted. | `account.delete.success` (missing) | — | user-facing |

#### `Features/SettingsFeature/View/SettingsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 112 | Notifications | `settings.notifications.title` (missing) | — | user-facing |
| 115 | Manage alerts and reminders | `settings.notifications.subtitle` (missing) | — | user-facing |
| 197 | General | `settings.general.title` (missing) | — | user-facing |
| 219 | Premium Features | `settings.premium.title` (missing) | — | user-facing |
| 238 | Savings Goals | `settings.premium.savings_goals` (missing) | — | user-facing |
| 243 | Tracking & Goals | `settings.premium.tracking.title` (missing) | — | user-facing |
| 253 | Premium Themes | `settings.premium.themes` (missing) | — | user-facing |
| 260 | Widgets | `settings.premium.widgets` (missing) | — | user-facing |
| 267 | Data Export | `settings.premium.export` (missing) | — | user-facing |
| 272 | Customization | `settings.premium.customization.title` (missing) | — | user-facing |
| 282 | Biometric Lock | `settings.premium.biometric` (missing) | — | user-facing |
| 287 | Security | `settings.premium.security.title` (missing) | — | user-facing |
| 319 | Account & Backup | `settings.account.title` (missing) | — | user-facing |
| 322 | Sign in and manage cloud backup | `settings.account.subtitle` (missing) | — | user-facing |

#### `Features/SettingsFeature/ViewModel/NotificationSettingsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 127 | Failed to load notification settings | `notifications.error.load_failed` (broken-nested) | In file, broken structure | user-facing |
| 157 | Failed to save notification settings | `notifications.error.save_failed` (broken-nested) | In file, broken structure | user-facing |
| 264 | Failed to request notification permissions | `notifications.error.permission_failed` (broken-nested) | In file, broken structure | user-facing |

#### `Features/SettingsFeature/View/NotificationSettingsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 402 | Every Sunday at \(timeString) | hardcoded | — | user-facing |
| 407 | Every day at \(timeString) | hardcoded | — | user-facing |

#### `Features/SettingsFeature/View/Components/NotificationToggleRow.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 103 | PREMIUM | `ui.premium` (broken-nested) | In file, broken structure | user-facing |

### Premium Feature

#### `Features/PremiumFeature/View/PremiumPaywallView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 76 | Purchases Restored | `premium.restore.success` (missing) | — | user-facing |
| 77 | OK | `premium.ok` (missing) | — | user-facing |
| 79 | Your previous purchases have been restored successfully… | `premium.restore.success.message` (missing) | — | user-facing |
| 81 | Welcome to Premium! | `premium.purchase.success` (missing) | — | user-facing |
| 82 | OK | `premium.ok` (missing) | — | user-facing |
| 84 | Thank you for upgrading to BudgetMeter Premium! | `premium.purchase.success.message` (missing) | — | user-facing |
| 98 | BudgetMeter Premium | `premium.header.title` (missing) | — | user-facing |
| 111 | $4.99 | `premium.price` (missing) | — | user-facing |
| 116 | One-time purchase • Lifetime access | `premium.price.subtitle` (missing) | — | user-facing |
| 135 | Everything included: | `premium.features.title` (missing) | — | user-facing |
| 190 | Upgrade to Premium | `premium.purchase.button` (missing) | — | user-facing |
| 204 | Restore Purchases | `premium.restore.button` (missing) | — | user-facing |
| 213 | Terms | `premium.terms.link` (missing) | — | user-facing |
| 223 | Privacy | `premium.privacy.link` (missing) | — | user-facing |

#### `Features/PremiumThemesFeature/View/PremiumThemesView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 27 | Premium Themes | hardcoded | `Premium Themes` | user-facing |
| 31 | Choose from beautiful color themes to personalize your … | hardcoded | `Choose from beautiful color themes to personalize your BudgetMeter experience.` | user-facing |
| 56 | Currently Active | hardcoded | `Currently Active` | user-facing |
| 82 | Themes | hardcoded | `Themes` | user-facing |
| 158 | Active | hardcoded | `Active` | user-facing |

#### `Features/PremiumFeature/View/PremiumFeatureView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 71 | Premium Feature | `premium.gated.title` (missing) | — | user-facing |
| 77 | This feature is available with BudgetMeter Premium | `premium.gated.description` (missing) | — | user-facing |
| 96 | Upgrade to Premium | `premium.gated.upgrade` (missing) | — | user-facing |

### Bills Feature

#### `Features/BillsFeature/View/BillInputView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 70 | 1 day before | `bill.reminder.one_day` (broken-nested) | In file, broken structure | user-facing |
| 71 | 3 days before | `bill.reminder.three_days` (broken-nested) | In file, broken structure | user-facing |
| 72 | 7 days before | `bill.reminder.seven_days` (broken-nested) | In file, broken structure | user-facing |
| 84 | Edit Bill | `bill.title.edit` (broken-nested) | In file, broken structure | user-facing |
| 84 | Add Bill | `bill.title.add` (broken-nested) | In file, broken structure | user-facing |
| 113 | Bill Name * | `bill.name` (broken-nested) | In file, broken structure | user-facing |
| 118 | Electric Bill, Rent, etc. | `bill.name_placeholder` (broken-nested) | In file, broken structure | user-facing |
| 129 | Amount * | `form.amount` (broken-nested) | In file, broken structure | user-facing |
| 153 | Due Date * | `bill.due_date` (broken-nested) | In file, broken structure | user-facing |
| 159 | Due Date | `bill.due_date` (broken-nested) | In file, broken structure | user-facing |
| 174 | Recurring Bill | `bill.recurring` (broken-nested) | In file, broken structure | user-facing |
| 179 | Automatically create next bill when paid | `bill.recurring_description` (broken-nested) | In file, broken structure | user-facing |
| 188 | Frequency | `bill.frequency` (broken-nested) | In file, broken structure | user-facing |
| 208 | Category | `form.category` (broken-nested) | In file, broken structure | user-facing |
| 228 | AutoPay Enabled | `bill.autopay` (broken-nested) | In file, broken structure | user-facing |
| 233 | This bill is automatically paid | `bill.autopay_description` (broken-nested) | In file, broken structure | user-facing |
| 247 | Remind me | `bill.remind_me` (broken-nested) | In file, broken structure | user-facing |
| 263 | Notes (optional) | `form.notes_optional` (broken-nested) | In file, broken structure | user-facing |
| 278 | Save Changes | `form.save_changes` (broken-nested) | In file, broken structure | user-facing |
| 278 | Add Bill | `bill.title.add` (broken-nested) | In file, broken structure | user-facing |
| 297 | Mark as Unpaid | `bill.mark_unpaid` (broken-nested) | In file, broken structure | user-facing |
| 297 | Mark as Paid | `bill.mark_paid` (broken-nested) | In file, broken structure | user-facing |
| 309 | Delete Bill | `bill.delete` (broken-nested) | In file, broken structure | user-facing |
| 324 | Cancel | `form.cancel` (broken-nested) | In file, broken structure | user-facing |
| 331 | Done | `form.done` (broken-nested) | In file, broken structure | user-facing |
| 338 | Delete Bill? | `bill.delete_confirm_title` (broken-nested) | In file, broken structure | user-facing |
| 339 | Cancel | `form.cancel` (broken-nested) | In file, broken structure | user-facing |
| 340 | Delete Bill | `bill.delete` (broken-nested) | In file, broken structure | user-facing |
| 344 | This will permanently delete this bill. This action can… | `bill.delete_confirm_message` (broken-nested) | In file, broken structure | user-facing |
| 385 | Please enter a valid amount | `form.error.invalid_amount` (broken-nested) | In file, broken structure | user-facing |
| 392 | Please enter a bill name | `bill.error.enter_name` (broken-nested) | In file, broken structure | user-facing |
| 422 | Failed to update bill | `bill.error.failed_update` (broken-nested) | In file, broken structure | user-facing |
| 443 | Failed to create bill | `bill.error.failed_create` (broken-nested) | In file, broken structure | user-facing |
| 463 | Failed to update bill | `bill.error.failed_update` (broken-nested) | In file, broken structure | user-facing |
| 477 | Failed to delete bill | `bill.error.failed_delete` (broken-nested) | In file, broken structure | user-facing |

#### `Features/BillsFeature/ViewModel/BillsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 37 | Due Date | `bills.sort.due_date` (broken-nested) | In file, broken structure | user-facing |
| 38 | Amount | `bills.sort.amount` (broken-nested) | In file, broken structure | user-facing |
| 39 | Name | `bills.sort.name` (broken-nested) | In file, broken structure | user-facing |
| 51 | All | `bills.filter.all` (broken-nested) | In file, broken structure | user-facing |
| 52 | Paid | `bills.filter.paid` (broken-nested) | In file, broken structure | user-facing |
| 53 | Unpaid | `bills.filter.unpaid` (broken-nested) | In file, broken structure | user-facing |
| 172 | This Month | `bills.summary.title` (broken-nested) | In file, broken structure | user-facing |
| 176 | Overdue (%d) | `bills.summary.overdue` (broken-nested) | In file, broken structure | user-facing |
| 180 | Due Soon (Next 7 days) | `bills.summary.due_soon` (broken-nested) | In file, broken structure | user-facing |
| 184 | All Bills | `bills.summary.all_bills` (broken-nested) | In file, broken structure | user-facing |
| 272 | Paid %@ | `bills.due_date.paid` (broken-nested) | In file, broken structure | user-facing |
| 278 | \(overdue) day\(overdue == 1 ?  | `bills.due_date.overdue` (broken-nested) | In file, broken structure | user-facing |
| 281 | Due today | `bills.due_date.today` (broken-nested) | In file, broken structure | user-facing |
| 283 | Due tomorrow | `bills.due_date.tomorrow` (broken-nested) | In file, broken structure | user-facing |
| 285 | Due in %d days | `bills.due_date.in_days` (broken-nested) | In file, broken structure | user-facing |
| 287 | Due %@ | `bills.due_date.due` (broken-nested) | In file, broken structure | user-facing |
| 293 | One-time | `bills.frequency.one_time` (broken-nested) | In file, broken structure | user-facing |
| 297 | Daily | `recurring.frequency.daily` (missing) | — | user-facing |
| 298 | Weekly | `recurring.frequency.weekly` (missing) | — | user-facing |
| 299 | Monthly | `recurring.frequency.monthly` (missing) | — | user-facing |
| 300 | Quarterly | `recurring.frequency.quarterly` (missing) | — | user-facing |
| 301 | Yearly | `recurring.frequency.yearly` (missing) | — | user-facing |

#### `Features/BillsFeature/View/BillsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 46 | Bills | `bills.title` (missing) | — | user-facing |
| 87 | due | hardcoded | `due` | user-facing |
| 210 | Sort by: | `bills.sort_by` (missing) | — | user-facing |
| 224 | Show: | `bills.filter` (missing) | — | user-facing |
| 287 | No Bills Yet | `bills.empty.title` (missing) | — | user-facing |
| 291 | Tap + to add your first bill | `bills.empty.subtitle` (missing) | — | user-facing |

#### `Features/BillsFeature/View/Components/BillRowView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 120 | AutoPay | hardcoded | `AutoPay` | user-facing |
| 136 | ✓ Paid | hardcoded | `✓ Paid` | user-facing |

### Subscriptions Feature

#### `Features/SubscriptionsFeature/View/SubscriptionInputView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 68 | 1 day before | `bill.reminder.one_day` (broken-nested) | In file, broken structure | user-facing |
| 69 | 3 days before | `bill.reminder.three_days` (broken-nested) | In file, broken structure | user-facing |
| 70 | 7 days before | `bill.reminder.seven_days` (broken-nested) | In file, broken structure | user-facing |
| 82 | Edit Subscription | `subscription.title.edit` (broken-nested) | In file, broken structure | user-facing |
| 82 | Add Subscription | `subscription.title.add` (broken-nested) | In file, broken structure | user-facing |
| 93 | Next renewal: %@ | `subscription.next_renewal` (broken-nested) | In file, broken structure | user-facing |
| 116 | Service Name * | `subscription.service_name` (broken-nested) | In file, broken structure | user-facing |
| 121 | Netflix, Spotify, etc. | `subscription.service_name_placeholder` (broken-nested) | In file, broken structure | user-facing |
| 132 | Amount * | `form.amount` (broken-nested) | In file, broken structure | user-facing |
| 156 | How often? * | `subscription.billing_cycle` (broken-nested) | In file, broken structure | user-facing |
| 171 | First payment date * | `subscription.first_payment_date` (broken-nested) | In file, broken structure | user-facing |
| 177 | First payment date | `subscription.first_payment_date` (broken-nested) | In file, broken structure | user-facing |
| 194 | Category | `form.category` (broken-nested) | In file, broken structure | user-facing |
| 212 | Remind me | `bill.remind_me` (broken-nested) | In file, broken structure | user-facing |
| 227 | Notes (optional) | `form.notes_optional` (broken-nested) | In file, broken structure | user-facing |
| 242 | Save Changes | `form.save_changes` (broken-nested) | In file, broken structure | user-facing |
| 242 | Add Subscription | `subscription.title.add` (broken-nested) | In file, broken structure | user-facing |
| 260 | Resume Subscription | `subscription.resume` (broken-nested) | In file, broken structure | user-facing |
| 260 | Pause Subscription | `subscription.pause` (broken-nested) | In file, broken structure | user-facing |
| 271 | Delete Subscription | `subscription.delete` (broken-nested) | In file, broken structure | user-facing |
| 286 | Cancel | `form.cancel` (broken-nested) | In file, broken structure | user-facing |
| 293 | Done | `form.done` (broken-nested) | In file, broken structure | user-facing |
| 300 | Delete Subscription? | `subscription.delete_confirm_title` (broken-nested) | In file, broken structure | user-facing |
| 301 | Cancel | `form.cancel` (broken-nested) | In file, broken structure | user-facing |
| 302 | Delete Subscription | `subscription.delete` (broken-nested) | In file, broken structure | user-facing |
| 306 | This will permanently delete this subscription. This ac… | `subscription.delete_confirm_message` (broken-nested) | In file, broken structure | user-facing |
| 347 | Please enter a valid amount | `form.error.invalid_amount` (broken-nested) | In file, broken structure | user-facing |
| 354 | Please enter a service name | `subscription.error.enter_name` (broken-nested) | In file, broken structure | user-facing |
| 381 | Failed to update subscription | `subscription.error.failed_update` (broken-nested) | In file, broken structure | user-facing |
| 400 | Failed to create subscription | `subscription.error.failed_create` (broken-nested) | In file, broken structure | user-facing |
| 420 | resume | `subscription.resume` (broken-nested) | In file, broken structure | user-facing |
| 420 | pause | `subscription.pause` (broken-nested) | In file, broken structure | user-facing |
| 435 | Failed to delete subscription | `subscription.error.failed_delete` (broken-nested) | In file, broken structure | user-facing |

#### `Features/SubscriptionsFeature/ViewModel/SubscriptionsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 33 | Renewal Date | `subscriptions.sort.renewal_date` (broken-nested) | In file, broken structure | user-facing |
| 34 | Name | `subscriptions.sort.name` (broken-nested) | In file, broken structure | user-facing |
| 74 | Monthly Total | `subscriptions.summary.title` (missing) | — | user-facing |
| 78 | Renewing Soon | `subscriptions.renewing_soon.title` (missing) | — | user-facing |
| 82 | All Subscriptions | `subscriptions.all.title` (missing) | — | user-facing |
| 123 | Failed to delete subscription | `subscriptions.error.delete_failed` (broken-nested) | In file, broken structure | user-facing |
| 135 | Failed to pause subscription | `subscriptions.error.pause_failed` (broken-nested) | In file, broken structure | user-facing |
| 147 | Failed to resume subscription | `subscriptions.error.resume_failed` (broken-nested) | In file, broken structure | user-facing |
| 174 | Renews today | `subscriptions.renews.today` (missing) | — | user-facing |
| 176 | Renews tomorrow | `subscriptions.renews.tomorrow` (missing) | — | user-facing |
| 178 | Renews in \(days) days | `subscriptions.renews.in_days` (missing) | — | user-facing |
| 180 | Renews \(formatDate(subscription.nextRenewalDate ?? Dat… | `subscriptions.renews.on_date` (missing) | — | user-facing |
| 189 | Monthly | `subscriptions.cycle.monthly` (missing) | — | user-facing |
| 191 | Yearly | `subscriptions.cycle.yearly` (missing) | — | user-facing |
| 193 | Weekly | `subscriptions.cycle.weekly` (missing) | — | user-facing |

#### `Features/SubscriptionsFeature/View/SubscriptionsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 41 | Subscriptions | `subscriptions.title` (missing) | — | user-facing |
| 82 | /month | `ui.units.per_month` (broken-nested) | In file, broken structure | user-facing |
| 139 | Sort by: | `subscriptions.sort_by` (missing) | — | user-facing |
| 197 | No Subscriptions Yet | `subscriptions.empty.title` (missing) | — | user-facing |
| 201 | Tap + to add your first subscription | `subscriptions.empty.subtitle` (missing) | — | user-facing |
| 307 | Paused | `subscriptions.paused` (broken-nested) | In file, broken structure | user-facing |

### Insights Feature

#### `Features/InsightsFeature/ViewModel/InsightsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 111 | Failed to load insights: %@ | `insights.error.load_failed` (broken-nested) | In file, broken structure | user-facing |
| 273 | Last Month | `insights.chart.last_month` (broken-nested) | In file, broken structure | user-facing |
| 274 | This Month | `insights.chart.this_month` (broken-nested) | In file, broken structure | user-facing |

### Health Feature

#### `Features/HealthFeature/View/Components/HealthScoreDetailCard.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 29 | Financial Health Score | hardcoded | `Financial Health Score` | user-facing |
| 108 | Excellent work! Your financial health is outstanding. K… | hardcoded | — | user-facing |
| 110 | Great job! Your financial health is strong. A few tweak… | hardcoded | — | user-facing |
| 112 | Good progress! Your financial health is on the right tr… | hardcoded | — | user-facing |
| 114 | Fair start. Your financial health needs attention. Chec… | hardcoded | — | user-facing |
| 116 | Your financial health needs improvement. Follow the rec… | hardcoded | — | user-facing |
| 118 | Getting started. Set up your budget to see your financi… | hardcoded | — | user-facing |

#### `Features/HealthFeature/View/Components/HealthBreakdownRow.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 142 | Excellent - You're doing great in this area! | hardcoded | — | user-facing |
| 144 | Great - Strong performance with room for minor improvem… | hardcoded | — | user-facing |
| 146 | Good - On the right track, keep it up! | hardcoded | — | user-facing |
| 148 | Fair - This area needs some attention. | hardcoded | — | user-facing |
| 150 | Needs work - Focus on improving this component. | hardcoded | — | user-facing |

#### `Features/HealthFeature/ViewModel/HealthDetailsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 318 | No financial data available. Please set up your budget … | `health.error.no_data` (broken-nested) | In file, broken structure | user-facing |
| 320 | Failed to calculate health score. Please try again. | `health.error.calculation_failed` (broken-nested) | In file, broken structure | user-facing |

### Recurring Transactions

#### `Features/RecurringTransactionsFeature/View/RecurringTransactionsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 11 | Overdue | `recurring.overdue.title` (missing) | — | user-facing |
| 27 | Upcoming | `recurring.upcoming.title` (missing) | — | user-facing |
| 42 | All Recurring Transactions | `recurring.all.title` (missing) | — | user-facing |
| 55 | Recurring Transactions | `recurring.nav_title` (missing) | — | user-facing |
| 59 | Close | `toolbar.close` (missing) | — | user-facing |
| 89 | Error | `error.title` (missing) | — | user-facing |
| 190 | Transaction Details | `edit_recurring.details.title` (missing) | — | user-facing |
| 191 | Transaction Title | `edit_recurring.title_placeholder` (missing) | — | user-facing |
| 195 | Amount | `edit_recurring.amount_label` (missing) | — | user-facing |
| 203 | Category | `edit_recurring.category.title` (missing) | — | user-facing |
| 204 | Type | `edit_recurring.category_type_label` (missing) | — | user-facing |
| 205 | Income | `edit_recurring.type_income` (missing) | — | user-facing |
| 206 | Expense | `edit_recurring.type_expense` (missing) | — | user-facing |
| 214 | Category | `edit_recurring.category_name_label` (missing) | — | user-facing |
| 216 | Select Category | `edit_recurring.select_category` (missing) | — | user-facing |
| 225 | Schedule | `edit_recurring.schedule.title` (missing) | — | user-facing |
| 230 | Frequency | `edit_recurring.frequency_label` (missing) | — | user-facing |
| 240 | Start Date | `edit_recurring.start_date_label` (missing) | — | user-facing |
| 242 | Has End Date | `edit_recurring.has_end_date` (missing) | — | user-facing |
| 245 | End Date | `edit_recurring.end_date_label` (missing) | — | user-facing |
| 249 | Notes | `edit_recurring.notes.title` (missing) | — | user-facing |
| 250 | Optional notes... | `edit_recurring.notes_placeholder` (missing) | — | user-facing |
| 254 | Edit Recurring Transaction | `edit_recurring.edit_title` (missing) | — | user-facing |
| 254 | Add Recurring Transaction | `edit_recurring.add_title` (missing) | — | user-facing |
| 362 | Select Category | `category_picker.nav_title` (missing) | — | user-facing |
| 399 | Select Frequency | `frequency_picker.nav_title` (missing) | — | user-facing |

#### `Features/RecurringTransactionsFeature/ViewModel/RecurringTransactionsViewModel.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 16 | Daily | `recurring.frequency.daily` (missing) | — | user-facing |
| 17 | Weekly | `recurring.frequency.weekly` (missing) | — | user-facing |
| 18 | Monthly | `recurring.frequency.monthly` (missing) | — | user-facing |
| 19 | Quarterly | `recurring.frequency.quarterly` (missing) | — | user-facing |
| 20 | Yearly | `recurring.frequency.yearly` (missing) | — | user-facing |
| 99 | Failed to fetch recurring transactions: \(error.localiz… | `recurring.error.fetch_failed` (missing) | — | user-facing |

### Shared Components

#### `Features/Shared/CreateCategoryModal.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 57 | Entry Type | `financial.entry.type_header` (missing) | — | user-facing |
| 73 | Category Name | `category.modal.name_placeholder` (broken-nested) | In file, broken structure | user-facing |
| 89 | Category Details | `category.modal.details_header` (broken-nested) | In file, broken structure | user-facing |
| 96 | Choose Icon | `category.modal.choose_icon` (broken-nested) | In file, broken structure | user-facing |
| 107 | Choose Color | `category.modal.choose_color` (broken-nested) | In file, broken structure | user-facing |
| 109 | Premium | `category.modal.premium` (broken-nested) | In file, broken structure | user-facing |
| 124 | Category Name | `category.modal.name_placeholder` (broken-nested) | In file, broken structure | user-facing |
| 130 | Preview | `category.modal.preview` (broken-nested) | In file, broken structure | user-facing |
| 133 | Add %@ Category | `category.modal.title.add` (broken-nested) | In file, broken structure | user-facing |
| 137 | Cancel | `category.modal.cancel` (broken-nested) | In file, broken structure | user-facing |
| 143 | Save | `category.modal.save` (broken-nested) | In file, broken structure | user-facing |
| 149 | Invalid Category | `category.modal.invalid_title` (broken-nested) | In file, broken structure | user-facing |
| 213 | Failed to save category. Please try again. | `category.modal.save_error` (broken-nested) | In file, broken structure | user-facing |
| 218 | Failed to create category | `category.modal.create_error` (broken-nested) | In file, broken structure | user-facing |

#### `Features/Shared/AddCustomCategoryCard.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 45 | Unlock | `ui.unlock` (broken-nested) | In file, broken structure | user-facing |

### DesignSystem

#### `DesignSystem/Components/Indicators/TrendIndicator.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 134 | Negative Trend | hardcoded | — | user-facing |
| 138 | Spending | hardcoded | `charts.spending_breakdown.empty` | user-facing |
| 150 | Neutral Trend | hardcoded | — | user-facing |
| 154 | Savings Rate | hardcoded | — | user-facing |
| 166 | Large Changes | hardcoded | — | user-facing |
| 171 | Huge increase | hardcoded | — | user-facing |
| 180 | Big decrease | hardcoded | — | user-facing |
| 192 | Custom Colors | hardcoded | — | user-facing |
| 197 | With blue | hardcoded | — | user-facing |
| 206 | With purple | hardcoded | — | user-facing |
| 218 | From/To Constructor | hardcoded | — | user-facing |
| 255 | Expenses | hardcoded | `Expenses` | user-facing |
| 261 | Neutral | hardcoded | — | user-facing |

#### `DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 19 | Subscription tracking | `premium.banner.feature.subscriptions` (missing) | — | user-facing |
| 20 | Bill reminders | `premium.banner.feature.bills` (missing) | — | user-facing |
| 21 | Savings goals | `premium.banner.feature.savings` (missing) | — | user-facing |
| 38 | Unlock Premium | `premium.banner.title` (missing) | — | user-facing |
| 45 | Get access to all 9 powerful features: | `premium.banner.subtitle` (missing) | — | user-facing |
| 64 | And 6 more... | `premium.banner.feature.more` (missing) | — | user-facing |
| 70 | One-time purchase. No subscription. | `premium.banner.onetime` (missing) | — | user-facing |
| 79 | Upgrade Now | `premium.banner.cta` (missing) | — | user-facing |
| 83 | $4.99 — Lifetime Access | `premium.banner.price` (missing) | — | user-facing |
| 101 | Unlock Premium features for $4.99 one-time purchase. Ta… | `premium.banner.accessibility` (missing) | — | user-facing |

#### `DesignSystem/Components/Charts/MiniBarChart.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 98 | No data available | hardcoded | `No data available` | user-facing |
| 114 | Chart showing \(trend) with \(data.count) data points | hardcoded | — | user-facing |
| 138 | Decreasing Trend | hardcoded | — | user-facing |
| 152 | Volatile Trend | hardcoded | — | user-facing |
| 166 | Many Data Points | hardcoded | — | user-facing |

#### `DesignSystem/Components/Cards/CompactDailyBudgetCard.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 89 | Last day | `home.daily_budget.last_day` (missing) | — | user-facing |
| 123 | Today you can spend | `home.daily_budget.title` (missing) | — | user-facing |

#### `DesignSystem/Components/Cards/DailyBudgetCard.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 83 | Last day of month | `home.daily_budget.last_day` (missing) | — | user-facing |
| 119 | Daily Budget | `home.daily_budget.title` (missing) | — | user-facing |

#### `DesignSystem/Components/Cards/HealthScoreCard.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 85 | Financial Health Score | hardcoded | `Financial Health Score` | user-facing |
| 126 | /100 | hardcoded | `/100` | user-facing |

#### `DesignSystem/Components/Rows/EmptyStateRow.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 37 | No \(frequencyText) income yet — tap + to add your firs… | hardcoded | — | user-facing |
| 48 | No \(frequencyText) expenses tracked — tap + to add! | hardcoded | — | user-facing |

#### `DesignSystem/Components/Cards/SavingsGoalCard.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 93 | Savings Goal | hardcoded | `Savings Goal` | user-facing |

#### `DesignSystem/Components/Sections/FinancialSection.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 227 | Add monthly income | `ui.add_monthly_income` (broken-nested) | In file, broken structure | user-facing |

### Widgets

#### `Features/WidgetsFeature/View/WidgetsSetupView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 20 | Widgets Setup | `widgets.setup.title` (broken-nested) | In file, broken structure | user-facing |
| 47 | How to Add Widgets | `widgets.setup.how_to_add` (broken-nested) | In file, broken structure | user-facing |
| 54 | Long Press Home Screen | `widgets.setup.step1.title` (missing) | — | user-facing |
| 62 | Tap the + Button | `widgets.setup.step2.title` (missing) | — | user-facing |
| 70 | Search for BudgetMeter | `widgets.setup.step3.title` (missing) | — | user-facing |
| 78 | Choose Net Daily Pace | `widgets.setup.step4.title` (missing) | — | user-facing |
| 86 | Add Widget | `widgets.setup.step5.title` (missing) | — | user-facing |
| 97 | Available Widget | `widgets.setup.available.v1` (missing) | — | user-facing |
| 101 | Net Daily Pace | `widget.pace.title` (missing) | — | user-facing |
| 113 | Widgets | hardcoded | `Widgets` | user-facing |

#### `BudgetMeterWidgets/NetDailyPaceWidget.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 21 | Net Daily Pace | `widget.pace.title` (missing) | — | user-facing |
| 24 | See whether you're moving forward or slowing down | `widget.pace.description` (missing) | — | user-facing |

### Data Export

#### `Features/DataExportFeature/View/DataExportView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 29 | All Time | `export.date_range.all` (missing) | — | user-facing |
| 30 | Last Month | `export.date_range.last_month` (missing) | — | user-facing |
| 31 | Last 3 Months | `export.date_range.last_3_months` (missing) | — | user-facing |
| 32 | Last Year | `export.date_range.last_year` (missing) | — | user-facing |
| 33 | Custom Range | `export.date_range.custom` (missing) | — | user-facing |
| 41 | Export Format | `export.format.title` (missing) | — | user-facing |
| 71 | Date Range | `export.date_range.title` (missing) | — | user-facing |
| 92 | Start Date | `export.start_date` (missing) | — | user-facing |
| 93 | End Date | `export.end_date` (missing) | — | user-facing |
| 112 | Exporting... | `export.exporting` (missing) | — | user-facing |
| 112 | Export Data | `export.export_button` (missing) | — | user-facing |
| 129 | Export Information | `export.info.title` (missing) | — | user-facing |
| 131 | Your data will be exported in the selected format. The … | `export.info.description` (missing) | — | user-facing |
| 136 | • Financial categories and amounts | hardcoded | `• Financial categories and amounts` | user-facing |
| 137 | • Recurring transactions | hardcoded | `• Recurring transactions` | user-facing |
| 138 | • Custom categories | hardcoded | `• Custom categories` | user-facing |
| 139 | • App settings and preferences | hardcoded | `• App settings and preferences` | user-facing |
| 147 | Export Data | `export.nav_title` (missing) | — | user-facing |
| 151 | Close | `toolbar.close` (missing) | — | user-facing |
| 161 | Error | `error.title` (missing) | — | user-facing |
| 164 | An unknown error occurred | `export.error.unknown` (missing) | — | user-facing |
| 179 | Formatted report with charts and summaries | `export.format.pdf.description` (missing) | — | user-facing |
| 180 | Spreadsheet-compatible data format | `export.format.csv.description` (missing) | — | user-facing |
| 181 | Machine-readable data format | `export.format.json.description` (missing) | — | user-facing |
| 211 | Export failed: \(error.localizedDescription) | `export.error.failed` (missing) | — | user-facing |

### Security

#### `Features/SecurityFeature/View/BiometricAuthView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 86 | OK | `toolbar.ok` (missing) | — | user-facing |

#### `Features/SecurityFeature/View/BiometricSettingsView.swift`

| Line | String | Key / Status | Existing key? | Severity |
|-----:|--------|--------------|---------------|----------|
| 111 | OK | `toolbar.ok` (missing) | — | user-facing |

## Appendix A — Broken-nested keys in `UI.xcstrings` (sample)

These keys have translations in the file but are nested under `/income.summary.yearly/` and need to be moved into the `strings` dict:

- `bill.autopay`
- `bill.autopay_description`
- `bill.delete`
- `bill.delete_confirm_message`
- `bill.delete_confirm_title`
- `bill.due_date`
- `bill.error.enter_name`
- `bill.error.failed_create`
- `bill.error.failed_delete`
- `bill.error.failed_update`
- `bill.frequency`
- `bill.mark_paid`
- `bill.mark_unpaid`
- `bill.name`
- `bill.name_placeholder`
- `bill.recurring`
- `bill.recurring_description`
- `bill.remind_me`
- `bill.reminder.one_day`
- `bill.reminder.seven_days`
- `bill.reminder.three_days`
- `bill.title.add`
- `bill.title.edit`
- `bills.due_date.due`
- `bills.due_date.in_days`
- `bills.due_date.overdue`
- `bills.due_date.paid`
- `bills.due_date.today`
- `bills.due_date.tomorrow`
- `bills.filter.all`
- `bills.filter.paid`
- `bills.filter.unpaid`
- `bills.frequency.one_time`
- `bills.sort.amount`
- `bills.sort.due_date`
- `bills.sort.name`
- `bills.summary.all_bills`
- `bills.summary.due_soon`
- `bills.summary.overdue`
- `bills.summary.title`
- `category.modal.cancel`
- `category.modal.choose_color`
- `category.modal.choose_icon`
- `category.modal.create_error`
- `category.modal.details_header`
- `category.modal.invalid_title`
- `category.modal.name_placeholder`
- `category.modal.premium`
- `category.modal.preview`
- `category.modal.save`
- … and 89 more

## Appendix B — Truly missing key domains

| Domain prefix | Missing key count |
|---------------|------------------:|
| `premium.*` | 34 |
| `backup.*` | 23 |
| `export.*` | 22 |
| `edit_recurring.*` | 18 |
| `recurring.*` | 15 |
| `subscriptions.*` | 14 |
| `settings.*` | 14 |
| `account.*` | 14 |
| `home.*` | 7 |
| `widgets.*` | 6 |
| `bills.*` | 5 |
| `savings_goals.*` | 5 |
| `auth.*` | 5 |
| `toolbar.*` | 4 |
| `widget.*` | 3 |
| `error.*` | 2 |
| `common.*` | 2 |
| `category_picker.*` | 1 |
| `frequency_picker.*` | 1 |
| `financial.*` | 1 |
| `security.*` | 1 |

## Appendix C — Catalog files reference

| File | Valid keys in `strings` | Notes |
|------|------------------------:|-------|
| `Alerts.xcstrings` | 5 |  |
| `Categories.xcstrings` | 65 |  |
| `Currency.xcstrings` | 1 |  |
| `Debug.xcstrings` | 5 |  |
| `Home.xcstrings` | 70 |  |
| `Localizable.xcstrings` | 529 |  |
| `Settings.xcstrings` | 88 |  |
| `UI.xcstrings` | 11 | ⚠️ +139 broken-nested, +8 orphaned |
