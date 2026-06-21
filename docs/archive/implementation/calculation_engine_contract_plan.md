# Calculation Engine Contract Plan

## Purpose

Define the contract for the shared financial calculation engine before UI or data implementation starts.

BudgetMeter's core product promise depends on consistent pace values. Home, savings, charts, widgets, weekly recap, and premium insights must not calculate money movement separately.

## Scope

- Daily normalization rules
- Minute/hour/day/week/month conversion
- Recurring income
- One-time income
- Fixed/regular expenses
- Surprise/one-time expenses
- Bills/subscriptions rollup
- Net pace
- Biggest drain
- Savings timeline
- Period comparison
- Weekly recap inputs

## Current Codebase Context

`CLAUDE.md` identifies `CoreKit/Sources/Engine/CalculationEngine.swift` as the source of financial math with existing constants:

- `daysPerMonth = 30.4375`
- `daysPerYear = 365.25`
- `hoursPerDay = 24`
- `weeksPerMonth = 4.348`

Current tests reportedly cover CalculationEngine heavily. The audit must verify current behavior and duplicate formulas elsewhere.

## Product Decisions It Must Respect

- All core surfaces share one normalized calculation model
- Day is the default Home unit
- Minute is a secondary live metric
- Recurring entries normalize to daily base
- One-time entries affect only selected/current period
- One-time entries do not change permanent long-term pace
- Savings calculations use Home net pace
- Biggest drain combines recurring and one-time expenses by selected period/category

## Files / Folders Likely To Be Touched

Later implementation may touch:

- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.iosTests/CalculationEngineTests.swift`
- `budgetmeter.iosTests/ViewModelCalculationTests.swift`
- Home, Income, Expense, Savings ViewModels
- Widget data provider if added

Exact files must be verified during audit.

## New Code Likely Needed

- Shared input DTO/model for financial entries
- Shared output summary model for Home/widgets/charts/savings
- Period selection model
- Biggest drain calculation
- One-time period application logic
- Awareness streak/weekly recap input summaries
- Expanded test fixtures

## Existing Code Likely To Be Revised

- Existing CalculationEngine APIs
- ViewModel calculation calls
- Any duplicate formulas outside CalculationEngine
- Chart data generation
- Savings timeline calculation

## Code That Must Not Be Touched Yet

- UI redesign screens
- CoreData schema
- Supabase/Auth
- Premium feature gates
- Widget targets

## Data / Migration Risks

- Existing stored values may not include enough timing/frequency data
- One-time entries may be indistinguishable from recurring records
- Bills/subscriptions may currently bypass the main expense model
- Historical snapshots may use old formulas

## Premium / Free Boundary Impact

- Core calculations are free
- Premium may consume deeper outputs, but must not change the core pace result
- Premium forecasting/history must be layered on top of the same base model

## Localization / Accessibility Impact

- Calculation outputs need localized labels and units
- Currency formatting must be centralized
- Negative states should support gentle wording like "Slowing down"
- Color cannot be the only signal of positive/negative pace

## Testing Requirements

- Daily/weekly/monthly/yearly normalization tests
- Minute/hour/day/week/month conversion tests
- Recurring income/expense tests
- One-time current-period-only tests
- Biggest drain tests
- Savings timeline tests
- Period comparison tests
- Regression tests for existing calculation behavior

## Step-by-Step Implementation Sequence

1. Audit current CalculationEngine APIs and tests
2. Identify duplicate calculations outside the engine
3. Define shared input model
4. Define shared output summary
5. Define period behavior
6. Define one-time vs recurring rules
7. Define test matrix
8. Refactor engine behind tests
9. Update consumers only after contract is stable

## What To Postpone

- Advanced forecasting
- AI insights
- Supabase sync calculations
- Complex challenge mechanics
- Full historical analytics

## Success Criteria

- Calculation contract is documented
- All consumers know which output to use
- Test matrix is defined
- No UI or persistence changes are required to understand the contract
- Implementation can proceed without formula ambiguity

