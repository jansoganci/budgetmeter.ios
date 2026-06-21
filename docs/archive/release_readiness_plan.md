# BudgetMeter iOS — Release Readiness Action Plan

**Created:** 2026-06-18  
**Based on:** `docs/implementation/phase10_release_qa_audit.md`, `docs/qa/release_tracker.md`, `docs/qa/known_issues.md`  
**Current score:** 22 / 100 — **Not ready for release**

---

## Executive Summary

BudgetMeter has a strong automated baseline (G0: 152/152 tests, simulator build passes) but **Phase 10 manual QA has barely started** (2/65 checklist items, 0/5 scripts run). Shipping is blocked until Stage A is executed and signed, open Critical/Major issues are resolved or waived, and G10 go/no-go is documented.

**Critical path:**

```
G0 (done) → Code fixes (KI-005, etc.) → Script A → Script B → Script C (device)
  → Remaining Stage A checklist → G1–G7 sign-off
  → [If Stage B in v1] KI-008 config → Script E → G8
  → G9 App Store → G10 Go/No-Go
```

**Scope decision required:** Confirm whether Stage B (auth/sync) ships in v1. If **no**, KI-008 blocks G8 only — Stage A can still ship a local-first build. If **yes**, KI-008 is on the critical path.

---

## Legend

| Symbol | Meaning |
|--------|---------|
| **Cursor** | Automated: code changes, tests, builds, doc updates |
| **User** | Manual: simulator/device QA, Apple Developer, App Store Connect, legal |
| **Effort** | S = <1 hr · M = 1–3 hr · L = half day+ · XL = multi-day |

---

## Part 1 — What Cursor Can Do

These steps can be executed in the IDE without a physical device or Apple Developer portal access.

---

### Step C1 — Maintain G0 baseline

| Field | Value |
|-------|-------|
| **What** | Re-run app build, full test suite (152 tests), and widget extension build on reference simulator (`iPhone 17, OS 26.5`). Record results in `release_tracker.md`. |
| **Who** | Cursor |
| **Effort** | S (~15 min) |
| **Dependencies** | None — can run anytime |

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build

xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -parallel-testing-enabled NO test

xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

---

### Step C2 — Fix KI-005: localize SavingsGoalDetailView strings

| Field | Value |
|-------|-------|
| **What** | Replace remaining hardcoded English in `SavingsGoalDetailView` (Target Date, Add Money, Withdraw, Notes, sheet titles). Add keys to `UI.xcstrings` for all 10 languages. |
| **Who** | Cursor |
| **Effort** | M (~1–2 hr) |
| **Dependencies** | None |
| **Gate impact** | G5 (localization matrix) |

**Files:** `Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift`, `Resources/UI.xcstrings`

---

### Step C3 — Fix KI-001: duplicate `.xcstrings` in Copy Bundle Resources

| Field | Value |
|-------|-------|
| **What** | Remove duplicate entries for 8 `.xcstrings` files in `project.pbxproj` Copy Bundle Resources phase. |
| **Who** | Cursor |
| **Effort** | S (~30 min) |
| **Dependencies** | None |
| **Gate impact** | G0 cleanliness |

---

### Step C4 — Run Release configuration build

| Field | Value |
|-------|-------|
| **What** | Build with `-configuration Release`. Verify PF-06: no DEBUG premium toggle in Release binary. |
| **Who** | Cursor |
| **Effort** | S (~30 min) |
| **Dependencies** | C1 pass |
| **Gate impact** | G0, G9 (pre-submission build) |

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

---

### Step C5 — Update QA tracker for resolved items

| Field | Value |
|-------|-------|
| **What** | Update `release_tracker.md` and `known_issues.md`: mark KI-003 as resolved for simulator Debug (per 2026-06-18 audit); refresh G0 date to 2026-06-18; note widget extension simulator build now passes. |
| **Who** | Cursor |
| **Effort** | S (~15 min) |
| **Dependencies** | C1 pass |
| **Gate impact** | Documentation accuracy |

