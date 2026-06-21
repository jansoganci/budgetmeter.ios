# Phase 7 — Premium Cleanup Scope

## 1. Executive Summary

Phase 7 centralizes BudgetMeter premium entitlement boundaries without changing the product model, StoreKit product, CoreData schema, widgets, or cloud sync. The goal is to make premium access predictable, testable, and impossible to accidentally apply to the free core money-meter loop.

The current app already has a lifetime StoreKit purchase path, `PremiumManager`, paywall views, and several premium-looking surfaces. The risk is not the absence of premium code; the risk is that access checks are scattered across view wrappers, settings rows, feature view models, widgets, and manager classes with no single gate matrix that says what is free and what is premium.

Recommendation: **Ready for implementation planning, not started.**

First safe implementation step: create a canonical premium feature matrix and tests around the existing gates before refactoring any paywall or entitlement code.

## 2. Current Codebase Context

Relevant premium code currently exists in:

- `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Premium/ThemeManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`
- `budgetmeter.ios/CoreKit/Sources/Security/BiometricManager.swift`
- `budgetmeter.ios/Features/PremiumFeature/`
- `budgetmeter.ios/Features/PremiumThemesFeature/`
- `budgetmeter.ios/Features/DataExportFeature/`
- `budgetmeter.ios/Features/SecurityFeature/`
- `budgetmeter.ios/Features/SettingsFeature/`
- `budgetmeter.ios/Features/InsightsFeature/`
- `budgetmeter.ios/Features/HealthFeature/`
- `budgetmeter.ios/Features/SavingsGoalsFeature/`
- `budgetmeter.ios/Features/WidgetsFeature/`
- `budgetmeter.ios/Widgets/`
- `budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`
- `budgetmeter.ios/DesignSystem/Components/Rows/AddFinancialItemRow.swift`

The app uses `AppSettings.isPremiumUser` and `AppSettings.premiumPurchaseDate` as local cached entitlement state. StoreKit remains the source for purchase/restore validation, while local state is used for fast runtime access and offline continuity.

Phase 7 must be treated as a cleanup and safety phase, not a monetization redesign.

## 3. Current Premium Architecture Inventory

### `PremiumManager`

Current responsibilities:

- Owns singleton premium state through `PremiumManager.shared`.
- Publishes `isPremium`, `purchaseState`, `isLoading`, and `errorMessage`.
- Loads local entitlement from `AppSettings.isPremiumUser`.
- Loads StoreKit product ID `com.budgetmeter.premium.lifetime`.
- Starts a StoreKit transaction listener.
- Handles purchase flow through `product.purchase()`.
- Handles restore through `AppStore.sync()` and `Transaction.currentEntitlements`.
- Persists successful purchases to CoreData.
- Provides DEBUG-only `setDebugPremiumStatus`.

Current limitations:

- Only exposes two named feature helpers: `hasInsights` and `hasAdvancedNotifications`.
- Most features still check `premiumManager.isPremium` directly.
- There is no central feature matrix that maps `PremiumFeature` to access behavior.
- Restore does not clearly distinguish "restore succeeded with entitlement" from "no previous purchase found."
- User-facing errors are mostly raw English strings.
- Product display price is not exposed for the paywall.

### `PremiumFeature`

Current cases:

- `customCategories`
- `subscriptionTracking`
- `billReminders`
- `savingsGoals`
- `recurringTransactions`
- `dataExport`
- `widgets`
- `spendingInsights`
- `biometricLock`
- `premiumThemes`

Current mismatch risks:

- `subscriptionTracking`, `billReminders`, and `recurringTransactions` overlap with product decisions that basic recurring entry remains free, while automation and advanced management are premium.
- `savingsGoals` is too broad after Phase 6 because one basic savings goal is free and multiple or advanced goals are premium.
- `dataExport` currently says PDF, CSV, or JSON; product scope names CSV/PDF as premium, while JSON needs an explicit decision.
- `widgets` currently describes Home and Lock Screen, but widget v1 scope is Home Screen `systemSmall` only.

### Paywall and premium wrappers

Current surfaces:

- `PremiumPaywallView`
- `PremiumFeatureView`
- `PremiumFeatureButton`
- `PremiumFeatureRow`
- `PremiumUpgradeBanner`

Current limitations:

- Hardcoded paywall price copy appears in the paywall.
- Terms and privacy buttons appear to be placeholder/TODO behavior.
- Wrappers gate by `isPremium`, not by a feature-specific entitlement helper.
- Lock state, badge state, paywall entry, and accessibility copy are not fully standardized.

### Settings entry points

Settings currently exposes several premium surfaces to premium users:

