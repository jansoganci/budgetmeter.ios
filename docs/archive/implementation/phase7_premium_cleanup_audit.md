# Phase 7 — Premium Cleanup Audit

**Audit date:** 2026-06-18  
**Auditor scope:** Read-only code review against `phase7_premium_cleanup_scope.md` and current implementation  
**Status:** Phase 7 is **largely implemented** with a canonical gate matrix, service guards, and focused tests. Several enforcement gaps, product-decision ambiguities, and localization/accessibility items remain.

---

## Executive Summary

Phase 7 delivered its core goal: a single `BudgetMeterCapability` matrix, `PremiumManager.hasAccess(to:)` (instance + static), refactored premium wrappers, and service-level guards for export, biometric enablement, and theme application. StoreKit lifetime product ID is unchanged (`com.budgetmeter.premium.lifetime`), restore reports a no-purchase-found state, and paywall price uses StoreKit metadata with a localized fallback.

**What works well**

- Canonical 22-capability matrix with `.free`, `.premium`, and `.postponed` access levels
- `PremiumGateMatrixTests` (8 tests) pass and protect free-core boundaries
- Free core (Home pace, income/expense entry, one basic savings goal, default theme) is not gated in navigation or matrix
- Premium wrappers (`PremiumFeatureView`, `PremiumFeatureButton`, `PremiumFeatureRow`) use feature-specific `hasAccess`
- Service guards: `DataExportService`, `BiometricManager.enableBiometric()`, `ThemeManager.applyTheme(_:)`
- Restore flow sets `premium.restore.none_found` when no entitlement is found
- Most paywall/error strings are in `UI.xcstrings` under `premium.*`

**Remaining risks (priority order)**

1. **Enforcement gaps:** `subscriptionTracking`, `billReminders`, and `recurringAutomation` are premium in the matrix but lack UI/service gates on live surfaces (subscriptions on Expense screen, `RecurringTransactionsView`, `BackgroundProcessingService`).
2. **Settings UX:** Non-premium users see only an upgrade banner — no per-feature locked rows — so discovery of individual premium features is limited.
3. **JSON export:** All export formats (PDF/CSV/JSON) are gated as `dataExport` premium; product docs still need an explicit JSON decision.
4. **Terms/legal mismatch:** Settings Terms of Service still describe auto-renewing subscriptions while the app sells a lifetime non-consumable.
5. **Localization gaps:** `AddCustomCategoryCard` uses hardcoded `"Add Card"` / `"Premium"`; banner and paywall still hardcode `$4.99` in fallback paths.
6. **Manual StoreKit QA:** Not evidenced in repo; unit tests cannot validate purchase/restore on device.

---

## 1. BudgetMeterCapability Matrix

**Source:** `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`

### Full capability inventory

