# Phase 6 Basic Savings Integration Audit

Date: 2026-06-17  
Auditor: Codex (strict post-implementation verification)  
Scope: Read-only audit of Phase 6 behavior, architecture alignment, premium boundary, data safety, tests, and build/test health.  

## 1. Executive verdict

**PASS WITH RISKS**

Phase 6 core implementation is largely correct for Home + SavingsGoals surfaces and shared summary integration, but there are important residual risks and cross-surface inconsistencies that should be addressed before Phase 7 is considered fully safe.

## 2. Scope compliance

### What matched Phase 6 scope

- Deterministic primary goal selection exists and is shared:
  - `SavingsGoalManager.getPrimaryActiveGoal()` and `SavingsGoalManager.primaryActiveGoal(in:)` both use the same sort descriptor chain.
  - `FinancialSummaryBuilder` uses `SavingsGoalManager.primaryActiveGoal(in:)` directly.
- Source-of-truth precedence is implemented in summary builder:
  - Primary active `SavingsGoal` is preferred over `AppSettings.savingsGoalAmount`.
  - `AppSettings.savingsGoalAmount` is fallback when no active goal exists.
- Home quick-save writes through `SavingsGoal` via `upsertPrimaryBasicGoal` in `HomeViewModel.updateSavingsGoal(_:)`.
- Shared ETA path is used:
  - Home uses `HomeDisplayMapping.formatSavingsETA(from:)` backed by `FinancialSummary`.
  - Savings list/detail surfaces use shared ETA for the primary goal path.
- No CoreData/Xcode/Swift calculation formula edits beyond intended Phase 6/related prior phases.
- Existing paywall path is reused (`PremiumPaywallView`), and no new StoreKit logic was added in reviewed Phase 6 files.

### Anything outside scope

- Savings screens still contain legacy target-date pacing logic (`calculateRequiredMonthlyContribution`, `isPaceStatus`) and independent date-based copy. It is presented as additional info, but still parallel logic.
- Non-Phase-6 surfaces/services still use `AppSettings.savingsGoalAmount` as primary savings input (details in Bugs/Risks).

## 3. Architecture review

### Source of truth

- **Pass (within Phase 6 target surfaces):**
  - `FinancialSummaryBuilder.makeInput(...)` sets:
    - `savingsTarget = primaryGoal.targetAmount ?? appSettings.savingsGoalAmount ?? 0`
    - `savingsCurrent = primaryGoal.currentAmount ?? 0`
  - Home and SavingsGoalsViewModel consume summary outputs for ETA and remaining.
- **Risk (cross-surface):**
  - `InsightsService`, `HealthDetailsViewModel`, `HistoricalDataService`, and `NotificationService` still directly use `AppSettings.savingsGoalAmount`.

### FinancialSummary usage

- **Pass for Home + SavingsGoals primary display path:**
  - Home uses `latestSummary` for `savingsRemaining`, `savingsTimeToGoal`, and formatted ETA copy.
  - SavingsGoalsViewModel uses `sharedPaceETAText(for:)` from summary for primary goal.
- **Risk:**
  - Detail/input screens still show date-based required-monthly/pacing logic in parallel (secondary display), which can diverge from shared pace interpretation.

### Savings manager behavior

- Deterministic rule is implemented consistently (`priority ASC`, then `createdAt ASC`, then stable tie-breakers).
- `upsertPrimaryBasicGoal` is idempotent for the primary selected row (updates existing instead of creating new).
- Archived goals are excluded by predicate (`isArchived == NO`).
- Completed goals are not excluded from primary selection (could be intended, but should be explicitly confirmed).

## 4. Data safety review

- No CoreData schema change introduced by this audit (read-only verification).
- Existing users with only legacy `AppSettings.savingsGoalAmount` still receive fallback via `FinancialSummaryBuilder`.
- Quick-save does not create duplicate primary goals; it updates existing primary if present.
- Upsert path is idempotent at manager level for repeated Home quick-save updates.
- Deleted/archived goals are excluded from primary selection via `isArchived == NO`.
- **Risk:** nil `priority` / nil `createdAt` ordering behavior is not explicitly guarded or tested.

## 5. Premium boundary review

- One-goal free UX gate exists (`SavingsGoalsViewModel.canAddAnotherGoal` + add button routing to paywall).
- Existing paywall path is reused (`PremiumPaywallView`).
- No new StoreKit logic in reviewed Phase 6 implementation files.
- **Risk:** Gate is enforced at UI/view-model level, not in `SavingsGoalManager.createGoal`; programmatic paths could still create multiple active goals.
- No clear evidence Phase 7 premium cleanup was implemented early in reviewed files.

## 6. UI behavior review

