# Income Flow Plan

## UI

- Income screen should be summary-first
- Recurring and one-time income should be visually separate
- The flow should feel simple and easy to understand
- The structure should support the same style direction that will later be used for the Expense screen

## User Flow

- User should first select income type
- After income type, user should choose whether the income is recurring or one-time
- Recurring income should be entered inside the main Income Flow
- One-time income should also be entered inside the main Income Flow
- Users should not face too many choices at once

## Services

- Income flow should support recurring income inside the main Income module
- Income flow should support one-time income inside the main Income module
- All income values should normalize to daily value as the base calculation

## Data Model

- Income type first, then recurring or one-time
- Stable/variable should be optional only for recurring income
- Default income categories should stay small
- Custom income categories should exist as a secondary extension, not the main structure

## Backend / Database

- Backend/database should support recurring income and one-time income as separate structures if needed
- All stored income values should support normalization to daily value as the base calculation

## Premium Rules

- Core income flow should remain part of the free product
- Recurring income inside Income Flow should remain part of the core product unless product direction changes later

## Open Questions

- Exact default category list TBD
- Exact summary metrics TBD

## Technical Planning Later

- exact Core Data changes TBD
- exact ViewModel changes TBD
- recurring income implementation TBD
- one-time income model TBD
- daily normalization logic TBD
- backend/database dependency TBD
- implementation tasks TBD
