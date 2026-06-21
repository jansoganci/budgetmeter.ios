# Widgets Implementation Plan

## Purpose

Plan widgets so they become functional, premium, and consistent with the Home dashboard data contract.

Current docs indicate widgets exist but may be non-functional or not fully connected. This plan prevents another UI-only widget pass.

## Scope

- Widget target status
- Home screen `systemSmall` widget (v1)
- Premium gating
- App Group/shared storage
- Widget data contract
- Deep links
- Refresh behavior
- Locked teaser behavior for non-premium users

## Current Codebase Context

`CLAUDE.md` says `Widgets/` exists and widgets need extension setup. Audit must verify target membership, build status, and data sharing.

## Product Decisions It Must Respect

- Widgets are premium
- Widgets extend Home but do not replace it
- Widget data must use the same Home summary/calculation model
- Day is default
- v1 scope: Home Screen `systemSmall` only
- v1 metric: net daily pace status + value
- v1 deep link target: Home hero section
- Non-premium users see locked teaser + upgrade/paywall deep link
- No lock screen widgets in v1
- No medium widgets in v1
- No complex charts in v1
- Pulsey should not appear in v1 widget except a tiny static brand mark if trivial

## Files / Folders Likely To Be Touched

- `budgetmeter.ios/Widgets/`
- Xcode widget target files later
- App Group/shared storage later
- Home summary data provider
- PremiumManager
- Deep link routing

## New Code Likely Needed

- Widget data provider
- Shared storage writer/reader
- Premium widget gate
- Widget timeline provider updates
- Deep link routing
- Compact `systemSmall` widget component
- Locked teaser widget state component

## Existing Code Likely To Be Revised

- Existing widget files
- Home summary serialization
- Premium gate integration
- App navigation deep links

## Code That Must Not Be Touched Yet

- Xcode project/target setup until widget audit is complete
- Supabase-backed widget data
- Advanced widget families
- Lock screen widgets

## Data / Migration Risks

- Widgets cannot directly rely on app-only in-memory state
- Shared storage must not duplicate calculation logic
- Premium state must be available safely to widget code
- Widget data freshness can mislead users if stale

## Premium / Free Boundary Impact

- Widgets are premium
- Widget gate must not block app Home dashboard
- Lock screen/medium variants are postponed in v1 scope
- Pulsey widget treatments are postponed in v1 scope

## Localization / Accessibility Impact

- Widget text must be localized
- Values must fit small layouts
- Color cannot be the only state
- Widget accessibility labels are required

## Testing Requirements

- Widget build test
- Widget target membership check
- Timeline refresh QA
- Shared storage tests
- Premium gate tests
- Deep link tests
- `systemSmall` layout QA
- Locked teaser state QA

## Step-by-Step Implementation Sequence

1. Audit current widget target status
2. Apply fixed v1 scope (`systemSmall` only)
3. Define widget data contract from Home summary
4. Define shared storage approach
5. Define premium gating
6. Define deep links
7. Define localization/accessibility requirements
8. Implement after Home summary is stable

## What To Postpone

- Lock screen widgets
- Medium widgets
- Multiple widget families
- Pulsey widget states
- Supabase cloud widget state
- Savings widget variants
- Biggest-drain widget variants
- Advanced recap widgets

## Success Criteria

- Widget scope is clear
- Data source matches Home summary
- Premium gate is defined
- Target/setup risks are known
- Widgets can be implemented without separate calculation logic

