# Navigation Flow Plan

## Purpose

Plan the app navigation so Home remains central and other areas support the financial pace experience.

The redesign should simplify the user's path to understanding status and entering income/expenses quickly.

## Scope

- App launch destination
- Tab structure
- Home-first hierarchy
- Add income/expense entry
- Settings/account
- Premium entry points
- Onboarding handoff
- Deep links from widgets

## Current Codebase Context

`CLAUDE.md` says `ContentView.swift` currently manages tab navigation with 5 tabs. Current tabs and feature wiring must be verified during audit.

## Product Decisions It Must Respect

- Home is central
- Other areas support Home
- Quick entry must stay fast
- Pulsey must not slow entry
- Premium should not block core value
- Free users can use locally without auth
- Premium users can enable cloud backup/sync

## Files / Folders Likely To Be Touched

- `budgetmeter.ios/App/ContentView.swift`
- Feature root views
- Settings/account views
- PremiumFeature entry points
- Widget deep link routing if implemented

## New Code Likely Needed

- Updated navigation model
- Central add action or bottom action tray
- Route/deep link handling
- Account/sync settings entry
- Premium entry surfaces

## Existing Code Likely To Be Revised

- Current tab configuration
- Feature root screen order
- Add transaction routing
- Settings navigation
- Paywall presentation routing

## Code That Must Not Be Touched Yet

- Xcode targets
- Widget target setup
- CoreData schema
- Supabase/Auth internals
- Calculation formulas

## Data / Migration Risks

Navigation has low data risk, but incorrect routing can expose premium flows, destructive settings, or unfinished features.

## Premium / Free Boundary Impact

- Free users must reach Home, income, expense, and basic savings without paywall
- Premium entry points should be contextual
- Sync/backup settings should explain premium and auth requirements
- Widgets remain premium

## Localization / Accessibility Impact

- Tab labels and action labels need localization
- Bottom actions must have accessible labels
- Navigation must work with large text and VoiceOver
- Icons cannot be the only meaning

## Testing Requirements

- Launch route tests/manual QA
- Tab navigation QA
- Quick add flow QA
- Paywall route QA
- Auth/sync settings route QA
- Widget deep link QA later

## Step-by-Step Implementation Sequence

1. Audit current tabs/routes
2. Decide target navigation map
3. Decide central add vs bottom action tray
4. Define Home support screens
5. Define premium/settings/account entry
6. Define onboarding handoff
7. Define deep link destinations
8. Implement after Home and DesignSystem plans are stable

## What To Postpone

- Complex dashboard customization
- Widget deep links until widget scope is planned
- Supabase account flows until auth plan is active
- Advanced premium routing

## Success Criteria

- Target navigation map is clear
- Home remains primary
- Quick entry route is decided
- Premium/auth/settings routes are clear
- Implementation can proceed without route ambiguity