| Capability | Access Level | `PremiumFeature` mapping | Notes |
| --- | --- | --- | --- |
| `homeDashboard` | **Free** | — | Home tab has no premium gate |
| `sharedFinancialSummary` | **Free** | — | `FinancialSummaryBuilder` not gated |
| `incomeEntry` | **Free** | — | Income tab ungated |
| `expenseEntry` | **Free** | — | Expense tab ungated |
| `oneTimeEntry` | **Free** | — | One-time sections on Income/Expense |
| `basicRecurringEntry` | **Free** | — | Recurring category rows on Income/Expense |
| `oneBasicSavingsGoal` | **Free** | — | Enforced in `SavingsGoalManager` + `SavingsGoalsViewModel` |
| `defaultTheme` | **Free** | — | `AppTheme.default.requiresPremium == false` |
| `customCategories` | **Premium** | `.customCategories` | UI gates in `AddCustomCategoryCard`, `CreateCategoryModal`, etc. |
| `subscriptionTracking` | **Premium** | `.subscriptionTracking` | **Matrix only** — Expense subscriptions section has no gate |
| `billReminders` | **Premium** | `.billReminders` | **Matrix only** — `BillsView` exists but is not linked from main nav |
| `multipleSavingsGoals` | **Premium** | `.savingsGoals` | Gated in ViewModel + `SavingsGoalManager` |
| `recurringAutomation` | **Premium** | `.recurringTransactions` | **Matrix only** — automation runs without premium check |
| `dataExport` | **Premium** | `.dataExport` | Service guard; Settings nav gated behind `isPremium` |
| `widgets` | **Premium** | `.widgets` | Widget snapshot + `WidgetsSetupView` teaser |
| `spendingInsights` | **Premium** | `.spendingInsights` | Insights tab wrapped in `PremiumFeatureView` |
| `biometricLock` | **Premium** | `.biometricLock` | Service guard + Settings nav (premium users only) |
| `premiumThemes` | **Premium** | `.premiumThemes` | UI + `ThemeManager` guard |
| `advancedNotifications` | **Premium** | — (helpers: `hasAdvancedNotifications`) | Daily encouragement gated in ViewModel + `NotificationService` |
| `advancedHistoryReporting` | **Premium** | — | Matrix/test only; no dedicated UI gate found |
| `forecasting` | **Premium** | — | Matrix/test only; no UI implementation found |
| `backupSync` | **Premium** | — | Phase 9 — gated in `AccountBackupSettingsView` + `BackupService` |
| `adsFree` | **Postponed** | — | Always returns `false` from `hasAccess` |

### Matrix coverage questions

| Question | Finding |
| --- | --- |
| Does every major feature have a capability entry? | **Mostly yes.** Core loop, savings, export, themes, widgets, insights, notifications, backup, and placeholder capabilities (`forecasting`, `advancedHistoryReporting`) are represented. |
| Features premium-gated in code but NOT in matrix? | **No major mismatches.** Code gates align with matrix cases or use `PremiumFeature` → `capability` mapping. |
| Features in matrix that don't exist in app? | **`forecasting`** and **`advancedHistoryReporting`** are matrix placeholders without user-facing screens. **`billReminders`** / **`BillsView`** exist but are orphaned (preview-only, no `NavigationLink`). **`subscriptionTracking`** capability exists but subscription UI on Expense is ungated. |

### `PremiumFeature` vs `BudgetMeterCapability`

`PremiumFeature` has 10 cases, all mapping to premium capabilities. Free capabilities exist only on `BudgetMeterCapability`. `advancedNotifications`, `backupSync`, `forecasting`, and `advancedHistoryReporting` are capability-only (no paywall feature card).

---

## 2. PremiumManager API

**File:** `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`

| API item | Status | Details |
| --- | --- | --- |
| `hasAccess(to: BudgetMeterCapability)` (instance) | ✅ | Delegates to static helper with `isPremium` |
| `hasAccess(to: BudgetMeterCapability, isPremium:)` (static) | ✅ | Switches on `accessLevel`: `.free` → true, `.premium` → `isPremium`, `.postponed` → false |
| `hasAccess(to: PremiumFeature)` | ✅ | Maps via `feature.capability` |
| `hasInsights` / `hasAdvancedNotifications` | ✅ | Thin wrappers over `spendingInsights` / `advancedNotifications` |
| StoreKit product ID | ✅ | `com.budgetmeter.premium.lifetime` (unchanged) |
| `premiumDisplayPrice` | ✅ | `product?.displayPrice` from StoreKit |
| Purchase flow | ✅ | Handles success, cancelled, pending, unknown, failed with localized errors |
| Restore flow | ✅ | `AppStore.sync()` → `checkForValidTransactions()`; if none restored, sets `purchaseState = .notPurchased` and `premium.restore.none_found` message |
| Local cache | ✅ | `AppSettings.isPremiumUser` / `premiumPurchaseDate` |
| DEBUG toggle | ✅ | `setDebugPremiumStatus` behind `#if DEBUG`; Settings debug toggle in DEBUG only |
| Force-unwraps / crash risk | ✅ **Low** | No force-unwraps in `PremiumManager`. Optional chaining and guards used throughout. `DataExportService` PDF generation uses force-unwraps on dates in JSON path (separate file, pre-existing). |
| Widget refresh on purchase | ✅ | `updatePremiumStatus` calls `WidgetSnapshotService.refreshFromCurrentData` |

