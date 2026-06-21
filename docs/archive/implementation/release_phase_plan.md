# Release Phase Plan

## Purpose

Plan the safest phase order for moving BudgetMeter from product planning to implementation and release.

BudgetMeter is live, so release planning must protect user data, calculations, premium access, and App Store readiness.

## Scope

- Planning sequence
- Implementation phases
- Risk gates
- Testing gates
- Release gates
- Postponed scope
- App Store/live data concerns

## Current Codebase Context

Current app is SwiftUI, CoreData + CloudKit, feature-based, with partial premium and non-functional widgets per `CLAUDE.md`. The redesign adopts Supabase/Auth as the target cloud direction and plans CloudKit removal after migration safety validation.

## Product Decisions It Must Respect

- Core value remains free
- Home financial pace is central
- Shared calculation model
- Playful Momentum FinTech UI
- Pulsey
- Premium boundaries
- Local-first free use
- Premium cloud backup/sync later

## Files / Folders Likely To Be Touched

Release planning may cover all app areas but does not itself touch code.

Later phases may touch:

- CoreKit
- Features
- DesignSystem
- Resources
- Widgets
- Tests
- Xcode project/entitlements in later cloud/widget phases

## New Code Likely Needed

Defined by individual implementation plans, not this plan.

## Existing Code Likely To Be Revised

Defined by individual implementation plans.

## Code That Must Not Be Touched Yet

Before phase gates:

- CoreData schema
- CloudKit removal
- Supabase/Auth
- Widget target setup
- StoreKit product changes
- App Store entitlements

## Data / Migration Risks

Release risk is highest around:

- CoreData changes
- CloudKit changes
- Calculation changes
- Premium entitlement changes
- Backup/sync introduction

## Premium / Free Boundary Impact

Each release phase must verify that free users still have:

- Home dashboard
- Income/expense entry
- Basic recurring entries
- Basic savings goal

Premium phases must not regress existing premium users.

## Localization / Accessibility Impact

Every user-facing phase must include localization and accessibility acceptance criteria before release.

## Testing Requirements

- Build
- Unit tests
- Calculation regression tests
- ViewModel tests
- Manual persistence checks
- Premium restore checks
- Localization checks
- Accessibility checks
- Device-size visual QA
- App Store readiness QA

## Step-by-Step Implementation Sequence

### Phase 0: Audit And Contracts

- Codebase audit
- Data model migration planning
- Calculation engine contract

### Phase 1: Local Core Foundation

- Calculation engine refactor behind tests
- Shared Home summary
- Data model mapping without risky migrations if possible

### Phase 2: Design System And Home

- Dark-first design tokens
- Core cards/buttons/charts
- Home momentum hero
- Basic Home sections

### Phase 3: Entry Flows

- Income flow updates
- Expense flow updates
- Bills/subscriptions rollup planning
- Category boundaries

### Phase 4: Savings And Gamification v1

- Basic savings goal alignment
- Savings milestone
- Awareness streak
- Simple weekly recap
- Haptics/success animation
- Pulsey launch splash

### Phase 5: Premium Cleanup

- StoreKit entitlement cleanup
- Feature gate matrix
- Premium personalization planning
- Export/biometric/themes boundaries

### Phase 6: Widgets

- Only after Home summary is stable
- v1 scope: Home Screen `systemSmall` only
- Metric: net daily pace status + value
- Deep link: Home hero section
- Premium widget gating with locked teaser for non-premium users
- No lock screen/medium/complex chart widgets in v1

### Phase 7: Auth/Supabase Backup Sync

- Only after local model is stable
- Apple Sign In
- Supabase Auth + database backup/sync
- Stable user IDs
- CloudKit data-preservation migration step
- CloudKit removal after migration safety criteria are met

### Phase 8: Release QA

Stage A: Core redesign QA

- Home
- DesignSystem
- Calculation engine
- Income/expense flows
- Basic savings
- Localization
- Accessibility

Stage B: Auth/sync QA (after auth/sync scope freeze)

- Apple Sign In
- Supabase backup/sync
- Account/session states
- Account deletion and cloud data deletion
- Restore behavior
- Sync errors and recovery
- Migration from local/CoreData/CloudKit states

Final release gate:

- App Store readiness
- Migration checks

## What To Postpone

- True multi-device real-time sync
- Advanced forecasting
- Complex weekly recap
- Advanced widgets
- Lock screen widgets if not needed for first release
- AI assistant
- Bank sync
- Mascot progression
- Challenge engine
- Unlimited customization
- Lock screen widgets
- Medium widgets
- Pulsey widget states
- Savings widget variants
- Biggest-drain widget variants

## Success Criteria

- Each phase has clear entry/exit gates
- Highest-risk work is isolated
- Local core redesign can ship before cloud complexity if needed
- Premium/free boundary is protected
- Release can be staged without mixing all risks at once

