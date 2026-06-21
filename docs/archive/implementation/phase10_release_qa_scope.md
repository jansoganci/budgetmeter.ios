# Phase 10 — Release QA Scope

## 1. Executive Summary

Phase 10 is the release command center for BudgetMeter. It turns every known risk from Phases 0–9 into concrete QA gates, matrices, scripts, and a documented go/no-go decision. QA is staged so core redesign quality can ship or gate independently from auth/sync volatility.

**Stage A** validates the local-first redesign (Home, DesignSystem, calculations, income/expense, savings, premium/free boundary, widgets, localization, accessibility) before Supabase/Auth is in release scope.

**Stage B** validates Apple Sign In, Supabase backup/sync, CloudKit transition, account deletion, and restore safety only after Phase 9 scope is frozen and implemented.

BudgetMeter handles sensitive financial data. Data loss, calculation drift, bad restore, premium entitlement failure, and confusing financial copy are release blockers — not polish items.

Recommendation: **Ready for QA execution planning after this document upgrade; QA execution cannot begin until upstream phase exit gates are met.**

First safe implementation step: run the **Stage A preflight build/test baseline** and create the living QA tracker spreadsheet or markdown checklist from Section 7 before any manual device QA.

## 2. Current Codebase / Release Context

### Implementation status at time of this document (2026-06-17)

| Phase | Status | QA implication |
|-------|--------|----------------|
| Phase 0 — Audit | Completed | Baseline risks documented |
| Phase 1 — Calculation contract | Implemented and verified | 84+ tests; `FinancialSummaryBuilder` is authoritative |
| Phase 2 — Data model safety | Implemented (Steps 1–6) | v3 model, `FinancialDataMigrationService`, 10 migration tests |
| Phase 3 — Home dashboard | Implemented and verified | `HomeViewModel` uses builder only |
| Phase 4 — DesignSystem | Implemented and verified | Dark-first tokens, core cards |
| Phase 5 — Income/expense flows | Implemented and verified | 100 tests; entry kind model |
| Phase 6 — Basic savings | Implemented and verified | 121 tests; shared ETA |
| Phase 7 — Premium cleanup | Implemented and verified | 128 tests; `BudgetMeterCapability` matrix |
| Phase 8 — Widget v1 | Planning ready, not started | No extension target; legacy widgets out of scope |
| Phase 9 — Supabase/Auth | Planning ready, not started | `NSPersistentCloudKitContainer` still active |
| Phase 10 — Release QA | **This document** | Execution blocked on Phases 8–9 if in release scope |

### Current test inventory

| Test file | Focus |
|-----------|-------|
| `CalculationEngineTests.swift` | Formula regression |
| `FinancialSummaryBuilderTests.swift` | Shared summary mapping |
| `FinancialDataMigrationServiceTests.swift` | v2/v3 migration idempotency |
| `HomeViewModelMappingTests.swift` | Home display mapping |
| `IncomeExpenseFlowTests.swift` | Entry kind, rollup |
| `BasicSavingsIntegrationTests.swift` | Savings ETA, primary goal |
| `PremiumGateMatrixTests.swift` | Free/premium boundary |
| `ViewModelCalculationTests.swift` | Legacy formula consistency |
| `WidgetSnapshotStoreTests.swift` | Snapshot encode/decode (Phase 8) |
| `WidgetSnapshotWriterTests.swift` | Home → widget snapshot (Phase 8) |

### Known project warnings (track, do not auto-block unless regressing)

- Duplicate `.xcstrings` build resource warnings.
- `NSEntityDescription` duplicate warnings in repeated in-memory Core Data test loads.
- `HomeDisplayMapping` pace copy may not yet be fully cataloged in `.xcstrings`.
- Privacy policy copy still describes iCloud-only storage (Phase 9 dependency).

### Release scope decision required before final go/no-go

Document which of these ship in v1:

| Scope item | Default recommendation | Gate |
|------------|------------------------|------|
| Local core redesign (Phases 1–7) | **Required** | Stage A must pass |
| Widget v1 (`systemSmall` only) | **Required if Phase 8 ships** | Stage A widget matrix |
| Supabase backup/sync | **Staged after local stability** | Stage B must pass if included |
| CloudKit removal | **Only after migration safety** | Stage B CloudKit matrix |

Phase 10 supports **staged release**: Stage A can pass and ship a local-first build while Stage B remains open.

## 3. QA Philosophy and Release Gates

### Principles

1. **One financial reality** — Home, Income, Expense, Savings, Insights summaries, and widget must agree on pace values from `FinancialSummaryBuilder`.
2. **Local-first free core** — Free users must complete the money-meter loop without sign-in, purchase, or network.
3. **Premium must not regress** — Existing lifetime purchasers keep access; restore failures for verified purchases are blockers.
4. **Data safety over speed** — Migration, restore, and first-sign-in scenarios require explicit pass/fail, not "looks fine."
5. **Gentle financial language** — Negative states use calm copy ("Slowing down"), never shame or panic framing.
6. **Accessibility is release scope** — VoiceOver, Dynamic Type, RTL, and color-independent states are not optional polish.
7. **Fix at source phase** — QA findings route to the owning phase; Phase 10 does not become a catch-all refactor.

### Release gates (all must be explicitly signed off)

| Gate ID | Name | Prerequisite | Owner sign-off |
|---------|------|--------------|----------------|
| G0 | Build/test baseline | Clean build + full test pass on reference simulator | Engineering |
| G1 | Stage A core QA | Section 7 complete, no open Blockers | QA + Product |
| G2 | Migration QA | Section 10 complete on fixture matrix | Engineering + QA |
| G3 | Premium/StoreKit QA | Section 12 sandbox matrix complete | QA |
| G4 | Widget QA | Section 13 complete (if Phase 8 in scope) | QA |
| G5 | Localization/accessibility | Sections 15–16 matrices complete | QA + Design |
| G6 | Device matrix | Section 17 complete | QA |
| G7 | Performance/stability smoke | Section 18 complete | Engineering |
| G8 | Stage B auth/sync QA | Section 8 complete (if Phase 9 in scope) | Engineering + QA |
| G9 | App Store readiness | Section 19 complete | Product + Legal |
| G10 | Go/no-go decision | Section 21 signed | Release owner |

**Hard rule:** Any open **Blocker** in Section 6 fails the release regardless of other gate status.

## 4. Stage A vs Stage B Split

### Stage A — Core redesign QA (before auth/sync in release scope)

**Purpose:** Validate that Phases 1–8 deliver a trustworthy local-first app.

**Entry criteria:**

