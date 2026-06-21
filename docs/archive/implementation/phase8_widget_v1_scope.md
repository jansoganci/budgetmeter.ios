# Phase 8 — Widget v1 Scope

## 1. Executive Summary

Phase 8 delivers the fixed v1 widget: a premium-gated Home Screen `systemSmall` widget that shows net daily pace status and value, deep links to the Home hero, and shows a locked teaser for non-premium users.

The product contract is already clear. The implementation risk is not product ambiguity — it is engineering surface area. Widget work touches Xcode target setup, entitlements, App Group storage, timeline refresh, premium state sharing, stale-data handling, deep-link routing, and removal of legacy widget code that currently violates v1 scope.

Phase 8 is not a widget redesign, lock-screen launch, medium/large expansion, chart widget pass, Supabase-backed widget state, or StoreKit product change. It is a safety/alignment phase that makes one widget read the same `FinancialSummary`-derived snapshot as Home without introducing a second financial reality.

Recommendation: **Ready for implementation planning after this document upgrade; not ready to start coding from the previous thin scope doc.**

First safe implementation step: verify widget extension target/App Group entitlement status, define the shared widget snapshot contract, and remove or disable all out-of-scope widgets from the widget bundle before writing v1 UI.

## 2. Current Codebase Context

Relevant current pieces:

- Phase 1 defined `FinancialSummary` / `FinancialSummaryInput` and `PaceStatus`.
- Phase 3 made Home a `FinancialSummaryBuilder` consumer through `HomeViewModel`.
- `HomeDisplayMapping.paceStatusCopy(status:netDailyPace:currencySymbol:)` already formats the v1 widget copy contract.
- `MomentumHeroCard` on Home already displays `paceStatus`, `paceStatusCopy`, and `netDailyPace`.
- Phase 7 centralized premium gates and documented widgets as premium, but did not implement widget behavior.
- Widget Swift source files exist under `budgetmeter.ios/Widgets/`.
- `WidgetsSetupView` exists under `budgetmeter.ios/Features/WidgetsFeature/View/`.
- `WIDGET_GUIDE.md` exists but is outdated and describes the pre-v1 multi-widget plan.
- `WidgetCenter.shared.reloadAllTimelines()` is already called from Home, Income, Expense, and Settings flows.

Important distinction:

- The app should own financial truth through `FinancialSummaryBuilder`.
- The widget should only read a serialized snapshot written by the app.
- The widget must not fetch CoreData, call `CalculationEngine`, or rebuild financial totals independently.

## 3. Current Widget Inventory

### Source files

| File | Purpose | v1 status |
|------|---------|-----------|
| `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift` | `@main` widget bundle, Balance/Spending/Savings widgets | Out of v1 scope except as refactor base |
| `budgetmeter.ios/Widgets/CombinedBalanceSavingsWidget.swift` | Combined balance + savings `systemSmall` widget | Out of v1 scope |
| `budgetmeter.ios/Widgets/LockScreenWidgets.swift` | Circular/rectangular/inline lock-screen widgets | Out of v1 scope |
| `budgetmeter.ios/Features/WidgetsFeature/View/WidgetsSetupView.swift` | Settings/setup instructions screen | Must be updated in Phase 8 to describe v1 widget only |

### Existing widget types and families

| Widget kind | Supported families | Metric shown | Deep link |
|-------------|-------------------|--------------|-----------|
| `BalanceWidget` | `systemSmall`, `systemMedium` | Raw income minus expense category totals | `budgetmeter://home` |
| `SpendingWidget` | `systemMedium`, `systemLarge` | Monthly expense category totals + top categories | `budgetmeter://expenses` |
| `SavingsWidget` | `systemSmall`, `systemMedium` | Savings progress from `AppSettings.savingsGoalAmount` and income-expense delta | `budgetmeter://home` |
| `CombinedBalanceSavingsWidget` | `systemSmall` | Monthly recurring balance + savings progress | `budgetmeter://home` |
| `LockScreenBalanceCircular` | `accessoryCircular` | Compact balance | `budgetmeter://home` |
| `LockScreenBalanceRectangular` | `accessoryRectangular` | Balance + daily-only net | `budgetmeter://home` |
| `LockScreenBalanceInline` | `accessoryInline` | Compact balance | `budgetmeter://home` |

