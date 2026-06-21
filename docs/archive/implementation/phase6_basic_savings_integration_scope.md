# Phase 6 — Basic Savings Integration Scope

## 1. Executive Summary

Phase 6 makes savings a first-class consumer of BudgetMeter's shared financial pace model.

The product contract is simple: one basic savings goal is free, the primary active `SavingsGoal` is the source of truth, Home and Savings must show the same savings progress, and savings ETA must come from `FinancialSummary` using shared net recurring pace. `AppSettings.savingsGoalAmount` remains only a legacy fallback for users who do not yet have an active `SavingsGoal`.

Phase 6 is not a savings redesign, premium multi-goal launch, gamification expansion, or data-model migration. It is a safety/alignment phase that removes ambiguous savings sources and prevents hidden timeline formulas from drifting away from Home.

Recommendation: **Ready for implementation planning.** First safe implementation step: add focused tests for primary goal selection, `AppSettings` fallback, current saved fallback, remaining amount, and ETA from shared recurring pace before touching UI.

## 2. Current Codebase Context

Relevant current pieces:

- `SavingsGoal` exists in CoreData and supports multiple-goal-style fields:
  - `targetAmount`
  - `currentAmount`
  - `targetDate`
  - `priority`
  - `isArchived`
  - `completedDate`
  - `createdAt`
  - `lastModified`
- `AppSettings.savingsGoalAmount` still exists as a legacy single-value target.
- Phase 1 added savings fields to `FinancialSummary`:
  - `savingsTargetAmount`
  - `savingsCurrentAmount`
  - `savingsRemaining`
  - `savingsTimeToGoal`
- Phase 2 migration can create a `SavingsGoal` from `AppSettings.savingsGoalAmount` when no active goal exists.
- Phase 3 made Home a `FinancialSummaryBuilder` consumer and exposed Home savings fields from the shared summary.
- `SavingsGoalManager` owns CRUD, progress, target-date contribution logic, and active/completed/archive fetches.
- `SavingsGoalsViewModel` owns the dedicated savings screen display and still has risk of local goal-specific display logic.
- `HomeDisplayMapping` owns Home display formatting and is the right place for summary-to-copy formatting.

Important distinction:

- `FinancialSummaryBuilder` should own savings target/current/remaining/ETA calculation for app-wide display.
- `SavingsGoalManager` should own deterministic goal selection and goal mutations.
- Savings feature views can format goal rows, but must not create a second ETA formula for the primary goal.

## 3. Product Decisions It Must Respect

Phase 6 must respect these decisions from `docs/product_decisions_v1.md` and `docs/implementation/savings_gamification_plan.md`:

- BudgetMeter is a financial pace app, not a full budgeting/envelope app.
- Savings reads the same net pace as Home.
- One basic savings goal is free.
- Multiple goals are premium.
- Advanced savings tracking, target dates, history, forecasting, richer recap/progress, and multiple goals are premium or later scope.
- Basic savings includes target amount, optional current saved amount, and estimated timeline.
- Savings ETA must use ongoing recurring pace, not one-time windfalls.
- Gamification must reward awareness/progress without shame.
- Pulsey can support small milestone/success moments later, but must not dominate savings.

## 4. Current Savings Flow Summary

Home savings flow:

- Home has quick savings goal entry through `QuickSavingsGoalInputView`.
- Home displays a savings card/summary using published fields from `HomeViewModel`.
- Home should display target, current, remaining, and ETA from `FinancialSummary`.
- Home must not save a target only into `AppSettings` once an active `SavingsGoal` path exists.

Dedicated Savings flow:

- `SavingsGoalsView` shows active and completed goals.
- `SavingsGoalInputView` creates/edits a goal with name, target amount, current amount, optional emoji, optional target date, and notes.
- `SavingsGoalDetailView` supports add/withdraw/complete/edit interactions.
- `SavingsGoalsViewModel` formats progress, remaining, target-date time remaining, required monthly contribution, and pace status.
- Multiple active goals can exist structurally, even though the v1 free product boundary is one basic goal.

