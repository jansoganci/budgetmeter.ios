# Design System Redesign Plan

## Purpose

Plan the design system changes needed for the Playful Momentum FinTech redesign before screens are rebuilt.

The design system must make BudgetMeter feel dark-first, polished, readable, playful, and trustworthy without becoming childish or casino-like.

## Scope

- Colors
- Typography
- Spacing
- Cards
- Buttons
- Charts
- Glass usage
- Premium visual treatment
- Pulsey asset rules
- Motion/haptics guidance
- Accessibility constraints

## Current Codebase Context

`CLAUDE.md` identifies:

- `budgetmeter.ios/DesignSystem/Components/Cards/`
- `budgetmeter.ios/DesignSystem/Components/Charts/`
- `budgetmeter.ios/DesignSystem/Colors/`
- `budgetmeter.ios/DesignSystem/Typography/`
- `budgetmeter.ios/DesignSystem/Spacing/`
- `CoreKit/Sources/Premium/ThemeManager`

Audit must verify actual component names and usage.

## Product Decisions It Must Respect

- Dark-first identity
- Obsidian / dark navy background
- Slate card surfaces
- Vivid cyan / blue / indigo primary accent family
- Emerald positive momentum
- Amber caution
- Coral negative drain
- Avoid purple/pink AI gradient overuse
- Avoid casino gold glow
- Glass only for nav, sheets, overlays, secondary surfaces
- Critical numbers on solid/near-solid surfaces
- Premium personalization is controlled

## Files / Folders Likely To Be Touched

- `budgetmeter.ios/DesignSystem/`
- `budgetmeter.ios/Assets.xcassets/`
- Feature views using hardcoded styling
- `CoreKit/Sources/Premium/ThemeManager.swift`
- `Resources/` for design-related labels

## New Code Likely Needed

- New color tokens
- Semantic financial color tokens
- Momentum card components
- Ring visual component
- Premium badge/lock components
- Button variants
- Chart style variants
- Motion/haptic utilities if not already present

## Existing Code Likely To Be Revised

- Brand color definitions
- Text styles
- Card components
- Chart components
- ThemeManager
- Feature views with one-off styles

## Code That Must Not Be Touched Yet

- Feature business logic
- Persistence
- CalculationEngine formulas
- Supabase/Auth
- CoreData model

## Data / Migration Risks

Low direct data risk. Main risk is visual regression or premium theme state incompatibility.

Existing theme settings may need migration if current themes conflict with controlled personalization.

## Premium / Free Boundary Impact

- Default design must feel polished for free users
- Premium themes must enhance, not repair, the product
- Premium personalization includes accent packs, premium themes, app icon variants, chart styles, and Pulsey accent variants
- Unlimited color editing is out of scope

## Localization / Accessibility Impact

- Color states must have text/icon backup
- Dynamic Type support is required
- High contrast must be planned
- Reduce Motion must be respected
- RTL layout should not break card hierarchy

## Testing Requirements

- Visual QA across light/dark if light mode exists
- Accessibility contrast checks
- Dynamic Type checks
- Reduce Motion behavior checks
- Localization overflow checks
- Component preview checks if available

## Step-by-Step Implementation Sequence

1. Audit existing DesignSystem usage
2. Inventory hardcoded colors/styles
3. Define final tokens
4. Define card/button/chart component needs
5. Define glass usage rules
6. Define premium component rules
7. Define accessibility constraints
8. Refactor shared components before feature screens
9. Adopt components screen by screen

## What To Postpone

- Full theme marketplace
- Unlimited customization
- Complex Pulsey variants
- Advanced chart themes
- App icon variants until premium scope is stable

## Success Criteria

- Design tokens are planned
- Core components are identified
- Premium/free visual boundaries are clear
- Accessibility requirements are explicit
- Feature screens can be redesigned consistently