**Restore UX note:** Paywall shows restore errors inline (`errorMessage` text) but does not show a dedicated success alert for the no-purchase-found case — only purchase/restore success alerts when `isPremium` becomes true.

---

## 3. Premium Gates in Services

| Service | Expected gate | Implementation | Verdict |
| --- | --- | --- | --- |
| `DataExportService.exportData` | CSV/PDF premium | Checks `hasAccess(to: .dataExport)` before any format; throws `PremiumError.featureLocked(.dataExport)` | ✅ Guarded (all formats including JSON) |
| `BiometricManager.enableBiometric()` | Biometric lock premium | `guard PremiumManager.shared.hasAccess(to: .biometricLock)` at start | ✅ Guarded |
| `ThemeManager.applyTheme(_:)` | Non-default themes premium | `guard !theme.requiresPremium \|\| hasAccess(to: .premiumThemes)` | ✅ Guarded |
| `SavingsGoalManager` (create goal) | One basic goal free | `canCreateGoalUnderFreeBoundary` checks `isPremiumUser` + active goal count | ✅ Guarded (uses `AppSettings.isPremiumUser` directly, not `hasAccess`) |
| `BackupService` | Backup/sync premium | `validateBackupPreconditions` requires `isPremium` param | ✅ Guarded (Phase 9) |
| `NotificationService.scheduleDailyEncouragement` | Advanced notifications | Checks `settings.isPremiumUser` + `dailyEncouragementEnabled` | ✅ Guarded (cache-level, not capability helper) |
| `BackgroundProcessingService` | Recurring automation | **No premium check** before `processRecurringTransactions()` | ❌ Gap |

**Theme load edge case:** `ThemeManager.loadTheme()` restores saved premium theme without re-validating entitlement. A user who loses premium could retain a premium theme until they change it manually.

**Biometric edge case:** `BiometricSettingsView` is only reachable from Settings when `premiumManager.isPremium` is true, but `disableBiometric()` is unguarded (correct). If a non-premium user had biometric enabled from a prior premium period, the toggle UI is hidden but lock state may persist in `AppSettings`.

---

## 4. Premium UI Surfaces

### `PremiumPaywallView`

| Aspect | Status |
| --- | --- |
| Copy | Localized via `UI.xcstrings` (`premium.header.title`, `premium.features.title`, buttons, alerts) |
| Feature list | All `PremiumFeature.allCases` with localized names |
| Price | StoreKit `premiumDisplayPrice` with fallback `premium.price` (`$4.99`) |
| Purchase / Restore buttons | Localized; loading state on purchase |
| Terms / Privacy | Buttons present; **handlers are empty TODOs** (no URL open) |
| Feature parameter | Accepted but **not used** to highlight triggering feature |
| Accessibility | No explicit VoiceOver labels on locked states in paywall itself |

### `PremiumFeatureView` / `PremiumFeatureButton` / `PremiumFeatureRow`

- All use `premiumManager.hasAccess(to: premiumFeature)` ✅
- Gated state shows crown + upgrade CTA; opens paywall sheet ✅
- Used in `ContentView` for Insights tab ✅

### `SettingsView`

| Aspect | Status |
| --- | --- |
| Premium users | Shows Tracking & Goals, Customization (themes, widgets, export), Security (biometric) sections |
| Free users | **Only** `PremiumUpgradeBanner` — no locked per-feature rows |
| Section visibility | Uses top-level `premiumManager.isPremium`, not per-capability checks |
| Purchase/restore | Via paywall sheet from banner (feature preset: `.subscriptionTracking`) |
| Account & Backup | Always visible (free sign-in; backup gated inside child view) |

### Other premium-related views