- Phases 1–7 marked verified in `implementation_planning_index.md`.
- Phase 8 marked verified if widgets are in v1 release scope.
- `xcodebuild build` and full `xcodebuild test` pass on reference destination.
- No open Blocker bugs from prior phases.

**Exit criteria:**

- Section 7 checklist 100% executed; Blockers = 0, Critical ≤ agreed threshold (default 0).
- Sections 10–13, 15–18 complete for Stage A scope.
- G1, G2, G3, G4 (if applicable), G5, G6, G7 signed.

**Explicitly out of Stage A:**

- Apple Sign In
- Supabase upload/download
- CloudKit removal
- Account deletion cloud wipe
- Cross-device restore

### Stage B — Auth/sync QA (after Phase 9 scope freeze and implementation)

**Purpose:** Validate cloud backup, restore, identity, and CloudKit transition without data loss.

**Entry criteria:**

- Stage A passed (or explicitly waived for auth-only hotfix with product approval).
- Phase 9 implementation complete per `phase9_supabase_auth_database_migration_scope.md`.
- Phase 9 unit/integration tests pass.
- Privacy policy and Settings account copy updated for Supabase disclosure.
- `.backupSync` capability gate activated only when backup/sync is functional.

**Exit criteria:**

- Section 8 checklist 100% executed; Blockers = 0.
- CloudKit transition matrix complete with dry-run evidence.
- G8 and G9 (privacy/account sections) signed.

**Explicitly out of Stage B:**

- Widget medium/lock screen expansion
- Real-time multi-device sync
- StoreKit product changes
- New CoreData schema versions unrelated to restore

## 5. Known Risks Inherited from Previous Phases

Each risk maps to a QA section and minimum verification.

### Calculations (Phase 1)

| Risk | Source | QA mapping |
|------|--------|------------|
| Independent formulas on secondary screens | Pre-Phase 1 architecture | Section 11 cross-surface consistency |
| `daysPerMonth = 30.4375` drift in legacy tests | `ViewModelCalculationTests` | G0 full test pass |
| One-time entries affecting long-term pace | Product decision | Section 11 one-time vs recurring |
| `PeriodKind.custom` fallback to month bounds | Phase 1 note | Manual: custom period if exposed in UI |

### CoreData migration (Phase 2)

| Risk | Source | QA mapping |
|------|--------|------------|
| Legacy `frequency=recurring` rows | `FinancialDataMigrationService` | Section 10 v2→v3 upgrade |
| Idempotency on relaunch | Migration service guards | Section 10 double-launch |
| `AppSettings.savingsGoalAmount` legacy fallback | Phase 6 | Section 10 + savings QA |
| CloudKit-enabled model flags | All model versions | Section 10 CloudKit-existing user |

### Home summary (Phase 3)

| Risk | Source | QA mapping |
|------|--------|------------|
| Home recomputing outside builder | Pre-refactor | Section 7 Home + Section 11 |
| Pace copy not localized | `HomeDisplayMapping` | Section 15 |
| Deep link to hero incomplete | Phase 8 note | Section 13 deep link |

### Income/expense flows (Phase 5)

| Risk | Source | QA mapping |
|------|--------|------------|
| Bills/subscriptions double-count | Builder rollup | Section 7 income/expense |
| Seeded categories missing `entryKind` | Migration on launch | Section 10 fresh + upgrade |
| One-time add UX uses monthly preset | Phase 5 note | Section 7 manual script IE-4 |
| `SubscriptionManager` singleton vs injected builder | Phase 5 note | Section 11 summary card vs list |

### Savings (Phase 6)

| Risk | Source | QA mapping |
|------|--------|------------|
| ETA ignores one-time entries | By design | Section 11 savings ETA |
| Multiple goals for premium only | Product + Phase 7 | Section 7 savings + Section 12 |
| Target-date contribution vs shared ETA | Phase 6 note | Section 7: Home ETA ≠ detail secondary field |
| `AppSettings` fallback still present | Legacy | Section 10 upgrade fixture |

### DesignSystem (Phase 4)

| Risk | Source | QA mapping |
|------|--------|------------|
| Dynamic Type overflow on cards | New layouts | Section 16 |
| Color-only pace states | Product decision | Section 16 color-independent |
| Dark-first readability | Brand direction | Section 17 dark/light |
| Glass effects on critical numbers | Product decision | Section 7 DesignSystem |

### Premium gates (Phase 7)

| Risk | Source | QA mapping |
|------|--------|------------|
| Scattered `isPremium` checks | Pre-Phase 7 | Section 12 free/premium matrix |
| Restore "no purchase found" unclear | Phase 7 fix | Section 12 restore matrix |
| JSON export product ambiguity | Phase 7 note | Section 12 + product sign-off |
| Settings hides premium rows for free users | Phase 7 note | Section 7 premium boundary |
| Manual StoreKit QA not yet run | Phase 7 tracker | Section 12 full sandbox matrix |

### Widgets (Phase 8)

| Risk | Source | QA mapping |
|------|--------|------------|
| No widget extension target | Phase 8 audit | Section 13 target setup |
| Legacy widgets in bundle | Pre-v1 code | Section 13: only one `systemSmall` |
| Widget reads CoreData directly | Legacy providers | Section 13 data correctness |
| App Group entitlement unverified | Phase 8 audit | Section 13 + Section 10 |
| Stale/missing snapshot shows `$0` | Product risk | Section 13 stale/missing |
| Deep link notification gap in `ContentView` | Phase 8 audit | Section 13 deep link |

### Supabase/Auth (Phase 9)

| Risk | Source | QA mapping |
|------|--------|------------|
| First sign-in attaches wrong user | Phase 9 | Section 8 first sign-in |
| Restore overwrites local silently | Phase 9 | Section 8 restore confirmation |
| Privacy copy still iCloud-only | Phase 9 audit | Section 19 privacy |
| RLS not validated | Phase 9 | Section 8 RLS checks |
| `.backupSync` postponed | Phase 7/9 | Section 8 premium boundary |
| `supabase-swift` dependency | Already linked | Section 9 build on clean clone |

### CloudKit (legacy)

| Risk | Source | QA mapping |
|------|--------|------------|
| Live iCloud data for existing users | `NSPersistentCloudKitContainer` | Section 10 CloudKit-existing |
| CloudKit removal before Supabase validation | Phase 9 plan | Section 8 + Section 22 rollback |
| Entitlements mismatch (code vs plist) | Phase 9 audit | Section 10 verify in Xcode |
| Remote merge races first sign-in | Phase 9 | Section 8 overlap scenario |

### Localization / accessibility (cross-phase)

