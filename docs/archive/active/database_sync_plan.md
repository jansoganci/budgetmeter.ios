# Database Sync Plan

## UI

- Database and sync choices should stay mostly invisible to the user
- The app should feel local-first even when cloud backup/sync is enabled
- Free users should be able to use the app locally
- Premium users should be able to enable cloud backup/sync
- UI should explain cloud backup and future cross-device access clearly
- Sync status should be simple, such as synced, syncing, offline, or needs attention
- Avoid exposing technical database language to users
- Settings should provide clear controls for sync, backup, account status, and data deletion
- Apple Sign In should be presented as the account method when backup/sync requires sign-in

## User Flow

- Users should be able to use the core financial pace app without database complexity
- Users should be able to start local and enable premium backup/sync later
- Premium users should understand that cloud backup/sync protects their data and prepares future cross-device access
- Users should not need to understand database architecture to enter income or expenses
- Data reset and backup restore flows should be deliberate and clear
- Sync errors should not block basic local tracking
- Local data should remain available when the device is offline
- Signing in should connect local user data to a stable cloud user identity

## Services

- Persistence should support fast income and expense entry
- Dashboard services should read the financial data needed for pace, net direction, savings progress, and charts
- Income and expense services should support recurring and one-time structures if the data model requires them
- Sync service should support premium cloud backup and future cross-device access
- Backup service should protect user financial data without turning the app into heavy accounting software
- Auth service should provide stable user identity through Apple Sign In and Supabase
- Sync service should use stable user IDs to associate cloud records with the correct user
- Data export should remain separate from sync and backup

## Data Model

- Financial data should support daily normalization for pace calculations
- Income and expense records should support recurring and one-time entries if the new flows require them
- The model should preserve net direction and pace calculation needs before advanced reporting needs
- Savings target data should support basic savings timeline calculations
- Historical data should support useful comparisons without overbuilding analytics
- Each signed-in user must have a stable user ID
- User identity should remain separate from financial calculations
- User-linked financial records should be designed so they can sync across devices in the future
- Local records should be able to map to cloud records when backup/sync is enabled
- The data model should support local-first operation and cloud-backed persistence

## Backend / Database

- Supabase is the preferred backend/database platform
- The architecture should be local-first and cloud-backed
- Local persistence should keep the app fast and usable offline
- Supabase should store user-linked financial data for premium backup, restore, and future cross-device sync
- Apple Sign In should provide the preferred iOS auth path into stable user identity
- A self-managed VPS should be avoided unless there is a strong reason
- Local SQLite/Core Data should remain the fast local layer unless technical planning chooses a different local store
- Backend/database support should serve the product's financial pace model, not reshape it into heavy accounting
- Detailed Supabase schema, migrations, RLS, and conflict handling should be handled in technical planning later

## Premium Rules

- Local income entry, expense entry, core dashboard, net result, money pace, and basic savings target should remain free
- Cloud backup and sync are premium convenience/protection features
- Free users can use the app locally without backup/sync
- Premium users can unlock cloud backup/sync through auth
- Advanced history and reporting can depend on richer persisted data and can be premium
- Premium should not be required to keep a user's basic local data safe
- Data export can remain premium if product direction keeps export as a convenience feature

## Open Questions

- Which premium backup/sync scope should ship first?
- Which data types need cloud backup in the first version?
- How much historical data should be stored for free users?
- How should cloud backup, restore, reset, and account deletion work?
- Should widgets read from local data only or synced data as well?
- How should local records merge with cloud records when a user signs in after local use?
- What offline conflict behavior is acceptable for the first sync release?

## Technical Planning Later

- Supabase schema design TBD
- Supabase migrations TBD
- Supabase RLS policies TBD
- exact local/cloud architecture TBD
- exact Core Data changes TBD
- stable user ID mapping TBD
- sync conflict handling TBD
- backup and restore flow TBD
- data deletion flow TBD
- historical data retention TBD
- widget data dependency TBD
- implementation tasks TBD
