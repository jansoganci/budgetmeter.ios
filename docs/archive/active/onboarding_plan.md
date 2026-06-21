# Onboarding Plan

## UI

- Onboarding should be short and focused on making the first dashboard useful
- Onboarding should explain BudgetMeter as a financial pace / live money meter app
- Onboarding should feel playful, modern, and encouraging without feeling childish
- Pulsey can appear lightly in onboarding as a small abstract finance creature
- Pulsey should represent momentum, pulse, financial heartbeat, and forward motion
- Pulsey should be cute but not childish
- Pulsey should not dominate onboarding screens or slow the setup path
- Onboarding should not feel like a heavy budgeting setup
- Ask only reasonable questions that help personalize the app
- Avoid long forms and detailed accounting setup
- Use plain language around earning, spending, net direction, savings pace, and awareness
- If auth is introduced in onboarding, explain that Apple Sign In supports backup, restore, and future cross-device access

## User Flow

- Users should quickly understand the core question: am I financially moving forward or slowing down?
- Users should be guided to enter enough income and expense data to make the first pace result meaningful
- Onboarding should support both free and premium users without making premium required
- Free users should be able to start locally without signing in
- Premium users should be able to enable Apple Sign In for cloud backup/sync at the right point in the flow
- Users should be able to skip non-essential personalization
- First-run setup should end on the Home dashboard with a clear financial pace result or next step
- Premium education should appear after the user understands the free money pace value

## Services

- Onboarding should prepare the minimum data needed for the core dashboard
- Onboarding should connect to income, expense, savings target, currency, optional personalization, and optional sync services
- Onboarding should not create a separate product logic path from normal income and expense flows
- Onboarding should support personalization only where it improves clarity or emotional connection
- Onboarding should support premium education without forcing a paywall before core value is shown
- Apple Sign In should support stable user identity when backup/sync is enabled

## Data Model

- Onboarding data should map into the same income, expense, settings, and savings structures used by the app
- Store only data needed for financial pace, personalization, user preferences, and optional backup/sync
- Suggested onboarding data may include currency, basic income, basic regular expenses, optional savings target, and optional theme/accent preference
- Pulsey onboarding state should be lightweight and should not create a separate mascot progression system
- Avoid collecting unnecessary personal profile data
- User account data should stay separate from financial entries

## Backend / Database

- Onboarding should work with local-first storage for free users
- Apple Sign In is planned for users enabling premium backup/sync
- Supabase is planned for user-linked backup/sync data
- Onboarding should support account setup and backup opt-in without making it the first meaningful app experience
- Backend/database behavior should be consistent with normal app entry and update flows

## Premium Rules

- Onboarding should show the free core value first
- Core onboarding for income, expense, dashboard, net result, money pace, and basic savings target should remain free
- Premium can be introduced as personalization, ads-free experience, widgets, export, biometric lock, themes, advanced insights, history, forecasting, multiple savings goals, and sync/backup
- Premium personalization should be framed as curated control, not unlimited design editing
- Do not make account creation or premium purchase the first meaningful app experience

## Open Questions

- What exact onboarding screen sequence should be used?
- What is the minimum data needed to produce a useful first dashboard?
- Should users be asked for a savings target during onboarding?
- Should onboarding include currency selection?
- Where should the optional Apple Sign In / backup explanation appear?
- Should onboarding include a short Pulsey splash-to-onboarding transition?
- Should onboarding include a premium explanation screen after first value is shown?
- Should onboarding support skip and later setup?

## Technical Planning Later

- exact onboarding screen sequence TBD
- exact first-run state model TBD
- exact questions TBD
- Apple Sign In onboarding dependency TBD
- sync/backup dependency TBD
- income and expense prefill behavior TBD
- savings target setup behavior TBD
- Pulsey asset and animation behavior TBD
- implementation tasks TBD