---

### Step C6 — Prepare migration test fixtures (FIX-V2, FIX-V3)

| Field | Value |
|-------|-------|
| **What** | Document or script how to produce FIX-V2 (pre-`entryKind` v2 store) and FIX-V3 (mixed rows) fixtures for Script B. Leverage `FinancialDataMigrationServiceTests` and `CoreDataMigrationTestSupport`. |
| **Who** | Cursor |
| **Effort** | M (~2 hr) |
| **Dependencies** | None |
| **Gate impact** | G2 — unblocks User step U3 (Script B) |

---

### Step C7 — Draft KI-009 privacy policy updates

| Field | Value |
|-------|-------|
| **What** | If Stage B ships in v1: draft updated privacy policy text covering Supabase backup, Apple Sign In, account deletion, and local vs cloud data. Flag for User legal review. |
| **Who** | Cursor (draft) → User (approve) |
| **Effort** | M (~1–2 hr draft) |
| **Dependencies** | Product decision: Stage B in v1? |
| **Gate impact** | G9, KI-009 |

---

### Step C8 — Verify widget archive embedding (KI-004 investigation)

| Field | Value |
|-------|-------|
| **What** | Inspect `project.pbxproj` and entitlements for widget extension provisioning setup. Attempt Release archive build; document any signing errors for User to fix in Apple Developer portal. |
| **Who** | Cursor (investigate) → User (fix provisioning if needed) |
| **Effort** | M (~1 hr) |
| **Dependencies** | C4 |
| **Gate impact** | G4, G9 |

---

### Step C9 — Add missing localization keys surfaced during QA

| Field | Value |
|-------|-------|
| **What** | As User files failures from L10N-A02–A05 and full Section 15 matrix, Cursor adds missing keys and fixes overflow-prone layouts. |
| **Who** | Cursor |
| **Effort** | M–L (iterative) |
| **Dependencies** | User steps U5, U6 |
| **Gate impact** | G5 |

---

### Step C10 — Fix bugs filed from manual QA

| Field | Value |
|-------|-------|
| **What** | Triage and fix Blocker/Critical/Major issues filed during Scripts A–E and checklist execution. Route to owning phase per scope doc. |
| **Who** | Cursor |
| **Effort** | L–XL (depends on findings) |
| **Dependencies** | User manual QA steps |
| **Gate impact** | G1–G8 |

---

## Part 2 — What the User Must Do Manually

These steps require human judgment, physical devices, sandbox accounts, or Apple Developer / App Store Connect access.

---

### Step U0 — Confirm v1 release scope (product decision)

| Field | Value |
|-------|-------|
| **What** | Document which ship in v1: local core (Phases 1–7) **required**, widget v1 **yes/no**, Stage B auth/sync **yes/no**. This determines whether KI-008 and G8 are blocking. |
| **Who** | User (Product) |
| **Effort** | S (~30 min meeting) |
| **Dependencies** | None — **do this first** |
| **Gate impact** | G8, G9, G10 |

---

### Step U1 — Run Script A: First-time user (~20 min)

| Field | Value |
|-------|-------|
| **What** | Fresh install on iPhone 17 simulator. Walk through first-time flow per scope doc Section 20 Script A. Pass/fail and check off Section 7 items: **H-01–H-10**, **CALC-01–CALC-08**, **IE-01–IE-10**, **SAV-01–SAV-07**, **OFF-01–OFF-02**. Take screenshots. |
| **Who** | User |
| **Effort** | M (~20–40 min) |
| **Dependencies** | C1 pass; U0 scope confirmed |
| **Gate impact** | G1 (partial) |