| View | Gate mechanism |
| --- | --- |
| `PremiumThemesView` | `canApplySelectedTheme` + paywall for non-default |
| `WidgetsSetupView` | Locked teaser when `!hasAccess(to: .widgets)` |
| `DataExportView` | No view-level gate; relies on Settings premium section + service throw |
| `SavingsGoalsView` | `canAddAnotherGoal` → paywall for second goal |
| `AccountBackupSettingsView` | `hasAccess(to: .backupSync)` |
| `InsightsView` / `InsightsViewModel` | `hasInsights` / `PremiumFeatureView` wrapper |
| `NotificationSettingsView` | Daily encouragement locked row + `hasAdvancedNotifications` |
| `HealthDetailsView` | Tips beyond first 3 locked; uses `spendingInsights` capability (orphaned screen — Home health card TODO) |
| `AddCustomCategoryCard` / `AddFinancialItemRow` | `customCategories` capability |
| `PremiumUpgradeBanner` | Marketing CTA; hardcoded price in `premium.banner.price` fallback |

---

## 5. Free Core Preservation

| Free core item | Verified free? | Evidence |
| --- | --- | --- |
| Home dashboard with pace | ✅ | `HomeView` / `HomeViewModel` — no `hasAccess` checks; `homeDashboard` = `.free` |
| Income entry (recurring + one-time) | ✅ | `IncomeView` / `IncomeViewModel` — no premium checks |
| Expense entry (recurring + one-time) | ✅ | `ExpenseView` / `ExpenseViewModel` — category entry free; subscriptions section is separate |
| One basic savings goal | ✅ | `SavingsGoalsViewModel.canAddAnotherGoal`, `SavingsGoalManager.canCreateGoalUnderFreeBoundary` |
| Default theme | ✅ | `AppTheme.default`, `ThemeManager` allows without premium |

**Caveats**

- Expense **subscriptions** UI is accessible to free users despite `subscriptionTracking` being premium in the matrix.
- **Recurring automation** (`BackgroundProcessingService`, `RecurringTransactionsViewModel`) can run/create automated entries without premium enforcement.
- Home **health score** (`CompactHealthCard`) is free on Home; detailed tips screen gates extra tips behind insights premium but is not linked from Home yet (TODO).

---

## 6. Gap Analysis (Planned vs Implemented)

### Scope doc requirements vs current state

| Requirement | Planned | Implemented | Gap |
| --- | --- | --- | --- |
| Canonical `BudgetMeterCapability` matrix | Yes | Yes | — |
| `hasAccess(to:)` helper | Yes | Yes (static + instance) | — |
| Premium wrappers use feature gates | Yes | Yes | — |
| Service guards (export, biometric, themes) | Yes | Yes | — |
| StoreKit lifetime ID unchanged | Yes | Yes | — |
| Restore no-purchase-found state | Yes | Yes (message string) | Minor UX: no dedicated alert |
| Free core protected by tests | Yes | Yes (`PremiumGateMatrixTests`) | — |
| Refactor scattered `isPremium` checks | Yes | **Partial** | Settings section visibility, widget refresh, savings manager still use raw `isPremium` / `isPremiumUser` |
| Per-feature locked Settings rows | Implied | **No** | Free users only see banner |
| JSON export product decision | Undecided | Gated as premium with PDF/CSV | Needs product sign-off |
| Subscription/bill management gates | Premium | Matrix only | Expense subscriptions ungated; Bills orphaned |
| Recurring automation gate | Premium | Matrix + tests only | Background + RT UI ungated |
| Localization for all premium copy | Yes | **Mostly** | See §7 |
| Accessibility for locked states | Yes | **Partial** | Crown icons; some `accessibilityHint` on health tips |
| Manual StoreKit sandbox QA | Required before verified | **Not documented** | Tracker marks postponed |
| Terms reflect lifetime purchase | Implied | **No** | Terms still describe subscriptions |

### Post-Phase 7 additions (out of original Phase 7 scope)

