# BudgetMeter Release QA Tracker

Living checklist for Phase 10. Update status as manual QA progresses.

**Last G0 run:** 2026-06-17  
**Reference destination:** `platform=iOS Simulator,name=iPhone 17,OS=26.5`

## G0 — Automated Baseline

| Check | Result | Notes |
|-------|--------|-------|
| App build | **PASS** | `xcodebuild -scheme budgetmeter.ios build` → SUCCEEDED |
| Full test suite | **PASS** | 147 passed / 0 failed (`-parallel-testing-enabled NO`) |
| Widget extension build | **BLOCKED** | `BudgetMeterWidgets` scheme not configured for build; direct target build fails on provisioning profile |
| Release build | **NOT RUN** | Pending after widget signing resolved |
| Duplicate `.xcstrings` warnings | **TRACK** | 8 duplicate Copy Bundle Resources warnings |

### Focused test groups (all pass via full suite 2026-06-17)

- CalculationEngineTests
- FinancialSummaryBuilderTests
- FinancialDataMigrationServiceTests (10 tests)
- HomeViewModelMappingTests
- IncomeExpenseFlowTests
- BasicSavingsIntegrationTests
- PremiumGateMatrixTests
- WidgetSnapshotStoreTests (5)
- WidgetSnapshotWriterTests (5)

---

## Gate Sign-Off

| Gate | Status | Date | Owner |
|------|--------|------|-------|
| G0 Build/test baseline | **PASS** | 2026-06-17 | Automated |
| G1 Stage A core QA | **NOT STARTED** | | |
| G2 Migration QA | **NOT STARTED** | | |
| G3 Premium/StoreKit QA | **NOT STARTED** | | |
| G4 Widget QA | **PARTIAL** | | Unit tests pass; manual + extension build blocked on signing |
| G5 Localization/accessibility | **NOT STARTED** | | |
| G6 Device matrix | **NOT STARTED** | | |
| G7 Performance smoke | **NOT STARTED** | | |
| G8 Stage B auth/sync QA | **PASSED FOR V1** | 2026-06-18 | Supabase migrations applied; backup/version history/account deletion verified by user. CloudKit removal remains postponed. |
| G9 App Store readiness | **NOT STARTED** | | |
| G10 Go/no-go | **NOT STARTED** | | |

---

## Stage A Checklist

Status key: `[ ]` pending · `[~]` partial · `[x]` pass · `[!]` fail

### Home (Section 7.1)

- [ ] H-01 Cold launch lands on Home
- [ ] H-02 Momentum hero pace status + value
- [ ] H-03 Net daily pace updates after income
- [ ] H-04 Net daily pace updates after expense
- [ ] H-05 Biggest drain label
- [ ] H-06 Savings snippet on Home
- [ ] H-07 Empty/new user state
- [ ] H-08 Pull to refresh
- [ ] H-09 Tab switch stability
- [ ] H-10 Background/foreground

### DesignSystem (7.2)

- [ ] DS-01 Dark mode contrast
- [ ] DS-02 Light mode
- [ ] DS-03 Pace status text + color
- [ ] DS-04 Reduce Motion ring
- [ ] DS-05 Tap targets
- [ ] DS-06 Sheets/modals tokens
- [ ] DS-07 Premium banner non-blocking

### Calculation (7.3)

- [ ] CALC-01 Home vs Income summary
- [ ] CALC-02 Home vs Expense summary
- [ ] CALC-03 One-time income pace rule
- [ ] CALC-04 One-time expense pace rule
- [ ] CALC-05 Net minute pace
- [ ] CALC-06 Currency change
- [ ] CALC-07 Zero income
- [ ] CALC-08 Large amounts

### Income / Expense (7.4)

- [ ] IE-01 Recurring income
- [ ] IE-02 Recurring expense
- [ ] IE-03 One-time income modal
- [ ] IE-04 One-time UX clarity
- [ ] IE-05 Edit amount
- [ ] IE-06 Delete/deactivate
- [ ] IE-07 Custom category gate
- [ ] IE-08 Basic category free
- [ ] IE-09 Recurring automation gate
- [ ] IE-10 Bills/subscriptions rollup

### Savings (7.5)

- [ ] SAV-01 Basic goal free
- [ ] SAV-02 Second goal gated
- [ ] SAV-03 Home remaining
- [ ] SAV-04 Home ETA vs detail
- [ ] SAV-05 Zero/negative pace ETA
- [ ] SAV-06 Quick save from Home
- [ ] SAV-07 Complete goal
- [ ] SAV-08 Premium multiple goals

### Premium / Free (7.6)

- [ ] PF-01 Free Home loop
- [ ] PF-02 Free income/expense/savings
- [ ] PF-03 Free premium features gated
- [ ] PF-04 Premium v1 access
- [ ] PF-05 Paywall dismiss
- [ ] PF-06 No DEBUG toggle in Release
- [ ] PF-07 Offline free usage
- [x] PF-08 `.backupSync` gate active (Phase 9 v1 slice landed)

### Localization smoke (7.7)

- [x] L10N-A01 Catalogs build
- [ ] L10N-A02 Turkish Home
- [ ] L10N-A03 German long labels
- [ ] L10N-A04 Arabic RTL
- [ ] L10N-A05 Paywall strings

### Accessibility smoke (7.8)

- [ ] A11Y-A01 VoiceOver Home
- [ ] A11Y-A02 Dynamic Type AX-Large
- [ ] A11Y-A03 Reduce Motion
- [ ] A11Y-A04 Locked premium row VO
- [ ] A11Y-A05 Chart/ring labels

### Offline (7.9)

- [ ] OFF-01 Airplane launch
- [ ] OFF-02 Offline add persists
- [ ] OFF-03 Premium offline cache
- [ ] OFF-04 No spurious sync errors when signed out

---

## Stage B Checklist

Supabase project SQL and v1 account deletion/backup QA passed on 2026-06-18. CloudKit removal and true row-level sync remain postponed.

- [ ] AUTH-01 through AUTH-09
- [ ] SYNC-01 through SYNC-06
- [ ] FS-01 through FS-04
- [ ] RST-01 through RST-05
- [ ] MERGE-01 through MERGE-03
- [ ] DEL-01 through DEL-04
- [ ] CK-01 through CK-05
- [ ] SEC-01 through SEC-04

---

## Manual Scripts

| Script | Status | Date | Tester |
|--------|--------|------|--------|
| A — First-time user | **NOT RUN** | | |
| B — Returning user upgrade | **NOT RUN** | | |
| C — Premium lifetime | **NOT RUN** | | |
| D — Widget v1 | **NOT RUN** | | |
| E — Auth/sync | **NOT RUN** | | |

---

## Next Actions

1. Run **Script A** on iPhone 17 simulator (first-time user flow).
2. Fix widget extension scheme/signing for G4 manual widget QA.
3. Run StoreKit sandbox matrix (Script C) on physical device.
4. Supabase SQL + Apple provider configured for v1 Stage B on 2026-06-18; re-run before App Store submission.
