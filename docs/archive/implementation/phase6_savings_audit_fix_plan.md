# Phase 6 Savings Audit Fix Plan

Date: 2026-06-17  
Status: Planning complete, implementation not started  
Scope: Define exact fix plan for Phase 6 audit follow-ups without implementing code changes.

## 1. Executive summary

Phase 6 core Home/Savings integration is mostly correct, but 4 follow-up issues must be fixed before Phase 7:

1) savings source-of-truth drift across non-Home surfaces  
2) one-free-goal boundary enforced only in UI  
3) primary-goal nil metadata handling is unspecified  
4) completed goal primary eligibility is not aligned with desired product behavior

This document defines strict product decisions, target files, test requirements, and implementation order for those fixes.

## 2. Audit issues recap

1. **Savings source-of-truth inconsistency**  
   Home and Savings rely on shared summary, but Insights/Health/Notifications/Historical paths still read `AppSettings.savingsGoalAmount` directly.

2. **One-free-goal boundary only UI-gated**  
   `SavingsGoalsViewModel.canAddAnotherGoal` gates the add button, but `SavingsGoalManager.createGoal` has no service-level enforcement.

3. **Primary goal nil-handling**  
   Primary selection uses sort descriptors, but behavior for nil `priority` and nil `createdAt` is not explicit/tested.

4. **Completed goal primary eligibility**  
   Current primary predicate includes completed-but-unarchived goals; desired behavior is to prefer in-progress goals first.

## 3. Current code findings

### Issue 1: source-of-truth

- **Correct canonical path**
  - `FinancialSummaryBuilder.makeInput(...)` in `CoreKit/Sources/Engine/FinancialSummaryBuilder.swift`:
    - `primary SavingsGoal` target/current first
    - `AppSettings.savingsGoalAmount` fallback only
- **Still reading AppSettings directly**
  - `CoreKit/Sources/Services/InsightsService.swift` (`generateGoalProgress`)
  - `Features/HealthFeature/ViewModel/HealthDetailsViewModel.swift` (`fetchFinancialData`)
  - `CoreKit/Sources/Services/HistoricalDataService.swift` (`getCurrentFinancialData`)
  - `CoreKit/Sources/Services/NotificationService.swift` (`checkGoalProgressMilestone`, `createDailyEncouragementContent`)
- **Legacy/fallback acceptable**
  - `CoreKit/Sources/Utilities/FinancialDataMigrationService.swift` (migration path)

### Issue 2: free boundary

- UI gate exists in `Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`:
  - `canAddAnotherGoal = activeGoals.isEmpty || PremiumManager.shared.isPremium`
- Add action respects UI gate in `Features/SavingsGoalsFeature/View/SavingsGoalsView.swift`.
- Service layer has no enforcement in `CoreKit/Sources/Services/SavingsGoalManager.swift`:
  - `createGoal(...)` always creates when data is valid.
- `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift` calls manager create directly.

### Issue 3: nil-handling

- Primary selection is deterministic by sort chain in `SavingsGoalManager`:
  - `priority ASC`, `createdAt ASC`, `targetDate ASC`, `name ASC`, `id ASC`
- No explicit nil normalization policy is documented or tested for:
  - `priority == nil`
  - `createdAt == nil`

### Issue 4: completed-goal eligibility

- Primary query predicate is `isArchived == NO` only.
- Completed-but-unarchived goals are eligible today and can become primary.
- Home summary inherits this selection through `FinancialSummaryBuilder`.

## 4. Product decision for each issue

### Decision A — savings source-of-truth

- Canonical rule remains:
  - `primary active SavingsGoal` is source of truth
  - `AppSettings.savingsGoalAmount` is fallback only when no eligible goal exists
- Required follow-up:
  - non-Home consumers must resolve savings through shared summary or shared resolver using the same rule.

### Decision B — one-free-goal boundary

- Free users: maximum **one non-archived goal**.
- Premium users: multiple goals remain allowed.
- Boundary enforcement must exist at service/domain layer, not UI only.
- Existing paywall/premium infrastructure stays unchanged in this fix set (no StoreKit redesign).

### Decision C — nil metadata handling for primary selection

- Explicit deterministic policy:
  - nil `priority` sorts after non-nil priorities (treat as lowest priority rank).
  - nil `createdAt` sorts after non-nil created dates.
- Tie-breakers stay deterministic after nil normalization.

### Decision D — completed goal primary eligibility

