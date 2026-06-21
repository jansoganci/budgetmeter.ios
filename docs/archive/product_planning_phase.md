# BudgetMeter Product Planning

## Product Direction

- Let users quickly enter earnings and expenses
- Show whether they are earning or losing money
- Make the result visible per minute, hour, day, and month
- Keep the experience simple, fast, and personal
- Build the app first for personal daily use
- Keep the main core around financial pace and net direction
- The app should feel different from a classic budgeting app
- The app should feel different in structure, input flow, and presentation
- The product should focus on net life pace, not heavy accounting
- The app should answer whether the user is moving forward or backward financially
- Do not turn the app into a heavy budgeting tool
- Keep the app centered on one question:
- "Am I financially moving forward or backward?"
- Keep the app centered on personal financial clarity
- Keep the product meaningfully different in experience and decision flow

## Core Dashboard

- Instant financial clarity
- Clear net result
- Better awareness of spending drains
- Simple view of financial progress
- Live earning rate
- Live expense rate
- Net flow summary
- Per minute / hour / day / month view
- Biggest expense categories
- Month vs last month comparison
- Simple end-of-month forecast
- History of earnings and expenses
- The home screen should show status first, not long lists
- Show whether the user is positive or negative
- Show what is draining the money most
- Show how fast the user is saving
- Show how long it may take to hit a savings target
- Core dashboard
- Net result visibility
- Money pace view per minute, hour, day, and month

## Income Flow

- Fast manual tracking
- Rethink how income is entered
- Make entry feel simple and natural
- Let users classify money as income, fixed expense, surprise expense, or goal-related money
- Income entry
- Recurring income and recurring expenses

## Expense Flow

- Rethink how expenses are entered
- Clear separation between regular and surprise expenses
- Separate regular monthly expenses
- Separate one-time surprise expenses
- Fixed expenses should be clearly visible
- Surprise or one-time expenses should be clearly visible
- Users should understand what is predictable and what is unexpected
- Expense entry
- Basic fixed vs surprise expense tracking

## Savings Goals

- Simple understanding of savings speed and timeline
- Savings timeline calculator
- Goal-based saving estimate
- Let users enter a target savings amount
- Show how much they currently save per month
- Estimate how many months are needed to reach the target
- Keep this feature simple and direct
- Basic savings target calculation

## Premium

- Sell premium as a one-time lifetime purchase
- Unlock stronger money insights and convenience features
- Keep the free app useful, but make premium feel complete
- Advanced insights
- Recurring transaction automation
- Full history and reporting
- Multi-device sync
- Cloud backup
- Better charts and comparisons
- Forecasting

### Free vs Premium Direction

#### Free

- Income entry
- Expense entry
- Core dashboard
- Net result visibility
- Money pace view per minute, hour, day, and month
- Basic savings target calculation
- Basic fixed vs surprise expense tracking

#### Premium

- Advanced insights
- Widgets
- Recurring transactions
- Data export
- Biometric lock
- Premium themes
- Advanced history and reporting
- Richer comparisons
- Forecasting
- Multi-device sync and backup

### Product Boundary Note

- Free should deliver the core product value
- Premium should unlock deeper control, better insight, and more convenience
- Premium should not block the main reason people use the app

### Current Codebase Premium Inventory

- Premium paywall exists
- Premium purchase flow exists
- Insights are already premium-gated
- Widgets are already started
- Data export exists
- Biometric feature exists
- Premium themes exist
- Recurring transactions feature exists
- Savings goals feature exists
- Bills and subscriptions features exist

## Auth

- Add auth only if the app needs sync, backup, or cross-device access
- Keep auth simple: sign in, sign up, sign out, reset password
- Make auth support the database strategy, not lead the product
- Decide auth requirement

## Database / Sync

- Local-only database if the app stays offline-first
- Supabase if the app needs auth, sync, and cloud storage
- Do not use self-managed VPS unless there is a strong reason
- Cloud backup and sync
- Decide local-first vs cloud-sync architecture
- Decide database approach
- Define backup and sync scope
- Local SQLite does not need a VPS if it stays on-device
- Supabase removes the need to manage your own backend server

## Widgets

- iOS home screen widgets
- iOS lock screen widgets
- Widget support is already started
- It still needs proper testing
- Final widget experience should stay simple and useful
- Review and test widget implementation
- Finalize widget scope and widget data

## Onboarding

- Add onboarding after auth
- Ask reasonable questions about the user
- Use onboarding to personalize the app
- Define onboarding flow after auth
- Define onboarding questions for users
- Define onboarding flow for free and premium users

## UI Redesign

- Change the whole UI
- Change the whole style
- Rework the product presentation around the app core
- Redesign the whole UI
- Redesign the whole visual style

## Technical / Planning Notes

- RevenueCat is useful for purchase handling and entitlement management
- Add RevenueCat purchase flow
- Define free vs premium feature boundaries
- Define the final premium offer
- Define user data model for earnings and expenses
- Define recurring transaction model
- Define insights and reporting model
