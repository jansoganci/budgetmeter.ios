# Savings Gamification Plan

## Purpose

Plan savings and v1 gamification so BudgetMeter feels playful without becoming a game or shaming users.

## Scope

- Basic savings goal
- Premium multiple goals
- Savings milestone
- Awareness streak
- Simple weekly recap
- Haptics
- Small success animation
- Pulsey moments

## Current Codebase Context

Likely areas:

- `Features/SavingsGoalsFeature/`
- `Features/HomeFeature/`
- `CoreKit/Sources/Services/SavingsGoalManager.swift` if present
- `CoreKit/Sources/Engine/CalculationEngine.swift`
- `DesignSystem/`

Verify exact files during audit.

## Product Decisions It Must Respect

- One basic savings goal is free
- Basic goal includes target amount, optional current saved amount, estimated timeline
- Multiple goals are premium
- Advanced savings tracking, milestones, target dates, history, forecasting, richer progress views are premium
- Savings uses the same Home net pace
- Current app already supports savings goal entry; redesign should preserve this behavior
- Awareness streak tracks money awareness, not wealth or success
- Gamification must not shame bad financial days
- Pulsey supports, but does not dominate

## Files / Folders Likely To Be Touched

- `Features/SavingsGoalsFeature/`
- `Features/HomeFeature/`
- `CoreKit/Sources/Services/`
- `CoreKit/Sources/Engine/`
- `DesignSystem/`
- `Resources/`
- Tests

## New Code Likely Needed

- Awareness streak model/service
- Weekly recap summary model
- Savings milestone state
- Haptic/success event hooks
- Pulsey state hooks for non-blocking moments
- Shared savings timeline formatter (days/weeks/months) if not already centralized

## Existing Code Likely To Be Revised

- Savings goal ViewModel
- Savings display on Home
- Savings calculation calls
- Any existing achievement/insight code
- Premium gating for advanced goals

## Code That Must Not Be Touched Yet

- Complex challenge system
- Push notifications
- Mascot progression
- Advanced forecasting
- Supabase sync
- CoreData schema before migration plan

## Data / Migration Risks

- Current SavingsGoal may support multiple goals already
- Current saved amount may be unclear
- Historical data may be insufficient for weekly recap
- Streak data may need a new local state model
- Existing dual path (`AppSettings` goal + `SavingsGoal` entity) can cause inconsistent UX if not contract-defined

## Premium / Free Boundary Impact

- Free: one basic savings goal, basic milestone, awareness streak, simple weekly recap
- Premium: multiple goals, advanced milestones, advanced recap, forecasting, richer history
- Premium must not block basic savings timeline

## Localization / Accessibility Impact

- Milestone and recap copy must be localized
- Avoid shame language
- Haptics/motion need alternatives or reduced motion compliance
- Progress cannot rely only on color

## Testing Requirements

- Savings timeline tests
- Current saved amount behavior tests
- Current-saved fallback to `0` tests
- Daily net pace baseline tests for timeline calculation
- Milestone trigger tests
- Awareness streak tests
- Weekly recap summary tests
- Premium boundary tests

## Step-by-Step Implementation Sequence

1. Complete calculation contract
2. Audit savings implementation
3. Define basic savings goal data requirements
4. Define milestone behavior
5. Define awareness streak rules
6. Define simple weekly recap inputs
7. Define premium advanced boundary
8. Add tests
9. Implement after Home summary is stable

## What To Postpone

- Advanced goal forecasting
- Multiple goals if core redesign is not stable
- Push reminders
- Challenge system
- Pulsey variants
- Advanced recap story format

## Success Criteria

- Free savings goal behavior is clear
- Premium savings boundary is clear
- Gamification v1 is scoped
- No shame/punishment mechanics are included
- Required data and tests are known
- Savings timeline contract is explicitly tied to shared Home net pace without hidden formulas

