# Premium Plan

## UI

- Premium should be presented as a one-time lifetime purchase unless product direction changes
- Premium should feel like unlocking more control, personalization, convenience, protection, and deeper insight
- BudgetMeter is becoming a fun, gamified consumer finance app, so premium should feel rewarding without making the free product feel restricted
- Paywall should explain premium as a richer version of the financial pace experience
- Paywall should not make the free product feel incomplete
- Premium UI should make the free vs premium boundary easy to understand
- Premium visual direction should feel refined and polished, not loud, casino-like, or cheap
- Premium can use subtle premium glass, refined lock/badge treatment, and soft gold/indigo edge treatment
- Premium should avoid loud purple/pink glow, casino-style gold glow, and obvious AI-looking gradients
- Avoid blocking the first core financial pace experience with a paywall
- Premium entry points should appear where premium adds clear value
- Keep premium messaging simple and direct
- Premium themes, widgets, exports, insights, and advanced history are good upgrade entry points
- Ads are deferred for v1 and should not be implemented in first release scope

## User Flow

- Users should experience the core value before being asked to upgrade
- Users should be able to enter income, enter expenses, add basic recurring income and expenses, view core dashboard, see net result, view money pace, and use a basic savings goal for free
- Users should be able to understand whether they are financially moving forward or backward without premium
- Premium upgrade should unlock personalization, convenience, deeper analysis, protection, exports, widgets, and advanced control
- Restore purchase should be clear and easy to find
- Users should understand that the current preferred premium model is a lifetime one-time purchase before purchase
- Premium should not block the main reason people use the app
- Premium prompts should appear after the user has seen useful financial pace value
- Premium users should be able to sign in for backup, restore, and future cross-device access
- Free users should be able to keep using the app locally without signing in

## Premium Positioning

- Free = understand your money pace
- Premium = personalize it, protect it, analyze it deeper, and access it everywhere

Premium should be positioned as an upgrade to the experience, not a gate in front of the core product.

The free product helps users quickly understand whether they are gaining or losing money and how fast.

Premium helps users make BudgetMeter feel more personal, more powerful, more convenient, and more useful over time.

Premium personalization should mean curated control, not unlimited visual editing.

Premium should preserve the Playful Momentum FinTech identity even when themes, accents, icons, or Pulsey variants change.

## Services

- Premium service should manage entitlement state cleanly
- StoreKit is the current preferred purchase system
- Purchase handling should support a lifetime one-time unlock
- Restore purchase should support existing premium users
- RevenueCat is optional later, not required now
- RevenueCat can be reconsidered if entitlement management, subscriptions, remote paywalls, or cross-platform needs become more complex
- Premium service should expose simple feature access checks
- Premium should connect to widgets, CSV export, PDF export, biometric lock, themes, advanced insights, custom categories, advanced history, forecasting, reminders, advanced savings goals, sync, and backup
- Premium should connect to controlled personalization: accent color packs, premium themes, app icon variants, chart style options, and Pulsey accent variants
- Premium should not be required by the calculation engine to produce the core financial pace result
- Auth exists to support stable user identity, backup, restore, and future cross-device access
- Premium sync and backup should use the same stable user identity as the auth plan and database sync plan

## Data Model

- Premium entitlement state should be simple and reliable
- Purchase date and entitlement type should be available if needed
- Premium state should not be mixed directly into core financial calculations
- Feature access should use entitlement state, not scattered local rules
- Ads-free can remain a future entitlement if ads are introduced in a later version
- Custom categories should be gated by premium while default categories remain available for free
- Advanced savings goals should be modeled separately from the free basic savings goal
- Premium personalization settings should be stored as controlled selections, not arbitrary user-defined color values
- Pulsey accent variants should be treated as controlled cosmetic options, not separate mascot personalities
- Cloud backup and sync should be linked to a stable user ID
- User financial data should be structured so premium users can restore it and sync it across devices in the future
- If RevenueCat or another purchase provider is selected later, local entitlement storage should be treated as cached state

## Backend / Database