| Risk | Source | QA mapping |
|------|--------|------------|
| Hardcoded English in paywall/errors | Phase 7 | Section 15 |
| Long DE/PT labels overflow | `localization_accessibility_qa_plan` | Section 15 |
| Arabic RTL layout breaks | 10-language support | Section 15 + 16 |
| Reduce Motion not respected | Product decision | Section 16 |
| Duplicate `.xcstrings` warnings | Build | G0 track; fix if causes missing strings |

## 6. Release Blocker Severity Model

### Severity definitions

| Severity | Code | Definition | Release impact |
|----------|------|------------|----------------|
| **Blocker** | B | Data loss, wrong money totals, premium paid user locked out, crash on core path, restore destroys local data, App Store rejection certain | **Cannot ship** |
| **Critical** | C | Major feature broken for common path, misleading financial state, inaccessible core flow, widget shows wrong pace, auth session leak | **Cannot ship** unless explicit product waiver documented |
| **Major** | M | Feature partially broken, ugly overflow, non-core crash, wrong non-financial copy, secondary screen miscalculation with clear workaround | Ship only with documented known issue + fix timeline |
| **Minor** | m | Cosmetic, rare edge, non-user-facing warning | Ship with known issue list |

### Financial-specific blocker examples

- Home net daily pace ≠ Income/Expense summary-derived pace by > rounding tolerance.
- Widget unlocked pace ≠ Home hero pace.
- Migration drops active `FinancialCategory` rows.
- Restore imports another user's data (RLS failure).
- Free user cannot add basic recurring income.
- Premium user loses lifetime access after restore.
- Savings ETA on Home ≠ Savings detail for same primary goal.
- Negative pace displayed as positive due to sign error.

### Ship-with-known-issue criteria

A **Major** or **Minor** may ship only if ALL are true:

1. Documented in release notes / known issues with ID (e.g. `KI-014`).
2. No data-loss or calculation-trust impact.
3. Workaround exists or impact is cosmetic/isolated.
4. Product owner and release owner sign Section 21 waiver line item.
5. Fix target version/date recorded.

**Never ship-with-known-issue:** Blockers, data loss, premium entitlement failures, restore safety failures, privacy disclosure gaps.

## 7. Stage A QA Checklist

Use checkbox format in living tracker. IDs are stable for bug filing.

### 7.1 Home

| ID | Check | Pass criteria |
|----|-------|---------------|
| H-01 | Cold launch lands on Home tab | Default tab is Home; no crash |
| H-02 | Momentum hero shows pace status + value | Matches `FinancialSummaryBuilder` for current data |
| H-03 | Net daily pace updates after income change | Visible refresh without relaunch |
| H-04 | Net daily pace updates after expense change | Same as H-03 |
| H-05 | Biggest drain label reasonable | Matches builder output category |
| H-06 | Savings snippet on Home | Remaining + ETA match Savings primary goal |
| H-07 | Empty/new user state | Calm empty copy; no fake numbers |
| H-08 | Pull to refresh / data reload | No duplicate cards or stale hero |
| H-09 | Tab switch away and back | Hero values stable |
| H-10 | Background/foreground | Timer-based minute pace updates if implemented |

### 7.2 DesignSystem

| ID | Check | Pass criteria |
|----|-------|---------------|
| DS-01 | Dark mode card contrast | Primary numbers readable on hero and summary cards |
| DS-02 | Light mode (if supported) | No invisible text |
| DS-03 | Pace status uses text + color | Not color-only |
| DS-04 | Momentum ring Reduce Motion | Static fallback when Reduce Motion on |
| DS-05 | Primary buttons meet tap target | No overlapping hit areas |
| DS-06 | Sheets and modals use design tokens | Consistent spacing/typography |
| DS-07 | Premium upgrade banner | Does not block core navigation |

### 7.3 Calculation consistency

| ID | Check | Pass criteria |
|----|-------|---------------|
| CALC-01 | Home vs Income summary card | Same recurring monthly income |
| CALC-02 | Home vs Expense summary card | Same recurring monthly expense incl. bills/subs rollup |
| CALC-03 | Add one-time income | Home long-term pace unchanged after period |
| CALC-04 | Add one-time expense | Same as CALC-03 |
| CALC-05 | Net minute pace | Consistent with net daily / 24 |
| CALC-06 | Currency change in Settings | All surfaces respect new symbol/format |
| CALC-07 | Zero income scenario | Pace status calm; no divide-by-zero crash |
| CALC-08 | Large amounts | Formatting compact and readable |

### 7.4 Income / expense

| ID | Check | Pass criteria |
|----|-------|---------------|
| IE-01 | Add recurring income | Appears in list; summary updates |
| IE-02 | Add recurring expense | Same |
| IE-03 | Add one-time income via modal | `entryKind` one-time; correct occurrence |
| IE-04 | One-time add flow | User can select one-time without confusion |
| IE-05 | Edit amount | Home updates |
| IE-06 | Delete/deactivate entry | Home updates; no orphan ghost rows |
| IE-07 | Custom category (premium) | Gated for free; works for premium |
| IE-08 | Basic category (free) | Always available |
| IE-09 | Recurring automation (premium) | Gated for free user |
| IE-10 | Bills/subscriptions in expense total | No double-count vs categories |

### 7.5 Savings

| ID | Check | Pass criteria |
|----|-------|---------------|
| SAV-01 | Create basic savings goal (free) | One active goal allowed |
| SAV-02 | Second goal attempt (free) | Gated with clear premium CTA |
| SAV-03 | Home savings remaining | Matches goal current/target |
| SAV-04 | Home savings ETA | Matches detail for primary goal |
| SAV-05 | Zero/negative pace | ETA hidden or "—"; no absurd date |
| SAV-06 | Quick save from Home | Updates primary goal |
| SAV-07 | Complete goal | Next primary selection sane |
| SAV-08 | Premium multiple goals | Create second goal works when premium |

### 7.6 Premium / free boundary

| ID | Check | Pass criteria |
|----|-------|---------------|
| PF-01 | Free: full Home loop | No paywall interruption |
| PF-02 | Free: income/expense/savings | Core flows complete |
| PF-03 | Free: insights/export/themes/lock/widgets | Gated with clear lock state |
| PF-04 | Premium: all v1 features | Access per `BudgetMeterCapability` |
| PF-05 | Paywall dismiss | Does not grant access |
| PF-06 | DEBUG premium toggle | Absent in Release build |
| PF-07 | Offline free usage | No network required |
| PF-08 | `.backupSync` | Still postponed or clearly "coming soon" if not Phase 9 |

### 7.7 Localization (Stage A smoke — full matrix in Section 15)