- Savings goals
- Premium themes
- Widgets setup
- Data export
- Biometric lock

For non-premium users, Settings primarily shows an upgrade banner instead of individually visible locked rows for each feature. This may be acceptable, but Phase 7 should make it an explicit product decision rather than an accidental side effect.

### Feature-level managers

Several premium-capable manager/service classes currently do not enforce premium internally:

- `ThemeManager.applyTheme(_:)`
- `DataExportService.exportData(format:dateRange:)`
- `BiometricManager.enableBiometric()`

This means premium enforcement currently depends on upstream navigation or UI gating. Phase 7 should decide whether each premium-only action is guarded at the view level only or also at the manager/service boundary.

For a B2C app, premium-only side effects should generally be guarded close to the action as well as in the UI.

## 4. Current Gate Inventory By Surface

### Free core surfaces that must remain free

- Home dashboard and pace summary
- Income entry
- Expense entry
- One-time income and expense entries
- Basic recurring income and expense entries
- One basic savings goal
- Basic fixed vs surprise expense tracking
- Basic financial health/momentum overview if it supports the core loop
- Default theme

### Premium or premium-adjacent surfaces already present

- Spending insights
- Advanced health tips/details
- Advanced notifications such as daily encouragement
- Data export
- Premium themes
- Biometric lock
- Widgets setup
- Widget runtime premium/locked state
- Multiple savings goals or advanced savings behavior
- Custom categories
- Subscription/bill management features
- Recurring automation

### Surfaces with scattered checks

- `InsightsViewModel` uses `premiumManager.hasInsights`.
- `NotificationSettingsViewModel` uses `premiumManager.hasAdvancedNotifications`.
- `PremiumFeatureView`, `PremiumFeatureButton`, and `PremiumFeatureRow` use `premiumManager.isPremium`.
- Settings conditionally shows premium destinations based on `premiumManager.isPremium`.
- Widgets read local premium state separately and should be handled in Phase 8.
- Data export, theme application, and biometric enabling rely on access being controlled before the user reaches the action.

## 5. Product Decisions It Must Respect

Phase 7 must preserve these decisions:

- BudgetMeter's core financial pace loop remains free.
- Basic income and expense entry remains free.
- Basic recurring income and expense entry remains free.
- One-time income and expense entries remain free.
- One basic savings goal remains free.
- Multiple savings goals and advanced savings behavior are premium.
- Recurring automation is premium.
- Bills and subscriptions are specialized regular expenses; basic expense recording remains free, while dedicated management, reminders, and automation can be premium.
- Widgets are premium.
- CSV/PDF export is premium.
- Premium themes are premium.
- Advanced insights and advanced history/reporting are premium.
- Custom categories are premium, but users must still be able to enter basic income/expense without paying.
- Biometric lock is premium.
- Backup/sync is later premium scope, not Phase 7 implementation scope.
- StoreKit lifetime purchase remains the current v1 direction.
- RevenueCat remains optional later.
- No ads in v1.
- Ads-free is not active v1 scope.
- Premium must not change calculation results.

## 6. Current Problems / Risks

### Entitlement risks

- `isPremium` is used directly in many places, which makes it hard to reason about individual feature access.
- `PremiumFeature` cases are broad and sometimes conflict with product boundaries.
- Local `AppSettings.isPremiumUser` is used as a runtime cache, but the code needs clearer behavior for restore, offline access, and no-entitlement states.
- Existing premium users must not lose access during cleanup.
- DEBUG premium toggling must remain unavailable in release builds.

### Free-core risks

- Broad cases like `savingsGoals`, `recurringTransactions`, `billReminders`, and `subscriptionTracking` can accidentally gate free basic behavior.
- If custom categories are premium, the app still needs usable default categories for free users.
- Widgets can be premium, but Home must not become premium by association.
- Insights can be premium, but the Home pace summary must remain free.

### StoreKit risks

- The lifetime product ID must stay stable unless a separate StoreKit migration is explicitly planned.
- The paywall should not hardcode price if StoreKit product metadata is available.
- Restore flow needs a calm "no purchase found" state.
- Pending, cancelled, failed, unavailable, and unverified transactions need user-safe states.
- App Store sandbox/manual QA is required; unit tests alone cannot fully validate purchase behavior.

### UI and accessibility risks

- Premium badges and locks are visually inconsistent across rows, cards, settings, and feature wrappers.
- Some copy is raw English or generic.
- Lock state must not rely only on color, crown icons, or glow.
- VoiceOver should clearly say when a feature is locked and what action opens the upgrade flow.
- Paywall copy must stay readable under Dynamic Type.

### Scope risks