- StoreKit should be used for current iOS premium purchase handling
- RevenueCat is not required for the current lifetime purchase direction
- Cloud sync and backup are planned premium features
- Supabase is the preferred backend/database platform for user-linked financial data, backup, and future cross-device sync
- Apple Sign In is the preferred iOS auth method for stable user identity
- Premium entitlement should work through StoreKit, while cloud backup/sync should require user auth
- Cloud sync and backup should not block local-first core product work
- Backend support should serve backup/sync and user identity, not reshape BudgetMeter into heavy accounting software

## Premium Rules

- Free should include income entry
- Free should include expense entry
- Free should include basic recurring income entry
- Free should include basic recurring expense entry
- Free should include core dashboard
- Free should include net result visibility
- Free should include financial pace / live money meter
- Free should include money pace view per minute, hour, day, week, and month where supported by the core dashboard
- Free should include one basic savings goal
- Free should include basic fixed vs surprise expense tracking
- Free should not require an account for local-first use
- Ads-free remains a future premium benefit only if ads are introduced after v1
- Premium should include widgets
- Premium should include CSV export
- Premium should include PDF export
- Premium should include premium themes
- Premium should include controlled personalization options
- Premium should include deeper / advanced financial insights
- Premium should include custom categories
- Premium should include advanced history and reporting
- Premium should include forecasting
- Premium should include biometric lock
- Premium should include cloud sync and backup
- Premium should include bill/subscription reminders or advanced management
- Premium should include multiple savings goals or advanced savings goal tracking
- Premium should include recurring transaction automation
- Premium should include richer comparisons

## Feature Boundary Decisions

- Basic recurring entries are free because they are required for an accurate money pace
- Recurring automation is premium because it adds convenience and control
- Basic fixed vs surprise expense tracking is free because it supports the core product model
- Bill and subscription reminders are premium because they are advanced management features
- Default categories are free
- Custom categories are premium
- Controlled accent color packs are premium
- Premium themes are premium
- App icon variants are premium
- Chart style options are premium
- Pulsey accent variants are premium
- Unlimited free color editing should not be included
- One basic savings goal is free
- Multiple goals and advanced savings goal tracking are premium
- Widgets are premium
- CSV and PDF export are premium
- Ads-free is a future premium benefit, out of v1 scope
- Cloud sync and backup are premium
- Auth is planned to support stable user identity, backup, restore, and future cross-device access
- Apple Sign In is the preferred auth method for iOS
- Free users can use the app locally without auth

## Premium Feature List

- Widgets
- CSV export
- PDF export
- Premium themes
- Controlled accent color packs
- App icon variants
- Chart style options
- Pulsey accent variants
- Deeper / advanced financial insights
- Custom categories
- Advanced history and reporting
- Forecasting
- Biometric lock
- Cloud sync / backup
- Bill/subscription reminders or advanced management
- Multiple savings goals or advanced savings goal tracking
- Recurring transaction automation
- Richer comparisons

## Open Questions

- Ads are deferred for v1. Revisit ad strategy in a later planning cycle.
- What exact widgets should ship first?
- What fields should CSV export include?
- What should the first PDF report contain?
- What premium themes should be available at launch?
- Which accent color packs should be included at launch?
- Which app icon variants should be included at launch?
- Which chart style options should be included at launch?
- Which Pulsey accent variants should be included at launch?
- How advanced should custom categories be in the first premium version?
- What exact bill/subscription reminder behavior is needed first?
- What advanced savings goal features should ship first?
- What exact cloud backup/sync scope should ship first?

## Technical Planning Later

- StoreKit product identifiers
- lifetime purchase entitlement model
- restore purchase behavior
- premium feature gate implementation
- ads strategy revisit (post-v1 only)
- widget entitlement checks
- CSV export format
- PDF export format
- premium theme implementation
- accent color pack model
- app icon variant scope
- chart style option scope
- Pulsey accent variant scope
- custom category storage rules
- biometric lock implementation
- Supabase schema planning
- sync conflict handling
- backup and restore behavior
- Apple Sign In session handling
- RevenueCat revisit only if StoreKit becomes insufficient
- paywall copy and pricing
- App Store metadata dependency
- implementation tasks
