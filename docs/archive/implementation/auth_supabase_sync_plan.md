# Auth Supabase Sync Plan

## Purpose

Plan Apple Sign In, Supabase, stable user IDs, and premium cloud backup/sync without disrupting local-first usage or existing CoreData/CloudKit behavior.

This is a high-risk architecture area and should not be implemented until local data and calculation contracts are stable.

Supabase is the target long-term backend for authenticated user-linked backup/sync. CloudKit is current/legacy infrastructure and will be removed after audit + migration planning confirms that live user data can be preserved safely.

## Scope

- Apple Sign In
- Stable user ID
- Supabase as preferred backend
- Local-first UX
- Premium cloud backup/sync
- Existing CoreData + CloudKit status
- Account/session behavior
- Backup/restore
- Future cross-device access
- Data deletion
- Conflict handling

## Current Codebase Context

`CLAUDE.md` states current persistence is CoreData + CloudKit and zero external dependencies. Supabase is planned in product docs, but likely not present in code yet. This creates dependency and migration risk.

## Product Decisions It Must Respect

- Apple Sign In is planned
- Supabase is planned
- Stable user identity is required and must come from authenticated account identity
- Free users can use the app locally
- Premium users unlock cloud backup/sync
- Auth exists for identity, backup, restore, future cross-device access
- StoreKit remains purchase source
- Auth does not replace premium entitlement checks
- CoreData can remain the local store
- CloudKit will not remain as the long-term sync backend
- Do not keep CloudKit and Supabase as parallel long-term sync systems unless a strong operational reason is documented
- Use Supabase Auth with Apple Sign In
- Use Supabase database for user-linked cloud data
- Use Supabase Edge Functions only if needed for secure backend logic

## Files / Folders Likely To Be Touched

- New Auth module, name TBD
- New Sync/Backup module, name TBD
- `CoreKit/Sources/Persistence/`
- `Features/SettingsFeature/`
- `Features/PremiumFeature/`
- Entitlements later
- App configuration later

Exact locations must be decided after audit.

## New Code Likely Needed

- Auth service
- Supabase client/API layer
- Stable user ID mapping based on authenticated account
- Backup service
- Sync state model
- Account settings UI model
- Local-to-cloud mapping metadata
- Conflict handling strategy

## Existing Code Likely To Be Revised

- PersistenceService
- AppSettings
- PremiumManager integration points
- Settings/account screens
- Data export/backup surfaces

## Code That Must Not Be Touched Yet

- CoreData schema until migration plan exists
- CloudKit removal/deactivation
- Xcode entitlements
- Dependency additions
- Supabase schema
- Account deletion implementation

## Data / Migration Risks

- Existing CloudKit data may exist
- Free users must retain local data
- Signing in after local use requires merge/backup behavior
- Stable account user ID must not conflict with local record IDs
- Cloud backup must not overwrite newer local data
- Account deletion has legal/privacy implications
- Users can lose data if first sign-in/first-backup flow is destructive or ambiguous

## Premium / Free Boundary Impact

- Auth itself is not premium
- Backup/sync is premium
- Free users can remain local without account
- Premium users need auth for backup/sync
- StoreKit entitlement remains separate from auth identity

## Localization / Accessibility Impact

- Sign-in, sync, backup, restore, error, and deletion copy must be localized
- Sync state must be understandable
- Apple Sign In button/accessibility rules must be followed
- Destructive data flows require clear accessible confirmation

## Testing Requirements

- Auth session tests where possible
- Local-only regression tests
- Backup serialization tests
- Restore behavior tests
- Conflict scenario tests
- Premium gate tests for sync
- Manual QA for Apple Sign In

## Step-by-Step Implementation Sequence

1. Complete codebase audit
2. Complete data model migration plan
3. Decide CoreData + CloudKit transition strategy and explicit Supabase target cutover
4. Define stable ID rules
5. Define first backup scope
6. Define local-to-cloud merge behavior
7. Define account/session states
8. Define Supabase schema separately
9. Define RLS and deletion behavior
10. Implement only after local core redesign is stable unless priority changes

## What To Postpone

- True real-time sync
- Multi-device conflict sophistication
- CloudKit removal implementation work until migration readiness is confirmed
- RevenueCat entitlements
- Email/password auth
- Social login beyond Apple
- Team/family sharing

## Success Criteria

- Local-first behavior is protected
- Premium backup/sync boundary is clear
- Stable user ID strategy is planned
- CloudKit/Supabase coexistence risk is documented
- No cloud implementation starts before migration risks are understood

## Stable Identity And Privacy Guidance (Apple + Supabase)

- Use authenticated account identity as source of truth: map app user identity to Sign in with Apple identity (`sub`) and Supabase `auth.users.id`.
- Treat `auth.users.id` as database-level stable user key for user-linked data and RLS.
- Do not use random local-only identifiers as long-term user identity for cloud ownership.
- Avoid using device identifiers (`IDFV`, device fingerprinting) as account identity.
- If `IDFV` is used at all for diagnostics, treat it as non-authoritative and changeable.
- Do not collect or depend on IDFA for BudgetMeter v1; no ads in v1.
- Keep local-only users fully functional without sign-in.

## First Sign-In / First Backup Safety Strategy

- Never replace local data immediately when user signs in.
- On first sign-in, create a migration session and classify data as local-only, cloud-only, or both.
- Default to non-destructive merge/copy behavior for first backup.
- Require explicit confirmation before destructive restore/overwrite operations.
- Keep an audit marker for migration completion so first-backup logic is idempotent.
- Add recoverability paths: local snapshot before merge and clear rollback messaging in settings.

## External Guidance References

- Apple Sign in with Apple auth docs: unique stable `sub` for app/team identity.
- Apple `identifierForVendor` docs: not permanent; changes in reinstall/test scenarios.
- Apple App Tracking Transparency + privacy rules: no fingerprinting; no IDFA dependence without consent.
- Supabase Auth user-data docs: use `auth.users.id` as stable primary key reference with RLS.
- Supabase identity-linking docs: identity linking is account-level, not device-ID-based.