- Required behavior:
  - Prefer in-progress (not completed, not archived) goals first.
  - If no in-progress goals exist, completed-but-unarchived goal may be selected as primary fallback.

## 5. Exact files likely to change

### Core logic

- `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryBuilder.swift`

### Surfaces/services still using AppSettings directly

- `budgetmeter.ios/CoreKit/Sources/Services/InsightsService.swift`
- `budgetmeter.ios/CoreKit/Sources/Services/HistoricalDataService.swift`
- `budgetmeter.ios/CoreKit/Sources/Services/NotificationService.swift`
- `budgetmeter.ios/Features/HealthFeature/ViewModel/HealthDetailsViewModel.swift`

### Boundary/UI consistency touchpoints

- `budgetmeter.ios/Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalsView.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift`
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift` (only if needed for guarded creation path consistency)

### Tests

- `budgetmeter.iosTests/BasicSavingsIntegrationTests.swift`
- `budgetmeter.iosTests/FinancialSummaryBuilderTests.swift`
- add focused test file(s) under `budgetmeter.iosTests/` for boundary + primary-selection rules if coverage becomes too broad in existing files

## 6. Files not allowed to change

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- `budgetmeter.ios.xcodeproj/**`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift` (formula changes out of scope)
- `budgetmeter.ios/CoreKit/Sources/Auth/**`
- `budgetmeter.ios/Widgets/**` (postponed for widget phase)
- StoreKit/premium purchase implementation files beyond boundary checks needed for savings-goal creation path

## 7. Proposed implementation sequence

1. **Test-first rule lock**
   - Add failing tests for boundary, nil metadata handling, and completed-goal priority behavior.
2. **Service-level boundary enforcement**
   - Enforce one-free-goal rule in `SavingsGoalManager.createGoal` and aligned entry paths.
3. **Primary selection rule update**
   - Update eligibility/order to prefer in-progress goals and deterministic nil handling.
4. **Builder alignment check**
   - Ensure `FinancialSummaryBuilder` uses the same primary-selection policy via manager static API.
5. **Cross-surface source-of-truth alignment**
   - Replace direct `AppSettings.savingsGoalAmount` reads in Insights/Health/Historical/Notifications with shared source logic.
6. **UI boundary consistency pass**
   - Keep existing paywall UX, but ensure UI state derives from same boundary definition as service layer.
7. **Regression run**
   - Run full tests and build, document warnings separately from regressions.

## 8. Test plan

### Required additions

- **Boundary tests**
  - Free user cannot create second non-archived goal via service path.
  - Premium user can create multiple goals.
  - Completed goal still counts for free-limit policy (or documented alternative if changed).
- **Primary selection tests**
  - nil `priority` handling determinism.
  - nil `createdAt` handling determinism.
  - tie-breakers deterministic for equal priority/date.
  - completed vs in-progress selection follows new rule.
- **Source-of-truth consistency tests**
  - Insights/Health/Notifications/Historical use `SavingsGoal`/summary-first rule, not AppSettings primary.
- **Regression checks**
  - Existing Phase 6 tests still pass:
    - primary beats AppSettings
    - fallback when no active/eligible goal
    - remaining and ETA behavior

### Verification commands (during implementation phase)

- `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test`
- `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`

## 9. Risks

- Boundary logic drift if UI and service-layer checks use different goal-count definitions.
- Behavior change risk for existing users who currently rely on completed-goal primary selection.
- Cross-surface consistency changes may alter existing notification/insight copy expectations.
- CoreData optional metadata (`priority`, `createdAt`) can produce unexpected ordering if not explicitly normalized.

## 10. What is postponed

- Widget savings source alignment (`budgetmeter.ios/Widgets/**`) to widget phase.
- StoreKit/premium architecture cleanup beyond savings-goal boundary enforcement.
- CoreData schema changes (none required for this fix set).
- Localization cleanup for all savings copy not directly required for the 4 audit issues.

## 11. Success criteria

- Single source-of-truth rule applied consistently across Home, Savings, Insights, Health, Historical, and Notifications for savings target selection.
- Service layer blocks second non-archived goal for non-premium users.
- Primary goal selection is deterministic with explicit nil handling.
- In-progress goals are preferred as primary when available.
- New and existing savings integration tests pass.
- Build and full test suite pass with no new failures.

## 12. Recommendation

- **Ready for fix implementation:** **Yes**  
- **First safe implementation step:** add/lock tests for the 4 issues before code refactors, then implement service-level boundary and primary-selection rules prior to cross-surface source-of-truth alignment.
