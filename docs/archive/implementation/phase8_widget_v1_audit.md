# Phase 8 — Widget v1 Audit Report

**Audit date:** 2026-06-18  
**Auditor:** Read-only codebase + build/test verification  
**Scope reference:** `docs/implementation/phase8_widget_v1_scope.md`  
**Tracker reference:** `docs/implementation/implementation_planning_index.md` (Phase 8)

---

## Executive Summary

Phase 8 Widget v1 is **largely implemented and aligned with product scope**. The codebase delivers a single premium-gated `systemSmall` widget (`NetDailyPaceWidget`) that reads a shared App Group snapshot written by the main app from `FinancialSummaryBuilder` output. Legacy balance/spending/savings/lock-screen widgets have been removed from the bundle and deleted from the app target.

**What works well:**
- Widget extension target exists, is embedded in the main app, and builds successfully via `budgetmeter.ios` scheme on simulator.
- Snapshot contract (`WidgetSnapshot` / `WidgetSnapshotStore` / `WidgetSnapshotWriter`) matches the scope doc field list.
- Widget provider reads snapshot only — no CoreData, `CalculationEngine`, or `FinancialSummaryBuilder` in the extension.
- Premium gating via `BudgetMeterCapability.widgets` is defined; locked teaser UI and paywall deep link are wired.
- Deep links `budgetmeter://home/hero` and `budgetmeter://premium/widgets` route through `budgetmeter_iosApp.swift` → `ContentView.swift` → `HomeView` hero scroll.
- Unit tests: `WidgetSnapshotStoreTests` (5/5) and `WidgetSnapshotWriterTests` (5/5) pass.
- v1 localization keys exist in `UI.xcstrings` for all 10 languages.

**Open gaps / risks:**
- **KI-003** remains open: `xcodebuild -scheme BudgetMeterWidgets build` fails (`Scheme BudgetMeterWidgets is not currently configured for the build action`), despite a valid-looking shared scheme file. Main-app-embedded build succeeds.
- **KI-004** partially mitigated on simulator; device/archive signing for the extension may still need verification.
- Stale widget state still shows `displayValue` in the secondary line — scope recommended calm stale copy without implying live accuracy.
- Locked-teaser snapshots still **write full financial values** to App Group storage (UI hides them, but container is readable).
- No deep-link or timeline provider unit tests (`WidgetDeepLinkRoutingTests`, `WidgetTimelineMappingTests` recommended in scope).
- Manual widget QA on simulator/device not evidenced in this audit.
- Legacy widget localization keys (`widget.balance`, `widget.savings`, `widgets.setup.description`) remain in catalog.

**Overall status:** **Implemented with known infra and QA gaps** — suitable for Stage A release QA with widget manual pass and scheme/signing cleanup.

---

## Component-by-Component Audit