- Widget implementation belongs to Phase 8.
- Supabase/Auth and cloud entitlement sync belong to Phase 9 or later.
- CoreData schema changes are not needed for Phase 7.
- Premium cleanup can easily spread across too many feature screens if it is not constrained to gates and access behavior.

## 7. Required Phase 7 Behavior

Phase 7 should deliver:

- A single canonical way to ask whether a premium feature is available.
- A feature gate matrix that separates free, premium v1, premium later, and postponed/not-active features.
- A clear distinction between broad product areas and specific gated capabilities.
- Free core flows protected by tests.
- Existing premium access preserved.
- Lifetime purchase and restore behavior verified.
- Feature-specific paywall entry points that use consistent copy and accessibility behavior.
- Consistent locked, teaser, and upgrade states.
- No changes to financial calculation outputs.
- No CoreData schema changes.
- No widget implementation changes before Phase 8.
- No Supabase/Auth changes.

## 8. Recommended Feature Gate Matrix

| Capability | Access | Phase 7 Gate Meaning |
| --- | --- | --- |
| Home dashboard | Free | Never gate the main pace meter. |
| Shared financial summary | Free | Premium cannot alter formulas or returned values. |
| Basic income entry | Free | Default categories must remain enough to use the app. |
| Basic expense entry | Free | Default categories must remain enough to use the app. |
| One-time income/expense | Free | Must remain usable without premium. |
| Basic recurring income/expense | Free | Manual/basic recurring entry remains free. |
| Recurring automation | Premium | Auto-generation, advanced scheduling, or automation can be gated. |
| One basic savings goal | Free | Phase 6 behavior must remain intact. |
| Multiple savings goals | Premium | Gate creation beyond the free goal. |
| Advanced savings insights/gamification | Premium or later | Do not block the basic goal. |
| Default theme | Free | Always available. |
| Premium themes | Premium | Gate applying non-default premium themes. |
| Custom categories | Premium | Gate category creation/customization, not basic entry. |
| Spending insights | Premium | Gate full charts/deep analysis. |
| Basic Home pace insight | Free | Must not depend on Insights premium. |
| Advanced health tips/history | Premium | Gate deeper analysis, not basic status if used in core loop. |
| Advanced notifications | Premium | Daily encouragement or smart automation can be gated. |
| Basic reminders/notifications | Free or existing behavior | Do not broaden the gate without product approval. |
| Data export CSV/PDF | Premium | Confirm UI and service boundary. |
| Data export JSON | Decision needed | Current code mentions JSON; product docs emphasize CSV/PDF. |
| Biometric lock | Premium | Gate enablement and settings access. |
| Widgets | Premium | Phase 7 documents boundary; Phase 8 implements v1 widget. |
| Backup/sync | Premium later | Do not implement until Supabase/Auth phase. |
| Ads-free | Not active v1 | Do not add an ads-free gate because there are no ads. |

## 9. StoreKit / Entitlement Contract

Phase 7 should keep this contract unless the user explicitly approves a product change:

- Product type: lifetime non-consumable.
- Current product ID: `com.budgetmeter.premium.lifetime`.
- Purchase source of truth: StoreKit verified transaction.
- Runtime/local cache: `AppSettings.isPremiumUser`.
- Purchase date cache: `AppSettings.premiumPurchaseDate`.
- Restore source: `Transaction.currentEntitlements`.
- Offline behavior: previously verified local entitlement should remain usable.
- No RevenueCat in v1 cleanup.
- No subscription model in v1 cleanup.
- No StoreKit product file or App Store Connect product rename in Phase 7 implementation unless separately planned.

Required cleanup decisions:

- Expose a feature-specific access helper, such as `hasAccess(to:)`, instead of checking `isPremium` everywhere.
- Decide whether premium-only service actions should throw/return an entitlement error if called directly.
- Add a user-visible no-restored-purchase state.
- Replace hardcoded price display with StoreKit product display data if available.
- Keep fallback paywall copy when product metadata is unavailable.

## 10. Files Likely To Touch In Phase 7

### Premium core

- `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumFeatureView.swift`

### Settings and shared premium UI

- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/NotificationSettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/NotificationSettingsViewModel.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/Components/NotificationToggleRow.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`
- `budgetmeter.ios/DesignSystem/Components/Rows/AddFinancialItemRow.swift`

### Premium feature surfaces

- `budgetmeter.ios/Features/PremiumThemesFeature/`
- `budgetmeter.ios/Features/DataExportFeature/`
- `budgetmeter.ios/Features/SecurityFeature/`
- `budgetmeter.ios/Features/InsightsFeature/`
- `budgetmeter.ios/Features/HealthFeature/`
- `budgetmeter.ios/Features/SavingsGoalsFeature/` only for multiple-goal gate consistency.

### Core services with premium side effects

- `budgetmeter.ios/CoreKit/Sources/Premium/ThemeManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`
- `budgetmeter.ios/CoreKit/Sources/Security/BiometricManager.swift`

### Tests and resources

- `budgetmeter.iosTests/`
- Localization resources only for premium/paywall/restore/lock strings that Phase 7 directly introduces or changes.

## 11. Files Not Allowed To Touch In Phase 7

- CoreData model/schema files.
- Xcode project files unless a test target issue blocks verification and the user approves.
- StoreKit product configuration files unless a separate StoreKit task is approved.
- Supabase/Auth implementation.
- CloudKit setup/removal.
- Widget providers, widget timelines, widget extension implementation, or App Group storage before Phase 8.
- Calculation engine formulas.
- `FinancialSummaryBuilder` unless a premium gate has incorrectly entered calculation output, which should be treated as a bug.
- Home dashboard redesign.
- Income/Expense flow behavior except narrow custom-category gate display if required.
- RevenueCat integration.
- Ads implementation.
- Broad premium theme redesign beyond gate consistency.

## 12. Data / Migration Impact

Phase 7 should require no CoreData schema migration.

Existing data that must be preserved:

- `AppSettings.isPremiumUser`
- `AppSettings.premiumPurchaseDate`
- selected theme
- biometric enabled preference
- export-related timestamps/preferences
- notification settings
- savings goal data from Phase 6
- financial entries and categories

Migration risks:

- Existing premium users must remain premium after app update.
- Users with a selected premium theme should not be forced into a broken theme state.
- Users with biometric lock enabled should not be locked out because of a gate cleanup.
- Users with widget settings should not crash or lose settings before Phase 8.

Implementation guidance:

- Treat local premium state as a cache of previously verified StoreKit entitlement.
- Do not clear local premium state during cleanup.
- Do not introduce a new entitlement persistence model in Phase 7.

## 13. Localization / Accessibility Impact

### Localization

Phase 7 copy should be prepared for localization where it touches user-facing strings:

- Paywall title and subtitle.
- Lifetime purchase copy.
- Purchase button state.
- Restore button state.
- Purchase cancelled.
- Purchase pending.
- Purchase failed.
- Product unavailable.
- No previous purchase found.
- Premium locked state.
- Premium badge text.
- Feature-specific upgrade reasons.

Avoid hardcoding:

- Price strings when StoreKit product display price is available.
- Long feature descriptions in views without localization keys.
- Error strings surfaced directly from low-level APIs unless wrapped in user-friendly copy.

### Accessibility

Required behavior:

- Locked rows identify that the feature is premium.
- Locked controls expose a button action that opens upgrade options.
- Premium badge is not the only signal.
- Color is not the only signal.
- VoiceOver labels should include feature name, locked/unlocked state, and action.
- Paywall supports Dynamic Type without truncating primary price/action copy.
- Restore and purchase loading states are announced or clearly represented.

## 14. Free vs Premium Boundary Impact

Phase 7 owns the app-wide boundary. It should not change the business model, but it should make that model enforceable.

Free must include:

- Home pace meter.
- Core dashboard interpretation.
- Income entry.
- Expense entry.
- One-time entries.
- Basic recurring entries.
- Basic categories/default category flow.
- One basic savings goal.
- Default theme.
- Existing free notification behavior.

Premium v1 can include:

- Widgets.
- CSV/PDF export.
- Premium themes.
- Advanced insights.
- Custom categories.
- Biometric lock.
- Advanced history/reporting.
- Forecasting.
- Multiple savings goals.
- Advanced notification features.
- Advanced bill/subscription management and automation.

Premium later:

- Backup/sync.
- Supabase account-linked entitlement sync.
- Multi-device data sync.
- Remote paywall experimentation.

Not active v1:

- Ads.
- Ads-free entitlement.
- Subscription pricing.
- RevenueCat.

## 15. Test Requirements

### Unit tests

Add or update tests for:

- Free users have access to free core capabilities.
- Premium users have access to all premium v1 capabilities.
- Feature-specific gate helper returns correct results.
- One basic savings goal remains free.
- Multiple savings goals are gated.
- Basic recurring entry remains free.
- Recurring automation is gated.
- Custom category creation is gated without blocking basic entry.
- Data export access is gated.
- Premium theme application is gated.
- Biometric enablement is gated.
- Advanced insights/notifications are gated.
- Existing `AppSettings.isPremiumUser == true` loads as premium.
- Existing `AppSettings.isPremiumUser == false` loads as non-premium.

### UI or view-model tests

Cover:

- Locked feature opens paywall.
- Premium feature action runs when premium is active.
- Paywall dismiss does not incorrectly unlock access.
- Restore no-entitlement state is user-safe.
- Product-unavailable state is user-safe.
- Notification premium toggle does not stay enabled for non-premium users.

### Manual StoreKit QA

Required manual checks:

- Fresh install, non-premium user.
- Successful lifetime purchase.
- Cancelled purchase.
- Pending purchase.
- Failed purchase.
- Restore successful purchase.
- Restore with no previous purchase.
- Product unavailable / StoreKit configuration unavailable.
- Offline launch after prior verified premium purchase.
- Release build does not expose debug premium toggle.

### Regression tests

Before Phase 7 is marked verified:

- Existing calculation tests must pass.
- Existing savings tests must pass.
- Existing migration tests must pass.
- Build must pass.
- No free core flow should require premium.

## 16. Step-By-Step Phase 7 Implementation Sequence

1. Re-audit every current premium gate with `rg` before editing.
2. Define a canonical premium feature matrix in code or tests.
3. Add a feature-specific access helper to `PremiumManager`, such as `hasAccess(to:)`.
4. Add tests for the matrix before refactoring call sites.
5. Preserve existing `isPremium` and StoreKit behavior while adding the new helper.
6. Refactor `hasInsights` and `hasAdvancedNotifications` to use the canonical helper.
7. Refactor premium wrappers to use feature-specific access instead of raw `isPremium`.
8. Refactor settings premium rows so locked/unlocked behavior is deliberate and consistent.
9. Add or confirm service/action guards for premium-only side effects:
   - applying premium themes
   - exporting data
   - enabling biometric lock
10. Keep one basic savings goal free and gate only multiple/advanced savings behavior.
11. Keep basic recurring entry free and gate only automation/advanced recurring behavior.
12. Improve StoreKit state handling without changing the product ID:
   - product unavailable
   - pending
   - cancelled
   - failed
   - restored
   - no purchase found
13. Replace hardcoded paywall price display with StoreKit product metadata where safe.
14. Add localization-safe strings for changed paywall, restore, and lock states.
15. Run focused premium tests.
16. Run broader regression tests.
17. Run build.
18. Perform manual StoreKit QA before marking verified.

## 17. Build/Test Checkpoints

Checkpoint 1: after adding gate matrix tests.

- Run focused premium tests.
- Confirm tests fail or cover current expected behavior before refactor.

Checkpoint 2: after adding feature-specific helper.

- Run premium tests.
- Run any existing settings/view-model tests.

Checkpoint 3: after refactoring wrappers and settings.

- Run premium tests.
- Smoke test paywall entry points manually.

Checkpoint 4: after StoreKit state cleanup.

- Run premium tests.
- Run manual StoreKit sandbox checks.

Checkpoint 5: before marking Phase 7 complete.

- Run full unit test suite.
- Run app build.
- Confirm release build has no debug premium toggle.

## 18. What To Postpone

Postpone:

- RevenueCat integration.
- Subscription pricing.
- Remote paywall configuration.
- A/B pricing tests.
- Ads.
- Ads-free entitlement.
- Supabase/Auth.
- Cloud entitlement sync.
- Cloud backup/sync.
- Widget implementation details.
- Lock Screen widgets.
- Medium widgets.
- StoreKit product migration.
- Full premium theme redesign.
- Full localization pass beyond touched strings.
- App Store metadata/pricing changes.

## 19. Success Criteria

Phase 7 is successful when:

- There is one clear premium feature matrix.
- Free core value cannot be accidentally gated.
- Premium access checks are feature-specific, not mostly raw `isPremium`.
- Existing premium users keep access.
- Lifetime purchase path remains intact.
- Restore behavior is clear for success, failure, and no-purchase states.
- Premium-only side effects cannot be triggered through an unguarded path.
- Paywall and locked-feature states are consistent.
- Changed premium copy is localization-safe.
- Locked states are accessible.
- Widgets remain documented as premium but are not implemented in Phase 7.
- Supabase/Auth remains untouched.
- CoreData schema remains untouched.
- Build passes.
- Required tests pass.
- Manual StoreKit QA is completed before verified status.

## 20. Recommendation

Status: **Ready for implementation planning, not started.**

Phase 7 is ready to plan, but implementation should be test-first and narrow. The first safe implementation step is to add a canonical gate matrix test around the current product decisions, then introduce a `PremiumManager` feature-access helper while preserving the existing StoreKit lifetime purchase path.
