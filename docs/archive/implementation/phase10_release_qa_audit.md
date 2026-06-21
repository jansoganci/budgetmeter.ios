# Phase 10 — Release QA Audit Report

**Audit date:** 2026-06-18  
**Auditor:** Automated Phase 10 audit (read-only)  
**Reference destination:** `platform=iOS Simulator,name=iPhone 17,OS=26.5`  
**Source documents:** `implementation_planning_index.md`, `phase10_release_qa_scope.md`, `docs/qa/release_tracker.md`, `docs/qa/known_issues.md`

---

## Executive Summary

### Release readiness score: **22 / 100** — Not ready for release

BudgetMeter has a **strong automated engineering baseline** (G0 pass: clean build, 152/152 unit tests) and **Phases 1–9 implementation largely landed in code**, but **Phase 10 QA execution is in early preflight**. Almost all manual Stage A checklists, StoreKit sandbox validation, migration fixtures, localization/accessibility matrices, device matrix, and Stage B auth/sync QA remain **not started**.

| Dimension | Status | Weight | Score |
|-----------|--------|--------|-------|
| G0 Build/test baseline | **PASS** (2026-06-18) | 15% | 15 |
| Automated test coverage (Phases 1–9) | Strong (152 tests) | 10% | 9 |
| Stage A manual QA (G1–G7) | **3% complete** (2/65 items) | 35% | 1 |
| Stage B auth/sync (G8) | **Blocked** (KI-008) | 15% | 0 |
| Known issues / blockers | 1 Critical, 4 Major open | 10% | 0 |
| App Store readiness (G9) | Not started | 10% | 0 |
| Go/no-go (G10) | Not started | 5% | 0 |
| Widget manual QA (G4) | Unit tests pass; simulator build now succeeds; manual matrix not run | 10% | 2 |

**Bottom line:** Safe to continue **Stage A manual QA** (Script A onward). **Not safe to ship** until G1–G7 are signed, open Critical/Major issues are resolved or waived, and a go/no-go decision is documented.

**Biggest blocker:** **Stage A manual QA has not started** (0/5 scripts run, 63/65 checklist items unchecked). Secondary blockers: **KI-008** (Supabase + Apple Sign In config for Stage B), **G3 StoreKit sandbox** (Script C not run), and **G2 migration fixture matrix** (Script B not run).

---

## 1. Build & Test Baseline (G0)

Audit run: **2026-06-18**

### App build

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

| Result | Details |
|--------|---------|
| **SUCCEEDED** | Exit code 0 |
| Duration | ~9 s (incremental) |
| Widget embed | `BudgetMeterWidgets.appex` embedded in app bundle |