**Script A steps (summary):**
1. Fresh install → land on Home (H-01, H-07)
2. Add $5,000/mo income, $2,000/mo expense → verify pace (H-02–H-04, CALC-01–CALC-02)
3. Add $100 one-time expense → long-term pace unchanged (CALC-03–CALC-04)
4. Create savings goal $10k / $1k saved → ETA on Home (SAV-01, SAV-03–SAV-04, H-06)
5. Expense tab summary matches (CALC-02, IE-10)
6. Airplane mode → add expense → relaunch persists (OFF-01–OFF-02)

---

### Step U2 — Run Script A continued: DesignSystem + Premium smoke

| Field | Value |
|-------|-------|
| **What** | During or after Script A, verify **DS-01–DS-07**, **PF-01–PF-05**, **PF-07**, tab stability (H-09), background/foreground (H-10), pull to refresh (H-08). |
| **Who** | User |
| **Effort** | M (~30 min) |
| **Dependencies** | U1 |
| **Gate impact** | G1 |

---

### Step U3 — Run Script B: Returning user upgrade (~30 min)

| Field | Value |
|-------|-------|
| **What** | Install over FIX-V2 fixture. Verify migration, data integrity, DE overflow, AR RTL. Check off **G2** migration matrix items. |
| **Who** | User |
| **Effort** | M (~30–45 min) |
| **Dependencies** | C6 (fixtures ready); U1 pass |
| **Gate impact** | G2 |

**Covers checklist indirectly:** migration safety for savings (SAV-*), calculation consistency post-upgrade (CALC-*), localization smoke L10N-A03–A04.

---

### Step U4 — Run Script C: Premium lifetime / StoreKit sandbox (~25 min) — **PHYSICAL DEVICE**

| Field | Value |
|-------|-------|
| **What** | On a **physical device** with sandbox Apple ID(s): execute Section 12 matrix (SK-01–SK-13). Complete purchase, cancel, restore, offline premium, feature unlock. Verify PF-04–PF-06, **SAV-02**, **SAV-08**. |
| **Who** | User |
| **Effort** | L (~45–90 min with 2 sandbox accounts) |
| **Dependencies** | App Store Connect: IAP `com.budgetmeter.premium.lifetime` configured; 2+ sandbox Apple IDs; U1 pass |
| **Gate impact** | **G3** |

**StoreKit cases to verify:**

| Case | Action |
|------|--------|
| SK-02 | Purchase lifetime → premium unlocks |
| SK-03 | Cancel → remains free |
| SK-06–SK-07 | Premium persists relaunch + offline |
| SK-08 | Restore with no purchase → clear message |
| SK-09 | Restore on fresh install → premium returns |
| SK-11–SK-12 | Premium features vs free paywall |
| SK-13 | Release build: no DEBUG toggle (with C4) |

---

### Step U5 — Run Script D: Widget v1 (~20 min)

| Field | Value |
|-------|-------|
| **What** | Premium user with data: add `systemSmall` widget, compare to Home hero (W-10). Free user: locked teaser (W-12–W-13). Tap deep links (W-14). Stale/missing snapshot (W-15–W-16). Currency change (W-17). Purchase unlock (W-18). Check W-01–W-05 scope enforcement. |
| **Who** | User |
| **Effort** | M (~20–40 min) |
| **Dependencies** | U4 (premium state); C8 widget signing OK for device if needed |
| **Gate impact** | **G4** |

---

### Step U6 — Localization smoke: L10N-A02–A05

| Field | Value |
|-------|-------|
| **What** | Switch device language and verify: Turkish Home (L10N-A02), German long labels (L10N-A03), Arabic RTL (L10N-A04), Paywall strings (L10N-A05). File overflow/RTL issues for Cursor (C9). |
| **Who** | User |
| **Effort** | M (~1 hr for smoke; L for full 10-language Section 15 matrix) |
| **Dependencies** | C2 (KI-005 fix) recommended before full pass |
| **Gate impact** | **G5** |

---

### Step U7 — Accessibility smoke: A11Y-A01–A05