| ID | Check | Pass criteria |
|----|-------|---------------|
| L10N-A01 | App builds with all catalogs | No missing key build failures |
| L10N-A02 | Switch device language to TR | Home hero strings localized |
| L10N-A03 | Switch to DE | Long labels do not clip hero |
| L10N-A04 | Switch to AR | RTL layout correct on Home |
| L10N-A05 | Paywall strings | No raw English in primary CTA (if localized pass done) |

### 7.8 Accessibility (Stage A smoke — full matrix in Section 16)

| ID | Check | Pass criteria |
|----|-------|---------------|
| A11Y-A01 | VoiceOver Home hero | Reads status, value, hint |
| A11Y-A02 | Dynamic Type AX-Large Home | No clipped primary pace value |
| A11Y-A03 | Reduce Motion | Animations respect setting |
| A11Y-A04 | Locked premium row | VO announces locked + action |
| A11Y-A05 | Chart/ring if visible | Has accessibility label |

### 7.9 Offline / local-first

| ID | Check | Pass criteria |
|----|-------|---------------|
| OFF-01 | Airplane mode launch | App opens; local data visible |
| OFF-02 | Add expense offline | Persists after relaunch |
| OFF-03 | Premium offline after prior purchase | Still premium |
| OFF-04 | No spurious "syncing" errors in Stage A | Unless Phase 9 partially enabled |

## 8. Stage B QA Checklist

Execute only when Phase 9 is in release scope and Stage A passed.

### 8.1 Apple Sign In

| ID | Check | Pass criteria |
|----|-------|---------------|
| AUTH-01 | Sign in with Apple success | Session established; UI shows signed-in state |
| AUTH-02 | Cancel sign-in | Local data unchanged |
| AUTH-03 | Sign in failure (revoked credential) | Safe error; no partial wipe |
| AUTH-04 | Sign out | Session cleared; local CoreData retained |
| AUTH-05 | Relaunch after sign-in | Session restored |
| AUTH-06 | Reinstall + session | Expected re-auth behavior documented and correct |

### 8.2 Supabase Auth

| ID | Check | Pass criteria |
|----|-------|---------------|
| AUTH-07 | Supabase user ID stable | Same Apple account → same `auth.users.id` |
| AUTH-08 | Invalid token/expired session | Re-auth prompt before cloud ops |
| AUTH-09 | Sign-in does not imply premium | Free signed-in user unchanged feature access |

### 8.3 Backup / sync

| ID | Check | Pass criteria |
|----|-------|---------------|
| SYNC-01 | First backup (premium + signed in) | Upload succeeds; status shows success |
| SYNC-02 | Backup payload completeness | Categories, goals, settings per v1 schema |
| SYNC-03 | Backup incremental edit | Re-backup updates cloud |
| SYNC-04 | Sync status UI | Text + icon; not color-only |
| SYNC-05 | Offline backup attempt | Fails gracefully; local data safe |
| SYNC-06 | Free user backup attempt | Blocked at gate; clear messaging |

### 8.4 First sign-in after local use

| ID | Check | Pass criteria |
|----|-------|---------------|
| FS-01 | Local-only user signs in | **Zero data loss**; record counts match |
| FS-02 | Local premium user signs in | Premium cache intact; backup offered |
| FS-03 | Sign-in during active editing | No race crash; consistent save |
| FS-04 | Wrong-account prevention | Cannot attach local store to wrong Apple ID without explicit flow |

### 8.5 Restore

| ID | Check | Pass criteria |
|----|-------|---------------|
| RST-01 | Restore to empty app | Data matches backup |
| RST-02 | Restore over existing local | **Confirmation required**; no silent overwrite |
| RST-03 | Restore failure rollback | Local snapshot restored; app usable |
| RST-04 | New device cloud restore | Premium + signed in → data appears |
| RST-05 | Currency/theme prefs | Restore correctly |

### 8.6 Conflict / merge

| ID | Check | Pass criteria |
|----|-------|---------------|
| MERGE-01 | Overlap device scenario | Chooser UI; user picks local vs cloud |
| MERGE-02 | Unselected side preserved | Snapshot or export path documented |
| MERGE-03 | No silent merge | Log/audit trail for QA |

### 8.7 Account deletion

| ID | Check | Pass criteria |
|----|-------|---------------|
| DEL-01 | Delete account confirmation | Accessible destructive confirm |
| DEL-02 | Cloud data removed | Supabase rows gone for test user |
| DEL-03 | Local data after delete | Policy-defined: wipe or keep local copy explicit |
| DEL-04 | Delete failure | Safe error; user can retry or contact support copy |

### 8.8 CloudKit transition

| ID | Check | Pass criteria |
|----|-------|---------------|
| CK-01 | CloudKit-existing user classification | App detects iCloud availability |
| CK-02 | Export before CloudKit deactivation | Dry-run completed on fixture |
| CK-03 | No CloudKit removal in same release as first Supabase restore | Unless waiver documented |
| CK-04 | `FinancialSummaryBuilder` before/after pipeline | Same totals on dry-run fixture |
| CK-05 | Legacy `cloudKitRecordID` fields | Ignored or mapped; no owner key confusion |

### 8.9 RLS / security

| ID | Check | Pass criteria |
|----|-------|---------------|
| SEC-01 | User A cannot read User B backup | Integration test pass |
| SEC-02 | Signed-out upload rejected | Fails at API |
| SEC-03 | Anon key only in client | No service role in repo/binary |
| SEC-04 | Account deletion removes remote data | Verified on test project |

## 9. Build / Test Requirements

### Reference destination

```sh
xcodebuild -showdestinations -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios
```

Default reference (update if simulator names differ):

```sh
DEST="platform=iOS Simulator,name=iPhone 17,OS=26.5"
```

### G0 — Full baseline (required before any manual QA)

```sh
# Build
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination "$DEST" build

# Full test suite (parallel off for stability)
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination "$DEST" -parallel-testing-enabled NO test
```

**Pass criteria:** Build `** SUCCEEDED **`, 0 test failures.

Record: total passed count, failure list, build warnings count (duplicate xcstrings, etc.).

### Focused test groups

Run after related phase changes or QA fixes:

| Group | Command |
|-------|---------|
| Calculation | `-only-testing:budgetmeter.iosTests/CalculationEngineTests` |
| Builder | `-only-testing:budgetmeter.iosTests/FinancialSummaryBuilderTests` |
| Migration | `-only-testing:budgetmeter.iosTests/FinancialDataMigrationServiceTests` |
| Home | `-only-testing:budgetmeter.iosTests/HomeViewModelMappingTests` |
| Income/expense | `-only-testing:budgetmeter.iosTests/IncomeExpenseFlowTests` |
| Savings | `-only-testing:budgetmeter.iosTests/BasicSavingsIntegrationTests` |
| Premium | `-only-testing:budgetmeter.iosTests/PremiumGateMatrixTests` |
| Widget snapshot | `-only-testing:budgetmeter.iosTests/WidgetSnapshotStoreTests -only-testing:budgetmeter.iosTests/WidgetSnapshotWriterTests` |