| # | Component | Status | Finding |
|---|-----------|--------|---------|
| 1 | **Widget Extension Target** | ✅ Pass | `BudgetMeterWidgets` native target exists in `project.pbxproj`. Bundle ID: `com.janstrade.budgetmeter-ios.BudgetMeterWidgets`. Deployment target: **iOS 26.0**. Embedded via `Embed Foundation Extensions` → `PlugIns/BudgetMeterWidgets.appex`. |
| 1a | UI.xcstrings in extension | ✅ Pass | `budgetmeter.ios/Resources/UI.xcstrings` included in widget target Copy Bundle Resources (`C5W8E0152F2D000100A1F002`). |
| 1b | App Group entitlements | ✅ Pass | Both `budgetmeter.ios/budgetmeter.ios.entitlements` and `BudgetMeterWidgets/BudgetMeterWidgets.entitlements` declare `group.com.budgetmeter.shared`. |
| 2 | **Widget Registration** | ✅ Pass | `BudgetMeterWidgets/BudgetMeterWidgets.swift` registers **only** `NetDailyPaceWidget()`. No legacy or lock-screen widgets. |
| 2a | Legacy widget removal | ✅ Pass | `budgetmeter.ios/Widgets/` deleted (Balance, Spending, Savings, Combined, LockScreen). Git status shows deletions. |
| 3 | **Widget Provider & Timeline** | ✅ Pass (minor gap) | `NetDailyPaceProvider` uses `WidgetSnapshotStore().load()`. Timeline: single entry, `.after(snapshot.staleAfter ?? 1h fallback)`. Handles locked, unlocked, missing, stale, insufficientData. |
| 3a | Stale display policy | ⚠️ Gap | Stale state shows `staleMessage` + `displayValue` secondary line. Scope recommended not pretending live accuracy. |
| 4 | **Snapshot Contract** | ✅ Pass | `WidgetSnapshot` has all scope fields + `displayState`, `missingMessage`, `staleMessage`. `WidgetSnapshotWriter` maps from `FinancialSummary` via `HomeDisplayMapping`. `WidgetConstants` defines App Group ID, storage key, kind, schema v1, stale interval (6h), deep links. |
| 4a | Shared code layout | ✅ Pass | `budgetmeter.ios/WidgetShared/` compiled into extension; app uses `CoreKit/Sources/Widget/` for writer/service. |
| 5 | **Premium Gating** | ✅ Pass (storage gap) | `BudgetMeterCapability.widgets` is `.premium`. `PremiumFeature.widgets` maps correctly. `WidgetsSetupView` uses `hasAccess(to: .widgets)`. Writer uses `isPremium` / purchase refresh. Locked teaser UI shows no financial numbers. |
| 5a | Snapshot redaction | ⚠️ Gap | Non-premium snapshots still encode `netDailyPace`, `displayValue`, etc. in App Group JSON. |
| 6 | **Deep Links** | ✅ Pass | `budgetmeter://home/hero` → `.navigateToHomeHero` → Home tab + `.focusHomeHero` scroll. `budgetmeter://premium/widgets` → `.navigateToPremiumWidgets` → `PremiumPaywallView(feature: .widgets)`. URL scheme registered in `budgetmeter.ios/Info.plist`. |
| 7 | **Build & Test** | ⚠️ Partial | Main scheme build: **SUCCEEDED** (simulator, iPhone 17, iOS 26.5). Embedded appex validated. Widget scheme standalone: **FAILED** (KI-003). Widget snapshot tests: **10/10 passed**. KI-003/KI-004 still open in `docs/qa/known_issues.md`. |
| 8 | **Localization** | ✅ Pass | v1 keys present with 10 languages: `widget.brand`, `widget.pace.title/description`, `widget.locked.*`, `widget.missing.message`, `widget.stale.message`, `widgets.setup.*.v1`. Widget views use `String(localized:table: "UI")`. Writer uses `.localized()` for teaser/missing/stale strings. |
| 9 | **WidgetsSetupView** | ✅ Pass | Updated to v1 copy only (net daily pace, single widget, lock hint for free users). |

---

## 1. Widget Extension Target

### Configuration (from `project.pbxproj`)

| Setting | Value |
|---------|-------|
| Target name | `BudgetMeterWidgets` |
| Product type | `com.apple.product-type.app-extension` |
| Bundle identifier | `com.janstrade.budgetmeter-ios.BudgetMeterWidgets` |
| Deployment target | iOS **26.0** |
| Entitlements | `BudgetMeterWidgets/BudgetMeterWidgets.entitlements` |
| Info.plist | `BudgetMeterWidgets/Info.plist` |
| Extension point | `com.apple.widgetkit-extension` |

### Embedding

The main app target `budgetmeter.ios` includes:
- `PBXTargetDependency` on `BudgetMeterWidgets`
- `Embed Foundation Extensions` build phase copying `BudgetMeterWidgets.appex` into `budgetmeter.ios.app/PlugIns/`

Simulator build output confirmed:
```
ValidateEmbeddedBinary .../budgetmeter.ios.app/PlugIns/BudgetMeterWidgets.appex
** BUILD SUCCEEDED **
```

### UI.xcstrings

Explicit `PBXBuildFile` entry copies `budgetmeter.ios/Resources/UI.xcstrings` into the widget extension Resources build phase. Widget `String(localized:..., table: "UI")` calls can resolve catalog strings at runtime when the extension bundle includes the catalog.

### App Group

| Target | Entitlement file | App Group |
|--------|------------------|-----------|
| Main app | `budgetmeter.ios/budgetmeter.ios.entitlements` | `group.com.budgetmeter.shared` |
| Widget | `BudgetMeterWidgets/BudgetMeterWidgets.entitlements` | `group.com.budgetmeter.shared` |

`PersistenceService` also references `group.com.budgetmeter.shared` for SQLite container path.

### WidgetShared target membership

`budgetmeter.ios/WidgetShared` is a synchronized root group linked to the **widget target** explicitly. The same files live under the `budgetmeter.ios/` folder tree and are also compiled into the main app target via the parent folder sync (required for `WidgetSnapshotWriter` / tests).