### Full test suite

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -parallel-testing-enabled NO test
```

| Metric | 2026-06-17 (tracker) | 2026-06-18 (this audit) |
|--------|----------------------|-------------------------|
| Total tests | 147 | **152** |
| Passed | 147 | **152** |
| Failed | 0 | **0** |
| Result | TEST SUCCEEDED | **TEST SUCCEEDED** |

**Delta:** +5 tests since last G0 run — new `WidgetDeepLinkRoutingTests` suite (5 tests).

### Widget extension build

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

| Result | Details |
|--------|---------|
| **SUCCEEDED** | Exit code 0; `BudgetMeterWidgets.appex` built and validated |
| Signing | Simulator: "Sign to Run Locally" |

**Note vs known issues:** `release_tracker.md` and KI-003/KI-004 (2026-06-17) record widget build as **BLOCKED**. This audit run shows the **`BudgetMeterWidgets` scheme builds successfully on simulator**. KI-003/KI-004 may be **resolved for simulator Debug** but should be re-verified for **Release archive / physical device provisioning** before closing.

### Release build

| Check | Status |
|-------|--------|
| Release configuration build | **NOT RUN** in this audit |
| DEBUG premium toggle absent in Release | **NOT VERIFIED** |

### G0 verdict

| Check | Status |
|-------|--------|
| App build | **PASS** |
| Full test suite | **PASS** (152/152) |
| Widget extension build (simulator) | **PASS** (updated from prior BLOCKED) |
| Release build | **NOT RUN** |

**G0 overall: PASS** (simulator Debug baseline; Release pending)

---

## 2. Gate Status

From `docs/qa/release_tracker.md`, updated with this audit's G0 re-run.

| Gate | Name | Status | Date | Notes |
|------|------|--------|------|-------|
| **G0** | Build/test baseline | **PASS** | 2026-06-18 | 152/152 tests; build succeeded |
| **G1** | Stage A core QA | **NOT STARTED** | — | 2/65 checklist items checked |
| **G2** | Migration QA | **NOT STARTED** | — | No fixture matrix evidence |
| **G3** | Premium/StoreKit QA | **NOT STARTED** | — | Script C not run; sandbox matrix pending |
| **G4** | Widget QA | **PARTIAL** | — | 15 unit tests pass; simulator build pass; manual W-01–W-18 not run |
| **G5** | Localization/accessibility | **NOT STARTED** | — | L10N-A01 only; full 10-language matrix pending |
| **G6** | Device matrix | **NOT STARTED** | — | No SE/Pro Max/physical device evidence |
| **G7** | Performance smoke | **NOT STARTED** | — | PERF-01–PERF-08 not run |
| **G8** | Stage B auth/sync QA | **NOT STARTED** | — | **Blocked by KI-008** (Supabase SQL + Apple provider) |
| **G9** | App Store readiness | **NOT STARTED** | — | Privacy, metadata, Release archive pending |
| **G10** | Go/no-go | **NOT STARTED** | — | No decision owner/date |

**Gates passed:** 1 / 11 (G0 only)  
**Gates partial:** 1 (G4)  
**Gates blocked:** 1 (G8)

---

## 3. Known Issues Status

From `docs/qa/known_issues.md` — all KI-001 through KI-010.

| ID | Severity | Area | Status | Ship impact |
|----|----------|------|--------|-------------|
| **KI-001** | Minor | Build | **Open** | 8 duplicate `.xcstrings` in Copy Bundle Resources — still present in 2026-06-18 build |
| **KI-002** | Minor | Tests | **Open** | `NSEntityDescription` duplicate warnings during in-memory Core Data test loads — confirmed in test run |
| **KI-003** | Major | Widget | **Likely resolved (simulator)** | Scheme builds on 2026-06-18 audit; tracker still says blocked — needs tracker update |
| **KI-004** | Major | Widget | **Open (device/archive TBD)** | Provisioning profile issue may still apply to non-simulator builds |
| **KI-005** | Major | Localization | **Open** | Hardcoded English in `SavingsGoalDetailView` |
| **KI-006** | Minor | Localization | **Open** | Preview-only hardcoded strings in DesignSystem |
| **KI-007** | Minor | Dev | **Open** | Debug/test views — not ship surfaces |
| **KI-008** | **Critical** | Stage B | **Open** | Live cloud backup QA blocked until Supabase SQL + Apple Sign In provider configured |
| **KI-009** | Major | Privacy | **Open** | Privacy policy may still describe iCloud-only storage |
| **KI-010** | Minor | Naming | **Mitigated** | `LocalizedError` shadowing — mitigated in auth/backup paths |

### Summary

| Severity | Open | Resolved |
|----------|------|----------|
| Critical | 1 (KI-008) | 0 |
| Major | 4 (KI-003*, KI-004, KI-005, KI-009) | 0 |
| Minor | 4 (KI-001, KI-002, KI-006, KI-007) | 1 mitigated (KI-010) |

\* KI-003 may be resolved for simulator Debug builds per this audit.

### Ship waivers

**None approved.**

---

## 4. Stage A Checklist Status

Source: `docs/qa/release_tracker.md` Section 7 checklists.

### Counts by section

| Section | Total | Checked | Unchecked | Complete? |
|---------|-------|---------|-----------|-----------|
| Home (7.1) | 10 | 0 | 10 | No |
| DesignSystem (7.2) | 7 | 0 | 7 | No |
| Calculation (7.3) | 8 | 0 | 8 | No |
| Income / Expense (7.4) | 10 | 0 | 10 | No |
| Savings (7.5) | 8 | 0 | 8 | No |
| Premium / Free (7.6) | 8 | 1 | 7 | No |
| Localization smoke (7.7) | 5 | 1 | 4 | No |
| Accessibility smoke (7.8) | 5 | 0 | 5 | No |
| Offline (7.9) | 4 | 0 | 4 | No |
| **Total** | **65** | **2** | **63** | **No** |

### Checked items

- `[x]` **PF-08** — `.backupSync` gate active (Phase 9 v1 slice landed)
- `[x]` **L10N-A01** — Catalogs build (no missing-key build failures)

### Overall Stage A readiness

| Metric | Value |
|--------|-------|
| Checklist completion | **3.1%** (2/65) |
| Manual scripts run | **0 / 5** |
| Blockers in checklist | 0 filed (none executed yet) |
| **Readiness** | **Not ready** — automated baseline only |

**Pending sections (all):** Home, DesignSystem, Calculation, Income/Expense, Savings, Premium (except PF-08), Localization (except L10N-A01), Accessibility, Offline.

---

## 5. Stage B Checklist Status

Source: `docs/qa/release_tracker.md` — blocked until Supabase SQL applied and Apple Sign In provider configured.

### Counts

| Group | Items | Checked | Status |
|-------|-------|---------|--------|
| Apple Sign In (AUTH-01–09) | 9 | 0 | Blocked |
| Backup/sync (SYNC-01–06) | 6 | 0 | Blocked |
| First sign-in (FS-01–04) | 4 | 0 | Blocked |
| Restore (RST-01–05) | 5 | 0 | Blocked |
| Conflict/merge (MERGE-01–03) | 3 | 0 | Blocked |
| Account deletion (DEL-01–04) | 4 | 0 | Blocked |
| CloudKit transition (CK-01–05) | 5 | 0 | Blocked |
| RLS/security (SEC-01–04) | 4 | 0 | Blocked |
| **Total** | **40** | **0** | **0% — blocked** |

### Blockers

| ID | Blocker | Impact |
|----|---------|--------|
| **KI-008** | Supabase SQL + Apple Sign In provider not configured | Entire Stage B (G8) cannot execute |
| **G1 dependency** | Stage A not passed | Stage B entry criteria not met |

**Stage B readiness: 0% — do not start until KI-008 resolved and Stage A signed.**

---

## 6. Manual Scripts Status

| Script | Purpose | Stage | Status | Date | Tester |
|--------|---------|-------|--------|------|--------|
| **A** | First-time user (~20 min) | A | **NOT RUN** | — | — |
| **B** | Returning user upgrade (~30 min) | A | **NOT RUN** | — | — |
| **C** | Premium lifetime / StoreKit (~25 min) | A | **NOT RUN** | — | — |
| **D** | Widget v1 (~20 min) | A | **NOT RUN** | — | — |
| **E** | Auth/sync (~45 min) | B | **NOT RUN** | — | — |

All five scripts remain **not executed** per `release_tracker.md`.

---

## 7. Test Inventory

### Test files and counts

| Test file | Tests | Primary phase | Focus |
|-----------|-------|---------------|-------|
| `CalculationEngineTests.swift` | 53 | 1 | Formula regression, net flow, health score, live meter |
| `ViewModelCalculationTests.swift` | 15 | 0–1 | Legacy formula consistency, parse amount, realistic scenarios |
| `FinancialSummaryBuilderTests.swift` | 15 | 1, 6 | Shared summary mapping, rollups, savings ETA, biggest drain |
| `FinancialDataMigrationServiceTests.swift` | 10 | 2 | v2/v3 migration, idempotency, legacy frequency |
| `HomeViewModelMappingTests.swift` | 6 | 3 | Home display mapping from builder |
| `IncomeExpenseFlowTests.swift` | 10 | 5 | Entry kind, rollup, automation writes |
| `BasicSavingsIntegrationTests.swift` | 12 | 6 | Primary goal, ETA, free/premium goal limits |
| `PremiumGateMatrixTests.swift` | 8 | 7 | `BudgetMeterCapability` free/premium boundary |
| `WidgetSnapshotStoreTests.swift` | 5 | 8 | App Group snapshot encode/decode |
| `WidgetSnapshotWriterTests.swift` | 5 | 8 | Home → widget snapshot mapping |
| `WidgetDeepLinkRoutingTests.swift` | 5 | 8 | Deep link URLs, locked/unlocked routes |
| `BackupSerializerTests.swift` | 4 | 9 | Export payload, round-trip, schema version |
| `FirstSignInStateMachineTests.swift` | 4 | 9 | Local/cloud/overlap sign-in scenarios |
| `Support/CoreDataMigrationTestSupport.swift` | — | 2 | Test helper (not a test suite) |
| **Total** | **152** | | |

### Phase coverage map

| Phase | Automated tests? | Notes |
|-------|------------------|-------|
| 0 — Codebase audit | Partial | No dedicated audit tests; baseline via build/test |
| 1 — Calculation contract | **Yes** | 53 + 15 + 15 tests |
| 2 — Data model safety | **Yes** | 10 migration tests |
| 3 — Home dashboard | **Yes** | 6 mapping tests |
| 4 — DesignSystem | **No** | Visual/token QA manual only |
| 5 — Income/expense | **Yes** | 10 flow tests |
| 6 — Basic savings | **Yes** | 12 + builder savings cases |
| 7 — Premium cleanup | **Yes** | 8 gate matrix tests |
| 8 — Widget v1 | **Yes** | 15 snapshot/deep-link tests |
| 9 — Auth/Supabase | **Partial** | 4 serializer + 4 state machine; no live Supabase integration tests |
| 10 — Release QA | N/A | QA process, not code phase |

### Coverage gaps

| Gap | Risk | Mitigation |
|-----|------|------------|
| No UI / XCUITest coverage | Regressions in navigation, sheets, paywall | Manual Scripts A–D |
| No StoreKit automated tests | Premium purchase/restore failures | Script C + Section 12 matrix on device |
| No localization tests | Missing keys, RTL overflow | Section 15 matrix |
| No accessibility automated tests | VO/Dynamic Type failures | Section 16 matrix |
| No Insights/chart integration tests | Secondary screen calc drift | Section 11 cross-surface manual |
| No live Supabase/RLS integration tests | Backup/restore security (KI-008) | Stage B Section 8 + SEC-01–04 |
| No CloudKit-existing user fixture tests | Live iCloud upgrade risk | FIX-CLOUDKIT manual (real device) |
| DesignSystem (Phase 4) untested in CI | Visual regressions | Manual DS-01–DS-07 |
| Release configuration untested | DEBUG hooks in Release | Release build + PF-06 |

---

## 8. Known Build Warnings

Observed during 2026-06-18 G0 run.

### Duplicate `.xcstrings` (KI-001)

**8 warnings** — unchanged from tracker:

```
Skipping duplicate build file in Copy Bundle Resources build phase:
  Alerts.xcstrings, Categories.xcstrings, Currency.xcstrings, Debug.xcstrings,
  Home.xcstrings, Settings.xcstrings, UI.xcstrings, Localizable.xcstrings