### Widget extension build (when Phase 8 complete)

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets \
  -destination "$DEST" build
```

### Release configuration build

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination "$DEST" -configuration Release build
```

Verify: no `DEBUG` premium toggle, no test hooks in Release.

### Warnings tracking

Maintain a warnings log with columns: warning text, first seen date, Blocker/Critical/Major/Minor, owner, fix phase.

Minimum tracked warnings:

- Duplicate `.xcstrings` in Copy Bundle Resources.
- CoreData `NSEntityDescription` duplicate in tests.
- Any new deprecation introduced during QA fix window.

**Policy:** Warnings do not auto-block unless they indicate missing localizations, signing failures, or duplicate symbols.

## 10. CoreData / Migration QA

### Fixture plan

Create and label fixtures before manual QA. Store under `docs/qa/fixtures/` or team vault (not committed if containing real user data).

| Fixture ID | Description | How to create |
|------------|-------------|---------------|
| FIX-FRESH | No prior install | Delete app; install build |
| FIX-V1 | Legacy v1 store | Restore from archived test store if available |
| FIX-V2 | Pre-`entryKind` v2 store | Phase 2 test artifact |
| FIX-V3 | Current v3 with mixed rows | Seed recurring + one-time + legacy frequency |
| FIX-SAV-LEGACY | `AppSettings.savingsGoalAmount` only | No `SavingsGoal` entity |
| FIX-SAV-GOAL | Active `SavingsGoal` + legacy setting | Both present; goal wins |
| FIX-PREM | `isPremiumUser=true` | StoreKit sandbox or test flag in Debug only |
| FIX-CLOUDKIT | iCloud-enabled device with existing sync | **Real device**; dev Apple ID |
| FIX-CORRUPT | Truncated/missing sqlite | Engineering-generated negative test |

### Migration test matrix

| Scenario | Fixture | Steps | Pass criteria |
|----------|---------|-------|---------------|
| Fresh install | FIX-FRESH | Install → launch → add data | v3 schema; no migration errors |
| v2 → v3 upgrade | FIX-V2 | Install new build over old | `entryKind` populated; recurring legacy migrated |
| v3 idempotent relaunch | FIX-V3 | Launch 3× | No duplicate migrations; counts stable |
| Legacy savings fallback | FIX-SAV-LEGACY | Launch Home | Summary uses fallback; can create goal |
| Goal precedence | FIX-SAV-GOAL | Open Home/Savings | Goal values win over `AppSettings` |
| Corrupt store | FIX-CORRUPT | Launch | Graceful error; no silent wipe; recovery copy |
| CloudKit-existing | FIX-CLOUDKIT | Launch before/after upgrade | Data present; no duplicate merges on upgrade |

### CloudKit-existing user protocol

1. Document iCloud account used (test only).
2. Record entity counts before upgrade.
3. Upgrade app; record counts after.
4. Run `FinancialSummaryBuilder` totals before/after — must match within tolerance.
5. If Phase 9 enabled: run backup dry-run before any CloudKit deactivation.

### Rollback / recovery (local)

| Event | Recovery action |
|-------|-----------------|
| Migration failure on launch | App shows recovery UI; user directed to support/export if available |
| Bad upgrade | Reinstall previous App Store version if still compatible; restore from device backup |
| Accidental Settings reset | Confirm destructive action; no undo — QA must verify copy warns clearly |
| Failed restore (Phase 9) | Local snapshot rollback per Phase 9 importer design |

## 11. Calculation QA

### Cross-surface consistency matrix

Record values in QA sheet for fixed test dataset **QA-CALC-SET-01**:

| Surface | Fields to compare |
|---------|-------------------|
| Home hero | `netDailyPace`, `paceStatus`, `paceStatusCopy` |
| Income summary card | `recurringIncomeMonthly`, daily projection |
| Expense summary card | `recurringExpenseMonthly`, daily projection |
| Savings Home snippet | `savingsRemaining`, `savingsTimeToGoal` |
| Savings detail | Same as Home for primary goal |
| Widget (unlocked) | `netDailyPace`, `paceStatus` from snapshot |
| Insights (if in scope) | Uses builder totals, not raw category sums |

**Tolerance:** Currency rounding only; no > $0.01/day drift without explanation.

### QA-CALC-SET-01 seed data

- Recurring income: $5,000/month salary
- Recurring expense: $2,000/month rent + $500/month subscriptions (via builder rollup)
- One-time expense: $300 today (must not change long-term daily pace after period)
- One-time income: $1,000 bonus (same rule)
- Primary savings goal: $10,000 target, $2,000 current

### Behavioral checks

| ID | Behavior | Expected |
|----|----------|----------|
| CR-01 | One-time vs recurring | Only recurring in pace denominator |
| CR-02 | Net daily pace | (recurring income − recurring expense) / 30.4375 |
| CR-03 | Net minute pace | Net daily / 24 |
| CR-04 | Biggest drain | Highest recurring expense category |
| CR-05 | Savings ETA | Remaining / positive net daily recurring pace only |
| CR-06 | Negative pace | Status "Slowing down" or equivalent; no shame copy |
| CR-07 | Bills paid exclusion | Paid bills not double-counted in rollup |

## 12. Premium / StoreKit QA

### Sandbox account matrix

Prepare at least 2 sandbox Apple IDs in App Store Connect.

| Case ID | User state | Action | Expected |
|---------|------------|--------|----------|
| SK-01 | Fresh install, free | Launch | Core flows open |
| SK-02 | Free | Attempt purchase | StoreKit sheet; success → premium |
| SK-03 | Free | Cancel purchase | Remains free; no partial state |
| SK-04 | Free | Pending purchase (if simulatable) | UI shows pending; no unlock |
| SK-05 | Free | Failed purchase | Error copy; remains free |
| SK-06 | Premium | Relaunch | Still premium from local cache |
| SK-07 | Premium | Offline relaunch | Still premium |
| SK-08 | Free | Restore with no purchase | Clear "no purchase found" |
| SK-09 | Premium | Restore on new install | Premium restored |
| SK-10 | Free | Product unavailable | Safe error (StoreKit config) |
| SK-11 | Premium | Export/themes/lock/widgets | Each gate opens feature |
| SK-12 | Free | Same features | Paywall/lock only |
| SK-13 | Release build | No debug toggle | Confirm absent |