- **Phase 8:** Widget extension with premium locked teaser — uses `isPremium` on snapshot ✅
- **Phase 9:** `backupSync` capability + `AccountBackupSettingsView` gates — implemented after Phase 7 scope doc was written ✅

---

## 7. Known Issues

### Hardcoded / missing localization

| Location | Issue | `UI.xcstrings` key exists? |
| --- | --- | --- |
| `AddCustomCategoryCard.swift` | `"Add Card"` and `"Premium"` hardcoded | `premium.badge` exists; no `add_card` key |
| `PremiumUpgradeBanner` | Fallback `$4.99 — Lifetime Access` via `premium.banner.price` | Key exists but static price |
| `PremiumPaywallView` | Fallback `premium.price` = `$4.99` | Key exists (acceptable fallback when StoreKit unavailable) |
| `HealthTipCard` | `accessibilityHint` English: `"Premium feature. Unlock to see all tips"` | Not in catalog |
| `DataExportService` PDF/CSV content | English report strings (export file content) | N/A (export output, not UI) |
| Settings Terms (`settings.terms.policy.iap.content`) | Describes **auto-renewing subscription** | Localized but **wrong product model** |

### `premium.*` keys in `UI.xcstrings`

Present and used: errors (`premium.error.*`), feature names/descriptions (`premium.feature.*`), paywall (`premium.header.title`, `premium.price`, `premium.purchase.button`, `premium.restore.*`), gated wrapper (`premium.gated.*`), settings rows (`settings.premium.*`).

Also in `Localizable.xcstrings`: `premium.badge`, `insights.premium.*`, `debug.premium.*`.

---

## 8. Feature-by-Feature Audit Table

| Feature / Surface | Matrix access | UI gate | Service gate | Tests | Overall |
| --- | --- | --- | --- | --- | --- |
| Home dashboard / pace | Free | None | N/A | Matrix test | ✅ |
| Income / expense entry | Free | None | N/A | Matrix test | ✅ |
| One-time entry | Free | None | N/A | Matrix test | ✅ |
| Basic recurring entry | Free | None | N/A | Matrix test | ✅ |
| Custom categories | Premium | Yes (cards, modals) | Implicit (color save) | Matrix test | ✅ |
| Subscription tracking | Premium | **No** (Expense section open) | No | Matrix test only | ⚠️ |
| Bill reminders | Premium | **Orphaned** (`BillsView`) | No | Matrix test only | ⚠️ |
| One basic savings goal | Free | Yes | Yes (`SavingsGoalManager`) | Matrix + integration | ✅ |
| Multiple savings goals | Premium | Yes | Yes | Matrix + integration | ✅ |
| Recurring automation | Premium | **No** | **No** (`BackgroundProcessingService`) | Matrix test only | ❌ |
| Data export (PDF/CSV/JSON) | Premium | Settings nav (premium only) | Yes | Matrix test only | ✅ (JSON decision open) |
| Widgets | Premium | Settings + widget teaser | Snapshot writer | Widget tests | ✅ |
| Spending insights | Premium | `PremiumFeatureView` on tab | N/A | Matrix test | ✅ |
| Biometric lock | Premium | Settings (premium section) | Yes | Matrix test only | ✅ |
| Premium themes | Premium | Yes | Yes | Matrix test | ✅ |
| Advanced notifications | Premium | Yes (daily toggle) | Yes (`NotificationService`) | Matrix test only | ✅ |
| Advanced health tips | Premium (insights-adjacent) | Yes on orphaned `HealthDetailsView` | N/A | No | ⚠️ |
| Backup/sync | Premium (Phase 9) | Yes | Yes | Matrix test | ✅ |
| Forecasting | Premium | Not implemented | N/A | Matrix test only | N/A (placeholder) |
| Ads-free | Postponed | N/A | N/A | Matrix test | ✅ (correctly blocked) |

---

## 9. Risk Assessment

