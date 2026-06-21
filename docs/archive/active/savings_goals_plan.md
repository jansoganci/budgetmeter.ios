# Savings Goals Plan

## UI

- Savings goals should stay simple and direct
- The main purpose is to show savings speed and timeline
- The current app already has savings goal entry; redesign should improve UX without removing existing core behavior
- Home should show a lightweight savings progress module
- Dedicated savings screens can show more detail, but should not feel like complex financial planning
- Users should be able to enter a target savings amount easily
- One basic savings goal should remain simple enough to support Home without feeling like a planning tool
- Progress should be understandable at a glance
- Timeline estimate should be written in plain language
- Avoid overloading savings with too many goal management options on the main dashboard
- Advanced savings features should support the Playful Momentum FinTech direction through milestones and progress, not complex financial planning

## User Flow

- User should be able to set a basic savings target quickly
- Basic savings goal should include target amount, optional current saved amount, and estimated timeline
- User should see how much they currently save per month or period
- User should see an estimate of how long it may take to reach the target
- User should understand if their current net pace supports the target
- Basic savings target should support the core dashboard
- Advanced goal management should stay outside the main Home dashboard
- Users should not need to understand complex investment or budgeting concepts
- If current saved amount is unavailable, calculation should use `0`

## Services

- Savings service should calculate progress toward a target
- Savings service should estimate timeline based on current net saving pace
- Savings service should support Home dashboard savings display
- Savings service should support simple goal-based saving estimate
- Savings service should avoid complex financial planning logic unless product direction changes
- Savings calculations must use the same shared financial summary / net pace as Home
- Savings milestone logic should use the same savings progress data as the basic savings goal
- Default timeline baseline should use daily net pace from the shared calculation engine output
- Timeline output can be formatted as days/weeks/months for readability
- Savings calculations must not use a separate hidden formula in Home, widgets, or savings screens

## Data Model

- Basic savings target amount
- Optional current saved amount or current savings progress state
- Estimated savings based on shared net pace (daily baseline by default)
- Timeline estimate for reaching target
- One basic savings goal is free
- Multiple savings goals are premium
- Target dates are premium when used as advanced savings goal tracking
- Advanced milestones, history, forecasting, and richer progress views are premium

## Backend / Database

- Basic savings target data should be available locally
- Savings progress should read the same income and expense data used by the dashboard
- Premium cloud backup/sync should include savings goal data
- Backend/database support should stay practical and limited to savings target, progress, and timeline needs

## Premium Rules

- One basic savings goal should remain part of the free product
- Basic savings goal includes target amount, optional current saved amount, and estimated timeline
- Home savings progress should remain visible in the free core dashboard
- Multiple goals are premium
- Advanced savings tracking, milestones, target dates, history, forecasting, and richer progress views are premium
- Premium should not block the user's basic understanding of savings speed and timeline

## Open Questions

- Should current saved amount be manually entered in v1 savings flow, or derived only where explicit source data exists?
- Which savings details belong on Home vs a dedicated savings screen?

## Technical Planning Later

- exact savings goal model TBD
- exact Home savings module data TBD
- timeline calculation details TBD
- multiple goals implementation TBD
- premium target date behavior TBD
- sync/backup dependency TBD
- ViewModel changes TBD
- implementation tasks TBD