### Product ID freeze

Do not change during QA: `com.budgetmeter.premium.lifetime`

### Premium feature matrix regression

Verify against `BudgetMeterCapability` / `PremiumGateMatrixTests` cases:

- `basicRecurringEntry` → free
- `oneBasicSavingsGoal` → free
- `customCategories` → premium
- `dataExport` → premium
- `widgets` → premium
- `spendingInsights` → premium
- `biometricLock` → premium
- `premiumThemes` → premium
- `backupSync` → postponed until Phase 9 complete

## 13. Widget QA

Applies when Phase 8 is in release scope.

### Scope enforcement

| ID | Check | Pass |
|----|-------|------|
| W-01 | Widget gallery count | Exactly one widget kind |
| W-02 | Supported family | `systemSmall` only |
| W-03 | No medium/large | Not offered |
| W-04 | No lock screen widgets | Not in bundle |
| W-05 | Extension embed | App installs widget extension |

### Data / premium matrix

| ID | State | Expected widget |
|----|-------|-----------------|
| W-10 | Premium, data present | Net daily pace + status matches Home |
| W-11 | Premium, no data | Insufficient-data copy; not `$0/day` |
| W-12 | Free | Locked teaser only |
| W-13 | Free tap teaser | Routes to paywall/premium |
| W-14 | Premium tap | Deep link to Home hero |
| W-15 | Stale snapshot | Stale copy; no false live indicator |
| W-16 | Missing snapshot pre-first-open | Setup/missing copy |
| W-17 | Currency change | Widget updates after app open + reload |
| W-18 | Purchase unlock | Widget unlocks without reinstall |

### Target / entitlement checks

- App Group `group.com.budgetmeter.shared` on app + extension.
- Widget reads snapshot only — never CoreData in extension.
- `WidgetSnapshotWriter` values match `HomeViewModel` after edits.

## 14. Auth / Supabase QA

Applies when Phase 9 is in release scope. Cross-reference Section 8.

### User state matrix

| State | Backup | Restore | Premium features | Sign-in required |
|-------|--------|---------|------------------|------------------|
| Local-only free | Blocked | N/A | Free core only | No |
| Signed-in free | Blocked | N/A | Free core only | Yes for account features |
| Local-only premium | Prompt sign-in | N/A | Premium v1 | No for local premium |
| Signed-in premium | Allowed | Allowed | Premium + sync | Yes |

### Privacy / copy verification (not final copy — verify presence and accuracy)

- [ ] Privacy policy mentions Supabase for premium backup (not "no external servers" alone).
- [ ] Apple Sign In disclosure present.
- [ ] Account deletion instructions present.
- [ ] Export/backup wording distinguishes local reset vs cloud delete.
- [ ] Data collection section matches actual SDK/network calls.

## 15. Localization Matrix

### Languages (all required for release)

| Code | Language | Priority smoke | Full pass |
|------|----------|----------------|-----------|
| EN | English | Required | Required |
| TR | Turkish | Required | Required |
| DE | German | Required (long text) | Required |
| FR | French | Required | Required |
| ES | Spanish | Required | Required |
| IT | Italian | Required | Required |
| PT | Portuguese | Required (long text) | Required |
| JA | Japanese | Required (CJK compact) | Required |
| ZH | Chinese | Required (CJK compact) | Required |
| AR | Arabic | Required (RTL) | Required |

### Stage A full pass surfaces

Minimum screens per language:

- Home hero (pace status + value)
- Income + Expense summary labels
- Savings goal empty/active
- Paywall primary CTA + restore
- Settings critical rows
- Tab bar labels
- Widget v1 strings (if shipped)
- Common alerts (delete, reset, errors)

### Special layout checks

| Language | Check |
|----------|-------|
| DE, PT | Long words in buttons and cards — truncate or wrap safely |
| JA, ZH | Compact width; no overlapping hero text |
| AR | RTL tab order; currency position; leading/trailing correct |
| TR | Special characters render in pace copy |

### Hardcoded string hunt

```sh
rg "Text\(\"[A-Za-z]" budgetmeter.ios/Features budgetmeter.ios/DesignSystem \
  --glob '*.swift' | rg -v 'Preview|#if DEBUG'
```

File hits require ticket or waiver before release.

## 16. Accessibility Matrix

| ID | Setting | Surfaces | Pass criteria |
|----|---------|----------|---------------|
| AX-01 | VoiceOver | Home, Income, Expense, Savings, Paywall, Settings | Logical order; labels on all interactive elements |
| AX-02 | VoiceOver | Locked premium features | "Locked, Premium, Button" pattern |
| AX-03 | Dynamic Type Default | Core cards | Layout intact |
| AX-04 | Dynamic Type AX1–AX5 | Home hero, paywall | Primary values visible or scrollable |
| AX-05 | Reduce Motion | Momentum ring, success animations | Reduced or static |
| AX-06 | Increase Contrast | Dark mode hero | Text/icons distinguishable |
| AX-07 | Color-independent | Pace status, trends, charts | Text/icon/shape redundancy |
| AX-08 | VoiceOver | Widgets (if shipped) | Locked vs unlocked announced |

### Device + accessibility combos

Run AX-04 on **iPhone SE (small)** and **iPhone Pro Max (large)** at minimum.

## 17. Device Matrix

| Device class | Representative | OS | Mode | Stage A | Stage B |
|--------------|----------------|-----|------|---------|---------|
| Small iPhone | iPhone SE (3rd gen) or iPhone 16e sim | Latest iOS supported | Light + Dark | Required | Required |
| Standard iPhone | iPhone 15/16/17 sim | Latest | Dark-first focus | Required | Required |
| Large iPhone | iPhone 15/16/17 Pro Max sim | Latest | Dark + Light | Required | Sample |
| iPad | If `TARGETED_DEVICE_FAMILY` includes iPad | Latest | Both | **If supported** | Sample |
| Physical device | Any team device | Latest public iOS | Dark | Required for StoreKit + widget | Required for Apple Sign In |

### iPad policy

Check `project.pbxproj` / target settings:

- If iPad not supported: document "iPhone only" in release notes; skip iPad matrix.
- If supported: run layout smoke on iPad 11" and 13" simulators.

### Dark / light mode

Brand is dark-first. QA both modes on at least standard iPhone for readability regressions.

## 18. Performance / Stability QA

Smoke-level — not full profiling unless Blocker/Critical suspected.