Current bundle registration in `BudgetMeterWidgets`:

- Home Screen: `BalanceWidget`, `SpendingWidget`, `SavingsWidget`, `CombinedBalanceSavingsWidget`
- Lock Screen: `LockScreenBalanceCircular`, `LockScreenBalanceRectangular`, `LockScreenBalanceInline`

### Xcode target / project status

Verified current project state:

- `xcodebuild -list` and `project.pbxproj` show only:
  - `budgetmeter.ios`
  - `budgetmeter.iosTests`
- There is **no widget extension target**.
- Widget Swift files are explicitly excluded from the app target through `PBXFileSystemSynchronizedBuildFileExceptionSet` membership exceptions.
- No `.entitlements` file was found in the repo during Phase 0 and this audit.
- `WIDGET_GUIDE.md` still describes manual creation of a `BudgetMeterWidgets` extension target as unfinished work.

Conclusion: widgets are code-present and planned, but not functional as a shipped extension.

### Explicitly out of v1 scope and must be disabled/removed from the v1 bundle

Disable or remove from the widget bundle before shipping v1:

- `BalanceWidget`
- `SpendingWidget`
- `SavingsWidget`
- `CombinedBalanceSavingsWidget`
- `LockScreenBalanceCircular`
- `LockScreenBalanceRectangular`
- `LockScreenBalanceInline`
- All `systemMedium` and `systemLarge` families
- All lock-screen accessory families
- All balance/spending/savings/combined widget UIs
- All chart/category-breakdown widget UIs

Keep only as refactor reference until v1 widget is implemented:

- Timeline provider structure
- `widgetURL` pattern
- Localization key usage pattern
- Preview structure

## 4. Current Widget Problems / Risks

### Data-source risks

- Every existing provider reads CoreData directly through `PersistenceService.shared.viewContext`.
- `BalanceWidget` and `SavingsWidget` sum raw `FinancialCategory.amount` values without frequency normalization.
- `SpendingWidget` sums expense categories without recurring/one-time distinction.
- `CombinedBalanceSavingsWidget` and lock-screen providers call `CalculationEngine`, but only from `FinancialCategory` rows.
- None of the current widgets use `FinancialSummaryBuilder`, subscriptions, bills, recurring transactions, or Phase 6 savings source-of-truth rules.
- Widget values can disagree with Home even if the extension compiled.

### Target / entitlement risks

- No widget extension target means current widget code cannot ship.
- No checked-in entitlements file means App Group capability is unverified.
- `PersistenceService` attempts to place SQLite in `group.com.budgetmeter.shared`, but entitlement presence must be confirmed in Xcode before relying on shared storage.
- Adding a widget extension incorrectly could create duplicate `@main` entry points or duplicate CoreData model linkage.

### Premium boundary risks

- Existing widgets read `AppSettings.isPremiumUser` directly and only show a crown icon.
- There is no locked teaser state for non-premium users.
- `PremiumFeature.widgets` description still says "Home and Lock Screen", which exceeds v1 scope.
- Widget premium state must be shared safely without making Home premium.

### Refresh / staleness risks

- Existing refresh intervals are arbitrary per widget: 1 hour, 6 hours, 12 hours.
- App already calls `WidgetCenter.shared.reloadAllTimelines()` after data changes, but with no working extension this is effectively a no-op.
- Widget timeline refresh must not assume app memory or live session timer state.
- Missing snapshot data must not look like a zero-dollar financial state.

### Deep-link risks

- Existing widgets mostly deep link to `budgetmeter://home` or `budgetmeter://expenses`.
- `budgetmeter_iosApp.swift` posts `NavigateToHome`, `NavigateToExpenses`, and `NavigateToIncome` notifications.
- `ContentView.swift` does **not** observe those notifications, so tab routing from widgets is currently incomplete.
- No `budgetmeter://premium` or paywall route exists for locked teaser taps.
- v1 requires deep link to Home hero, not just Home tab selection.

