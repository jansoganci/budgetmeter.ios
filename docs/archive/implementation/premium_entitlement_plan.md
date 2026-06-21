# Premium Entitlement Plan

## Purpose

Plan premium entitlement and feature gating before premium features are revised or expanded.

BudgetMeter must keep the core financial pace experience free while premium unlocks control, personalization, convenience, protection, export, widgets, and deeper insight.

## Scope

- StoreKit lifetime purchase
- Restore purchase
- PremiumManager
- Feature gates
- Ads-free
- Widgets
- CSV/PDF export
- Premium themes
- Custom categories
- Biometric lock
- Advanced history/reporting
- Forecasting
- Multiple savings goals
- Cloud backup/sync
- RevenueCat optional later

## Current Codebase Context

`CLAUDE.md` says premium/IAP is partially implemented and identifies:

- `CoreKit/Sources/Premium/`
- `Features/PremiumFeature/`
- `CoreKit/Sources/Security/`
- `CoreKit/Sources/Export/`

Current purchase status must be verified during audit.

## Product Decisions It Must Respect

- StoreKit remains preferred for current lifetime purchase
- RevenueCat remains optional later
- Core value remains free
- Premium includes ads-free, widgets, CSV/PDF export, themes, advanced insights, custom categories, biometric lock, advanced history/reporting, forecasting, multiple goals, cloud backup/sync
- Premium personalization is controlled
- Premium must not affect the core calculation engine result

## Files / Folders Likely To Be Touched

- `CoreKit/Sources/Premium/`
- `Features/PremiumFeature/`
- `Features/SettingsFeature/`
- `CoreKit/Sources/Security/`
- `CoreKit/Sources/Export/`
- Widget gating code later
- StoreKit configuration if present

## New Code Likely Needed

- Central feature gate matrix
- Premium entitlement state model
- Restore state handling
- Offline entitlement behavior
- Premium personalization selection model
- Ads-free flag handling if ads are added

## Existing Code Likely To Be Revised

- PremiumManager
- Paywall views
- ThemeManager
- Biometric feature access
- Export access
- Settings premium rows
- Feature gates scattered across screens

## Code That Must Not Be Touched Yet

- Supabase sync entitlement coupling
- Xcode StoreKit products
- RevenueCat integration
- Core financial calculations
- CoreData schema

## Data / Migration Risks

- Existing premium users must keep access
- Product IDs may be placeholders or real
- Local cached entitlement could conflict with StoreKit state
- Premium theme settings may need compatibility handling

## Premium / Free Boundary Impact

This plan owns the boundary.

Free:

- Core dashboard
- Income/expense entry
- Basic recurring entries
- Basic savings goal
- Basic fixed vs surprise tracking

Premium:

- Ads-free
- Widgets
- CSV/PDF export
- Premium themes/personalization
- Custom categories
- Biometric lock
- Advanced history/reporting
- Forecasting
- Multiple savings goals
- Cloud backup/sync
- Advanced bill/subscription automation

## Localization / Accessibility Impact

- Paywall copy must be localized
- Restore and purchase error states must be localized
- Premium badges/locks need accessible labels
- Premium visuals cannot rely only on color/glow

## Testing Requirements

- Entitlement state tests
- Feature gate tests
- Restore purchase tests/manual StoreKit QA
- Offline entitlement behavior tests
- Free core access regression tests
- Premium personalization access tests

## Step-by-Step Implementation Sequence

1. Audit current PremiumManager and StoreKit status
2. Inventory current premium gates
3. Define final feature gate matrix
4. Define restore behavior
5. Define offline behavior
6. Define premium personalization model
7. Define tests
8. Refactor central gate checks
9. Add feature-specific gates incrementally

## What To Postpone

- RevenueCat
- Subscriptions
- Remote paywall experimentation
- Complex pricing tests
- Cloud entitlement syncing beyond StoreKit/local needs

## Success Criteria

- Feature gate matrix is clear
- StoreKit lifetime direction is preserved
- Restore behavior is planned
- Free core cannot be accidentally gated
- Premium features can be implemented consistently

