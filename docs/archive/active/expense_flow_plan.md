# Expense Flow Plan

## UI

- Expense screen should be summary-first
- Fixed/regular expenses and surprise/one-time expenses should be visually separate
- The flow should feel simple and easy to understand
- Expense entry should support the same style direction as the Income screen
- Expense entry should support the Playful Momentum FinTech direction without feeling like accounting software
- Predictable expenses should be clearly visible
- Unexpected expenses should be clearly visible
- Avoid making users manage too many categories before entering an expense
- Keep the screen focused on what drains money and how it affects financial pace
- Negative expense impact should use calm, useful language and should not shame the user

## User Flow

- User should first select expense type
- After expense type, user should choose whether the expense is regular or surprise/one-time
- Regular expenses should be entered inside the main Expense Flow
- Surprise or one-time expenses should also be entered inside the main Expense Flow
- Basic bill/subscription-style expenses should be entered as regular expenses if the user only needs them to count toward pace
- Users should not face too many choices at once
- Users should understand whether an expense is predictable or unexpected
- Expense entry should help the dashboard explain why the user is moving forward or slowing down

## Services

- Expense flow should support regular recurring expenses inside the main Expense module
- Expense flow should support one-time surprise expenses inside the main Expense module
- Expense values should normalize to daily value when needed for pace calculations
- Expense services should support biggest drain calculations for the dashboard
- Expense services should support simple fixed vs surprise summaries
- Bills and subscriptions should roll up into the same regular expense totals used by Home
- One-time expenses should affect only the selected/current period where they occur
- One-time expenses should not change the permanent long-term pace baseline
- Expense services should avoid heavy accounting concepts unless needed later

## Data Model

- Expense type first, then regular or one-time
- Fixed/regular expenses should be distinguishable from surprise/one-time expenses
- Bills and subscriptions are specialized fixed/regular expenses
- Basic bill/subscription-style expenses can count as regular expenses
- Advanced bill/subscription management should be treated as premium behavior, not a separate core financial model
- One-time expenses should preserve occurrence date and selected/current period impact
- One-time expenses should not become recurring unless the user creates or converts them into a regular expense
- Default expense categories should stay small and practical
- Custom expense categories should exist as a secondary extension, not the main structure
- Expense records should preserve enough timing information for pace, forecast, and simple comparisons
- Goal-related spending should remain understandable without adding complex budgeting structures

## Backend / Database

- Backend/database should support regular and one-time expenses as separate structures if needed
- All stored expense values should support normalization to daily value as the base pace calculation
- Expense data should support Home dashboard needs: net direction, biggest drain, forecast, and comparisons
- Bills and subscriptions should map into the regular expense model for shared pace calculations
- One-time expenses should be stored as dated events and should not change long-term recurring pace
- Database support should stay practical and not expand into full accounting unless product direction changes

## Premium Rules

- Core expense entry should remain part of the free product
- Basic recurring/fixed expense entry should remain part of the free product
- Basic fixed vs surprise expense tracking should remain part of the free product
- Basic bill/subscription-style expenses can be tracked as regular expenses for free
- Expense data needed for core dashboard and money pace should remain free
- Advanced expense insights, richer comparisons, forecasting, export, and history can be premium
- Recurring expense automation is premium
- Advanced bill/subscription management, reminders, renewal tracking, and automation are premium

## Open Questions

- Exact default expense category list TBD
- Exact fixed vs surprise naming TBD
- Exact summary metrics TBD

## Technical Planning Later

- exact Core Data changes TBD
- exact ViewModel changes TBD
- fixed expense implementation TBD
- surprise expense implementation TBD
- one-time expense model TBD
- daily normalization logic TBD
- bill/subscription premium management implementation TBD
- backend/database dependency TBD
- implementation tasks TBD
