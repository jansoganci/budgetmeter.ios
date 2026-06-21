# Phase 9 — Supabase Auth / Database Migration Scope

## 1. Executive Summary

Phase 9 prepares and implements Apple Sign In + Supabase Auth + Supabase database-backed premium backup/sync in a local-first way. It is the highest-risk implementation phase in the BudgetMeter redesign because it touches auth identity, cloud data ownership, local data preservation, CloudKit legacy migration, premium backup boundaries, account deletion, privacy copy, and data-loss prevention.

The product target is clear: free users keep a fully local app; premium users can sign in and unlock cloud backup/restore across devices. Auth itself is not premium. StoreKit remains the purchase source. Supabase `auth.users.id` is the stable cloud owner key. CloudKit is current legacy infrastructure and must not be removed until migration safety gates pass.

The current codebase is not ready for cloud behavior changes. `PersistenceService` still uses `NSPersistentCloudKitContainer`, all CoreData model versions are CloudKit/syncable, `SupabaseConfig.swift` exists with project credentials but no auth/sync service layer, privacy copy still describes iCloud-only cloud storage, and `BudgetMeterCapability.backupSync` is marked `.postponed` in the premium gate matrix.

Recommendation: **Ready for implementation planning after this document upgrade; not ready for cloud behavior implementation.**

First safe implementation step: define and test the first-sign-in safety contract, local snapshot format, and backup serialization contract using local fixtures only — before adding Sign in with Apple entitlements, before writing to Supabase, and before changing CloudKit behavior.

## 2. Current Codebase Context

Relevant current pieces:

- Phases 0–6 established shared financial summary, Home contract, income/expense flows, and basic savings alignment.
- Phase 7 centralized premium gates through `BudgetMeterCapability` and `PremiumManager.hasAccess(to:)`.
- Phase 8 defines widget v1 as premium and local snapshot based; Supabase-backed widget state is explicitly later scope.
- `PersistenceService` uses `NSPersistentCloudKitContainer(name: "BudgetMeter")` with persistent history tracking and remote change notifications enabled.
- CoreData store path attempts App Group placement at `group.com.budgetmeter.shared/BudgetMeter.sqlite`.
- Current CoreData model version is `BudgetMeter 3` with 8 entities, all `syncable="YES"` and `usedWithCloudKit="YES"`.
- `SupabaseConfig.swift` exists under `CoreKit/Sources/Auth/` with project URL and anon key.
- `supabase-swift` 2.47.2 is pinned in `Package.resolved` and linked in the Xcode project.
- No `AuthService`, `BackupService`, `SyncService`, or account settings UI exists yet.
- No Sign in with Apple entitlement is checked into repo entitlements.
- Checked-in `budgetmeter.ios.entitlements` contains App Groups only; CloudKit/iCloud capability is not present in the checked-in entitlements file even though code uses CloudKit APIs.
- Settings privacy policy copy still claims iCloud-only cloud storage and "No external servers or third-party databases."
- Local premium state is cached in `AppSettings.isPremiumUser` via StoreKit-verified purchase flow.

Important distinction:

- CoreData remains the fast local runtime store during Phase 9.
- Supabase becomes the target cloud backup/sync layer for authenticated premium users.
- CloudKit is legacy sync infrastructure to be migrated away from, not a long-term parallel backend.
- Phase 9 must not introduce a second financial reality; cloud payloads must serialize the same local canonical data the app already uses.

## 3. Current Auth / Cloud / Persistence Inventory

### CoreData local store

| Item | Current state | Phase 9 implication |
|------|---------------|---------------------|
| Container type | `NSPersistentCloudKitContainer` | Must remain unchanged until CloudKit removal gate passes |
| Model versions | v1, v2, v3 all CloudKit-enabled | Backup serialization must target current canonical entities/fields |
| Current version | `BudgetMeter 3` | Schema planning must map from v3 entities, not invent parallel tables blindly |
| Store location | App Group SQLite path when container available | Local snapshot path must not collide with live store writes |
| Merge policy | Default viewContext auto-merge from parent | Cloud restore must use explicit merge/session flow, not silent auto-merge |
| Test helper | `makeInMemoryForTesting()` disables CloudKit options | Use for backup/restore unit tests |

Current entities (all syncable):

| Entity | Primary purpose | Backup relevance |
|--------|-----------------|------------------|
| `AppSettings` | Singleton app config, premium cache, theme, notifications | Include non-secret preferences; exclude or carefully scope premium cache |
| `FinancialCategory` | Income/expense categories and pace entries | Core backup payload |
| `RecurringTransaction` | Recurring automation records | Core backup payload |
| `FinancialSnapshot` | Historical analytics snapshots | Include if needed for premium history; define v1 scope |
| `Subscription` | Premium subscription tracking | Include; has `cloudKitRecordID` legacy field |
| `Bill` | Premium bill tracking | Include; has `cloudKitRecordID` legacy field |
| `BillPayment` | Bill payment history | Include if bills are included |
| `SavingsGoal` | Savings goals | Include; free vs premium goal count must survive restore |

Notable local identity fields already present:

- Many entities use `id: UUID`.
- `FinancialCategory` also has `uniqueID: String`.
- Legacy CloudKit fields exist on `Subscription` and `Bill` (`cloudKitRecordID`).
- No authenticated Supabase user ID is stored locally yet.

### CloudKit current state