### Setup / documentation drift risks

- `WidgetsSetupView` advertises Balance, Spending, Savings, and Combined widgets.
- `WIDGET_GUIDE.md` documents 7 widgets and lock-screen support.
- `UI.xcstrings` contains legacy widget keys like `widget.balance`, `widget.savings`, and `widgets.setup.available`.
- These docs/UI surfaces will mislead QA and users unless updated during Phase 8.

## 5. Product Decisions Phase 8 Must Respect

From `docs/product_decisions_v1.md`, `docs/active/widgets_plan.md`, and `docs/implementation/widgets_plan.md`:

- Widgets are premium.
- v1 scope is Home Screen `systemSmall` only.
- v1 metric is net daily pace status + value.
- v1 deep link target is Home hero section.
- Non-premium users see locked teaser state.
- Home remains free and is the source of truth inside the app.
- Widget data must use the same Home summary/calculation model.
- Day is the default pace unit for v1 display.
- No lock screen widgets in v1.
- No medium widgets in v1.
- No large widgets in v1.
- No charts in v1.
- No complex Pulsey state in v1.
- Pulsey may appear only as a tiny static brand mark if trivial.
- Widget must not introduce separate calculations or simplified formulas.
- Supabase-backed widget state is later scope.
- StoreKit product setup is unchanged in Phase 8.

## 6. Required v1 Behavior

Phase 8 must deliver:

- Exactly one widget kind in the widget gallery for v1.
- Exactly one supported family: `systemSmall`.
- Premium users see live net daily pace status + value from the shared snapshot.
- Non-premium users see a locked teaser state, not live financial values.
- Locked teaser tap opens premium upgrade/paywall path.
- Unlocked widget tap deep links to Home hero.
- Widget reads only the shared snapshot; no CoreData fetches in the widget extension.
- Widget does not call `CalculationEngine` or `FinancialSummaryBuilder`.
- Widget value matches Home `netDailyPace` and `paceStatus` for the same app state.
- Missing snapshot shows a calm setup/open-app state.
- Stale snapshot shows a calm stale state, not misleading live values.
- Snapshot includes generation timestamp and stale threshold.
- Widget refresh responds to app data changes through snapshot rewrite + timeline reload.
- `WidgetsSetupView` describes only the v1 widget.
- Existing out-of-scope widgets are removed from the bundle or otherwise unavailable in the widget gallery.

## 7. Data Source Contract

### Writer side (app target)

The app owns snapshot creation.

Recommended flow:

1. `HomeViewModel` or a dedicated `WidgetSnapshotWriter` builds or receives a `FinancialSummary` from `FinancialSummaryBuilder`.
2. App maps summary values into a small `WidgetSnapshot` codable model.
3. App writes JSON to App Group `UserDefaults` or a small App Group file.
4. App calls `WidgetCenter.shared.reloadTimelines(ofKind:)` for the v1 widget kind.

Writer triggers:

- Home refresh / initial load
- Income changes
- Expense changes
- Savings goal changes
- Currency/settings changes
- Premium purchase/restore changes
- Cumulative meter reset

Writer must not:

- Write widget-specific alternate formulas
- Write balance/spending/savings widget fields in v1
- Depend on live session timer values for the widget snapshot

### Reader side (widget extension)

The widget extension owns display only.

Recommended flow:

1. Timeline provider reads `WidgetSnapshot` from App Group storage.
2. Provider maps snapshot into a timeline entry.
3. Entry view renders status/value or locked/stale/missing states.
4. Provider schedules next reload using snapshot `staleAfter` or a conservative fallback interval.

Reader must not:

- Import CoreData
- Link `BudgetMeter.xcdatamodeld`
- Instantiate `PersistenceService`
- Call `CalculationEngine`
- Rebuild `FinancialSummary`