Shared calculation flow:

- `FinancialSummaryBuilder` should select the primary active `SavingsGoal`.
- If no active goal exists, builder may read `AppSettings.savingsGoalAmount`.
- Builder should set current saved amount to `0` for fallback/legacy cases.
- Builder should compute remaining as `max(0, target - current)`.
- Builder should compute ETA only from net recurring daily pace converted to hourly.

## 5. Current Problems / Risks

Source-of-truth risks:

- `SavingsGoal` and `AppSettings.savingsGoalAmount` can both contain savings targets.
- Home quick entry historically saved to `AppSettings`, while the savings feature uses `SavingsGoal`.
- Dedicated savings screens can display goal-specific target-date math that does not match Home ETA.
- Multiple active goals can exist, so "primary" must be deterministic and test-covered.

Calculation risks:

- `SavingsGoalManager.calculateRequiredMonthlyContribution(for:)` uses target-date calendar months.
- `SavingsGoalManager.isPaceStatus(for:)` uses target-date progress heuristics.
- `SavingsGoalInputView` can preview monthly required contribution inline.
- These target-date calculations are acceptable as secondary target-date UI, but they must not replace shared pace ETA for the primary basic goal.

Data risks:

- Migrated users may only have `AppSettings.savingsGoalAmount`.
- Migrated `SavingsGoal.currentAmount` may be `0` or effectively missing.
- Completed goals can have `currentAmount >= targetAmount`; remaining must not go negative.
- Archived goals must not become the Home/basic primary goal.
- Repeated migration or quick-entry saves must not create duplicate active basic goals.

Premium-boundary risks:

- The data model supports multiple goals, but free v1 should keep one basic active goal.
- Phase 6 must not redesign premium gates or build the full multiple-goal premium experience.
- Any existing paywall/add-goal boundary should be preserved, not broadly refactored.

## 6. Required Source-Of-Truth Contract

Primary target:

- Use the deterministic primary active `SavingsGoal` target when at least one non-archived goal exists.
- Use `AppSettings.savingsGoalAmount` only when there is no active `SavingsGoal`.
- Do not merge or sum `SavingsGoal` and `AppSettings` values.

Primary current saved:

- Use primary active `SavingsGoal.currentAmount`.
- If there is no active goal and only `AppSettings.savingsGoalAmount` exists, current saved is `0`.
- If current saved is missing/implicit, treat it as `0`.

Remaining:

- `savingsRemaining = max(0, savingsTargetAmount - savingsCurrentAmount)`.
- Completed or overfunded goals show `0` remaining.

ETA:

- ETA is based on shared net recurring daily pace.
- Convert shared net daily pace to hourly using `CalculationEngine.hoursPerDay`.
- Do not include one-time income/expense in savings ETA.
- If remaining is `0`, ETA is nil or "goal reached" display copy.
- If net recurring pace is zero or negative, display a calm no-ETA state.
- Do not call target-date monthly contribution logic for Home ETA.

Primary goal selection:

- Selection must be deterministic.
- Recommended order:
  1. non-archived goals only
  2. lowest `priority`
  3. oldest `createdAt`
  4. earliest `targetDate` as tie-breaker
  5. stable `name` / `id` tie-breaker
- Completed-but-not-archived goals should be handled deliberately. For basic Home savings, prefer active in-progress goals when present; if only completed non-archived goals exist, display completed state rather than falling back to `AppSettings`.

## 7. Files Likely To Touch

Implementation may touch only focused savings/shared-summary files:

- `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryBuilder.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryModels.swift` only if tests prove a missing savings field
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift` only for savings display consistency
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeDisplayMapping.swift` only for savings ETA copy formatting
- `budgetmeter.ios/Features/HomeFeature/View/QuickSavingsGoalInputView.swift` only if Home quick entry must write to the primary `SavingsGoal`
- `budgetmeter.ios/Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalsView.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift` only if needed for current-saved fallback or primary/basic behavior
- `budgetmeter.iosTests/FinancialSummaryBuilderTests.swift`
- focused savings integration tests, e.g. `budgetmeter.iosTests/BasicSavingsIntegrationTests.swift`