| Field | Value |
|-------|-------|
| **What** | VoiceOver on Home (A11Y-A01), Dynamic Type AX-Large (A11Y-A02), Reduce Motion ring (A11Y-A03, DS-04), locked premium row VO (A11Y-A04), chart/ring labels (A11Y-A05). |
| **Who** | User |
| **Effort** | M (~1 hr smoke; L for full Section 16 matrix) |
| **Dependencies** | U1 |
| **Gate impact** | **G5** |

---

### Step U8 — Offline checklist: OFF-03–OFF-04

| Field | Value |
|-------|-------|
| **What** | Premium offline cache (OFF-03): force-quit offline, relaunch — premium still active. Signed-out state (OFF-04): no spurious sync errors when not signed in. |
| **Who** | User |
| **Effort** | S (~15 min) |
| **Dependencies** | U4 (premium state) |
| **Gate impact** | G1 |

---

### Step U9 — Device matrix (G6) + Performance smoke (G7)

| Field | Value |
|-------|-------|
| **What** | Section 17: iPhone SE, standard, Pro Max — dark/light. Section 18: PERF-01–PERF-08 launch, scroll, memory smoke. |
| **Who** | User |
| **Effort** | L (~half day) |
| **Dependencies** | U1–U5 core paths pass |
| **Gate impact** | **G6**, **G7** |

---

### Step U10 — Configure KI-008: Supabase + Apple Sign In — **IF Stage B in v1**

| Field | Value |
|-------|-------|
| **What** | 1) Apply `docs/supabase/phase9_user_backups.sql` in Supabase SQL editor. 2) Configure Apple Sign In provider in Supabase Auth dashboard (Services ID, key, team ID). 3) Verify entitlements in Xcode match Apple Developer portal. |
| **Who** | User |
| **Effort** | L (~2–4 hr first time) |
| **Dependencies** | U0 (Stage B in scope); Supabase project access; Apple Developer account |
| **Gate impact** | **KI-008**, **G8** — unblocks entire Stage B |

---

### Step U11 — Run Script E: Auth/sync (~45 min) — **IF Stage B in v1**

| Field | Value |
|-------|-------|
| **What** | Local premium user → Sign in with Apple → backup → delete app → reinstall → restore → verify totals. Sign out — local data remains. Execute Stage B checklist: AUTH-01–09, SYNC-01–06, FS-01–04, RST-01–05, MERGE-01–03, DEL-01–04, CK-01–05, SEC-01–04. |
| **Who** | User |
| **Effort** | L (~1–2 hr) |
| **Dependencies** | U10 (KI-008 resolved); U1 pass; Stage A signed |
| **Gate impact** | **G8** |

---

### Step U12 — Resolve KI-009: Privacy policy + in-app legal

| Field | Value |
|-------|-------|
| **What** | Review and publish updated privacy policy (not iCloud-only if Supabase ships). Verify in-app links, App Privacy labels in App Store Connect, account deletion path, local reset vs cloud delete copy. |
| **Who** | User (Legal/Product) — Cursor drafted in C7 |
| **Effort** | M (~2–3 hr) |
| **Dependencies** | U0 scope; U10 if auth ships |
| **Gate impact** | **G9**, **KI-009** |

---

### Step U13 — App Store readiness (G9)

| Field | Value |
|-------|-------|
| **What** | Section 19 checklist: Release archive + TestFlight upload; screenshots (redesigned Home); metadata; IAP configured; review notes with sandbox test account; dSYM; entitlements audit; age rating. |
| **Who** | User |
| **Effort** | L (~1 day) |
| **Dependencies** | G1–G7 signed (or waived); C4 Release build; C8 widget provisioning; U4 StoreKit validated |
| **Gate impact** | **G9** |

| Item | Action |
|------|--------|
| App icon | Matches current brand |
| Screenshots | Redesigned Home, not legacy |
| IAP | `com.budgetmeter.premium.lifetime` live |
| Review notes | Sandbox Apple ID instructions |
| Pre-submission | Release archive succeeds on device |

