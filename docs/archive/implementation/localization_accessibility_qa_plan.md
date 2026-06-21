# Localization Accessibility QA Plan

## Purpose

Plan localization, accessibility, and QA requirements before the redesign introduces many new strings, layouts, animations, and visual states.

BudgetMeter supports multiple languages and handles sensitive financial information. The redesigned UI must remain readable, localized, accessible, and trustworthy.

QA is staged:
- Stage A validates core redesign quality before auth/sync rollout.
- Stage B validates auth/sync and migration behavior after auth/sync scope is frozen.

## Scope

- String catalogs
- 10 supported languages
- Hardcoded strings
- Currency/date/number formatting
- Dynamic Type
- VoiceOver
- High contrast
- Reduce Motion
- RTL behavior
- Chart accessibility
- QA matrix
- Stage A core redesign QA
- Stage B auth/sync QA

## Current Codebase Context

`CLAUDE.md` says all user-facing strings must be localized and 10 languages are supported:

- EN
- TR
- DE
- FR
- ES
- IT
- PT
- JA
- ZH
- AR

Resources are under `budgetmeter.ios/Resources/`.

## Product Decisions It Must Respect

- Gentle financial language
- No shame/panic copy
- Pulsey copy must be calm and translatable
- Negative state: "Slowing down" style
- Color cannot be the only state
- Motion must respect Reduce Motion
- Critical numbers must remain readable

## Files / Folders Likely To Be Touched

- `budgetmeter.ios/Resources/`
- All redesigned feature views
- DesignSystem components
- Chart components
- Accessibility labels/hints
- Tests/manual QA docs

## New Code Likely Needed

- New localization keys
- Accessibility labels for new components
- Reduced motion handling
- Chart accessibility descriptions
- QA checklist artifacts

## Existing Code Likely To Be Revised

- Hardcoded strings
- Existing localized copy
- Currency formatting usage
- Date formatting usage
- Components that break with Dynamic Type

## Code That Must Not Be Touched Yet

- Product logic
- CoreData schema
- Supabase/Auth
- Premium entitlements
- Calculation formulas

## Data / Migration Risks

Low direct data risk. Main risk is misformatted financial values or mistranslated financial states.

## Premium / Free Boundary Impact

- Paywall and premium labels must be localized
- Premium lock/badge states need accessible meaning
- Free core must remain clear in every language

## Localization / Accessibility Impact

This plan owns that impact.

Focus areas:

- Long German/Portuguese labels
- Japanese/Chinese compact text
- Arabic RTL layout
- Currency symbol positioning
- Dynamic Type overflow
- VoiceOver order on Home
- Ring/chart descriptions

## Testing Requirements

- Build with all string catalogs valid
- Search for hardcoded user-facing strings
- Dynamic Type QA
- VoiceOver QA
- Reduce Motion QA
- High contrast QA
- RTL QA
- Small-screen layout QA
- Paywall localization QA

Stage A QA checklist:

- Home, DesignSystem, calculation engine, income/expense, and basic savings localization/accessibility coverage
- Core status/pace/savings language remains clear and non-shaming in all supported locales
- Dynamic Type, VoiceOver, Reduce Motion, high contrast, RTL validation for redesigned core flows

Stage B QA checklist (after auth/sync scope freeze):

- Apple Sign In copy and accessibility
- Supabase backup/sync states (`syncing`, `synced`, `offline`, `needs attention`)
- Account deletion and cloud data deletion confirmation flows
- Restore + sign-in-after-local-use migration messaging
- Sync error and recovery copy localization

## Step-by-Step Implementation Sequence

1. Audit current localization coverage
2. Inventory new string areas
3. Define copy style rules
4. Define accessibility rules
5. Define Stage A device/language QA matrix
6. Add strings alongside core feature implementation
7. Run Stage A localization/accessibility QA
8. Freeze auth/sync scope and add Stage B auth/sync copy matrix
9. Run Stage B localization/accessibility QA before release

## What To Postpone

- Perfect marketing copy
- Full App Store screenshot localization
- Advanced animation polish
- Nonessential mascot copy variants

## Success Criteria

- All new user-facing strings have localization keys
- Accessibility requirements are documented
- QA matrix is defined
- Critical financial values remain readable
- The redesign can ship without localization regressions