---

## 2. Widget Registration

**File:** `BudgetMeterWidgets/BudgetMeterWidgets.swift`

```swift
@main
struct BudgetMeterWidgets: WidgetBundle {
    var body: some Widget {
        NetDailyPaceWidget()
    }
}
```

**Verdict:** ✅ Exactly one v1 widget. No legacy or lock-screen registrations.

**Removed (confirmed deleted):**
- `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift` (old multi-widget bundle)
- `CombinedBalanceSavingsWidget.swift`
- `LockScreenWidgets.swift`

---

## 3. Widget Provider & Timeline

**File:** `BudgetMeterWidgets/NetDailyPaceWidget.swift`

### Data fetching

- Provider instantiates `WidgetSnapshotStore()` (App Group `UserDefaults`, key `widgetSummarySnapshot`).
- **No** imports of CoreData, `PersistenceService`, `CalculationEngine`, or `FinancialSummaryBuilder`.

### Display states

| State | Trigger | UI behavior |
|-------|---------|-------------|
| `missing` | `store.load()` returns nil | Brand title + missing message; deep link to home hero |
| `lockedTeaser` | `snapshot.isLockedTeaser` / `displayState == .lockedTeaser` | Crown/lock icon, teaser title/subtitle, upgrade CTA; deep link to paywall |
| `insufficientData` | Writer sets when no financial input | Status copy only |
| `unlocked` | Premium + has input | Value + status copy |
| `stale` | `Date() > snapshot.staleAfter` on unlocked snapshot | Stale message + **still shows displayValue** |

### Timeline refresh

```swift
let nextUpdate = snapshot?.staleAfter
    ?? currentDate.addingTimeInterval(WidgetConstants.fallbackRefreshInterval) // 1 hour
let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
```

Matches scope: `staleAfter`-driven refresh with 1h fallback.

### App-initiated refresh

`WidgetSnapshotWriter.persistAndReload` calls:
```swift
WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.netDailyPaceWidgetKind)
```

**Call sites:**
- `HomeViewModel.publishWidgetSnapshot` (on every summary refresh)
- `WidgetSnapshotService.refreshFromCurrentData` (Income, Expense, Settings, premium purchase)

---

## 4. Snapshot Contract

### WidgetSnapshot fields (actual vs scope)

| Field | Present | Notes |
|-------|---------|-------|
| `schemaVersion` | ✅ | `WidgetConstants.schemaVersion = 1` |
| `netDailyPace` | ✅ | From `summary.netPacePerDay` |
| `paceStatus` | ✅ | String raw value of `PaceStatus` |
| `displayValue` | ✅ | `HomeDisplayMapping.signedDailyAmount` |
| `displayStatusCopy` | ✅ | `HomeDisplayMapping.paceStatusCopy` |
| `currencyCode` / `currencySymbol` | ✅ | |
| `isPremium` | ✅ | From writer argument |
| `generatedAt` / `staleAfter` | ✅ | `staleAfter = generatedAt + 6h` |
| `isLockedTeaser` | ✅ | `!isPremium` |
| `lockedTeaserTitle` / `lockedTeaserSubtitle` | ✅ | Localized at write time |
| `deepLinkURL` | ✅ | Locked → paywall; unlocked → hero |
| `hasFinancialInput` | ✅ | `HomeDisplayMapping.hasFinancialInput` |
| `displayState` | ✅ | Extra field — explicit state for provider |
| `missingMessage` / `staleMessage` | ✅ | Extra fields — localized at write time |

### WidgetSnapshotWriter mapping

**File:** `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift`

- Maps `FinancialSummary` → `WidgetSnapshot` using `HomeDisplayMapping` (same contract as Home hero).
- Sets `displayState`: `.lockedTeaser` if non-premium; `.insufficientData` if no input; else `.unlocked`.
- Does **not** introduce alternate formulas.

### WidgetConstants deep links

| Constant | URL |
|----------|-----|
| `unlockedDeepLink` | `budgetmeter://home/hero` |
| `lockedDeepLink` | `budgetmeter://premium/widgets` |
| `netDailyPaceWidgetKind` | `NetDailyPaceWidget` |
| `appGroupID` | `group.com.budgetmeter.shared` |
| `snapshotStorageKey` | `widgetSummarySnapshot` |

### Storage