| ID | Check | Method | Pass |
|----|-------|--------|------|
| PERF-01 | Cold launch time | Stopwatch < 3s to interactive Home on reference sim | No white screen hang |
| PERF-02 | Home load | Instruments optional | No main-thread block > 500ms perceived |
| PERF-03 | CoreData fetch on Home | Add 50 categories | Still responsive |
| PERF-04 | Widget snapshot write | Edit expense | Completes without UI stall |
| PERF-05 | Memory smoke | Navigate all tabs 5 min | No runaway growth |
| PERF-06 | Crash smoke | Fast tab switching | No crash |
| PERF-07 | Background/foreground 10× | — | No crash/data loss |
| PERF-08 | Low Power Mode | Home refresh | Acceptable degradation only |

Log crashes in QA tracker with severity per Section 6.

## 19. Privacy / App Store Readiness

Verify items exist and match actual behavior — do not invent final legal copy in Phase 10.

### In-app legal / policy

| Item | Verify |
|------|--------|
| Privacy policy link | Opens; content matches data practices |
| Terms link | Opens or planned waiver documented |
| Account deletion path | Present if auth ships (Phase 9) |
| Local reset vs cloud delete | Distinct copy and outcomes |
| Export/backup description | Accurate for premium sync scope |

### App Privacy labels (App Store Connect)

| Data type | Expected declaration |
|-----------|---------------------|
| Financial info | User-entered budget data; local + cloud if sync |
| Identifiers | Apple Sign In if auth ships |
| Usage data | Only if analytics added — default none expected |

### Entitlements / capabilities audit

- [ ] App Groups (widget/shared storage)
- [ ] Sign in with Apple (if Phase 9)
- [ ] No unnecessary capabilities
- [ ] CloudKit capability state documented vs `PersistenceService` usage

### Metadata / assets checklist

| Asset | Status to verify |
|-------|------------------|
| App icon | Matches current brand |
| Screenshots | Reflect redesigned Home, not legacy UI |
| App name/subtitle | Accurate |
| Keywords | No misleading claims |
| Age rating | Appropriate for finance |
| IAP | Lifetime premium product configured |
| Review notes | Test account / sandbox instructions |

### Pre-submission build

- [ ] Release archive succeeds
- [ ] Bitcode/symbol settings correct
- [ ] dSYM uploaded for crash symbolication
- [ ] No test API keys in Release (Supabase anon key is expected; no service role)

## 20. Manual QA Scripts

### Script A — First-time user (Stage A, ~20 min)

1. Fresh install on standard iPhone sim.
2. Complete onboarding if present; land on Home.
3. Observe empty state copy.
4. Add recurring income $5,000/month.
5. Add recurring expense $2,000/month.
6. Confirm Home pace positive; status readable.
7. Add one-time expense $100.
8. Confirm long-term pace unchanged (per product rule).
9. Create basic savings goal $10,000 / $1,000 saved.
10. Confirm ETA appears on Home.
11. Switch to Expense tab; confirm summary matches.
12. Enable airplane mode; add $50 expense; relaunch — persists.
13. Pass/fail each step with screenshots.

### Script B — Returning user upgrade (Stage A, ~30 min)

1. Install over FIX-V2 or internal beta with data.
2. Launch; confirm migration completes without error dialog.
3. Record category counts before/after.
4. Open Home — pace matches pre-upgrade expectations.
5. Open Savings — goal data intact.
6. Toggle language DE; check hero overflow.
7. Toggle AR; check RTL.
8. Pass/fail.

### Script C — Premium lifetime (Stage A, ~25 min)

1. Fresh sandbox user.
2. Confirm free access to Home/income/expense/savings.
3. Tap locked export — paywall appears.
4. Complete lifetime purchase.
5. Confirm export, themes, widgets setup unlock.
6. Force quit; relaunch — still premium.
7. Restore on second sim install — premium returns.
8. Pass/fail.

### Script D — Widget v1 (Stage A, when Phase 8 done, ~20 min)

1. Premium user with data.
2. Add widget to Home Screen small slot.
3. Compare value to app Home hero.
4. Change expense in app; widget updates within expected window.
5. Free user: locked teaser only; tap → paywall.
6. Premium tap → Home hero visible.
7. Pass/fail.

### Script E — Auth/sync (Stage B, ~45 min)

1. Local-only premium user with seeded data.
2. Sign in with Apple.
3. Verify record counts unchanged.
4. Run backup.
5. Delete app; reinstall; sign in; restore.
6. Verify totals match Script A dataset equivalents.
7. Sign out; verify local data remains.
8. Pass/fail.

## 21. Go / No-Go Checklist

Complete on release day or submission eve. All must be checked for **Go**.

### Engineering

- [ ] G0 build/test baseline pass recorded
- [ ] 0 open Blockers
- [ ] 0 open Critical (or waivers attached)
- [ ] Release build archived and smoke-tested
- [ ] Migration matrix complete
- [ ] Known issues list published (Section 6 waivers)

### Product

- [ ] Stage A scope matches shipped features
- [ ] Stage B scope decision documented (in or out of v1)
- [ ] Free core loop validated by QA
- [ ] Premium matrix signed
- [ ] Widget v1 scope signed (if applicable)

### QA

- [ ] Section 7 checklist executed
- [ ] Section 8 checklist executed (if Stage B in scope)
- [ ] Device matrix (Section 17) complete
- [ ] Localization matrix (Section 15) complete
- [ ] Accessibility matrix (Section 16) complete
- [ ] StoreKit matrix (Section 12) complete
- [ ] Widget matrix (Section 13) complete if applicable

### Legal / App Store

- [ ] Privacy policy accurate
- [ ] App Privacy labels reviewed
- [ ] Account deletion path verified (if auth)
- [ ] Screenshots/metadata current

### Decision

| Field | Value |
|-------|-------|
| Release version | |
| Build number | |
| Stage A result | Pass / Fail |
| Stage B result | Pass / Fail / N/A |
| Decision | **Go** / **No-Go** |
| Decision owner | |
| Date | |
| Blockers remaining | |
| Waived issues | KI-IDs |

## 22. Rollback / Recovery Plan

### Pre-release rollback

| Trigger | Action |
|---------|--------|
| Blocker found in RC build | Halt submission; fix in owning phase; re-run G0 + affected matrices |
| Stage B auth failure | Ship Stage A only build without Phase 9 features if product approves split release |
| Widget extension crash | Disable widget target from release build only with product approval; document known issue |

### Post-release incident response

| Severity | Action |
|----------|--------|
| Data loss reports | Pause rollout; advise users not to reset; hotfix branch; restore path comms |
| Premium restore failures | Priority hotfix; verify StoreKit + local cache |
| Bad migration | Stop phased rollout; offer previous version if compatible |
| Supabase RLS breach | Rotate keys; disable backup endpoint; incident response per security plan |