Localization resources may be touched only if implementation adds new user-visible copy. Prefer existing localized keys where possible.

## 8. Files Not Allowed To Touch

Do not touch in Phase 6:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- CoreData schema/model versions
- Xcode project files
- Supabase/Auth files
- widget targets, widget providers, or App Group setup
- StoreKit product configuration
- broad `PremiumManager` / entitlement logic
- paywall redesign
- CloudKit setup/removal
- `CalculationEngine.swift` formulas
- Income/Expense flows
- Bills/Subscriptions flows
- full DesignSystem redesign
- broader navigation changes

## 9. Required Behavior

Phase 6 must deliver:

- Home and Savings use the same savings target/current/remaining/ETA values for the primary basic goal.
- Primary active `SavingsGoal` beats `AppSettings.savingsGoalAmount`.
- `AppSettings.savingsGoalAmount` fallback works only when no active goal exists.
- `currentSavedAmount` defaults to `0` when using legacy fallback.
- Remaining amount never goes below `0`.
- Completed goal state is calm and non-shaming.
- Zero or negative net recurring pace produces no timeline estimate and a calm no-ETA display.
- One-time income does not shorten savings ETA.
- Multiple active goals resolve to the same primary goal every time.
- Free users can still create/use one basic savings goal.
- Existing premium boundary for additional goals is preserved.

## 10. Free vs Premium Boundary Impact

Free in Phase 6:

- One basic savings goal.
- Target amount.
- Current saved amount, defaulting to `0`.
- Basic progress and remaining amount.
- Basic ETA from shared net recurring pace.
- Basic completed/goal-reached state.

Premium or later:

- Multiple active goals.
- Advanced milestones.
- Target-date forecasting.
- Savings history charts.
- Rich weekly recap.
- Goal-specific insights.
- Goal prioritization UI.
- Automated savings rules.
- Cloud sync for goals.

Phase 6 may preserve or minimally enforce an existing "one active goal unless premium" check, but it must not redesign premium logic.

## 11. Data / Migration Impact

No CoreData schema changes are allowed.

Migration rules:

- Preserve Phase 2 migration behavior.
- Do not delete `AppSettings.savingsGoalAmount`.
- Do not create duplicate `SavingsGoal` records on repeated app launch.
- Do not mutate legacy settings just to display savings.
- If Home quick entry is updated, it should create/update the primary basic `SavingsGoal` instead of only updating `AppSettings`.

Fallback rules:

- Active `SavingsGoal` exists: ignore `AppSettings.savingsGoalAmount` for display.
- No active `SavingsGoal`, `AppSettings.savingsGoalAmount > 0`: display that target with current `0`.
- No active goal and no settings target: display empty/no goal state.

## 12. Localization / Accessibility Impact

Localization:

- ETA copy must be localization-safe and support long strings.
- Avoid string interpolation inside localization keys where plural/unit handling can break.
- Required copy states:
  - no savings goal
  - amount remaining
  - at current pace/time to goal
  - goal reached
  - no ETA because pace is zero/negative

Accessibility:

- Savings progress cannot rely only on color.
- VoiceOver should include goal name, current amount, target amount, remaining amount, and ETA/no-ETA state.
- Dynamic Type must not clip target/current/remaining values.
- Completed states should be accessible without relying on confetti, emoji, or color.
- Reduced Motion should avoid mandatory progress animation.

## 13. Test Requirements

Required calculation tests:

- Primary active `SavingsGoal` beats `AppSettings.savingsGoalAmount`.
- `AppSettings.savingsGoalAmount` fallback works only when no active goal exists.
- Archived goals do not beat fallback or active goals.
- Current saved amount defaults to `0` for fallback.
- Remaining amount is `max(0, target - current)`.
- Completed/overfunded goal remaining is `0`.
- Zero net recurring pace produces no ETA.
- Negative net recurring pace produces no ETA/calm no-ETA state.
- ETA uses shared recurring net pace converted to hourly.
- ETA ignores one-time income windfalls and one-time expense hits.
- Multiple active goals select a deterministic primary.

