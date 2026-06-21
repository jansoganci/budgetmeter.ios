# Widgets Plan

## UI

- Widgets should stay simple and useful
- Widgets should reflect the same financial pace idea as the Home dashboard
- Widgets should show quick status, not dense budgeting detail
- v1 widget scope is fixed to Home Screen `systemSmall` only
- v1 widget shows net daily pace status + value (for example: "Moving forward +$12/day" or "Slowing down -$8/day")
- No lock screen widgets in v1
- No medium widgets in v1
- No complex charts in v1
- Widget visuals should be consistent with the Playful Momentum FinTech design direction
- Pulsey should not appear in v1 widget, except a tiny static brand mark if trivial
- Widgets should use dark-first surfaces, readable text, and lively but controlled accent colors
- Avoid complex interactions or crowded widget layouts
- Avoid putting critical financial values on unreadable blur or decorative effects

## User Flow

- Users should understand their financial status without opening the app
- Tapping a widget should open the most relevant app area
- Widget setup should be easy to understand from Settings or a lightweight setup screen
- Users should not need to configure many options to get value
- Widgets should reinforce the core question: am I financially moving forward or slowing down?
- Widget experience should not replace the Home dashboard, only extend it
- Widgets should feel like premium convenience, not required core functionality
- Widget tap should deep link to the Home hero section

## Services

- Widget data should depend on the same financial pace and net direction calculations as Home
- Widget data should support net daily pace status + value only in v1
- Widget data should support Day as the default main unit
- Widget refresh should respond to income, expense, savings, and settings changes
- Widget service should avoid separate calculation logic where possible
- Widget data should be stable enough for glanceable display

## Data Model

- Widget data should include only the minimum fields needed for display
- v1 widget state includes net daily pace value, positive/negative momentum state, short status copy, and currency
- Widget data should not require heavy history or reporting by default
- Widget data should align with the core dashboard data contract
- v1 uses a single widget type with one clear purpose

## Backend / Database

- Widgets should read the same local/shared app data used by Home
- Premium backup/sync should not create a separate widget calculation model
- If App Group or shared storage is needed, it should be planned with the database/sync work
- Widget implementation should be reviewed and tested before release
- Widget storage and refresh should stay practical and limited to widget needs

## Premium Rules

- Widgets are premium in the current product direction
- Premium widgets should provide convenience without blocking the core app value
- Non-premium users should see a locked teaser state with upgrade/paywall deep link
- Lock screen, medium, and richer widget variants are postponed beyond v1
- Pulsey widget treatments are postponed beyond v1
- Widget premium gating should align with the premium feature matrix

## Open Questions

- How should locked teaser copy be worded for non-premium users?
- What exact paywall/upgrade deep link route should the locked teaser use?
- How should widget refresh cadence be tuned for balance and battery?

## Technical Planning Later

- App Group/shared storage dependency TBD
- widget target setup TBD
- widget refresh behavior TBD
- premium gating behavior TBD
- deep link destinations TBD
- testing checklist TBD
- implementation tasks TBD
- medium/lock screen widget expansion (post-v1)
- Pulsey widget states (post-v1)
- savings/biggest-drain widget variants (post-v1)
