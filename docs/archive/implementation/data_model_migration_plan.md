# Data Model Migration Plan

## Purpose

Plan how BudgetMeter's existing local data model can support the next product direction without risking live user data.

This plan exists before coding because BudgetMeter already has CoreData entities, CloudKit history, premium features, bills/subscriptions, savings goals, and calculation logic. The redesign requires a shared financial model for Home, charts, widgets, savings, and weekly recap.

CoreData remains the local store direction. Supabase is the target cloud backup/sync layer for authenticated premium users. CloudKit is current/legacy infrastructure and will be removed after safe migration planning.

## Scope

- Existing CoreData entities
- CoreData model versioning
- Current CloudKit relationship
- Future Supabase-backed backup/sync direction
- Stable user ID mapping
- Recurring vs one-time income
- Fixed/regular vs surprise/one-time expenses
- Bills/subscriptions as regular expenses
- Savings goal data
- Financial snapshots/history

## Current Codebase Context

From `CLAUDE.md`, current storage is CoreData + CloudKit with these entities:

- `AppSettings`
- `FinancialCategory`
- `RecurringTransaction`
- `FinancialSnapshot`
- `Subscription`
- `Bill`
- `BillPayment`
- `SavingsGoal`

The audit must verify whether these entities are still accurate and actively used before any migration plan becomes executable.

## Product Decisions It Must Respect

- One shared financial data model feeds Home, savings, charts, widgets, and recap surfaces
- Basic recurring income/expense entry is free
- Recurring automation is premium
- Bills/subscriptions are specialized regular expenses
- One-time entries affect their selected/current period only
- One-time entries do not change permanent long-term pace
- One basic savings goal is free
- Multiple/advanced savings goals are premium
- Free users can use the app locally
- Premium users unlock cloud backup/sync
- Apple Sign In and Supabase are planned
- Stable user identity is required for synced users and must come from authenticated account identity
- Supabase is the target long-term backend for user-linked cloud data
- CloudKit will not remain as long-term sync infrastructure
- Supabase Auth with Apple Sign In is the target auth approach
- Supabase Edge Functions are optional and should be introduced only when secure backend logic requires them

## Files / Folders Likely To Be Touched

Planning only. Later implementation may touch:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/`
- `budgetmeter.ios/CoreKit/Sources/Persistence/`
- `budgetmeter.ios/CoreKit/Sources/Services/`
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- Feature ViewModels that read/write financial data
- Supabase/auth modules if later added

Exact files must be verified during codebase audit.

## New Code Likely Needed

Likely later, not during this plan:

- Shared financial entry/read model
- Migration helpers
- Stable local record identifiers
- User ID mapping layer
- Local-to-cloud mapping metadata
- Backup/sync serialization models
- Tests for migration and mapping behavior

## Existing Code Likely To Be Revised

- Persistence fetch/save APIs
- CoreData entity usage
- Bills/subscriptions relationship to recurring expenses
- Savings goal storage
- Financial snapshot generation
- Home/Income/Expense/Savings ViewModel data loading

## Code That Must Not Be Touched Yet

- CoreData schema
- Existing CloudKit configuration
- Xcode project files
- Production entitlements
- Supabase/Auth implementation
- StoreKit/Premium entitlement code
- Live data migration code

## Data / Migration Risks

- Live user data may already exist in CoreData and CloudKit
- Existing entities may not map cleanly to the new shared financial model
- `FinancialCategory` may mix category and transaction concerns
- Bills/subscriptions may duplicate recurring transaction behavior
- `SavingsGoal` may be active, partial, or unused
- CloudKit data may require preservation or deprecation planning
- Adding Supabase later may create dual-cloud migration complexity
- Misattribution risk if local records are attached to the wrong authenticated user during first sign-in
- Data-loss risk if CloudKit is deactivated before migration safeguards are validated

## Premium / Free Boundary Impact

- Free data must support income, expense, basic recurring entries, core dashboard, basic savings goal, and basic fixed vs surprise tracking
- Premium data must support custom categories, multiple goals, advanced history, forecasting, widgets, bill/subscription automation, and backup/sync
- Premium flags must not be embedded in core calculation values

## Localization / Accessibility Impact

- Data model changes may introduce new labels, empty states, migration messages, and sync states
- Migration errors must be understandable and localized
- Financial state labels should not rely on color alone

## Testing Requirements

- Migration tests for existing entities
- Mapping tests from current data to shared financial summary inputs
- One-time vs recurring behavior tests
- Bills/subscriptions rollup tests
- Savings goal free vs premium data tests
- Cloud/local identity mapping tests when sync planning begins

## Step-by-Step Implementation Sequence

1. Complete `codebase_audit_plan.md` audit
2. Inventory current entities and usage
3. Map existing entities to new product concepts
4. Identify reusable entities and fields
5. Identify entities requiring migration planning
6. Decide local canonical model before Supabase schema
7. Define stable authenticated user identity mapping (`Apple user identity -> Supabase auth user id`)
8. Define local record identity + cloud ownership mapping strategy
9. Define migration scenarios and test cases (local-only, CloudKit-existing, mixed states)
10. Only then plan schema/version changes

## What To Postpone

- Exact Supabase SQL schema
- RLS policies
- Live CloudKit-to-Supabase migration
- Multi-device conflict resolution
- Entity deletion/removal
- Any CoreData model edits

## CloudKit Transition Direction

- Treat CloudKit as current/legacy sync infrastructure.
- Do not keep CloudKit and Supabase as parallel long-term sync systems by default.
- Permit temporary coexistence only for controlled migration windows.
- CloudKit removal is required before final release architecture.
- Any CloudKit removal requires:
- explicit migration readiness checklist,
- verified live-user data preservation path,
- rollback strategy,
- and staged release validation.

## Success Criteria

- Current data model is fully inventoried
- Each entity has an intended future role or removal candidate status
- Migration risks are documented
- Shared financial model requirements are clear
- No code/schema/project changes were made
- Next planning step can define the calculation engine contract safely