| Risk | Severity | Likelihood | Mitigation status |
| --- | --- | --- | --- |
| Free user accesses premium subscriptions/automation | **High** | Medium | Not mitigated in UI/services |
| JSON export premium vs free backup confusion | Medium | Low | Document product decision |
| Terms/legal mismatch (subscription vs lifetime) | **High** (App Review) | High if unchanged | Not fixed |
| Premium theme persists after entitlement loss | Low | Low | Acceptable; optional re-validation on launch |
| Biometric enabled but settings hidden | Low | Low | Edge case for lapsed premium |
| StoreKit untested on device | Medium | High | Manual QA still required |
| Scattered `isPremium` vs `hasAccess` drift | Medium | Medium | Partial refactor done |
| Free core accidentally gated in future | Medium | Low | `PremiumGateMatrixTests` guard rail |

---

## 10. Test Coverage Analysis

### Automated tests

| Test file | Premium-related coverage | Count |
| --- | --- | --- |
| `PremiumGateMatrixTests.swift` | Full matrix: free, premium, postponed, backup, feature mapping, savings, recurring, themes | **8 tests — all pass** (verified 2026-06-18) |
| `BasicSavingsIntegrationTests.swift` | Multiple goals vs premium (`canAddAnotherGoal`) | Partial |
| `WidgetSnapshotWriterTests.swift` / `WidgetSnapshotStoreTests.swift` | Locked teaser for non-premium | Partial |

### Not covered by tests

- `DataExportService` entitlement throw path
- `BiometricManager.enableBiometric()` premium rejection
- `ThemeManager.applyTheme` premium rejection
- `NotificationService` daily encouragement premium guard
- UI/paywall interaction tests
- Restore no-purchase-found paywall presentation
- Service-level subscription/bill/automation gates (not implemented)

### Manual QA (scope doc requirement)

| Check | Status |
| --- | --- |
| Fresh install non-premium | Not documented |
| Successful lifetime purchase | Not documented |
| Cancelled / pending / failed purchase | Not documented |
| Restore with/without prior purchase | Not documented |
| Offline launch after verified premium | Not documented |
| Release build no debug toggle | Code review: `#if DEBUG` ✅ |

### Tracker claims vs audit

Implementation index states Phase 7: **7/7 focused tests, 128/128 full suite**. Current `PremiumGateMatrixTests` has **8** test methods (added `test_backupSyncRequiresPremiumInPhase9`). Focused suite passes on 2026-06-18.

---

## 11. Recommendations (Audit Only — No Code Changes)

1. **Enforce `subscriptionTracking`** on Expense subscriptions section and/or `SubscriptionManager` write paths.
2. **Enforce `recurringAutomation`** in `BackgroundProcessingService` and gate `RecurringTransactionsView` entry (or remove from paywall feature list if intentionally deferred).
3. **Decide JSON export** — keep premium with CSV/PDF or split capability.
4. **Update Terms of Service** localized strings to describe lifetime purchase, not subscription.
5. **Localize** `AddCustomCategoryCard` strings; wire paywall Terms/Privacy URLs.
6. **Settings for free users:** consider locked feature rows (product decision) vs banner-only.
7. **Complete manual StoreKit QA** before marking Phase 7 fully verified for App Store.
8. **Optional:** migrate remaining `isPremium` / `isPremiumUser` checks to `hasAccess(to:)` for consistency (`SavingsGoalManager`, `WidgetSnapshotService`, Settings section visibility).

---

## 12. Conclusion

Phase 7 successfully established a **canonical, testable premium boundary** and protected the free core money-meter loop. The implementation matches the tracker’s “Implemented and Verified” status for matrix, helpers, wrappers, core service guards, StoreKit contract, and unit tests.

The audit finds **meaningful enforcement gaps** where matrix capabilities (`subscriptionTracking`, `billReminders`, `recurringAutomation`) are not yet reflected in live UI or background services, plus **product/legal** items (JSON export decision, subscription wording in Terms) that should be resolved before release.

**Audit verdict:** Phase 7 core deliverables — **complete**. Full product alignment and release readiness — **conditional** on closing enforcement gaps, Terms update, and manual StoreKit QA.