### Single source of truth rule

- `FinancialSummaryBuilder` remains the only financial truth builder.
- `WidgetSnapshot` is a display cache, not a second financial model.
- If app and widget disagree, the bug is in snapshot writing, not widget math.

## 8. Recommended Widget Snapshot Fields

Recommended `WidgetSnapshot` codable contract:

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `schemaVersion` | `Int` | Yes | Allows safe future snapshot evolution |
| `netDailyPace` | `Double` | Yes | Raw net recurring pace per day |
| `paceStatus` | `String` | Yes | One of `movingForward`, `slowingDown`, `neutral`, `insufficientData` |
| `displayValue` | `String` | Yes | Preformatted pace value, e.g. `+$12/day` |
| `displayStatusCopy` | `String` | Yes | Preformatted status line from `HomeDisplayMapping` |
| `currencyCode` | `String` | Yes | ISO currency code |
| `currencySymbol` | `String` | Yes | Display symbol |
| `isPremium` | `Bool` | Yes | Whether widget should render unlocked content |
| `generatedAt` | `Date` | Yes | Snapshot write time |
| `staleAfter` | `Date` | Yes | Time after which widget should show stale state |
| `isLockedTeaser` | `Bool` | Yes | Explicit locked state for non-premium users |
| `lockedTeaserTitle` | `String` | No | Short teaser title |
| `lockedTeaserSubtitle` | `String` | No | Short teaser subtitle |
| `deepLinkURL` | `String` | No | Default `budgetmeter://home` for unlocked, paywall route for locked |
| `hasFinancialInput` | `Bool` | Yes | Mirrors `HomeDisplayMapping.hasFinancialInput(in:)` |

Recommended formatting rule:

- `displayStatusCopy` should be produced in the app using `HomeDisplayMapping.paceStatusCopy(...)`.
- Widget should render prepared strings, not re-derive copy logic.

Recommended staleness rule:

- `staleAfter = generatedAt + 6 hours` for v1 unless manual QA proves a tighter window is needed.
- If snapshot is missing, treat as "open app to refresh" state.
- If `hasFinancialInput == false`, show insufficient-data copy, not zero-dollar success/failure.

## 9. Premium / Free Boundary

Free in Phase 8:

- Full Home dashboard in app.
- All core pace loop functionality in app.
- Ability to see widget marketing/setup copy.
- Locked widget teaser only; no live widget values.

Premium in Phase 8:

- Unlocked `systemSmall` widget with live net pace status/value.
- Widget deep link to Home hero.

Explicit non-goals:

- Do not gate Home hero content.
- Do not gate net pace inside the app.
- Do not add lock-screen/medium/large widgets as premium extras in this phase.
- Do not change StoreKit product or pricing.

Locked teaser behavior:

- Show app name or widget title.
- Show short "Premium widget" or equivalent localized copy.
- Show lock icon and upgrade CTA text.
- Do not show real financial values.
- Tap should route to paywall/premium flow, not fake numbers.

## 10. App Group / Shared Storage Requirements

### Current state

- `PersistenceService` already attempts to use App Group identifier `group.com.budgetmeter.shared` for the SQLite store path.
- No `.entitlements` file is checked into the repo.
- `WIDGET_GUIDE.md` expects App Groups on both app and widget targets.

### Phase 8 requirements

Before widget implementation is considered safe:

1. Confirm App Group capability exists on the app target in Xcode.
2. Create widget extension target.
3. Add the same App Group capability to the widget target.
4. Verify both targets use exactly `group.com.budgetmeter.shared`.
5. Verify container read/write from app and extension builds.

### Recommended storage approach for v1

Preferred:

- Small JSON snapshot file or App Group `UserDefaults` key, e.g. `widgetSummarySnapshot`.
- Written by app target.
- Read by widget extension only.

Not preferred for v1:

- Sharing live CoreData SQLite access with the widget extension.
- Linking the full persistence stack into the extension.
- Computing finance from App Group database reads in the widget process.

Reason:

- Phase 0–7 spent effort eliminating multiple financial realities.
- Shared database access reintroduces duplicate fetch logic and entitlement complexity.

### Verification checklist

- App can write snapshot and read it back.
- Widget extension can read snapshot without launching UI.
- Premium flag persists across app restart.
- Missing container gracefully falls back to locked/missing state, not crash.
- Simulator and device both pass container access checks.

## 11. Timeline / Refresh Behavior

### App-initiated refresh

Keep and narrow existing `WidgetCenter` usage:

- Continue reload calls after financial data mutations.
- Replace `reloadAllTimelines()` with reload of the v1 widget kind once legacy widgets are removed.
- Rewrite snapshot before requesting reload.

Current reload call sites to preserve/narrow:

- `HomeViewModel`
- `IncomeViewModel`
- `ExpenseViewModel`
- `SettingsViewModel`

### Widget-initiated refresh

Recommended v1 policy:

- Use `Timeline(entries:policy:)` with `.after(nextRefreshDate)`.
- `nextRefreshDate` should come from `snapshot.staleAfter` when snapshot exists.
- Fallback refresh interval: 1 hour.
- Do not attempt per-second live meter updates on the widget.
- Live session minute pace is Home-only and out of widget v1 scope.

### Stale/missing states

| State | User-facing behavior |
|-------|----------------------|
| Missing snapshot | "Open BudgetMeter to refresh" or equivalent localized copy |
| Stale snapshot | Show last known value only for premium users if product approves; otherwise show stale badge/copy. Default safer v1 choice: stale copy without pretending live accuracy |
| Insufficient data | Use `insufficientData` status copy, matching Home |
| Non-premium | Locked teaser only |

## 12. Deep-Link Behavior

### Required v1 routes

| User action | Required destination |
|-------------|----------------------|
| Premium widget tap | Home tab + scroll/focus Home hero |
| Locked teaser tap | Paywall / premium upgrade flow |
| Missing/stale informational tap | Home tab |

### Current deep-link state

Existing URL scheme handling in `budgetmeter_iosApp.swift`:

- `budgetmeter://home`
- `budgetmeter://expenses`
- `budgetmeter://income`

Current gaps:

- `ContentView` does not handle `NavigateToHome` or other navigation notifications.
- No route for paywall/premium from widget.
- No hero-focus/scroll behavior exists for Home deep links.

### Phase 8 deep-link requirements

Implement during Phase 8:

- Tab selection routing for Home.
- Home hero focus behavior for unlocked widget taps.
- Paywall/premium route for locked teaser taps.
- URL registration verification in app Info.plist / generated build settings.

Recommended URL contract for v1:

- Unlocked widget: `budgetmeter://home#hero` or a dedicated `budgetmeter://home/hero` route.
- Locked teaser: `budgetmeter://premium/widgets` or existing paywall route once Phase 7 premium entry path is canonical.

Do not keep `budgetmeter://expenses` on the v1 widget.

## 13. UI Scope

v1 widget UI must be:

- `systemSmall` only
- Compact net pace/status display
- One primary value line and one status line
- Optional tiny static brand mark only
- Dark-first, high-contrast, readable in light/dark wallpaper contexts
- No charts
- No category lists
- No savings progress bar
- No balance/spending labels
- No medium/lock-screen layouts
- No live minute pace line
- No Pulsey animation/state machine

Recommended visual content for unlocked state:

- App/widget title or icon
- Status copy such as "Moving forward"
- Value copy such as `+$12/day`
- Subtle status icon or color token matching `PaceStatus`

Recommended visual content for locked state:

- Lock icon
- "Premium widget" or equivalent localized title
- Short upgrade CTA
- No financial numbers

## 14. Localization Requirements

Localization must cover:

- Widget display name
- Widget description in widget gallery
- Unlocked status copy
- Unlocked value formatting via app-produced localized strings
- Locked teaser title/subtitle/CTA
- Missing snapshot copy
- Stale snapshot copy
- Insufficient-data copy
- Accessibility labels

Existing resources:

- `UI.xcstrings` already contains some widget/setup keys.
- `HomeDisplayMapping` uses localized insufficient-data copy.
- Legacy widget keys for balance/spending/savings should not be reused for v1 metric copy unless repurposed deliberately.

Requirements:

- All user-visible widget strings must use String Catalog keys.
- Support all 10 app languages.
- Avoid hardcoded English in widget views.
- Keep small-layout copy short for DE/FR/ES/IT/PT/TR/AR/ZH/JA variants.
- Prefer app-side string preparation for complex interpolation.

## 15. Accessibility Requirements

Required behavior:

- VoiceOver label includes status, value, and currency unit for unlocked widget.
- Locked teaser identifies premium lock state and action.
- Stale/missing states are announced clearly.
- Color is not the only indicator of positive/negative/neutral status; text and icon should carry meaning.
- Dynamic Type constraints apply within widget limits; use truncation/minimumScaleFactor carefully.
- Reduce Motion: no required animation for v1 widget.
- Sufficient contrast for status text on widget background.

## 16. Files Likely To Touch in Phase 8 Implementation

Implementation may touch only focused widget/shared-summary/navigation files:

### New files likely needed

- `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshot.swift`
- `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotStore.swift`
- `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift`
- `budgetmeter.ios/Widgets/NetDailyPaceWidget.swift` or equivalent v1 widget file
- `budgetmeter.iosTests/WidgetSnapshotStoreTests.swift`
- `budgetmeter.iosTests/WidgetSnapshotWriterTests.swift`
- Widget extension target generated by Xcode, e.g. `BudgetMeterWidgets/`

### Existing files likely to revise

- `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift` — reduce bundle to v1 widget only
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift` — write snapshot after summary refresh
- `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift` — snapshot refresh trigger
- `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift` — snapshot refresh trigger
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift` — currency/premium/settings refresh trigger
- `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift` — read-only premium state for snapshot writing and widget description copy
- `budgetmeter.ios/Features/WidgetsFeature/View/WidgetsSetupView.swift` — v1 setup copy only
- `budgetmeter.ios/budgetmeter_iosApp.swift` — deep-link routing
- `budgetmeter.ios/ContentView.swift` or `HomeView.swift` — Home hero focus routing
- `budgetmeter.ios/Resources/UI.xcstrings` and/or `Home.xcstrings` — widget strings
- `budgetmeter.ios.xcodeproj/project.pbxproj` — widget extension target and entitlements
- App and widget `.entitlements` files once created

### Existing files to disable/remove from target or bundle

- `budgetmeter.ios/Widgets/CombinedBalanceSavingsWidget.swift`
- `budgetmeter.ios/Widgets/LockScreenWidgets.swift`
- Legacy widget structs inside `BudgetMeterWidgets.swift`

These may remain in repo temporarily as reference but must not ship in v1 widget gallery.

## 17. Files Not Allowed To Touch in Phase 8

Do not touch in Phase 8:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- CoreData schema/model versions
- Supabase/Auth files
- CloudKit setup/removal behavior
- `CalculationEngine.swift` formulas
- `FinancialSummaryBuilder.swift` formulas
- StoreKit product configuration
- RevenueCat/subscription pricing
- Income/Expense flow redesign
- Bills/Subscriptions flow redesign
- Full DesignSystem redesign
- Medium/large/lock-screen widget implementation
- Supabase-backed widget state
- Widget refresh controls/settings UI beyond existing reload behavior

## 18. Required Tests

### Unit tests

Add or update tests for:

- Snapshot encodes/decodes all required fields.
- Snapshot writer maps `FinancialSummary.netPacePerDay` and `paceStatus` correctly.
- Snapshot writer sets `displayStatusCopy` using `HomeDisplayMapping`.
- Snapshot writer sets `isPremium` from app premium state.
- Snapshot writer sets `hasFinancialInput` consistently with Home.
- Missing snapshot returns safe widget placeholder state.
- Stale snapshot is detected using `staleAfter`.
- Locked teaser state is produced for non-premium users.
- Unlocked state is produced for premium users.
- Snapshot schema version mismatch fails safely.