---

### Step U14 — Gate sign-offs G1–G7

| Field | Value |
|-------|-------|
| **What** | Record pass dates and owners in `release_tracker.md` for each gate once its criteria are met. |
| **Who** | User (QA + Product + Engineering) |
| **Effort** | S (documentation) |
| **Dependencies** | Respective steps above |

| Gate | Criteria | Unblocked by |
|------|----------|--------------|
| G1 | Section 7 checklist 100%, 0 Blockers | U1–U8 |
| G2 | Section 10 fixture matrix | U3 |
| G3 | Section 12 StoreKit matrix | U4 |
| G4 | Section 13 widget matrix | U5 |
| G5 | Sections 15–16 matrices | U6, U7, C2, C9 |
| G6 | Section 17 device matrix | U9 |
| G7 | Section 18 performance smoke | U9 |

---

### Step U15 — Go / No-Go decision (G10)

| Field | Value |
|-------|-------|
| **What** | Complete Section 21 checklist. Document: release version, build number, Stage A/B results, decision (Go/No-Go), owner, date, remaining blockers, waived KI-IDs. |
| **Who** | User (Release owner) |
| **Effort** | S (~1 hr meeting + doc) |
| **Dependencies** | G0–G9 per scope; 0 open Blockers; Critical issues resolved or waived |
| **Gate impact** | **G10** |

**Hard rule:** Any open **Blocker** = No-Go. Currently no Blockers filed (manual QA not run yet). **KI-008 is Critical** — blocks Stage B only.

---

## Part 3 — Stage A Checklist Reference (63 items remaining)

Quick map of unchecked items to scripts/steps. Already done: **PF-08**, **L10N-A01**.

| Section | IDs | Covered by |
|---------|-----|------------|
| Home 7.1 | H-01–H-10 | U1, U2 |
| DesignSystem 7.2 | DS-01–DS-07 | U2 |
| Calculation 7.3 | CALC-01–CALC-08 | U1, U3 |
| Income/Expense 7.4 | IE-01–IE-10 | U1 |
| Savings 7.5 | SAV-01–SAV-08 | U1, U4 |
| Premium/Free 7.6 | PF-01–PF-07 | U2, U4, C4 |
| Localization 7.7 | L10N-A02–A05 | U3, U6 |
| Accessibility 7.8 | A11Y-A01–A05 | U7 |
| Offline 7.9 | OFF-01–OFF-04 | U1, U8 |

---

## Part 4 — Recommended Execution Order

### Wave 1 — Unblock QA (Day 1)

| # | Step | Who | Effort |
|---|------|-----|--------|
| 1 | U0 — Confirm v1 scope | User | S |
| 2 | C1 — G0 baseline re-run | Cursor | S |
| 3 | C2 — Fix KI-005 | Cursor | M |
| 4 | C5 — Update tracker (KI-003) | Cursor | S |
| 5 | C6 — Migration fixtures | Cursor | M |
| 6 | U1 — Script A | User | M |

### Wave 2 — Core validation (Days 2–3)

| # | Step | Who | Effort |
|---|------|-----|--------|
| 7 | U2 — DesignSystem + Premium smoke | User | M |
| 8 | U3 — Script B (migration) | User | M |
| 9 | C4 — Release build | Cursor | S |
| 10 | U4 — Script C StoreKit (**device**) | User | L |
| 11 | C8 — Widget archive check | Cursor | M |
| 12 | U5 — Script D Widget | User | M |

### Wave 3 — Polish gates (Days 4–5)

| # | Step | Who | Effort |
|---|------|-----|--------|
| 13 | U6 — Localization smoke/matrix | User | M–L |
| 14 | U7 — Accessibility smoke | User | M |
| 15 | U8 — OFF-03/04 | User | S |
| 16 | C9 — Fix localization issues | Cursor | M |
| 17 | U9 — Device + performance | User | L |
| 18 | U14 — Sign G1–G7 | User | S |

