# Income Expense Flow Implementation Plan

## Purpose

Plan the revised income and expense flows so user entries feed the shared financial pace model correctly.

These flows must stay fast, simple, and compatible with the Home dashboard.

## Scope

- Income entry
- Expense entry
- Recurring vs one-time income
- Fixed/regular vs surprise/one-time expenses
- Bills/subscriptions as regular expenses
- Frequencies
- Categories
- Premium automation boundary

## Current Codebase Context

Likely folders:

- `budgetmeter.ios/Features/IncomesFeature/`
- `budgetmeter.ios/Features/ExpensesFeature/`
- `budgetmeter.ios/Features/BillsFeature/`
- `budgetmeter.ios/Features/SubscriptionsFeature/`
- CoreKit services/managers
- CoreData entities

Exact files must be verified during audit.

## Product Decisions It Must Respect

- Core income and expense entry are free
- Basic recurring income/expense entries are free
- Recurring automation is premium
- Bills/subscriptions are specialized regular expenses
- Basic bill/subscription-style expenses count as regular expenses
- Advanced bill/subscription management/reminders/renewal tracking are premium
- One-time entries affect current/selected period only
- Values normalize to daily base for pace

## Files / Folders Likely To Be Touched

- `Features/IncomesFeature/`
- `Features/ExpensesFeature/`
- `Features/BillsFeature/`
- `Features/SubscriptionsFeature/`
- `CoreKit/Sources/Services/`
- `CoreKit/Sources/Engine/CalculationEngine.swift`
- `Resources/`
- Related tests

## New Code Likely Needed

- Shared entry form patterns
- Frequency selector model
- Entry type selectors
- Basic regular expense mapping
- One-time period behavior tests
- Category selection updates

## Existing Code Likely To Be Revised

- Income ViewModel
- Expense ViewModel
- Bills/subscriptions services
- Category handling
- Persistence mapping
- CalculationEngine consumers

## Code That Must Not Be Touched Yet

- Advanced bill/subscription automation
- Supabase sync
- CoreData model until migration plan exists
- Premium paywall implementation
- Widgets

## Data / Migration Risks

- Existing income/expense records may not distinguish one-time and recurring
- Bills/subscriptions may be separate from expense pace
- Categories may be used as financial records
- Frequency data may be incomplete
- One-time records may currently affect long-term pace incorrectly

## Premium / Free Boundary Impact

- Free: income entry, expense entry, basic recurring entries, basic fixed vs surprise tracking
- Premium: custom categories, automation, reminders, advanced bill/subscription management, advanced insights/history/forecasting
- Core entry must not require premium

## Localization / Accessibility Impact

- Entry labels and category names need localization
- Forms must support large text
- Type selectors must be accessible
- Negative/caution copy must be gentle

## Testing Requirements

- Entry creation tests
- Frequency normalization tests
- One-time period tests
- Bills/subscriptions rollup tests
- Free vs premium boundary tests
- ViewModel validation tests

## Step-by-Step Implementation Sequence

1. Complete data model and calculation plans
2. Audit current income/expense flows
3. Define shared entry concepts
4. Define frequency and type mapping
5. Define bills/subscriptions rollup
6. Define category boundary
7. Define test cases
8. Refactor income flow
9. Refactor expense flow
10. Connect both to Home summary

## What To Postpone

- Advanced automation
- Reminders
- Renewal tracking
- Custom category complexity
- Sync of entries
- Rich analytics

## Success Criteria

- Income and expense flows map to shared financial model
- Free/premium boundaries are clear
- One-time vs recurring behavior is unambiguous
- Bills/subscriptions relationship is planned
- Test coverage requirements are clear