### Widget/provider tests

Cover:

- Provider reads snapshot only; no CoreData dependency in extension target.
- Provider emits one entry for v1 timeline in normal state.
- Provider uses `staleAfter` for next reload date.
- Provider maps `insufficientData` copy safely.

### Integration/deep-link tests

Cover:

- `budgetmeter://home` selects Home tab.
- Home hero focus route is triggered from unlocked widget deep link.
- Locked teaser route opens paywall/premium path.

### Regression tests

Before Phase 8 is marked verified:

- Existing `FinancialSummaryBuilderTests` must pass.
- Existing `HomeViewModelMappingTests` must pass.
- Existing premium gate tests from Phase 7 must pass.
- App build must pass.
- Widget extension build must pass.

Recommended test files:

- `WidgetSnapshotStoreTests.swift`
- `WidgetSnapshotWriterTests.swift`
- `WidgetTimelineMappingTests.swift`
- `WidgetDeepLinkRoutingTests.swift` if routing is testable

## 19. Manual QA Requirements

### Target/setup QA

- Widget extension target exists and is embedded in the app.
- App Group entitlement exists on both targets.
- Widget appears exactly once in widget gallery.
- Only `systemSmall` size is offered.

### Data correctness QA

- Add recurring income and expense; widget matches Home net daily pace.
- Change currency; widget currency and formatted value match Home.
- Add one-time entries; widget recurring pace remains aligned with Home summary rules.
- Complete/pause premium purchase; widget locked/unlocked state changes correctly.
- No financial input; widget shows insufficient-data copy, not `$0/day` misleading state.

### Premium QA

- Non-premium user sees locked teaser only.
- Locked teaser tap opens paywall/premium flow.
- Premium user sees live values.
- Premium user widget values match Home hero card.

### Stale/missing QA

- Fresh install before first app open shows missing/setup state.
- App closed for longer than stale window shows stale state behavior defined by implementation.
- Airplane mode after premium purchase still respects last known premium snapshot state.

### Localization/layout QA

- Verify small widget layout in EN, TR, DE, FR, ES, AR at minimum.
- Long localized status strings truncate safely.
- RTL layout does not clip value text.

### Deep-link QA

- Unlocked widget tap lands on Home hero.
- Locked teaser tap lands on paywall.
- Existing app tabs still work after deep-link routing changes.

## 20. Build / Test Checkpoints

### Checkpoint 0: pre-implementation audit

Manual verification:

```sh
xcodebuild -list -project budgetmeter.ios.xcodeproj
rg "PBXNativeTarget|Widget|group.com.budgetmeter.shared|NavigateToHome" budgetmeter.ios.xcodeproj/project.pbxproj budgetmeter.ios
```

Confirm:

- No widget extension target yet.
- Widget files excluded from app target.
- App Group identifier usage in `PersistenceService`.
- Deep-link notification gap in `ContentView`.

### Checkpoint 1: after snapshot contract tests

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:budgetmeter.iosTests/WidgetSnapshotStoreTests test
```

### Checkpoint 2: after snapshot writer integration

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:budgetmeter.iosTests/WidgetSnapshotWriterTests test
```

### Checkpoint 3: after widget extension target creation

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

If scheme name differs after target creation, document the actual scheme in the Phase 8 implementation notes.

### Checkpoint 4: after v1 widget UI + deep links

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

### Checkpoint 5: before marking Phase 8 complete

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

Then run the manual QA section on simulator and at least one physical device if available.

If current simulator names differ, use:

```sh
xcodebuild -showdestinations -scheme budgetmeter.ios
```

## 21. Step-By-Step Phase 8 Implementation Sequence