### Wave 4 — Stage B (only if in v1 scope)

| # | Step | Who | Effort |
|---|------|-----|--------|
| 19 | U10 — KI-008 Supabase + Apple config | User | L |
| 20 | C7 — Privacy policy draft | Cursor | M |
| 21 | U11 — Script E auth/sync | User | L |
| 22 | U12 — KI-009 privacy final | User | M |

### Wave 5 — Ship (Days 6–7)

| # | Step | Who | Effort |
|---|------|-----|--------|
| 23 | U13 — App Store readiness (G9) | User | L |
| 24 | C10 — Fix any late QA bugs | Cursor | varies |
| 25 | U15 — G10 Go/No-Go | User | S |

---

## Part 5 — Known Issues Action Map

| ID | Severity | Action | Who | Blocks |
|----|----------|--------|-----|--------|
| **KI-005** | Major | Localize `SavingsGoalDetailView` | Cursor (C2) | G5 |
| **KI-008** | Critical | Supabase SQL + Apple provider | User (U10) | G8, Stage B |
| **KI-009** | Major | Update privacy policy for Supabase | User (U12), Cursor drafts (C7) | G9 |
| KI-003 | Major | Simulator build fixed — update tracker | Cursor (C5) | G4 doc |
| KI-004 | Major | Release archive / device provisioning | Cursor investigates (C8), User fixes portal | G4, G9 |
| KI-001 | Minor | Dedupe `.xcstrings` in pbxproj | Cursor (C3) | — |
| KI-002 | Minor | Core Data test warnings | Cursor (optional) | — |
| KI-006 | Minor | Preview-only strings | Waive or fix later | — |
| KI-007 | Minor | Debug views | Waive (not ship surfaces) | — |
| KI-010 | Minor | Mitigated | No action | — |

**Ship waivers:** None approved. Any waiver must be documented in G10 with KI-ID.

---

## Part 6 — Go/No-Go Prerequisites (G10)

All must be true for **Go**:

- [ ] G0 recorded (152/152 tests, build pass)
- [ ] 0 open Blockers from manual QA
- [ ] 0 open Critical — or explicit waivers (KI-008 waived only if Stage B out of v1)
- [ ] G1 Stage A signed (65/65 checklist)
- [ ] G2 migration matrix complete
- [ ] G3 StoreKit sandbox complete (physical device)
- [ ] G4 widget matrix complete (if widgets in v1)
- [ ] G5 localization + accessibility signed
- [ ] G6 device matrix complete
- [ ] G7 performance smoke complete
- [ ] G8 Stage B signed — or **N/A** if auth/sync not in v1
- [ ] G9 App Store assets + privacy accurate (KI-009 closed)
- [ ] Release archive smoke-tested on device
- [ ] Decision owner + date recorded in `release_tracker.md`

---

## Part 7 — Risk Summary

| Risk | Mitigation |
|------|------------|
| Manual QA never started | **Biggest blocker** — start U1 (Script A) immediately |
| StoreKit untested on device | U4 before any premium marketing claims |
| Migration data loss | U3 with FIX-V2/V3 before wide rollout |
| Privacy policy inaccurate | U12 before submission if Supabase ships |
| Widget fails on TestFlight | C8 + U5 before G9 archive |
| Stage B ships without config | Do not enable `.backupSync` until U10 + U11 pass |

---

## Quick Start — Do These Three Things Now

1. **User:** Run **U0** — decide if Stage B is in v1.
2. **User:** Run **U1** — Script A on iPhone 17 simulator (~20 min).
3. **Cursor:** Run **C2** — fix KI-005 before localization matrix.

---

*This plan is a living document. Update step status in `docs/qa/release_tracker.md` as work completes.*