`WidgetSnapshotStore` uses JSON encode/decode in App Group `UserDefaults`. Schema mismatch returns `nil` (safe failure). `clear()` supported for tests.

---

## 5. Premium Gating

### Capability matrix

**File:** `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`

- `BudgetMeterCapability.widgets` → `accessLevel: .premium`
- `PremiumFeature.widgets` → capability `.widgets`
- Covered by `PremiumGateMatrixTests` (widgets in premium capability list)

### Locked teaser behavior

| Layer | Behavior |
|-------|----------|
| Writer | `isLockedTeaser = !isPremium`; `deepLinkURL = lockedDeepLink` |
| Provider | Locked branch shows teaser strings only — no `displayValue` |
| Widget view | Crown + lock icons; no financial numbers |
| Tap | `widgetURL` → `budgetmeter://premium/widgets` |
| ContentView | Presents `PremiumPaywallView(feature: .widgets)` sheet |

### Premium refresh on purchase

`PremiumManager` calls `WidgetSnapshotService.refreshFromCurrentData(isPremium: true)` after successful purchase update.

### Note on gate API usage

Snapshot writing uses `PremiumManager.shared.isPremium` directly rather than `hasAccess(to: .widgets)`. For Phase 8 these are equivalent (widgets is premium-only, not postponed). `WidgetsSetupView` correctly uses `hasAccess(to: PremiumFeature.widgets)`.

---

## 6. Deep Links

### URL handling chain

```
Widget tap (widgetURL)
  → budgetmeter_iosApp.handleDeepLink(_:)
    → NotificationCenter post
      → ContentView.onReceive
        → Tab switch / sheet / hero focus
```

### Route verification

| URL | Handler | Destination | Status |
|-----|---------|-------------|--------|
| `budgetmeter://home/hero` | `path == "hero"` → `.navigateToHomeHero` | Home tab + `.focusHomeHero` → `HomeView` scrolls to `home-hero` | ✅ |
| `budgetmeter://home` | `.navigateToHome` | Home tab | ✅ |
| `budgetmeter://premium/widgets` | `host == "premium"`, `path == "widgets"` → `.navigateToPremiumWidgets` | `PremiumPaywallView(feature: .widgets)` sheet | ✅ |
| `budgetmeter://expenses` | `.navigateToExpenses` | Expenses tab | ✅ (legacy, not used by v1 widget) |
| `budgetmeter://income` | `.navigateToIncome` | Income tab | ✅ (legacy) |

**Files:**
- `budgetmeter.ios/budgetmeter_iosApp.swift` — URL parsing
- `budgetmeter.ios/ContentView.swift` — notification observers + paywall sheet
- `budgetmeter.ios/Features/HomeFeature/View/HomeView.swift` — `ScrollViewReader` hero scroll on `.focusHomeHero`
- `budgetmeter.ios/CoreKit/Sources/Utilities/DeepLinkNotifications.swift` — notification names

### URL scheme registration

`budgetmeter.ios/Info.plist` declares `CFBundleURLSchemes: budgetmeter`.

---

## 7. Build & Test Status

### Commands run (2026-06-18)

| Command | Result |
|---------|--------|
| `xcodebuild -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` | ✅ **BUILD SUCCEEDED** |
| `xcodebuild -scheme BudgetMeterWidgets -destination '...' build` | ❌ **FAILED** — "Scheme BudgetMeterWidgets is not currently configured for the build action" |
| `xcodebuild -target BudgetMeterWidgets -sdk iphonesimulator build` | ❌ **FAILED** — codesign "resource fork, Finder information, or similar detritus not allowed" (local `build/` folder artifact issue) |
| `-only-testing:WidgetSnapshotStoreTests -only-testing:WidgetSnapshotWriterTests test` | ✅ **10/10 passed** |

### Known issues (from `docs/qa/known_issues.md`)

| ID | Severity | Description | Audit finding |
|----|----------|-------------|---------------|
| **KI-003** | Major | `BudgetMeterWidgets` scheme not configured for build action | **Still open.** `xcshareddata/xcschemes/BudgetMeterWidgets.xcscheme` appears correctly configured with BuildActionEntries, but `xcodebuild -list` shows duplicate `BudgetMeterWidgets` schemes and a scheme load-error warning. CLI standalone build fails. |
| **KI-004** | Major | Widget extension provisioning profile failure | **Partially mitigated.** Embedded simulator build succeeds with "Sign to Run Locally." Device `-target` build attempted signing with development identity; separate codesign failure on local `build/` output. Archive/device QA still needed. |