Required integration/display tests:

- Home savings fields map from `FinancialSummary`.
- Savings feature primary goal ETA uses shared summary values.
- Savings feature target-date required contribution remains secondary and does not replace shared ETA.
- Free one-basic-goal behavior remains available.
- Additional-goal premium boundary is not accidentally removed.

Recommended test files:

- `FinancialSummaryBuilderTests.swift` for builder contract tests.
- `BasicSavingsIntegrationTests.swift` for manager/view-model integration.
- Existing Home mapping tests if display formatting changes.

## 14. Step-By-Step Implementation Sequence

1. Add builder tests for primary goal vs `AppSettings` fallback.
2. Add builder tests for current saved fallback, remaining amount, completed/overfunded goal, and archived goals.
3. Add ETA tests proving shared recurring pace is used and one-time entries are ignored.
4. Add deterministic primary-selection tests for multiple active goals.
5. Centralize deterministic primary active goal selection in `SavingsGoalManager`.
6. Make `FinancialSummaryBuilder` use that same primary-selection path.
7. Ensure `FinancialSummaryBuilder` falls back to `AppSettings.savingsGoalAmount` only when no active goal exists.
8. Ensure ETA is nil/no-ETA for zero or negative net recurring pace.
9. Update Home savings display only if it still reads any savings values outside `FinancialSummary`.
10. Update Home quick entry only if it still writes only to `AppSettings`.
11. Update SavingsGoals display so the primary goal can show shared pace ETA.
12. Keep target-date required monthly contribution as secondary goal-detail UI only.
13. Preserve one-basic-goal-free behavior and existing premium boundary for additional goals.
14. Add minimal localized copy only for new savings states.
15. Run focused tests, full tests, and build.
16. Update `implementation_planning_index.md` only after build/tests pass.

## 15. Build / Test Checkpoints

Focused checkpoints:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:budgetmeter.iosTests/FinancialSummaryBuilderTests test
```

If a dedicated savings integration test file exists:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:budgetmeter.iosTests/BasicSavingsIntegrationTests test
```

Final checkpoints:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

If current simulator names differ, use `xcodebuild -showdestinations -scheme budgetmeter.ios` and document the actual destination used.

## 16. What To Postpone

Postpone:

- Multiple-goal redesign.
- Premium multi-goal management UI.
- Advanced target-date forecasting.
- Goal history charts.
- Weekly recap.
- Awareness streak.
- Pulsey savings variants.
- Push reminders.
- Automated savings rules.
- Cloud sync for savings goals.
- New CoreData fields.
- Full localization catalog pass.
- Full accessibility QA pass beyond touched savings states.
- Widgets consuming savings data.

## 17. Success Criteria

Phase 6 is complete when:

- Home and Savings surfaces show consistent primary savings data.
- Primary active `SavingsGoal` is the savings source of truth.
- `AppSettings.savingsGoalAmount` is fallback only.
- Current saved fallback is `0`.
- Savings remaining is correct and never negative.
- Completed goals show `0` remaining.
- Savings ETA uses shared recurring net pace from `FinancialSummary`.
- One-time entries do not affect savings ETA.
- Zero/negative pace has a calm no-ETA state.
- One basic savings goal remains free.
- Multiple-goal premium/advanced behavior is not expanded.
- Focused tests pass.
- Full tests pass or any pre-existing failures are clearly documented.
- Build passes.

## 18. Recommendation

Status: **Ready for implementation planning.**

First safe implementation step: add the savings source-of-truth tests around `FinancialSummaryBuilder` and `SavingsGoalManager` before changing Home or Savings UI.

Do not start Phase 7 until Phase 6 has either:

- passed build/tests and has an updated implementation index entry, or
- documented a concrete blocker with no ambiguous partial status.