```

| Severity | Release impact |
|----------|----------------|
| Minor (tracked) | Does not block build; risk of missing runtime strings if wrong copy wins |

### CoreData `NSEntityDescription` warnings (KI-002)

**Present during test execution** — multiple models claim same MO subclasses (`FinancialCategory`, `AppSettings`, etc.) from repeated in-memory Core Data loads in tests.

| Severity | Release impact |
|----------|----------------|
| Minor (tracked) | Tests still pass (152/152); not observed blocking app runtime in this audit |

### New warnings introduced

**None identified** beyond the known KI-001 and KI-002 patterns. No new deprecation or signing warnings on simulator Debug builds.

---

## 9. Gap Analysis vs Scope

Comparison against `phase10_release_qa_scope.md` and `implementation_planning_index.md`.

### Planned vs actual

| Scope item | Planned | Actual (2026-06-18) | Gap |
|------------|---------|---------------------|-----|
| G0 baseline | Required before manual QA | **Done** — 152/152, build pass | Release config not run |
| Stage A checklist (65 items) | 100% before G1 sign-off | **3%** (2/65) | **62 items + 5 scripts** |
| Stage B checklist (40 items) | 100% if Phase 9 in release | **0%** — blocked | KI-008 |
| Phases 1–7 implementation | Required for Stage A | **Verified** in index | — |
| Phase 8 widget v1 | Required if widgets ship | **Implemented**; unit tests pass; simulator build pass | Manual widget matrix (Script D) not run |
| Phase 9 auth/sync | Staged / optional v1 | **v1 slice landed** (code + 8 tests) | Live cloud QA blocked |
| StoreKit sandbox matrix | Section 12 on device | **Not started** | Script C |
| Migration fixture matrix | Section 10 | **Not started** | Script B, FIX-* fixtures |
| 10-language localization | Section 15 | **Not started** (smoke: 1/5) | L10N-A02–A05 |
| Accessibility matrix | Section 16 | **Not started** | A11Y-A01–A05 |
| Device matrix | Section 17 | **Not started** | Physical device for StoreKit + Sign In |
| App Store readiness | Section 19 | **Not started** | KI-009 privacy copy |
| Go/no-go | Section 21 | **Not started** | G10 |

### Scope document staleness

`phase10_release_qa_scope.md` Section 2 still states Phase 8 "not started" and Phase 9 "not started" — **implementation index and codebase have moved ahead** (Phases 8–9 implemented in code). Scope doc should be updated in a future doc pass (outside this read-only audit).

### What's needed for release

1. **Execute Stage A manual QA** — Scripts A, B, C, D + full Section 7 checklist
2. **StoreKit sandbox on physical device** — G3 / Script C
3. **Migration fixture matrix** — G2 / Script B with FIX-V2, FIX-V3, FIX-SAV-*
4. **Localization + accessibility** — G5, 10 languages, AX on SE + standard iPhone
5. **Widget manual matrix** — G4 Script D (W-01–W-18)
6. **Release build + archive smoke** — PF-06, no DEBUG toggle
7. **App Store readiness** — privacy policy (KI-009), metadata, screenshots
8. **If Stage B in v1:** resolve KI-008, run Script E, sign G8
9. **Go/no-go** — G10 with 0 open Blockers

### Biggest blocker

**Stage A manual QA has not begun** — the product cannot be validated for calculation trust, UX, premium boundaries, or offline behavior without Scripts A–C and the 63 remaining checklist items. Automated tests alone do not satisfy Phase 10 exit criteria.

**Secondary blocker (if auth/sync ships):** **KI-008** — Supabase project SQL and Apple Sign In provider must be configured before any Stage B or live backup QA.

---

## 10. Blocker Analysis

| Priority | Blocker | Severity | Gate | Action |
|----------|---------|----------|------|--------|
| 1 | Stage A manual QA not executed | — (process) | G1 | Run Script A on iPhone 17 sim; work through Section 7 |
| 2 | KI-008 Supabase + Apple provider | Critical | G8 | Apply SQL; configure Apple provider in Supabase |
| 3 | StoreKit sandbox not validated | — (process) | G3 | Script C on physical device |
| 4 | KI-005 hardcoded SavingsGoalDetailView strings | Major | G5 | Localize before 10-language sign-off |
| 5 | KI-009 privacy policy accuracy | Major | G9 | Update copy if Supabase backup ships |
| 6 | KI-004 widget provisioning (device/archive) | Major | G4, G9 | Verify Release archive + TestFlight embed |
| 7 | Migration manual fixtures not run | — (process) | G2 | Script B + FIX-V2/V3 matrix |
| 8 | Release build not verified | — (process) | G0, G9 | `-configuration Release build` + archive |

**Hard release rule (from scope):** Any open **Blocker** fails release. Currently **KI-008 is Critical** (Stage B only). No Blocker-severity bugs filed yet from manual QA because manual QA has not run.

---

## 11. Recommended Next Actions (priority order)

1. **Run Script A (first-time user)** on iPhone 17 simulator — file pass/fail against H-*, CALC-*, IE-*, SAV-*, OFF-* IDs; update `release_tracker.md`.
2. **Run Script B (returning user upgrade)** with FIX-V2 fixture — validates G2 migration path.
3. **Fix or waive KI-005** (SavingsGoalDetailView hardcoded strings) before localization matrix.
4. **Run Script C (Premium lifetime)** on **physical device** with sandbox Apple ID — unblocks G3.
5. **Run Script D (Widget v1)** — compare Home hero vs widget; verify W-10–W-18; update G4/KI-003/KI-004 status.
6. **Execute remaining Stage A checklist** — DesignSystem, accessibility, localization smoke (L10N-A02–A05).
7. **Run Release configuration build** — confirm PF-06 (no DEBUG premium toggle).
8. **Apply Supabase SQL + Apple Sign In provider** — unblocks KI-008 and Stage B.
9. **Run Script E + Stage B checklist** — only after steps 1–8 and product confirms Stage B in v1 scope.
10. **Complete G9 App Store readiness** — privacy (KI-009), screenshots, metadata, archive.
11. **G10 go/no-go** — document decision owner, date, waived KI-IDs.

---

## Appendix A — G0 Command Log Summary

| Command | Exit | Result |
|---------|------|--------|
| `budgetmeter.ios` build | 0 | BUILD SUCCEEDED |
| `budgetmeter.ios` test (`-parallel-testing-enabled NO`) | 0 | TEST SUCCEEDED — 152 tests, 0 failures |
| `BudgetMeterWidgets` build | 0 | BUILD SUCCEEDED |

## Appendix B — Test suite breakdown (2026-06-18)

```
BackupSerializerTests              4
BasicSavingsIntegrationTests      12
CalculationEngineTests            53
FinancialDataMigrationServiceTests 10
FinancialSummaryBuilderTests      15
FirstSignInStateMachineTests       4
HomeViewModelMappingTests          6
IncomeExpenseFlowTests            10
PremiumGateMatrixTests             8
ViewModelCalculationTests         15
WidgetDeepLinkRoutingTests         5
WidgetSnapshotStoreTests           5
WidgetSnapshotWriterTests          5
────────────────────────────────────
Total                            152
```

---

*End of Phase 10 Release QA Audit — 2026-06-18*