### Test coverage

| Test file | Tests | Status | Coverage |
|-----------|-------|--------|----------|
| `WidgetSnapshotStoreTests` | 5 | ✅ Pass | Round-trip, missing, schema mismatch, clear, stale detection |
| `WidgetSnapshotWriterTests` | 5 | ✅ Pass | Pace mapping, HomeDisplayMapping copy, locked teaser, insufficient data, staleAfter |
| `WidgetTimelineMappingTests` | — | ❌ Not present | Scope recommended |
| `WidgetDeepLinkRoutingTests` | — | ❌ Not present | Scope recommended |
| `PremiumGateMatrixTests` | includes `.widgets` | ✅ (in full suite) | Capability gate only |

---

## 8. Localization

### v1 widget keys in `UI.xcstrings`

All 8 primary v1 keys verified with **10 languages** (en, ar, de, es, fr, it, ja, pt, tr, zh-Hans):

- `widget.brand`
- `widget.pace.title`
- `widget.pace.description`
- `widget.locked.title`
- `widget.locked.subtitle`
- `widget.locked.cta`
- `widget.missing.message`
- `widget.stale.message`

Setup v1 keys also present: `widgets.setup.description.v1`, `widgets.setup.available.v1`, step copy updated in `WidgetsSetupView`.

### Runtime resolution

- **Extension:** Loads `UI.xcstrings` from extension bundle; `NetDailyPaceWidget` uses `table: "UI"`.
- **App writer:** Uses `"widget.*".localized(defaultValue:)` for strings embedded in snapshot JSON at write time (widget renders preformatted strings for unlocked/stale/insufficient; extension resolves its own copy for missing/locked CTA).

### Legacy keys (not removed)

Still in catalog: `widget.balance`, `widget.savings`, `widget.today`, `widgets.setup.description` (mentions Lock Screen). Low risk — not referenced by v1 code paths.

### Duplicate catalog note

`widget.locked.subtitle` also appears in `Localizable.xcstrings` — potential duplicate resource warning (related to KI-001).

---

## 9. Gap Analysis vs Scope

### Planned vs implemented

| Scope requirement | Implemented? | Notes |
|-------------------|--------------|-------|
| Exactly one widget kind | ✅ | `NetDailyPaceWidget` only |
| `systemSmall` only | ✅ | `.supportedFamilies([.systemSmall])` |
| Net daily pace status + value | ✅ | Matches Home hero contract |
| Shared snapshot from `FinancialSummaryBuilder` | ✅ | Via `WidgetSnapshotWriter` |
| No CoreData in extension | ✅ | Verified — no forbidden imports |
| Premium unlocked / free locked teaser | ✅ | UI correct |
| Deep link to Home hero | ✅ | Full chain wired |
| Deep link to paywall for locked | ✅ | Sheet paywall |
| Missing snapshot calm state | ✅ | "Open BudgetMeter to refresh" |
| Stale snapshot calm state | ⚠️ Partial | Shows stale message but also last `displayValue` |
| Remove legacy widgets from gallery | ✅ | Bundle + file deletion |
| App Group shared storage | ✅ | Entitlements + store |
| `WidgetsSetupView` v1 copy | ✅ | Updated |
| Widget extension target + embed | ✅ | Builds via main scheme |
| Snapshot unit tests | ✅ | 10 tests |
| Timeline/deep-link unit tests | ❌ | Not added |
| Manual widget QA | ❓ | Not verified in this audit |

### Security & privacy assessment

| Topic | Risk level | Detail |
|-------|------------|--------|
| **Financial data in App Group** | Medium | Snapshot JSON in shared `UserDefaults` contains `netDailyPace`, `displayValue`, etc. even for non-premium users (`isLockedTeaser: true`). UI hides values, but container is readable on jailbroken/debug devices. Scope intended no real values for free users — storage layer does not redact. |
| **Premium flag staleness** | Low | Widget reads `isPremium` from last snapshot. Downgrade before app refresh could briefly show unlocked widget until rewrite. |
| **No network exposure** | ✅ Low risk | Widget is fully offline; no Supabase/cloud in extension. |
| **No CoreData in extension** | ✅ Low risk | Avoids duplicate fetch logic and full DB exposure in widget process. |
| **Deep link paywall** | ✅ Low risk | Locked tap opens in-app paywall; no external URL. |
| **Accessibility** | Low | `accessibilityLabel` set per state; color + icon + text for status. No automated a11y tests. |