### User recovery communications (verify templates exist)

- Export before upgrade reminder.
- Restore failure — contact support path.
- Account deletion confirmation email/copy.
- CloudKit → Supabase transition FAQ (if Stage B ships).

### Backup before destructive QA

QA engineers must not test restore/destructive flows on personal production data. Use fixtures and test Apple IDs only.

## 23. Files Likely To Update During QA Execution

Phase 10 QA **findings** may result in fixes in owning phases. QA documentation artifacts:

| Artifact | Purpose |
|----------|---------|
| `docs/implementation/phase10_release_qa_scope.md` | This scope (updated with results appendix) |
| `docs/qa/release_tracker.md` (create during execution) | Living checklist |
| `docs/qa/known_issues.md` (create during execution) | KI-IDs and waivers |
| `docs/qa/fixtures/README.md` (create during execution) | Fixture instructions |
| `implementation_planning_index.md` | Phase 10 status only |

Bug fixes route to phase owners — typical touch targets:

- `budgetmeter.ios/Features/**`
- `budgetmeter.ios/DesignSystem/**`
- `budgetmeter.ios/CoreKit/**`
- `budgetmeter.ios/Resources/*.xcstrings`
- `budgetmeter.iosTests/**`
- Widget extension (Phase 8)
- Auth/backup services (Phase 9)

## 24. Files Not Allowed To Touch in Phase 10 Planning

During **planning and checklist authoring only** (this document upgrade):

- Swift source files
- Xcode project / scheme files
- CoreData model files
- Entitlements plists
- Supabase/Auth implementation
- Widget implementation
- StoreKit product configuration
- CloudKit setup/removal
- Production Supabase secrets

QA **execution** may file bugs that cause later fixes in these files through owning phases — not through ad-hoc Phase 10 coding.

## 25. Step-by-Step Phase 10 Implementation Sequence

1. **Confirm upstream gates** — Phases 1–7 verified; 8–9 per release scope.
2. **Create QA tracker** from Sections 7–8, 12–13, 15–17.
3. **Run G0 baseline** — record build/test counts and warnings.
4. **Prepare fixtures** — Section 10 fixture IDs.
5. **Seed QA-CALC-SET-01** on reference simulator.
6. **Execute Script A** (first-time user).
7. **Execute Script B** (upgrade) if fixtures available.
8. **Run Section 7** checklist completely.
9. **Run Section 11** calculation matrix with recorded numbers.
10. **Run Section 12** StoreKit sandbox matrix on physical device.
11. **Run Section 15–16** localization/accessibility matrices.
12. **Run Section 17** device matrix.
13. **Run Section 18** performance smoke.
14. **Run Section 13** widget matrix if Phase 8 shipped.
15. **Run Section 10** migration matrix.
16. **Freeze Stage A** — triage Blockers/Critical; fix via owning phases.
17. **Re-run G0** after fixes.
18. **Sign G1–G7** gates.
19. **If Stage B in scope:** execute Section 8 after Phase 9 complete.
20. **Run Scripts D–E** as applicable.
21. **Run Section 19** App Store readiness.
22. **Complete Section 21** go/no-go.
23. **Update `implementation_planning_index.md`** Phase 10 status with results.
24. **Archive QA evidence** — screenshots, logs, test output, signed checklist.

## 26. What To Postpone

Not release-blocking for v1 QA scope:

- Nonessential visual polish and Pulsey variants.
- Advanced widgets (medium, large, lock screen).
- AI assistant, bank sync, remote config experiments.
- Full App Store screenshot localization in all 10 languages (unless marketing requires).
- Complex weekly recap and awareness streak perfection.
- Advanced forecasting and PDF export (if product not in v1).
- Multi-device real-time sync conflict resolution beyond Phase 9 v1.
- RevenueCat, subscriptions, ads.
- Perfect zero-warning build (track warnings; fix only if impactful).

## 27. Success Criteria

Phase 10 is successful when:

- Stage A checklist executed with 0 Blockers and signed G1–G7.
- Stage B checklist executed with 0 Blockers if auth/sync in release scope.
- G0 baseline recorded at start and end of QA window.
- Calculation cross-surface matrix documented with pass evidence.
- StoreKit sandbox matrix complete on physical device.
- Migration fixture matrix complete or explicitly N/A with waiver.
- Widget v1 matrix complete or N/A if widgets not in release.
- Localization 10-language matrix complete.
- Accessibility matrix complete on small + standard iPhone.
- App Store readiness checklist complete.
- Go/no-go decision documented with owner and date.
- Known issues list complete with severities and waivers.
- All Blockers resolved or release halted.

## 28. Recommendation

### Status

**Ready for QA execution planning after this document upgrade.**

QA execution timing:

| Release scope | When to start Stage A manual QA |
|---------------|--------------------------------|
| Local core only (Phases 1–7) | **Now** — after G0 baseline |
| Widget v1 included | After Phase 8 verified |
| Supabase/sync included | Stage B after Phase 9 verified |

### Remaining release risks (highest priority)

1. **Phase 8 not implemented** — widget QA blocked; legacy widget code still violates v1 if accidentally shipped.
2. **Phase 9 not implemented** — privacy copy inaccurate if sync marketed; CloudKit still active.
3. **Manual StoreKit QA not yet executed** — Phase 7 code verified but sandbox purchase/restore matrix outstanding.
4. **CloudKit-existing users** — migration safety unproven on real iCloud fixtures.
5. **Localization gaps** — `HomeDisplayMapping` and some Phase 5 strings may lack catalog entries.
6. **Duplicate `.xcstrings` warnings** — risk of missing strings at runtime.
7. **Deep link routing** — widget → Home hero may fail until Phase 8 routing complete.

### Whether Phase 10 is ready for QA execution

| QA stage | Ready? | Condition |
|----------|--------|-----------|
| Stage A automated (G0) | **Yes** | Phases 1–7 verified; run `xcodebuild` baseline now |
| Stage A manual core | **Partial** | Start Home/calc/income/expense/savings; defer widget until Phase 8 |
| Stage A StoreKit | **Yes** | Requires physical device + sandbox accounts |
| Stage B | **No** | Blocked on Phase 9 implementation |

### Recommended first QA step

Run the **G0 preflight baseline** and log results in a new `docs/qa/release_tracker.md`:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build

xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -parallel-testing-enabled NO test
```

Then execute **Script A (First-time user)** on iPhone 17 simulator and file issues against Section 7 IDs.

Do not wait for Phase 8 or Phase 9 to begin Stage A core QA — those phases gate only their respective matrix sections.