- Home savings display is stable and bound to shared summary (`HomeViewModel.applyFinancialSummary`).
- SavingsGoals list shows shared ETA for primary goal and keeps target-date required-monthly as additional information.
- SavingsGoalDetailView shows shared pace estimate in a dedicated card, while target-date required-monthly remains separate.
- No broad redesign outside expected Phase 6 savings/home integration was found in inspected files.
- **Minor UX risk:** Hardcoded English strings remain in several savings views (localization completeness risk, not a core contract break).

## 7. Test coverage review

### Strengths

- `FinancialSummaryBuilderTests` covers key Phase 6 savings contract points:
  - primary goal beats AppSettings
  - AppSettings fallback
  - missing current saved -> 0
  - remaining amount and completed goal
  - zero/negative pace -> no ETA
  - ETA based on recurring pace (one-time windfall ignored)
  - deterministic selection among multiple active goals
- `BasicSavingsIntegrationTests` covers:
  - Home quick-save writes to SavingsGoal path
  - manager/builder primary selection alignment
  - shared ETA formatting path
  - basic free-boundary check via `canAddAnotherGoal`

### Gaps

- No explicit tests for nil `priority` and nil `createdAt` behavior.
- No test that tie-breakers remain deterministic for equal priority + equal createdAt + nil name/id edge.
- No test that completed-but-not-archived goals should/should-not be selected as primary.
- No strict integration test proving second goal creation is blocked across all creation paths (service-level enforcement absent).
- No UI-level assertion that target-date required-monthly remains clearly secondary and cannot override shared ETA.

## 8. Build/test results

Commands executed:

1) Initial build attempt  
`xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`  
Result: **FAILED** (environment/concurrency issue)  
Error: build database lock (`build.db: database is locked`), indicating concurrent build DB access.

2) Build with isolated DerivedData  
`xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/budgetmeter_phase6_audit build`  
Result: **BUILD SUCCEEDED**  
Notes: duplicate `.xcstrings` resource warnings persist.

3) Full test suite with isolated DerivedData  
`xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/budgetmeter_phase6_audit test`  
Result: **TEST SUCCEEDED**  
Summary: **115 tests, 0 failures**  
Notes: repeated CoreData `NSEntityDescription` duplicate-match warnings still appear in test logs (non-failing).

## 9. Bugs found

### High

1. **Savings source-of-truth is still inconsistent outside Home/Savings surfaces**  
   - `InsightsService`, `HealthDetailsViewModel`, `HistoricalDataService`, and `NotificationService` still read `AppSettings.savingsGoalAmount` directly and use independent savings logic.  
   - Impact: users can see different savings interpretation across app surfaces despite Phase 6 source-of-truth goal.

### Medium

2. **Primary selection nil-handling is unspecified and untested**  
   - Selection relies on sort descriptors over optional `priority` and `createdAt` without explicit nil normalization.  
   - Impact: legacy/malformed rows with nil metadata may become primary unexpectedly.

3. **Premium one-goal boundary is UI-gated, not service-enforced**  
   - `SavingsGoalManager.createGoal` has no premium/limit guard.  
   - Impact: non-UI/programmatic paths can bypass one-goal free boundary.

4. **Completed goals can still be selected as “primary active”**  
   - Predicate filters only `isArchived == NO`; completed-but-unarchived goals remain eligible.  
   - Impact: ETA/primary behavior may favor a completed goal over an in-progress goal depending on ordering.

### Low

5. **Localization debt in savings UI copy**  
   - Several strings in savings views remain hardcoded English.  
   - Impact: i18n inconsistency; not a blocker for savings contract correctness.

## 10. Missing tests

- Add deterministic-primary tests for:
  - `priority == nil` vs non-nil cases
  - `createdAt == nil` vs non-nil cases
  - equal-priority/equal-createdAt tie-break determinism
- Add behavior tests for completed goal eligibility in primary selection.
- Add service-level boundary test for second active goal creation when non-premium.
- Add integration/UI test ensuring target-date required-monthly never overrides shared ETA messaging hierarchy.
- Add cross-surface consistency tests (Home/Savings/Insights/Health) for savings source-of-truth.

## 11. Required fixes before Phase 7

1. Align all savings-consuming surfaces/services to the same primary source contract (primary `SavingsGoal`, legacy AppSettings fallback only where explicitly intended).
2. Define and enforce primary selection behavior for nil `priority`/`createdAt` and cover with tests.
3. Enforce one-goal free boundary at service/domain layer (not only UI).
4. Decide whether completed goals should be eligible primary; codify and test.

## 12. Safe to start Phase 7?

**No (strict audit stance).**

Reason: Phase 6 core path works for Home and Savings screens, but source-of-truth and premium-boundary enforcement are still not robust across the app/service layer. Phase 7 can proceed safely after the required fixes above are addressed or formally accepted as deferred risk with explicit sign-off.