**Recommendation:** For stricter privacy alignment, redact financial fields in locked-teaser snapshots (write placeholder strings only).

---

## Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| Widget scheme CLI build broken (KI-003) | Major | High for CI | Fix duplicate/corrupt scheme; verify `xcodebuild -scheme BudgetMeterWidgets build` |
| Device signing / archive (KI-004) | Major | Medium | Device archive test before App Store |
| Stale state shows old financial value | Minor | Medium | Remove `displayValue` from stale secondary line per scope |
| Locked snapshot stores real values | Medium | Low–Medium | Redact fields at write time for non-premium |
| No manual widget QA | Major | High | Run scope Section 19 manual QA on simulator + device |
| No deep-link unit tests | Minor | Medium | Add routing tests or UI tests |
| Legacy l10n keys / WIDGET_GUIDE drift | Minor | Low | Cleanup in post-v1 pass |
| Deployment target iOS 26.0 | Info | — | Narrower than app minimum in some project settings (18.5 at project level); confirm intentional |

---

## Test Coverage Analysis

### Covered (automated)

- Snapshot encode/decode round-trip
- Schema version mismatch → nil load
- Stale detection via `staleAfter`
- Writer maps pace/status from `FinancialSummary`
- Writer uses `HomeDisplayMapping` for display copy
- Locked teaser for non-premium (`isLockedTeaser`, `displayState`, deep link)
- Insufficient data when no financial input
- `staleAfter` computed from `generatedAt + 6h`
- Premium capability `.widgets` in gate matrix tests

### Not covered (automated)

- Timeline provider state mapping (locked/stale/missing branches)
- Deep link URL → notification → tab/scroll/paywall routing
- Widget extension compile-time isolation (beyond manual grep)
- Localization layout truncation (DE/FR/AR small widget)
- Premium purchase → widget unlock integration
- App Group container read/write across processes (integration)
- `WidgetCenter.reloadTimelines(ofKind:)` invocation side effects

### Recommended next tests

1. `WidgetTimelineMappingTests` — provider `makeEntry` for each `WidgetDisplayState`
2. `WidgetDeepLinkRoutingTests` — parse URLs and assert notification names / routes
3. Integration test: write snapshot in app process, read in test using App Group suite
4. UI test: tap widget deep link lands on hero (requires widget test host)

---

## Audit Conclusion

Phase 8 Widget v1 implementation is **functionally complete** against the product contract: one `systemSmall` net daily pace widget, shared snapshot architecture, premium gating, deep links, localization, and legacy widget removal. The main app builds and embeds the extension successfully on simulator; snapshot unit tests pass.

**Blockers before marking Phase 8 fully verified:**
1. Resolve KI-003 (standalone widget scheme build)
2. Confirm KI-004 on device/archive build
3. Complete manual widget QA checklist (scope Section 19)
4. Decide on stale-state and locked-snapshot redaction policy

**Tracker alignment:** `implementation_planning_index.md` lists Phase 8 as "Implemented and Verified (2026-06-17)." This audit finds **implementation complete** but **verification partially incomplete** due to open KI-003/KI-004 and missing manual QA evidence.

---

## Appendix: Key File Index

| Path | Role |
|------|------|
| `BudgetMeterWidgets/BudgetMeterWidgets.swift` | Widget bundle entry |
| `BudgetMeterWidgets/NetDailyPaceWidget.swift` | v1 widget UI + provider |
| `BudgetMeterWidgets/BudgetMeterWidgets.entitlements` | Extension App Group |
| `budgetmeter.ios/WidgetShared/WidgetSnapshot.swift` | Shared codable model |
| `budgetmeter.ios/WidgetShared/WidgetSnapshotStore.swift` | App Group read/write |
| `budgetmeter.ios/WidgetShared/WidgetConstants.swift` | Shared constants + deep links |
| `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift` | Summary → snapshot |
| `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotService.swift` | Refresh orchestration |
| `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift` | Primary snapshot publish |
| `budgetmeter.ios/ContentView.swift` | Deep link routing |
| `budgetmeter.ios/budgetmeter_iosApp.swift` | URL scheme handler |
| `budgetmeter.iosTests/WidgetSnapshotStoreTests.swift` | Store tests (5) |
| `budgetmeter.iosTests/WidgetSnapshotWriterTests.swift` | Writer tests (5) |
| `docs/qa/known_issues.md` | KI-003, KI-004 |
