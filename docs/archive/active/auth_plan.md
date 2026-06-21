# Auth Plan

## UI

- Auth should stay simple and should not become a primary product surface
- Auth exists to support stable user identity, cloud backup, restore, and future cross-device access
- Apple Sign In is the preferred auth method for iOS
- Auth UI should support sign in, sign out, and restore session
- Auth should explain why an account is needed in plain language: backup, restore, and cross-device access
- Auth should not block local free usage
- Keep auth visually consistent with the rest of the app redesign
- Avoid finance-heavy or enterprise-style account setup screens
- Avoid email/password for now unless a later product or backend requirement makes it necessary

## User Flow

- Users should be able to understand the app's core value before being forced into account decisions
- Free users should be able to use the core app locally without signing in
- Premium users should sign in when enabling cloud backup, restore, or sync
- Apple Sign In should be the default sign-in option on iOS
- Users should be able to start local and add an account later
- Users should be able to continue using the core app without sync
- Users should be able to sign out without losing local data unless they explicitly choose data deletion
- Auth should restore an existing session where possible
- Email/password recovery should not be part of the first auth scope unless email/password is explicitly added later

## Services

- Auth should support stable user identity for sync, backup, restore, and future cross-device access
- Auth should connect cleanly to entitlement, backup, and sync services
- Auth should keep session state simple and observable by app settings and sync services
- Auth should not be used as a growth or onboarding gate for the core financial pace experience
- Supabase is the preferred backend platform for auth-linked user data
- StoreKit remains the preferred iOS purchase system; auth should not replace StoreKit entitlement checks

## Data Model

- User identity should be separate from local financial pace data
- Each signed-in user must have a stable user ID
- Local financial data should remain usable without a remote user account
- When backup/sync is enabled, user identity should map to the user's financial records and backup scope
- User financial data should be designed so it can sync across devices in the future
- Auth metadata should stay minimal
- Do not store unnecessary personal profile data
- Data deletion and sign-out behavior should be defined before implementation

## Backend / Database

- Supabase is the preferred backend/database platform
- Apple Sign In should connect to the selected backend auth strategy
- The backend should provide stable user identity for user-linked financial data
- Self-managed auth should be avoided unless there is a strong reason
- Auth should support cloud backup and future multi-device sync
- Detailed backend auth configuration should be handled in technical planning

## Premium Rules

- Auth itself should not be sold as a premium feature
- Core local app use should remain free
- Premium should unlock cloud backup and sync
- Premium users need auth to use backup, restore, and future cross-device access
- Biometric lock should remain a premium convenience/security feature, separate from account auth
- Premium entitlement should continue to use StoreKit for the current lifetime purchase model
- RevenueCat remains optional later, not required now

## Open Questions

- What exact point in the premium sync/backup flow should request Apple Sign In?
- What happens to local data when the user signs out?
- What is the account deletion and cloud data deletion flow?
- How should local data merge with cloud data when a user signs in after using the app locally?
- What session expiration behavior should the app expose to users?

## Technical Planning Later

- Supabase auth configuration
- Apple Sign In implementation details
- stable user ID mapping
- session restore behavior
- account deletion flow TBD
- local data vs cloud data behavior TBD
- entitlement/auth relationship TBD
- local-to-cloud merge behavior TBD
- implementation tasks TBD
