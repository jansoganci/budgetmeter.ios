# Phase 10 — Release QA Audit Prompt

## Goal
Create a comprehensive audit document at `docs/implementation/phase10_release_qa_audit.md` that analyzes the current Phase 10 Release QA status. DO NOT modify any source code — this is a read-only audit.

## Background
Read first: `docs/implementation/implementation_planning_index.md` (Phase 10 section), `docs/implementation/phase10_release_qa_scope.md`, `docs/qa/release_tracker.md`, and `docs/qa/known_issues.md`

## What to audit

### 1. Build & Test Baseline (G0)
- Run `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` and report result
- Run `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -parallel-testing-enabled NO test` and report result
- How many tests total? Are there any failures?
- Check if widget extension build works: `xcodebuild -scheme BudgetMeterWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`

### 2. Gate Status (from release_tracker.md)
Read `docs/qa/release_tracker.md` and report the status of each gate:
- G0: Build/test baseline
- G1: Stage A core QA
- G2: Migration QA
- G3: Premium/StoreKit QA
- G4: Widget QA
- G5: Localization/accessibility
- G6: Device matrix
- G7: Performance smoke
- G8: Stage B auth/sync QA
- G9: App Store readiness
- G10: Go/no-go

### 3. Known Issues (from known_issues.md)
Read `docs/qa/known_issues.md` and report:
- All open issues (KI-001 to KI-010)
- Severities
- Which are resolved vs still open
- Are there any ship waivers?

### 4. Stage A Checklist Status
Read the Stage A checklist from release_tracker.md:
- How many items checked vs unchecked?
- Which sections are complete vs pending?
- What's the overall Stage A readiness?

### 5. Stage B Checklist Status
Read the Stage B checklist:
- How many items checked vs unchecked?
- Are there blockers? (KI-008)

### 6. Manual Scripts
Read the manual scripts section:
- Script A (first-time user) — run?
- Script B (returning user) — run?
- Script C (premium lifetime) — run?
- Script D (widget v1) — run?
- Script E (auth/sync) — run?

### 7. Test Inventory
Read all test files in budgetmeter.iosTests/:
- List all test files and their test counts
- Are there tests for all phases (0-9)?
- Any gaps in test coverage?

### 8. Known Build Warnings
Check for:
- Duplicate .xcstrings warnings
- CoreData NSEntityDescription warnings
- Any new warnings introduced

### 9. Gap Analysis vs Scope
Compare against the phase10 scope doc:
- What was planned vs what's actually done?
- What's needed for a release?
- What's the biggest blocker?

## Output
Write everything to `docs/implementation/phase10_release_qa_audit.md` as a structured audit report with:
- Executive summary with release readiness score
- Gate-by-gate status table
- Known issues status
- Blocker analysis
- Test coverage report
- Recommended next actions in priority order
