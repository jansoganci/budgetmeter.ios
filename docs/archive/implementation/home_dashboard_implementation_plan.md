# Home Dashboard Implementation Plan

## Purpose

Plan the Home redesign around the hybrid momentum ring + live financial pace number without breaking the current dashboard data or calculation flow.

Home is the center of BudgetMeter. It must answer: "Am I financially moving forward or slowing down, and how fast?"

## Scope

- Home hero
- Momentum ring
- Live pace number
- Day default unit
- Minute secondary metric
- Time selector
- Income vs expense velocity
- Biggest drain
- Savings progress
- Lightweight chart
- Awareness streak
- Simple weekly recap
- Premium entry points

## Current Codebase Context

Likely current areas:

- `budgetmeter.ios/Features/HomeFeature/`
- `budgetmeter.ios/Features/HomeFeature/ViewModel/`
- `budgetmeter.ios/DesignSystem/Components/Cards/`
- `budgetmeter.ios/DesignSystem/Components/Charts/`
- `CoreKit/Sources/Engine/CalculationEngine.swift`

Current component names and data flow must be verified during audit.

## Product Decisions It Must Respect

- Home is central
- Hybrid momentum ring + live financial pace number
- Status copy: "Moving forward: +$12/day" style
- Gentle negative copy such as "Slowing down"
- Day default
- Minute as secondary live metric
- Shared calculation model for all pace values
- Pulsey must not dominate Home
- Critical numbers must be on readable solid/near-solid surfaces
- Core Home value is free

## Files / Folders Likely To Be Touched

- `budgetmeter.ios/Features/HomeFeature/`
- `budgetmeter.ios/DesignSystem/Components/Cards/`
- `budgetmeter.ios/DesignSystem/Components/Charts/`
- `budgetmeter.ios/DesignSystem/Colors/`
- `budgetmeter.ios/Resources/`
- Tests for HomeViewModel if present

## New Code Likely Needed

- Momentum hero component
- Momentum ring component
- Pace time selector component
- Home summary state model
- Biggest drain card
- Awareness streak/weekly recap UI model
- Empty/loading/error states

## Existing Code Likely To Be Revised

- `HomeView`
- `HomeViewModel`
- Existing dashboard cards
- Existing chart components
- Existing net flow/health score components

## Code That Must Not Be Touched Yet

- CoreData schema
- Supabase/Auth
- Widget target setup
- StoreKit entitlement implementation
- Advanced forecasting

## Data / Migration Risks

- Home may currently read old entities directly
- Charts may use snapshots based on old formulas
- Existing Home data may not distinguish one-time vs recurring
- Health score may conflict with the new momentum-first hierarchy

## Premium / Free Boundary Impact

- Main Home dashboard is free
- Momentum ring is free
- Basic savings progress is free
- Awareness streak can be free
- Premium can link to advanced insights, widgets, advanced history, forecasting, and richer recap
- Premium prompts must not push the hero out of focus

## Localization / Accessibility Impact

- Status copy requires localization
- Dynamic financial values need stable layout
- Use monospaced digits for live pace values
- Ring state must not rely only on color
- Reduce Motion must be respected
- Large text must not break card layout

## Testing Requirements

- HomeViewModel summary tests
- Day default tests
- Minute secondary metric tests
- Positive/negative status copy mapping tests
- Biggest drain tests
- Empty state tests
- Snapshot/manual visual QA later

## Step-by-Step Implementation Sequence

1. Wait for codebase audit and calculation contract
2. Define Home data contract
3. Decide exact Home section order
4. Identify reusable existing cards/charts
5. Plan ViewModel state refactor
6. Plan DesignSystem components needed
7. Plan localization keys
8. Plan tests before UI rewrite
9. Implement Home after calculation output is stable

## What To Postpone

- Full advanced insights
- Complex weekly recap
- Full Pulsey dashboard presence
- Advanced forecasting visuals
- Widgets
- Supabase-synced Home state

## Success Criteria

- Home data requirements are clear
- Home section hierarchy is decided
- Free/premium boundaries are clear
- Required components are identified
- Testing and localization needs are known
- Implementation can be split into small prompts