1. Re-audit widget target, entitlements, and widget file target membership before editing code.
2. Define `WidgetSnapshot` codable contract and storage key/path in App Group.
3. Add snapshot encode/decode tests.
4. Add `WidgetSnapshotWriter` that maps from `FinancialSummary` and premium state.
5. Add writer tests proving values match `HomeViewModel` mapping.
6. Wire snapshot writing into Home refresh and existing financial mutation call sites.
7. Narrow `WidgetCenter` reload calls to the v1 widget kind.
8. Create widget extension target in Xcode.
9. Add App Group entitlements to app and extension targets; verify container access.
10. Remove/disable all out-of-scope widgets from `BudgetMeterWidgets` bundle.
11. Implement `NetDailyPaceWidget` with `systemSmall` only.
12. Implement unlocked/locked/stale/missing entry views.
13. Implement timeline provider that reads shared snapshot only.
14. Update `WidgetsSetupView` to describe the single v1 widget.
15. Implement Home hero deep-link routing and locked teaser paywall routing.
16. Update widget localization keys and premium feature copy to v1 scope.
17. Run snapshot tests.
18. Run widget extension build.
19. Run app build and full regression tests.
20. Run manual widget QA on simulator/device.
21. Update `implementation_planning_index.md` only after build/tests/manual QA pass.

## 22. What To Postpone

Postpone:

- Lock screen widgets
- Medium widgets
- Large widgets
- Charts and category breakdown widgets
- Balance widget
- Spending widget
- Savings widget
- Combined balance/savings widget
- Biggest-drain widget
- Pulsey widget states and animation
- Live minute pace on widget
- Widget configuration intents
- Multiple widget kinds in gallery
- Supabase-backed widget state
- Cloud entitlement sync for widgets
- Advanced refresh controls
- Remote widget experiments
- Full localization catalog pass beyond widget strings
- Full accessibility audit beyond widget states
- `WIDGET_GUIDE.md` full rewrite unless needed for developer setup notes

## 23. Success Criteria

Phase 8 is complete when:

- Exactly one widget kind ships in v1.
- Only `systemSmall` family is supported.
- Widget reads shared `FinancialSummary`-derived snapshot only.
- Widget does not read CoreData or recompute financial formulas.
- Widget net daily pace matches Home hero values.
- Premium users see unlocked widget content.
- Non-premium users see locked teaser content.
- Locked teaser routes to paywall/premium flow.
- Unlocked widget routes to Home hero.
- Missing/stale states are calm and non-misleading.
- Out-of-scope widgets are not exposed in widget gallery.
- Widget extension target builds and is embedded in the app.
- App Group shared snapshot works on app and extension.
- Required tests pass.
- Manual widget QA passes.
- App build passes.

## 24. Recommendation

Status: **Ready for implementation planning after this document upgrade; implementation should remain test-first and narrow.**

Phase 8 is now documented to the same implementation-readiness level as Phases 6 and 7. The scope is correct, but coding should not begin with UI.

### Remaining risks

1. Widget extension target and entitlements still need to be created and verified in Xcode.
2. App Group container access is assumed in code but not proven by checked-in entitlements.
3. Existing widget code violates v1 scope and must be removed from the bundle early to avoid shipping wrong widgets.
4. Deep-link routing is incomplete because `ContentView` does not observe navigation notifications.
5. `WidgetsSetupView`, `WIDGET_GUIDE.md`, and `PremiumFeature.widgets` copy still describe the old multi-widget plan.
6. Existing widget providers use incorrect financial logic and must not be reused except for scaffolding.
7. Stale-data policy needs a product-safe default during implementation (recommended: calm stale copy rather than pretending live accuracy).

### Whether Phase 8 is ready to implement

**Yes for planning. Not yet for UI-first implementation.**

The phase is ready to start with infrastructure and contract work. It is not ready to start by editing existing widget views in place.

### Recommended first implementation step

Create the `WidgetSnapshot` contract and failing tests, then verify widget extension target + App Group entitlement setup before adding any widget UI.

The first code change should be:

1. Snapshot model + tests
2. Snapshot writer from `FinancialSummary`
3. Xcode target/entitlement audit

Only after those pass should the old widget bundle be stripped down and the v1 `systemSmall` widget added.