| Item | Current state | Risk |
|------|---------------|------|
| Container API | `NSPersistentCloudKitContainer` in `PersistenceService` | Active legacy sync path |
| Model flag | `usedWithCloudKit="YES"` on all model versions | CloudKit metadata/partition assumptions baked into schema |
| Entity sync | All 8 entities `syncable="YES"` | Live iCloud data may exist for existing users |
| Remote changes | History tracking + remote change notifications enabled | Background merges can race with first sign-in/restore |
| Availability check | `isCloudKitAvailable` via `ubiquityIdentityToken` | Useful for migration classification, not ownership |
| Entitlements | Not in checked-in entitlements plist | Xcode project may differ locally; verify before migration QA |
| Legacy record IDs | `cloudKitRecordID` on Bill/Subscription | Must map or ignore during Supabase migration; do not treat as owner key |

CloudKit conclusion:

- Treat CloudKit as active legacy infrastructure until explicitly validated otherwise.
- Assume some production users may have CloudKit-backed data.
- Do not deactivate CloudKit in the same release that first enables Supabase restore without dry-run validation.

### Supabase config / current presence

| Item | Current state | Risk |
|------|---------------|------|
| Config file | `CoreKit/Sources/Auth/SupabaseConfig.swift` | Credentials exist in repo |
| Project URL | `https://mqbtbtlbpcjzleghvrkv.supabase.co` | Must match Supabase dashboard + RLS environment |
| Client dependency | `supabase-swift` 2.47.2 linked in app target | Dependency already added; zero-dep policy is already broken for Supabase |
| Auth implementation | None | No session restore, sign-in, or token handling |
| Database writes | None | No backup tables, no upload/download service |
| Edge Functions | None | Only add if secure server logic is required |
| Sign in with Apple | Not implemented | Requires capability, nonce flow, Supabase provider config |
| Service role key | Not present in app (correct) | Must never ship in client |

Security note:

- Anon key in client is expected for Supabase, but all data protection must come from RLS and auth, not obscurity.
- Phase 9 planning must assume anon key exposure and design RLS accordingly.
- Do not store service role keys, Apple private keys, or refresh tokens insecurely.

### Premium entitlement state

| Item | Current state | Phase 9 rule |
|------|---------------|--------------|
| Purchase source | StoreKit lifetime `com.budgetmeter.premium.lifetime` | Unchanged |
| Local cache | `AppSettings.isPremiumUser`, `AppSettings.premiumPurchaseDate` | Remains local/offline cache only |
| Gate helper | `PremiumManager.hasAccess(to:)` | Backup/sync must use `BudgetMeterCapability.backupSync` |
| Capability status | `.backupSync` access level = `.postponed` | Flip to `.premium` only when backup/sync is actually implemented |
| Auth/premium coupling | None today | Must remain separate; sign-in must not imply premium |
| Cloud entitlement sync | None | Do not sync StoreKit entitlement through Supabase in v1 |

### Settings / privacy copy dependencies

Current user-facing copy conflicts with Phase 9 direction:

| Surface | Current copy claim | Required Phase 9 update |
|---------|-------------------|-------------------------|
| Privacy policy data collection | iCloud sync data stored in personal iCloud | Must add Supabase-backed premium backup when implemented |
| Privacy policy data use | Sync across devices via iCloud (optional) | Must describe Apple Sign In + premium Supabase backup |
| Privacy policy data storage | Local Core Data + private iCloud; no external servers | Must disclose Supabase as premium cloud storage processor |
| Privacy policy your rights | Delete via Settings reset; disable iCloud sync anytime | Must add account deletion / cloud deletion rights |
| Settings account section | No account/sign-in UI | Must add auth/account/sync status surfaces |
| Settings reset all data | Local Core Data wipe via `SettingsViewModel.resetAllData()` | Must distinguish local reset vs cloud account deletion |

Files with privacy dependency:

- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Resources/*.xcstrings` keys under `settings.privacy.*`

## 4. Current Problems / Risks

### Identity and ownership risks

- No stable authenticated owner key exists in app data today.
- Device identifiers must not become cloud ownership keys.
- First sign-in can attach local records to the wrong Supabase user if session/auth UI is rushed.
- Apple `sub` → Supabase user mapping must be verified on every sign-in.
- `FinancialCategory.uniqueID`, entity UUIDs, and CloudKit record IDs are not substitutes for `auth.users.id`.

### Data-loss risks

- First sign-in must not destroy local-only data.
- First backup must not overwrite newer local changes without explicit user confirmation.
- Restore must not silently replace a richer local database.
- CloudKit background merges can race with manual backup/restore if both systems are active.
- `SettingsViewModel.resetAllData()` is local-only today; users may believe it deletes cloud data when it does not.
- Lack of local snapshot before merge/restore is a release blocker.

### Architecture risks

- `NSPersistentCloudKitContainer` is still the live persistence stack.
- All entities are CloudKit syncable; removing CloudKit requires migration planning, not a toggle.
- Supabase dependency exists without auth/sync abstraction boundary.
- No backup serialization contract exists; inventing one during UI work will cause data corruption bugs.
- Real-time sync complexity must not be accidentally introduced through "helpful" background polling.

### Premium boundary risks

- `backupSync` is postponed; premature UI could expose non-functional premium promises.
- Sign-in could be incorrectly paywalled if placed only inside premium flows.
- StoreKit entitlement could be incorrectly inferred from Supabase account presence.
- Premium users without network must retain local premium features; only cloud backup/sync should degrade offline.

### Security and compliance risks

- Privacy policy currently denies third-party cloud storage; App Store review risk once Supabase backup ships.
- Account deletion requires both Supabase auth user deletion and cloud row deletion strategy.
- RLS policies are undefined; shipping tables without RLS review is unacceptable.
- Anon key is in source control; rely on RLS, not secret client keys.
- No Sign in with Apple capability in checked-in entitlements yet.

### Migration risks

- Existing CloudKit users may have cloud-only data on a second device with empty local store.
- Existing local-only users may have never enabled iCloud.
- Existing premium users may expect iCloud sync language to remain true until copy is updated.
- `cloudKitRecordID` fields imply prior CloudKit-specific assumptions for bills/subscriptions.
- CloudKit removal too early can strand live user data with no Supabase copy.

### Testing and operability risks

- No auth session tests exist.
- No backup serialization tests exist.
- No restore conflict tests exist.
- No CloudKit migration dry-run harness exists.
- Manual QA matrix is undefined for sign-in/first-backup/first-restore scenarios.

## 5. Product Decisions Phase 9 Must Respect

From `docs/product_decisions_v1.md`, `docs/implementation/auth_supabase_sync_plan.md`, and `docs/implementation/data_model_migration_plan.md`:

- Apple Sign In is the target auth method for iOS.
- Supabase Auth is the target identity system.
- Supabase database is the target cloud data layer for user-linked financial records.
- Supabase Edge Functions only if needed for secure backend logic.
- CoreData remains the local store/cache.
- CloudKit is current legacy infrastructure and will eventually be removed.
- Do not keep long-term CloudKit + Supabase dual sync.
- Free users can keep using the app locally without signing in.
- Auth itself is not premium.
- Backup/sync is premium.
- StoreKit remains purchase source.
- Supabase user ID, not device ID, must be stable cloud owner identity.
- First sign-in must not destroy local data.
- Migration must protect local data before cloud sync.
- Local-first UX must continue to work offline.
- Premium must not alter calculation outputs.
- Shared financial summary remains canonical local truth before cloud serialization.

## 6. Required Phase 9 Behavior

Phase 9 must deliver:

- Apple Sign In that creates/restores a Supabase authenticated session.
- Stable mapping from authenticated session to Supabase `auth.users.id`.
- Local-only app usage remains fully functional with no account requirement.
- Auth/sign-out/session-restore flows do not require premium.
- Premium-gated backup/sync entry points using `BudgetMeterCapability.backupSync`.
- Explicit sync/account status in Settings for signed-in premium users.
- First sign-in state machine covering local-only, cloud-only, overlapping, signed-out-with-local-data, and existing CloudKit user cases.
- Local snapshot taken before first backup, restore, or merge.
- Destructive overwrite requires explicit confirmation.
- Backup/upload and restore/download operations are user-initiated or clearly scheduled in v1; no hidden silent full-database replacement.
- Cloud payloads scoped to authenticated user via RLS-safe ownership fields.
- Offline behavior: local app works; cloud actions queue or fail gracefully with understandable status.
- Account deletion flow for signed-in users, with legal/privacy copy.
- Privacy policy and settings copy updated before release of cloud backup.
- CloudKit remains active until migration validation gates pass; removal is a late Phase 9 sub-step, not the first step.

## 7. Explicit Non-Goals

Phase 9 is not:

- Real-time multi-device sync.
- Background always-on bidirectional sync engine.
- Conflict-resolution UI beyond simple v1 safe rules.
- Email/password auth.
- Social login beyond Apple.
- RevenueCat or remote entitlement syncing.
- StoreKit product/pricing changes.
- CloudKit removal in the first implementation PR.
- CoreData schema redesign unrelated to auth/sync metadata.
- Widget cloud state or Supabase-backed widget refresh.
- Team/family sharing.
- Bank sync or third-party financial aggregation.
- Cloud analytics/AI features.
- Replacing local premium cache with Supabase entitlement records.
- Using device ID (`IDFV`) as account ownership.
- Dual long-term CloudKit + Supabase write paths.

## 8. Identity Contract

### Supabase `auth.users.id` as owner key

Rules:

- Every cloud-backed row must be owned by `auth.uid()` matching the signed-in Supabase user.
- Client-side queries and inserts must never trust user-supplied owner IDs without session validation.
- Local CoreData records keep local UUIDs; cloud rows store:
  - `user_id` = Supabase auth user UUID
  - `client_record_id` = stable local record UUID/string for idempotent upsert
- Backup restore maps by `client_record_id` first, then safe fallback rules; never by device ID.

### Apple Sign In identity mapping

Expected flow:

1. User taps Sign in with Apple.
2. App receives Apple credential with stable `user` identifier (`sub` scoped to team/app).
3. App exchanges credential with Supabase Auth Apple provider.
4. Supabase returns authenticated session; app reads `session.user.id`.
5. App stores non-secret session metadata locally for restore on next launch.
6. App never treats Apple `sub` alone as database foreign key; Supabase `auth.users.id` is canonical in Postgres.

Required safeguards:

- Nonce/state validation for Apple sign-in.
- Session refresh handling via Supabase client.
- Sign-out clears local session tokens and sync state, not local financial data by default.
- Reinstall/new device must restore cloud data only after authenticated session + explicit restore/premium backup path.

### No device-ID ownership

Forbidden:

- Using `UIDevice.current.identifierForVendor` as cloud owner key.
- Creating "anonymous cloud accounts" keyed by device ID.
- Writing financial records to Supabase before authenticated user exists.

Allowed:

- Optional diagnostic metadata if explicitly approved later, marked non-authoritative and non-RLS-controlling.

### Local-only user behavior

Local-only users:

- Have no Supabase session.
- Have no cloud backup destination.
- Continue reading/writing CoreData normally.
- May see optional "Sign in for backup across devices" copy, but must not be blocked from core app use.
- Must not lose data when choosing not to sign in.

## 9. Free vs Premium Boundary

### Auth not premium

Free and premium users may sign in/out if the UI exposes auth.

Sign-in enables identity and account management; it does not by itself unlock backup/sync.

### Backup/sync premium

Cloud backup, restore, and cross-device access require:

- `PremiumManager.hasAccess(to: .backupSync) == true`
- Valid authenticated Supabase session

Non-premium signed-in users may exist in v1 only if product intentionally allows account creation before purchase; if so, they must see locked backup/sync state, not partial uploads.

Recommended v1 UX:

- Sign-in available from Settings/account area.
- Backup/sync controls visible but locked with premium CTA when not entitled.
- Premium purchase does not auto-upload; first backup remains explicit or clearly prompted after entitlement + sign-in.

### Local app remains free

Free local scope unchanged:

- Home dashboard and pace loop
- Income/expense entry
- Basic recurring entry
- One basic savings goal
- Default theme
- Local-only persistence

Cloud failure, sign-out, or lack of premium must never disable local core functionality.

## 10. StoreKit vs Supabase Responsibility Split

| Concern | Owner | Notes |
|---------|-------|-------|
| Purchase validation | StoreKit | `Transaction.currentEntitlements`, verified transactions |
| Premium feature access | `PremiumManager` + local cache | `AppSettings.isPremiumUser` is runtime cache only |
| User identity | Supabase Auth | Apple Sign In via Supabase provider |
| Cloud data storage | Supabase Postgres | RLS-protected user-owned rows |
| Backup/restore transport | Supabase client/API layer | No StoreKit involvement |
| Account deletion | Supabase Auth + app orchestration | Separate from local reset |
| Offline premium use | Local StoreKit cache | Previously verified premium remains usable |
| Offline cloud backup | N/A / queued | Must fail gracefully without corrupting local data |
| Entitlement syncing to cloud | Not in v1 | Do not write `isPremiumUser` to Supabase as source of truth |

Hard rule:

- Never infer premium from Supabase account existence.
- Never infer cloud ownership from StoreKit transaction IDs.

## 11. First Sign-In Safety Contract

Phase 9 must implement a first-sign-in state machine before any destructive cloud/local merge.

### Scenario A — Local-only data, empty cloud

Conditions:

- User has local CoreData records.
- Supabase account has no prior backup for this user.

Required behavior:

- Preserve all local data.
- Do not download/replace local store.
- Offer premium user optional "Back up now" after snapshot creation.
- Mark migration session complete only after successful backup or explicit skip.

### Scenario B — Cloud-only data, empty/minimal local

Conditions:

- Local store empty or seed-only.
- Supabase backup exists for authenticated user.

Required behavior:

- Show restore offer before writing locally.
- Require explicit confirmation before importing cloud data into CoreData.
- Create local snapshot even if local data is minimal (rollback path).
- Do not silently import on sign-in success alone.

### Scenario C — Local + cloud overlap

Conditions:

- Both local and cloud contain financial records for same authenticated user.

Required behavior:

- Classify overlap before merge.
- Default to safest non-destructive v1 strategy (see Section 14).
- Never auto-merge on first sign-in without user-visible decision when both sides non-empty.
- Always snapshot local first.

### Scenario D — Signed out with local data

Conditions:

- User uses app locally, no auth session.

Required behavior:

- No cloud reads/writes.
- No change to current local persistence behavior.
- Sign-in path must begin with classification, not restore.

### Scenario E — Existing CloudKit user

Conditions:

- User previously synced via iCloud/CloudKit.
- May also have local-only changes on current device.

Required behavior:

- Detect CloudKit availability and/or local CloudKit-managed store state where possible.
- Treat CloudKit data as legacy source during migration window only.
- Do not assume CloudKit data equals Supabase data.
- First Supabase backup must snapshot local canonical state after CloudKit merges settle or after controlled export step.
- CloudKit-to-Supabase migration must support dry-run and rollback criteria before CloudKit removal.

First sign-in must never:

- Wipe local store on auth success.
- Upload before snapshot.
- Restore cloud data without confirmation when local data exists.
- Attach local records to the wrong user due to stale session.

## 12. Local Snapshot / Rollback Requirements

Local snapshot is mandatory before:

- First backup upload
- First restore import
- Any merge operation
- CloudKit migration dry-run that mutates local state

Snapshot requirements:

- Stored outside the live CoreData SQLite file path.
- Includes export timestamp, app version, schema/model version, authenticated user ID if present, record counts, and serialized payload or file copy.
- Named with monotonic session ID for support/debug.
- Retained until user dismisses recovery option or a safe cleanup policy expires old snapshots.
- Restorable through explicit developer-approved recovery path in Settings/debug/support flow.

Rollback requirements:

- Failed restore must not leave CoreData in partial import state without recovery.
- Use transactional import strategy where possible.
- Surface user-visible "Restore failed — your previous data was preserved" copy.
- Keep at least one pre-operation snapshot until success confirmed.

Recommended v1 snapshot format:

- Versioned JSON export using the same canonical backup serializer as Supabase upload payload, plus optional raw SQLite copy for internal QA only.

## 13. Backup/Restore Contract

### Backup (upload) contract

Writer side (app target):

1. Verify premium access to `.backupSync`.
2. Verify authenticated Supabase session.
3. Create local snapshot.
4. Serialize canonical local entities into versioned backup payload.
5. Upload to Supabase using idempotent upsert strategy keyed by `user_id + client_record_id`.
6. Write sync metadata locally: last backup timestamp, backup schema version, backup session ID, success/failure state.

Backup payload must include:

- Schema/version marker
- App build/version marker
- Entity records needed for full local restore of supported v1 scope
- Per-record `client_record_id`, `updated_at`, soft-delete/archive flags
- Non-secret app settings needed to restore user experience

Backup payload must exclude or carefully scope:

- StoreKit secrets or transaction payloads
- Supabase tokens
- Debug-only fields
- Derived/cached values recalculable locally unless needed for UX continuity

### Restore (download) contract

Reader side:

1. Verify premium access and authenticated session.
2. Fetch latest backup metadata for user.
3. Present summary: record counts, backup date, app version compatibility.
4. Require explicit confirmation if local data exists.
5. Create local snapshot.
6. Import into CoreData using merge rules from Section 14.
7. Recompute derived state locally; do not trust cloud-derived pace values as canonical.
8. Persist restore session marker locally.

Restore must not:

- Run automatically on every sign-in.
- Overwrite newer local edits without warning.
- Import unsupported schema versions without explicit migration path.

### Sync status contract

Settings/account UI must expose:

- Signed out / signed in
- Premium locked/unlocked for backup
- Last backup time or "Never backed up"
- Last restore time if applicable
- In-progress/failed/offline state
- CloudKit legacy note during migration window if still active

## 14. Merge/Conflict Strategy v1

v1 goal: simple and safe, not real-time sync sophistication.

Recommended v1 policy:

- No continuous background bidirectional sync.
- User-initiated backup upload replaces/updates cloud copy for that user's owned records using idempotent upserts.
- User-initiated restore is full-restore or explicitly scoped import, not field-level live merging in background.
- For first overlap case, present chooser:
  - Keep this device data and back it up
  - Restore cloud data to this device
  - Cancel
- Do not offer complex per-record merge UI in v1.

Conflict rules when both sides exist:

| Case | v1 behavior |
|------|---------------|
| Same `client_record_id`, cloud newer by `updated_at` | Prefer cloud on explicit restore only |
| Same `client_record_id`, local newer by `updated_at` | Prefer local on explicit backup only |
| Record exists only locally | Upload on backup |
| Record exists only in cloud | Import on restore |
| Deleted locally but present in cloud | Requires delete/archive flag contract; default to non-destructive retain until delete semantics defined |
| Premium-only entities on non-premium restore attempt | Block import of premium-only entities or strip with clear messaging |

Timestamps:

- Every backup-eligible record must have reliable `updated_at` semantics locally before cloud write.
- Missing timestamps must not silently default to "now" in a way that corrupts conflict decisions.

## 15. Supabase Schema Planning Requirements

Do not finalize schema as code in this scope doc. Define decisions that must be made before implementation.

### Tables likely needed

Planning-level table groups:

| Group | Likely tables/purpose |
|-------|----------------------|
| Backup metadata | One row per backup snapshot/version per user |
| Financial categories | User-owned income/expense records |
| Recurring transactions | User-owned recurring automation |
| Savings goals | User-owned goals |
| Bills/subscriptions/payments | Premium-managed entities if in backup v1 |
| Financial snapshots/history | Optional v1 or phased later |
| App preferences | Non-secret settings needed for restore |
| Migration sessions | First sign-in / CloudKit migration markers |

### Required column decisions

Every user-owned table must define:

- `user_id UUID NOT NULL` referencing auth user ownership through RLS
- `client_record_id TEXT/UUID NOT NULL` for idempotent upsert from local records
- `updated_at TIMESTAMPTZ NOT NULL`
- `created_at TIMESTAMPTZ NOT NULL`
- `deleted_at TIMESTAMPTZ NULL` or `is_deleted BOOLEAN` for soft delete/archive
- Optional `schema_version INT` on backup metadata rows
- Optional `source TEXT` enum for migration provenance: `local`, `cloudkit_export`, `restore`

Unique constraints:

- Unique `(user_id, client_record_id)` for upsertable entity tables.

Indexes:

- `(user_id, updated_at DESC)` for backup listing
- `(user_id, deleted_at)` for active-record queries

### Migration/session markers

Cloud-side or local-side markers needed:

- `first_sign_in_completed_at`
- `first_backup_completed_at`
- `last_backup_completed_at`
- `last_restore_completed_at`
- `cloudkit_migration_status`
- `backup_schema_version`

### Schema decisions still required before coding

- Exact v1 entity inclusion list: are bills/subscriptions/snapshots in first backup or phase 9B?
- Whether app settings backup includes theme/notification prefs only or broader settings.
- Whether soft delete is required day one for account deletion semantics.
- Whether backup metadata is one row per full snapshot or per record version.
- How unsupported future schema versions are handled on restore.
- Whether CloudKit export uses separate staging tables or direct import pipeline.

Do not finalize schema without RLS review (Section 16).

## 16. RLS/Security Requirements

Minimum RLS policy pattern:

- Enable RLS on every user-owned table.
- Allow `SELECT/INSERT/UPDATE/DELETE` only where `user_id = auth.uid()`.
- No public read/write policies on financial tables.
- Backup metadata readable/writable only by owner.
- Test policies with anon key + authenticated test users before app integration.

Additional requirements:

- Never use service role key in iOS app.
- Validate JWT/session on every sync operation client-side before attempting writes.
- Server-side Edge Function only if client-safe logic is insufficient (e.g., account deletion orchestration, admin cleanup).
- Audit account deletion path for orphaned rows.
- Log sync failures without logging raw financial amounts in production analytics unless explicitly approved.
- Rotate/review anon key exposure if repo history contains credentials.
- Ensure Supabase Apple provider configuration uses correct bundle ID and redirect settings.

Security QA gate:

- Attempt cross-user read/write with two test accounts must fail.
- Signed-out client writes must fail.
- Premium-locked client without auth must fail.

## 17. CloudKit Transition / Removal Plan

CloudKit removal is late Phase 9 work, not step one.

### When not to remove CloudKit

Do not remove/deactivate CloudKit until all are true:

- Supabase backup/restore path verified with real user-like fixtures.
- First sign-in safety flow verified manually.
- CloudKit migration dry-run completed for representative scenarios.
- Privacy copy updated.
- Account deletion path defined.
- Rollback plan documented and tested.
- No open data-loss bugs in backup/restore QA.

### Validation gates

Gate A — Readiness:

- Backup serializer covers agreed v1 entity set.
- Restore/import tests pass locally.
- Auth session tests pass.

Gate B — Dual-system safety:

- App can run with CloudKit still enabled while Supabase backup is manual-only.
- No automatic dual-write to both systems.
- No background CloudKit merge during restore without controlled process.

Gate C — Migration:

- CloudKit export/dry-run produces expected record counts.
- Supabase restore from migrated payload matches local canonical totals in QA fixtures.
- Existing CloudKit users have documented path.

Gate D — Removal:

- Switch persistence container plan approved separately.
- CoreData model CloudKit flags addressed in approved migration plan.
- iCloud copy removed/updated.
- Post-removal regression tests pass.

### Dry-run migration

Dry-run must:

- Operate on snapshot copies, not production live store first.
- Record entity counts before/after.
- Compare financial summary outputs via `FinancialSummaryBuilder` before/after.
- Fail gate if totals diverge beyond approved tolerance.

### Rollback criteria

Rollback CloudKit removal or Supabase cutover if:

- Restore corrupts entities or breaks app boot.
- Financial summary totals change unexpectedly after migration.
- Auth/session loss strands user without local snapshot recovery.
- Cross-user data exposure found in RLS tests.

## 18. Offline Behavior

Signed out:

- Full local app function except cloud backup/sync features.

Signed in, non-premium:

- Same as signed out for backup/sync; auth session may persist.

Signed in, premium, offline:

- Local app fully usable.
- Backup/restore actions disabled or queued with clear offline state.
- Do not cache failed partial uploads as success.
- Last successful backup timestamp remains visible.

Session offline restore:

- If session expired offline, require re-auth before cloud restore.
- Do not delete local data because refresh failed.

Premium offline:

- StoreKit local entitlement cache still grants premium features unrelated to cloud sync.

## 19. Account Deletion / Data Deletion Requirements

Must distinguish three operations clearly:

| Operation | Scope | v1 requirement |
|-----------|-------|----------------|
| Reset all data (local) | CoreData on device | Existing Settings action; update copy to clarify cloud data unaffected |
| Sign out | Session only | Keep local data |
| Delete account / cloud data | Supabase auth user + cloud rows | New explicit destructive flow |

Account deletion must:

- Require typed confirmation or equivalent strong confirmation.
- Delete or anonymize Supabase user-owned rows per RLS-safe server process.
- Delete/disable Supabase auth user.
- Sign out locally after completion.
- Explain whether local device data is kept or optionally wiped after cloud deletion.
- Provide understandable completion/error states.

Legal/privacy:

- Update privacy policy before release.
- Document data controller contact already present in Settings.
- Support user rights: access (export already premium elsewhere), delete, control sync.

## 20. Privacy and Compliance Impact

Required documentation/code updates before cloud backup release:

- Replace "No external servers or third-party databases" language.
- Disclose Supabase as processor/storage for premium cloud backup.
- Disclose Apple Sign In identity usage.
- Clarify that free use remains local-only.
- Clarify difference between local reset and account deletion.
- Update "disable iCloud sync anytime" to reflect CloudKit legacy + Supabase premium backup status during transition.

App Store review risks:

- Privacy nutrition labels must match new cloud behavior.
- Sign in with Apple required if other third-party auth were added; v1 uses Apple only.
- Account deletion requirement for apps supporting account creation.

Data minimization:

- Upload only data required for backup/sync v1 scope.
- Do not upload contacts, location, or unrelated device data.

## 21. Localization Requirements

All new user-facing strings must use String Catalogs with 10 languages:

- Sign in with Apple button-adjacent copy where custom text is used
- Sign out
- Account status
- Backup now / Restore / Last backed up / Never backed up
- Offline sync unavailable
- Backup in progress / Restore in progress
- Backup failed / Restore failed
- First sign-in chooser copy for local vs cloud
- Destructive overwrite confirmation
- Account deletion warnings and success/failure
- CloudKit legacy/migration informational copy during transition
- Premium locked backup/sync CTA

Avoid hardcoded English in auth/sync services surfaced to UI.

Recommended key prefixes:

- `auth.*`
- `backup.*`
- `sync.*`
- `account.*`

Update existing privacy strings rather than adding conflicting duplicates.

## 22. Accessibility Requirements

Required behavior:

- Sign in with Apple control follows Apple HIG; do not restyle deceptively.
- Sync status communicates state with text, not color alone.
- Destructive restore/delete confirmations are VoiceOver-accessible.
- Loading states for backup/restore are announced or clearly visible.
- Error messages readable under Dynamic Type.
- Locked premium backup/sync rows expose accessibility hint for upgrade action.
- Account deletion confirmation requires accessible confirmation affordance.

## 23. Files Likely To Touch In Phase 9 Implementation

### Auth / Supabase core

- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseConfig.swift`
- New: `AuthService.swift` or equivalent
- New: `SupabaseClientProvider.swift` or equivalent
- New: `AuthSessionStore.swift` for non-secret session metadata
- New: `AppleSignInCoordinator.swift` using `AuthenticationServices`

### Backup / sync core

- New: `BackupSerializer.swift`
- New: `BackupUploader.swift`
- New: `BackupDownloader.swift`
- New: `RestoreImporter.swift`
- New: `LocalSnapshotService.swift`
- New: `SyncStateStore.swift`
- New: backup payload model types

### Persistence integration

- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift` only with explicit approval for non-CloudKit changes
- Possible new local sync metadata storage in `AppSettings` or separate lightweight store

### Premium / settings UI

- `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift` for `.backupSync` gate activation only
- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift`
- New: account/backup settings views
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift` only if backup/sync CTA added

### App entry / entitlements

- `budgetmeter.ios/budgetmeter_iosApp.swift` for session restore hooks
- `budgetmeter.ios/budgetmeter.ios.entitlements` for Sign in with Apple capability
- Xcode project capabilities during approved implementation step

### Localization / docs

- `budgetmeter.ios/Resources/*.xcstrings`
- Supabase SQL migration files in repo or infra folder once schema approved
- Privacy policy strings in Settings

### Tests

- `budgetmeter.iosTests/BackupSerializerTests.swift`
- `budgetmeter.iosTests/FirstSignInSafetyTests.swift`
- `budgetmeter.iosTests/RestoreImporterTests.swift`
- `budgetmeter.iosTests/AuthSessionTests.swift`
- `budgetmeter.iosTests/PremiumBackupGateTests.swift`

## 24. Files Not Allowed To Touch Without Explicit Approval

During planning and first safety work:

- CoreData model files in `BudgetMeter.xcdatamodeld/` unless separate approved migration plan exists
- CloudKit removal/deactivation in `PersistenceService`
- Widget extension/providers except read-only impact analysis
- `CalculationEngine.swift` formulas
- StoreKit product configuration / product IDs
- `PremiumManager` purchase/restore logic beyond `.backupSync` gate activation
- RevenueCat or ads code
- Service role keys or production Supabase secrets in client
- Unrelated feature ViewModels (Home/Income/Expense) except narrow sync status hooks if approved

During first safe implementation slice:

- No Sign in with Apple entitlement changes until safety contracts have tests
- No Supabase table creation without RLS review
- No privacy policy user-facing release until legal/product review

## 25. Required Tests

### Local-only regression

- Free user can use Home/income/expense/savings without auth.
- Sign-in UI presence does not gate core tabs.
- Existing calculation and savings tests still pass.

### Auth session

- Sign-in success stores/restores session metadata.
- Sign-out clears session without deleting CoreData financial records.
- Expired session requires re-auth before cloud restore.
- Invalid Apple credential failure surfaces safe error.

### Backup serialization

- Serializer includes agreed v1 entities/fields.
- Round-trip local export -> decode preserves record counts and key fields.
- Schema version mismatch fails safely.
- Premium-only entities omitted or included per v1 decision consistently.

### Restore

- Restore into empty store recreates expected records.
- Restore with existing local data requires confirmation path in UI tests/manual QA.
- Failed import rolls back to snapshot state.

### First-sign-in preservation

- Local-only scenario keeps all records after sign-in.
- Cloud-only scenario does not import without confirmation.
- Overlap scenario triggers chooser, not silent merge.

### Premium sync gate

- Non-premium cannot upload/download backup.
- Premium without sign-in sees sign-in prompt, not crash.
- Premium + sign-in can backup/restore in happy path tests.

### RLS/security

- Integration tests with two Supabase test users cannot read/write each other's rows.
- Signed-out upload attempts fail.

### Offline

- Backup attempt offline sets failure state, not success.
- Local edits continue offline.

### Account deletion

- Manual QA for delete account success/failure states.
- Verify cloud rows removed for test user.

### CloudKit migration dry-run

- Fixture-based dry-run comparing `FinancialSummaryBuilder` output before/after export/import pipeline.
- No live CloudKit deletion in automated tests.

Recommended test files:

- `BackupSerializerTests.swift`
- `RestoreImporterTests.swift`
- `FirstSignInStateMachineTests.swift`
- `AuthSessionStoreTests.swift`
- `PremiumBackupGateTests.swift`
- `CloudKitMigrationDryRunTests.swift`

## 26. Manual QA Requirements

### Auth QA

- Sign in with Apple on device/simulator with Supabase test project.
- Sign out and relaunch app.
- Reinstall app and restore session/cloud data path.
- Cancelled sign-in leaves local data untouched.

### First sign-in QA

- Local-only user signs in: no data loss.
- Premium local-only user backs up successfully.
- Second device cloud-only restore works with confirmation.
- Overlap device shows chooser and preserves unselected side via snapshot.

### Backup/restore QA

- Backup then wipe local app data then restore: data returns correctly.
- Backup then edit local data then restore older cloud copy: confirmation required; no silent loss.
- Currency/theme/notification prefs restore as expected.

### Premium boundary QA

- Free user cannot backup/sync.
- Premium user without sign-in sees clear next step.
- Premium purchase after sign-in enables backup without requiring repurchase.

### Offline QA

- Airplane mode backup fails gracefully.
- Local edits still save in CoreData offline.

### CloudKit legacy QA

- User with iCloud enabled on legacy build/path: dry-run migration counts documented.
- No duplicate records after manual backup following CloudKit settle period.

### Privacy/deletion QA

- Privacy policy text matches behavior.
- Local reset does not delete cloud account.
- Delete account removes cloud access and data per policy.

## 27. Build/Test Checkpoints

Checkpoint 1 — after safety contract tests added:

- Backup serializer unit tests pass/fail meaningfully before implementation.
- First sign-in state machine tests exist.

Checkpoint 2 — after auth session layer:

- Auth session unit tests pass.
- App builds with Supabase client initialized but no backup writes yet.
- Local-only regression tests pass.

Checkpoint 3 — after backup upload only:

- Backup tests pass.
- Manual premium backup QA on test project.
- No restore/import enabled yet.

Checkpoint 4 — after restore import:

- Restore tests pass.
- Manual two-device restore QA.
- Snapshot rollback verified.

Checkpoint 5 — after settings/account UI:

- Localization keys present for touched strings.
- Accessibility smoke check for account/sync screens.

Checkpoint 6 — before CloudKit migration/removal sub-phase:

- Dry-run migration QA pass.
- Privacy copy updated.
- Account deletion QA pass.
- Full unit test suite pass.
- App build pass.

## 28. Step-by-Step Phase 9 Implementation Sequence

1. Re-audit auth/cloud/persistence inventory in repo before editing behavior.
2. Write first-sign-in safety contract and state machine doc/tests.
3. Define backup payload schema/version and serializer protocol.
4. Add local snapshot service design and tests using in-memory CoreData fixtures.
5. Add backup serializer round-trip tests without network.
6. Define Supabase schema decision checklist and RLS policy draft outside app code.
7. Review RLS with two test users before iOS upload code.
8. Implement auth session store + Supabase client wrapper only.
9. Implement Sign in with Apple flow and session restore.
10. Add Settings account section for sign-in/sign-out/session status only.
11. Activate premium gate for `.backupSync` in code matrix when backup is ready.
12. Implement manual backup upload using serializer + Supabase upserts.
13. Implement backup status UI: last backup, errors, offline.
14. Implement restore download + confirmation + import pipeline.
15. Implement overlap chooser for first sign-in/local+cloud case.
16. Add account deletion orchestration and updated privacy copy.
17. Run full auth/backup/restore QA matrix on test Supabase project.
18. Run CloudKit migration dry-run on snapshot copies and document results.
19. Only after gates pass: plan CloudKit deactivation/removal sub-phase separately.
20. Update `implementation_planning_index.md` after verified checkpoint completion.

## 29. What To Postpone

Postpone:

- Real-time multi-device sync
- Background periodic auto-sync
- Complex per-field merge UI
- Email/password auth
- Social login beyond Apple
- RevenueCat entitlement syncing
- CloudKit removal in first implementation slice
- Supabase Edge Functions unless account deletion or secure logic requires them
- Financial snapshots/history cloud backup if too large for v1; phase 9B instead
- Widget cloud state
- Bank sync / AI / analytics cloud features
- Dual CloudKit + Supabase long-term write path
- Using device ID for ownership
- Storing premium entitlement in Supabase as source of truth

## 30. Success Criteria

Phase 9 is complete when:

- Apple Sign In + Supabase Auth session works reliably.
- Stable cloud ownership uses Supabase `auth.users.id`.
- Local-first free usage remains intact without sign-in.
- Auth is not premium; backup/sync is premium-gated.
- StoreKit and Supabase responsibilities remain separate.
- First sign-in never silently destroys local data.
- Local snapshot and rollback exist before merge/restore.
- Manual backup/restore works for premium signed-in users.
- Overlap case is handled with explicit user choice.
- RLS prevents cross-user access in tested scenarios.
- Offline/local-only behavior is safe and understandable.
- Account deletion and privacy copy match actual behavior.
- CloudKit migration/removal gates are documented; removal only after validation.
- Required tests pass.
- Manual auth/sync QA passes.
- App build passes.

## 31. Recommendation

Status: **Ready for implementation planning after this document upgrade; not ready for cloud behavior implementation.**

Phase 9 is now documented to the same implementation-readiness level as Phases 7 and 8. The product direction is clear, but the codebase still lacks the safety contracts, serializer tests, RLS-defined schema, and first-sign-in state machine required before touching entitlements or CloudKit behavior.

### Remaining risks

1. `PersistenceService` still uses `NSPersistentCloudKitContainer`; live CloudKit merges can race with restore if not carefully staged.
2. All CoreData entities are CloudKit syncable; removal/migration is non-trivial.
3. Supabase client dependency exists before auth/sync abstractions or RLS-backed schema.
4. `SupabaseConfig.swift` contains project credentials in source; security depends entirely on RLS and auth design.
5. Privacy policy currently denies external cloud storage; release without copy update is a review/legal risk.
6. No Sign in with Apple entitlement is checked in yet.
7. `BudgetMeterCapability.backupSync` is still `.postponed`; premature UI could over-promise.
8. Settings reset is local-only while copy implies broader deletion control.
9. Legacy `cloudKitRecordID` fields and iCloud copy may mislead migration planning for bills/subscriptions.
10. Real-time sync complexity is the biggest architectural trap; v1 must stay manual backup/restore oriented.

### Whether Phase 9 is ready to implement

**Yes for planning. No for cloud/auth implementation starting with UI or entitlements.**

Phase 9 is ready to start with contracts and tests only. It is not ready to begin with Sign in with Apple entitlements, Supabase writes, or CloudKit deactivation.

### Recommended first implementation step

Define the versioned backup payload contract and first-sign-in state machine, add failing unit tests for serializer round-trip + local-only sign-in preservation using in-memory CoreData fixtures, and draft Supabase schema/RLS decisions in a separate reviewed doc before any auth UI or entitlements change.
