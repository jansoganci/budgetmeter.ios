# App Store Readiness Execution Plan

**Created:** 2026-06-18  
**Status:** Planning — documentation only  
**Source audit:** `docs/implementation/app_store_privacy_auth_readiness_audit.md`  
**Related plans:** `implementation_planning_index.md`, `phase9_supabase_auth_database_migration_scope.md`, `phase10_release_qa_scope.md`, `release_phase_plan.md`, `localization_accessibility_qa_plan.md`

---

## 1. Executive Summary

### Current verdict

**NOT READY** for App Store submission as an **auth + Supabase cloud backup + paid IAP** release.

Engineering baseline is strong (build passes, **155/155** unit tests pass as of 2026-06-18), and several auth flows work in manual testing. Legal/privacy gaps, incomplete local-reset behavior, unverified Supabase security QA, and broken email-registration UX block a confident ship.

### What is already working

| Area | Status | Evidence |
|------|--------|----------|
| Apple Sign In | **Working** (manual) | `WelcomeView` + `AuthService.handleAppleCredential` → Supabase `signInWithIdToken` |
| Auth session routing | **Working** | `RootAuthView` → splash → `WelcomeView` (signed out) → `ContentView` (signed in) |
| Account deletion UI + client | **Implemented** | `AccountBackupSettingsView` + `AuthService.deleteAccount()` → `delete-account` Edge Function |
| Sign out | **Working** | Clears Supabase session + local auth metadata; local Core Data retained |
| Premium gates + restore API | **Implemented** | `PremiumManager`, `PremiumPaywallView`, `BudgetMeterCapability` matrix |
| Widget v1 code | **Implemented** | Extension target, App Group snapshot, deep links, unit tests |
| In-app privacy copy (Supabase) | **Updated in catalogs** | `UI.xcstrings` privacy sections |
| RLS SQL (repo) | **Defined** | `supabase/migrations/0001–0003` |

### What is blocking App Store submission

| Priority | Blocker |
|----------|---------|
| P0 | Terms of Service describes **subscription**; app sells **lifetime non-consumable** |
| P0 | No **hosted** Privacy Policy or Terms URLs for App Store Connect |
| P0 | `PrivacyInfo.xcprivacy` does not reflect auth-linked data |
| P0 | Email/password **enabled** but **email confirmation flow incomplete** in app (Supabase confirm on; no `auth/callback` deep link) |
| P0 | `resetAllData()` does not yet perform **full local wipe** (product requires all local data deleted; code partial) |
| P1 | Account deletion cloud wipe — **one more live verification pass** required |
| P1 | RLS cross-user isolation — **not verified** on live project |
| P1 | Apple Sign In **nonce** not implemented |
| P1 | First sign-in overlap UX not wired |
| P1 | Stage B manual QA not executed |

### Recommended path for v1

1. **Email/password registration stays enabled for v1** — implement email confirmation + deep link; legal pages cover both auth methods.
2. **Complete Block 1 (Legal/Privacy) first** — GitHub Pages URLs, Terms IAP fix, privacy manifest, retention/deletion policy; use **manual premium cloud backup and restore** wording (not automatic sync).
3. **Complete Block 2** — email confirmation, nonce, account deletion re-verification, RLS test, overlap UX, **full local Reset All Data** implementation.
4. **Ship manual Supabase backup cautiously** — user-initiated Back Up Now / Restore only (`BackupService`); complete Stage B QA before marketing cloud features.
5. **Blocks 3–4 in parallel** where possible — StoreKit sandbox, widget device signing, localization polish.

---

## 2. Block 1 — App Store Legal / Privacy Block

### Block 1 planning artifact

| Item | Status |
|------|--------|
| Legal/Privacy GitHub Pages planning document | **Created** — [`docs/implementation/legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) |
| GitHub Pages HTML implementation | **Ready to start** — see [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) § Final Decisions Locked + §18 |
| GitHub Pages deployment | **Not started** |

---

### 2.1 Fix Terms of Service IAP copy (lifetime non-consumable, not subscription)

| Field | Detail |
|-------|--------|
| **Why it matters** | App Store Review rejects misleading IAP legal text. Paywall says “One-time purchase • Lifetime access” while Terms say auto-renewing subscription. |
| **Files likely to change** | `budgetmeter.ios/Resources/UI.xcstrings` (`settings.terms.policy.iap.content`, `settings.terms.policy.iap.title`, `settings.terms.policy.last_updated`); optionally `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift` defaultValues |
| **External action** | Hosted Terms page must match (see 2.3). |
| **Acceptance criteria** | All 10 locales describe **one-time lifetime purchase**, no renewal/cancel-subscription language; last-updated date refreshed; in-app Terms sheet matches paywall and App Store Connect IAP type. |

---

### 2.2 Create hosted Privacy Policy URL

| Field | Detail |
|-------|--------|
| **Why it matters** | App Store Connect requires a public privacy policy URL for apps with accounts and financial data. |
| **Files likely to change** | `docs/legal/privacy/index.html` + `docs/legal/assets/i18n/privacy.json` (GitHub Pages); optional in-app link in `SettingsView.swift`; see [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) |
| **External action** | **GitHub Pages** — deploy from `/docs` on `main`; add URL in App Store Connect → App Privacy. |
| **Acceptance criteria** | URL loads without login; content covers local storage, optional Supabase premium backup, Apple Sign In, account deletion, data retention, contact email; matches in-app policy; URL entered in App Store Connect. |

---

### 2.3 Create hosted Terms of Service URL

| Field | Detail |
|-------|--------|
| **Why it matters** | Required for paid apps / IAP; must match StoreKit product type. |
| **Files likely to change** | `docs/legal/terms/index.html` + `docs/legal/assets/i18n/terms.json` (GitHub Pages); optional in-app link in `SettingsView.swift`; see [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) |
| **External action** | **GitHub Pages** — deploy from `/docs` on `main`; link from App Store Connect if required. |
| **Acceptance criteria** | URL public; lifetime IAP section accurate; financial disclaimer present; matches in-app Terms sheet. |

---

### 2.4 Update `PrivacyInfo.xcprivacy`

| Field | Detail |
|-------|--------|
| **Why it matters** | Apple Privacy Nutrition Labels must match actual collection. Current file marks financial data as not linked; auth adds email/user ID; cloud backup links financial payload to account. |
| **Files likely to change** | `budgetmeter.ios/PrivacyInfo.xcprivacy` |
| **External action** | **App Store Connect** — App Privacy questionnaire must align after plist update. |
| **Acceptance criteria** | Declares email and/or user ID when account is created; financial info linked when user uses cloud backup (or document as optional/linked only when backup used); no tracking; required-reason APIs unchanged or updated with justification. |

---

### 2.5 Decide and document data retention policy

| Field | Detail |
|-------|--------|
| **Why it matters** | GDPR/CCPA and App Store privacy expectations; `user_backup_versions` grows append-only. |
| **Files likely to change** | Hosted privacy policy; in-app `settings.privacy.policy.*` strings in `UI.xcstrings`; optional `docs/legal/data_retention_policy.md` |
| **External action** | **Legal review**; optional Supabase cron/job for version pruning (future). |
| **Acceptance criteria** | Written policy states: local data retained until **Reset All Data**; Supabase stores **manual backup copies** only when user backs up; version history until account deletion; iCloud/CloudKit mentioned **only if verified active** in production (Apple data sync — not purchases). |

---

### 2.6 Decide and document account deletion policy

| Field | Detail |
|-------|--------|
| **Why it matters** | Apple requires in-app account deletion for apps with account creation; users must understand local vs cloud deletion. |
| **Files likely to change** | Hosted privacy policy; `UI.xcstrings` (`account.delete.*`, `settings.privacy.policy.your_rights.content`); optional `docs/legal/account_deletion_policy.md` |
| **External action** | **Legal review** |
| **Acceptance criteria** | Policy states: **Delete Account** removes Supabase auth user + stored backup rows; **Reset All Data** removes local app data only; sign-out does not delete cloud backups; steps documented for users. See [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md). |

---

### 2.7 Privacy copy: local, Supabase manual backup, optional iCloud

| Field | Detail |
|-------|--------|
| **Why it matters** | Public copy must distinguish local storage, user-initiated Supabase backup, and optional Apple iCloud sync (not purchases). |
| **Files likely to change** | `UI.xcstrings`; hosted `i18n/privacy.json`; see [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) CloudKit section |
| **External action** | None |
| **Acceptance criteria** | Supabase financial data = **manual backup/restore only**; iCloud/CloudKit disclosed **only if verified active** in production archive build; no vague “legal CloudKit” wording. |

---

### 2.8 Verify App Store Connect App Privacy Details

| Field | Detail |
|-------|--------|
| **Why it matters** | Mismatch between Connect labels and app behavior is a rejection and regulatory risk. |
| **Files likely to change** | None in code; checklist doc only |
| **External action** | **App Store Connect** — complete App Privacy questionnaire after 2.4–2.7. |
| **Acceptance criteria** | Labels reflect: financial info (local; linked when user stores manual backup in Supabase), email, user ID, optional **user-initiated** cloud backup to Supabase, no tracking, no third-party advertising. |

---

## 3. Block 2 — Auth / Supabase Safety Block

### 3.1 Apple Sign In nonce implementation

| Field | Detail |
|-------|--------|
| **Why it matters** | Supabase and Apple recommend nonce with `signInWithIdToken` to prevent replay attacks; listed in Phase 9 scope. |
| **Files likely to change** | `budgetmeter.ios/CoreKit/Sources/Auth/AuthService.swift`; `budgetmeter.ios/Features/AuthFeature/View/WelcomeView.swift`; optionally `AppleSignInCoordinator.swift` |
| **External action** | None |
| **Acceptance criteria** | Random nonce generated per sign-in; SHA-256 hashed nonce passed to Apple request and Supabase credentials; sign-in still succeeds on device; documented in QA script. |

---

### 3.2 Apple credential revocation handling or documented behavior

| Field | Detail |
|-------|--------|
| **Why it matters** | User can revoke Apple ID access in Settings; app should sign out or show clear error. |
| **Files likely to change** | `AuthService.swift`; `RootAuthView.swift` or `budgetmeter_iosApp.swift` (foreground check) |
| **External action** | None |
| **Acceptance criteria** | **Either:** `ASAuthorizationAppleIDProvider.getCredentialState` on launch/foreground signs user out when `.revoked` / `.notFound` **or** written QA doc + known limitation approved for v1 with manual test steps. |

---

### 3.3 Account deletion live verification (second pass)

| Field | Detail |
|-------|--------|
| **Why it matters** | Audit confirms code exists; production must prove cloud data is gone. User reports button/logic work — needs structured re-test. |
| **Files likely to change** | None if pass; `docs/qa/release_tracker.md` or Stage B checklist for evidence |
| **External action** | **Supabase dashboard** — confirm rows deleted; **Supabase** — Edge Function deployed |
| **Acceptance criteria** | Test account: create backup → Delete Account → confirm `user_backups` and `user_backup_versions` empty for user; auth user absent in Supabase Auth; app shows signed out; local data still present per policy; screenshot/log attached to QA record. |

---

### 3.4 Supabase Edge Function deploy verification

| Field | Detail |
|-------|--------|
| **Why it matters** | `delete-account` must be live with service role env vars. |
| **Files likely to change** | `supabase/functions/delete-account/index.ts` (only if fix needed) |
| **External action** | **Supabase dashboard** — deploy function; set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` secrets |
| **Acceptance criteria** | `POST /functions/v1/delete-account` with valid user JWT returns `{ "deleted": true }`; invalid token returns 401; function logs show no backup/auth delete errors. |

---

### 3.5 Supabase RLS / cross-user isolation test

| Field | Detail |
|-------|--------|
| **Why it matters** | Financial JSONB in `user_backups` must never leak across users. |
| **Files likely to change** | Optional `budgetmeter.iosTests/` integration test (staging); QA checklist |
| **External action** | **Supabase dashboard** — confirm migrations `0001–0003` applied on production/staging project |
| **Acceptance criteria** | User A token cannot `select` User B backup; User A cannot `upsert` with User B `user_id`; documented two-account manual test pass. |

---

### 3.6 First sign-in overlap UX

| Field | Detail |
|-------|--------|
| **Why it matters** | `FirstSignInStateMachine` returns `requireOverlapChoice` but UI only shows warning text; risk of accidental overwrite. |
| **Files likely to change** | `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift`; `UI.xcstrings` (`backup.overlap.*`); stop unconditional `markFirstSignInCompleted()` on every refresh |
| **External action** | None |
| **Acceptance criteria** | When local + cloud both have data: user must explicitly choose **Back up this device** or **Restore from cloud** (or cancel); no silent default; scenario not marked complete until user acts. |

---

### 3.7 Cloud-only restore prompt

| Field | Detail |
|-------|--------|
| **Why it matters** | New device with empty local data and existing cloud backup should be guided to restore. |
| **Files likely to change** | `AccountBackupSettingsView.swift`; `UI.xcstrings` |
| **External action** | None |
| **Acceptance criteria** | `FirstSignInScenario.cloudOnly` shows prominent restore CTA or sheet on first visit to Account & Backup; restore still requires confirmation. |

---

### 3.8 Logout vs delete behavior clarity

| Field | Detail |
|-------|--------|
| **Why it matters** | Sign out leaves cloud backup on server; delete removes cloud account; users confuse the two. |
| **Files likely to change** | `AccountBackupSettingsView.swift`; `WelcomeView.swift` / Settings account section; `UI.xcstrings` (`account.sign_out*`, `account.footer`, `account.delete.*`) |
| **External action** | None |
| **Acceptance criteria** | Sign out footer explains cloud data remains; delete alert restates local retention; privacy policy aligned (Block 1.6). |

---

### 3.9 Local data deletion — Reset All Data (locked product decision)

| Field | Detail |
|-------|--------|
| **Why it matters** | **Reset All Data** is **local-only** — not account deletion. Users must be able to wipe the device copy and start fresh. Legal pages and privacy copy must never conflate with Delete Account. |
| **Product intent** | Deletes **all** local user financial data; re-seeds defaults; does **not** touch Supabase account or cloud-stored backups. |
| **Files likely to change** | `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift`; `UI.xcstrings` reset confirmation copy; hosted legal pages |
| **External action** | None |
| **Acceptance criteria** | Reset removes all user financial entities (`SavingsGoal`, `Subscription`, `Bill`, `BillPayment`, `RecurringTransaction`, `FinancialSnapshot`, `FinancialCategory`, `AppSettings` per product rules); re-seeds defaults; widget snapshot refreshed; **does not** call `deleteAccount()`; legal/web copy matches behavior. |

**Code status:** Partial implementation today — only `FinancialCategory` + `AppSettings` deleted. **P0 fix before release.**

---

### 3.10 Email/password auth + confirmation (locked — enabled for v1)

**Decision locked:** Email/password registration **stays enabled**. Do **not** hide email auth for v1.

#### Current state (code inspection)

| Item | Finding |
|------|---------|
| **UI entry** | `WelcomeView` → Sign in with Apple, Sign in with Email, Create Account |
| **Register** | `RegisterView.swift` → `AuthService.signUp(email:password:)` |
| **Sign in** | `SignInView.swift` → `AuthService.signIn(email:password:)` |
| **Forgot password** | `ForgotPasswordView.swift` → `resetPasswordForEmail` **without** `redirectTo` |
| **Email confirmation** | Supabase confirm-email **enabled**; app lacks verification UI + `auth/callback` deep link |
| **signUp behavior** | Fails when `response.session` is nil (expected with confirmation on) |

#### Required implementation (P0 before release)

| Field | Detail |
|-------|--------|
| **Why it matters** | Shipped UI exposes email register; legal pages will document confirmation; flow must work. |
| **Files likely to change** | `AuthService.swift`; `RootAuthView.swift`; `RegisterView.swift`; `budgetmeter_iosApp.swift`; `SupabaseConfig.swift`; new verification view; `UI.xcstrings` |
| **External action** | **Supabase dashboard** — Site URL, redirect URLs (`budgetmeter://auth/callback`), email templates |
| **Acceptance criteria** | Register → verify-email screen; link opens app → session; unverified users blocked; password reset with redirect; legal copy matches. See [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) §13. |

#### Apple + email same-address linking (pre-release)

| Field | Detail |
|-------|--------|
| **Why it matters** | Same email via email/password and Apple Sign In may link or create duplicate Supabase users — legal copy must match actual behavior. |
| **Files likely to change** | Privacy/Terms JSON + `UI.xcstrings` after QA result |
| **External action** | Manual QA on Supabase dashboard |
| **Acceptance criteria** | Test documented: email register + confirm → sign out → Apple Sign In same email → record one user vs two; update public copy before release. |

#### Legal pages (parallel track)

| Field | Detail |
|-------|--------|
| **Why it matters** | Privacy/Terms must cover email/password, verification, reset alongside Apple Sign In. |
| **Files likely to change** | `docs/legal/assets/i18n/privacy.json`, `terms.json`; in-app `UI.xcstrings` |
| **Acceptance criteria** | Hosted + in-app copy describes both auth methods; no Apple-only wording. |

---

## 4. Block 3 — StoreKit / Widget / Device QA Block

### 4.1 StoreKit product ID verification in App Store Connect

| Field | Detail |
|-------|--------|
| **Why it matters** | Code uses `com.budgetmeter.premium.lifetime`; bundle ID is `com.janstrade.budgetmeter-ios` — product must exist and be cleared for sale. |
| **Files likely to change** | None if IDs match Connect; else `PremiumManager.swift` |
| **External action** | **App Store Connect** — create/configure non-consumable; paid apps agreement; tax/banking |
| **Acceptance criteria** | Product ID matches code; status “Ready to Submit”; price tier set; localized display name/description. |

---

### 4.2 StoreKit sandbox purchase test

| Field | Detail |
|-------|--------|
| **Why it matters** | Lifetime purchase must complete on real device sandbox account. |
| **Files likely to change** | None expected |
| **External action** | **Apple Developer** — sandbox tester; **Manual QA** on device |
| **Acceptance criteria** | Purchase succeeds; `isPremium` true; paywall dismisses; `AppSettings.isPremiumUser` persisted; widget snapshot refreshes to unlocked. |

---

### 4.3 Restore purchase test

| Field | Detail |
|-------|--------|
| **Why it matters** | App Store requires working restore for non-consumables. |
| **Files likely to change** | None expected |
| **External action** | **Manual QA** — sandbox account with prior purchase |
| **Acceptance criteria** | Restore on paywall succeeds; “no purchase found” shown when appropriate; premium gates unlock after restore. |

---

### 4.4 Paywall copy verification

| Field | Detail |
|-------|--------|
| **Why it matters** | Paywall, Terms, and App Store metadata must agree on lifetime purchase. |
| **Files likely to change** | `PremiumPaywallView.swift`; `UI.xcstrings` (`premium.*`) |
| **External action** | **App Store Connect** — IAP localization |
| **Acceptance criteria** | Paywall shows StoreKit price (not hardcoded fallback); “one-time / lifetime” language; no subscription wording anywhere in purchase path. |

---

### 4.5 Widget device / archive signing

| Field | Detail |
|-------|--------|
| **Why it matters** | KI-004: widget extension provisioning for device/Archive untested. |
| **Files likely to change** | `budgetmeter.ios.xcodeproj` signing settings only if misconfigured |
| **External action** | **Apple Developer** — App Groups capability; provisioning profiles for app + extension |
| **Acceptance criteria** | Archive succeeds; widget installs on physical device TestFlight build; App Group `group.com.budgetmeter.shared` works on device. |

---

### 4.6 Widget premium locked state manual QA

| Field | Detail |
|-------|--------|
| **Why it matters** | Free users must see teaser, not financial data. |
| **Files likely to change** | None expected |
| **External action** | **Manual QA** |
| **Acceptance criteria** | Free user: widget shows locked teaser + lock icon; premium user: net daily pace matches Home hero after app open; stale/missing states verified. |

---

### 4.7 Widget deep link manual QA

| Field | Detail |
|-------|--------|
| **Why it matters** | Locked widget must open paywall; unlocked must open Home hero. |
| **Files likely to change** | None expected (`budgetmeter://premium/widgets`, `budgetmeter://home/hero`) |
| **External action** | **Manual QA** |
| **Acceptance criteria** | Tap locked widget → app opens → premium paywall for widgets; tap unlocked → Home tab + hero focus. |

---

### 4.8 Physical device TestFlight smoke test

| Field | Detail |
|-------|--------|
| **Why it matters** | Simulator does not validate signing, StoreKit, Apple Sign In, or widget install end-to-end. |
| **Files likely to change** | None |
| **External action** | **App Store Connect** — TestFlight upload; **Manual QA** |
| **Acceptance criteria** | Fresh install: auth → optional backup → purchase → widget → sign out → delete account (staging); no crash on cold start or upgrade from previous build. |

---

## 5. Block 4 — Polish / Localization / Accessibility Block

### 5.1 Duplicate `UI.xcstrings` in Copy Bundle Resources

| Field | Detail |
|-------|--------|
| **Why it matters** | KI-001 — duplicate catalog in app + widget targets causes warnings and unpredictable string resolution. |
| **Files likely to change** | `budgetmeter.ios.xcodeproj/project.pbxproj` |
| **Acceptance criteria** | Single copy per target; build warnings for duplicate resources gone; auth/backup strings resolve correctly in app and widget. |

---

### 5.2 Hardcoded strings audit cleanup

| Field | Detail |
|-------|--------|
| **Why it matters** | `docs/hardcoded_strings_audit.md` lists 115 hardcoded + 197 missing-catalog strings; impacts non-English users. |
| **Files likely to change** | Per audit priority list (P0: `HomeDisplayMapping` — largely fixed; remaining user-facing rows in audit) |
| **Acceptance criteria** | All **user-facing** P0/P1 strings from audit resolved or waived; no English-only auth/legal errors. |

---

### 5.3 Missing localization keys

| Field | Detail |
|-------|--------|
| **Why it matters** | Keys with only `defaultValue` English fail for 10-language support. |
| **Files likely to change** | `UI.xcstrings`, `Home.xcstrings`, `Settings.xcstrings`, etc. |
| **Acceptance criteria** | All keys used in auth, backup, paywall, and settings privacy/terms have 10 locales or explicit waiver for v1. |

---

### 5.4 VoiceOver labels

| Field | Detail |
|-------|--------|
| **Why it matters** | Some labels hardcoded in English (`DailyBudgetCard`, etc.). |
| **Files likely to change** | `DesignSystem/Components/Cards/DailyBudgetCard.swift`; other cards per `localization_accessibility_qa_plan.md` |
| **Acceptance criteria** | Auth buttons, paywall, account delete, backup actions have localized accessibility labels; spot-check Home + Settings with VoiceOver on device. |

---

### 5.5 Dynamic Type

| Field | Detail |
|-------|--------|
| **Why it matters** | Financial apps must remain readable at largest content sizes. |
| **Files likely to change** | Hero cards, paywall, auth forms |
| **Acceptance criteria** | No clipped text at AX5 on Home hero, Welcome, Paywall, Account & Backup; widget exempt but documents known limitation. |

---

### 5.6 Dark / light contrast

| Field | Detail |
|-------|--------|
| **Why it matters** | Brand dark-first theme must meet contrast on pace amounts and errors. |
| **Files likely to change** | DesignSystem tokens if failures found |
| **Acceptance criteria** | Manual pass on Home, Welcome, Settings privacy sheets in light and dark; error text readable. |

---

### 5.7 RTL manual QA (Arabic)

| Field | Detail |
|-------|--------|
| **Why it matters** | Arabic catalog entries exist; layout mirroring not verified. |
| **Files likely to change** | Only if RTL layout bugs found |
| **Acceptance criteria** | Device language Arabic: Welcome, Home, Settings, paywall layout correct; numbers in financial rows readable. |

---

### 5.8 Offline backup error / copy improvement

| Field | Detail |
|-------|--------|
| **Why it matters** | `BackupServiceError.offline` never thrown; users see generic failure. |
| **Files likely to change** | `BackupService.swift`; `UI.xcstrings` (`backup.error.offline`) |
| **Acceptance criteria** | Airplane mode during backup/restore shows specific offline message; local data unchanged. |

---

## 6. Recommended Execution Order

1. **Block 1 — Legal / Privacy (P0)** — Terms IAP fix, hosted URLs, privacy manifest, retention/deletion policy, App Store Connect privacy labels.
2. **Block 2 — Auth / Supabase (P0–P1)** — email confirmation flow; nonce; account deletion re-verification; RLS test; overlap UX; **full local Reset All Data**; logout/delete copy; legal uses **manual backup/restore** wording.
3. **Block 3 — StoreKit / Widget / Device QA (P1)** — Connect product, sandbox purchase/restore, widget signing, TestFlight smoke.
4. **Block 4 — Polish (P2–P3)** — duplicate xcstrings, localization/a11y sweep, offline backup copy.

**Parallel work:** Block 3.1–3.4 (Connect setup) can start during Block 1 legal drafting. Block 4 items can run during TestFlight except xcstrings dedupe (before final archive).

---

## 7. Go/No-Go Gates

### Gate A — Local-first App Store candidate

**Purpose:** Ship core app with Apple Sign In + email/password auth; manual Supabase backup not marketed as sync; IAP optional.

| Must complete |
|---------------|
| Block 1.1 Terms IAP copy fixed |
| Block 1.2–1.3 Hosted privacy + terms URLs live (see [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md)) |
| Block 1.4 PrivacyInfo.xcprivacy updated |
| Block 2.10 Email confirmation flow implemented |
| Block 2.9 Full local Reset All Data implemented |
| Block 3.8 TestFlight smoke — auth + core flows |
| Block 4.1 Duplicate xcstrings fixed (recommended) |

**Does not require:** Cloud backup live QA, account deletion cloud verification (if auth accounts only used for identity without backup — **not current product direction**).

---

### Gate B — Auth + Supabase backup App Store candidate

**Purpose:** Premium **manual** cloud backup/restore to Supabase production-ready (not automatic sync).

| Must complete |
|---------------|
| **All Gate A items** |
| Block 1.5–1.7 Retention + deletion + storage copy (local / manual Supabase backup / optional iCloud if active) |
| Block 1.8 App Privacy Details accurate |
| Public legal copy uses **manual backup and restore** for Supabase — not “cloud sync” |
| **Controller:** Umurcan Soganci · **Support:** umursoganci@gmail.com · **Governing law:** Türkiye / Istanbul (draft default) |
| Block 2.1 Apple nonce |
| Block 2.2 Revocation handled or documented + tested |
| Block 2.3 Account deletion live verification **passed** |
| Block 2.4 Edge Function deployed |
| Block 2.5 RLS two-account test **passed** |
| Block 2.6 Overlap UX wired |
| Block 2.7 Cloud-only restore prompt |
| Block 2.8 Logout vs delete copy |
| Phase 10 Stage B checklist (AUTH, SYNC, DEL, SEC) signed in `release_tracker.md` |

---

### Gate C — Paid premium / IAP candidate

**Purpose:** Charge for lifetime premium including widgets, backup, etc.

| Must complete |
|---------------|
| **All Gate B items** (backup ships with premium) |
| Block 1.1 + 4.4 Paywall/Terms/Connect IAP alignment |
| Block 3.1–3.4 Product ID, sandbox purchase, restore |
| Block 3.5–3.7 Widget device QA |
| Block 4.4 VoiceOver on paywall + purchase buttons |

---

## 8. Master Checklist

| Block | Task | Priority | Status | Owner | Notes |
|-------|------|----------|--------|-------|-------|
| 1 | Fix Terms IAP copy (lifetime) | P0 | Not started | Code | `UI.xcstrings` |
| 1 | Hosted Privacy Policy URL | P0 | Not started | Legal docs | App Store Connect |
| 1 | Hosted Terms URL | P0 | Not started | Legal docs | Match IAP type |
| 1 | Update PrivacyInfo.xcprivacy | P0 | Not started | Code | Linked data types |
| 1 | Data retention policy | P1 | Not started | Legal docs | Include backup versions |
| 1 | Account deletion policy | P1 | Not started | Legal docs | Local vs cloud |
| 1 | Local/Supabase/iCloud copy | P1 | Not started | Legal docs | iCloud only if production-active |
| 2 | Apple + email linking QA | P0 | Not started | Manual QA + Legal docs | Same email test |
| 2 | CloudKit production verify | P1 | Not started | Manual QA | Archive build |
| 1 | App Store Connect privacy labels | P0 | Not started | App Store Connect | After plist |
| 2 | Apple Sign In nonce | P1 | Not started | Code | |
| 2 | Apple credential revocation | P1 | Not started | Code / Manual QA | Or documented waiver |
| 2 | Account deletion live verification | P0 | In progress | Supabase + Manual QA | User says works; formal pass needed |
| 2 | Edge Function deploy verify | P0 | Not started | Supabase dashboard | |
| 2 | RLS cross-user test | P0 | Not started | Supabase + Manual QA | Two test accounts |
| 2 | First sign-in overlap UX | P1 | Not started | Code | |
| 2 | Cloud-only restore prompt | P1 | Not started | Code | |
| 2 | Logout vs delete copy | P1 | Not started | Code | |
| 2 | Email confirmation flow (v1 enabled) | P0 | Not started | Code + Supabase | Locked decision |
| 2 | Email auth legal copy | P0 | Not started | Legal docs | Apple + email in Privacy/Terms |
| 2 | Fix resetAllData() full local wipe | P0 | Not started | Code | Not account deletion |
| 2 | Supabase persistence legal wording | P0 | Not started | Legal docs | Manual backup only — verified in code |
| 3 | StoreKit product ID in Connect | P0 | Not started | App Store Connect | |
| 3 | Sandbox purchase test | P1 | Not started | Manual QA | Device |
| 3 | Restore purchase test | P1 | Not started | Manual QA | |
| 3 | Paywall copy verification | P0 | Not started | Code + Connect | |
| 3 | Widget archive/device signing | P1 | Not started | Apple Developer | KI-004 |
| 3 | Widget locked state QA | P1 | Not started | Manual QA | |
| 3 | Widget deep link QA | P1 | Not started | Manual QA | |
| 3 | TestFlight smoke test | P1 | Not started | Manual QA | |
| 4 | Dedupe UI.xcstrings | P2 | Not started | Code | KI-001 |
| 4 | Hardcoded strings P0/P1 | P2 | Not started | Code | See audit doc |
| 4 | Missing localization keys | P2 | Not started | Code | |
| 4 | VoiceOver labels | P2 | Not started | Code | |
| 4 | Dynamic Type pass | P3 | Not started | Manual QA | |
| 4 | Dark/light contrast | P3 | Not started | Manual QA | |
| 4 | RTL Arabic QA | P3 | Not started | Manual QA | |
| 4 | Offline backup errors | P3 | Not started | Code | |

---

## 9. What Can Wait

| Item | Rationale |
|------|-----------|
| Full email/password + confirmation deep links | **Required for v1** — locked enabled |
| CloudKit removal / migration execution | Post-v1; public copy only mentions iCloud if still active |
| `user_backup_versions` automated pruning | Operational; document retention first |
| Local snapshot recovery UI | Mitigation for restore failure; backup manual v1 |
| Keychain for `AuthSessionStore` | Security hardening, not review blocker |
| Remove dead `AppleSignInCoordinator` | Cleanup |
| Preview-only hardcoded strings | Not shipped |
| Widget Dynamic Type perfection | Known widget limitation |
| RevenueCat, ads-free, subscription IAP | Postponed in product matrix |
| Automated RLS integration tests in CI | Manual two-account test sufficient for v1 |
| CORS tightening on Edge Function | Low mobile risk |

---

## 10. Final Recommendation

### Should email/password register be hidden for v1?

**No — locked enabled.** Implement email confirmation + legal copy for both Apple Sign In and email/password before release.

### Should Apple Sign In be primary auth path for v1?

**Apple Sign In and email/password are both v1 paths.** Apple remains the recommended primary option in UX; email is a full alternative with confirmation.

### Should cloud backup ship now or behind cautious setting?

**Ship only after Gate B passes**, as **manual premium backup and restore** to Supabase (`BackupService.backupNow` / `restoreFromCloud` only — **not automatic sync**). Require TestFlight validation of backup → restore → delete account before App Store release notes mention cloud backup.

### What is the first implementation block to start?

**Block 1 — Legal / Privacy**, in this order:

1. Draft English legal copy in `docs/legal/source/` per [`legal_privacy_github_pages_plan.md`](legal_privacy_github_pages_plan.md) locked decisions (Umurcan Soganci, umursoganci@gmail.com, Türkiye/Istanbul, manual Supabase backup, both auth methods).  
2. Build `docs/legal/` HTML/CSS/JS + English JSON.  
3. Fix Terms IAP strings in catalogs.  
4. Publish GitHub Pages; update Connect URLs.  
5. In parallel: **Block 2.10** email confirmation + **Block 2.9** full local reset + Apple/email linking QA.

Account deletion should receive its **formal second verification pass** (Block 2.3) immediately after Supabase deploy confirmation, using a throwaway test account with a real backup payload.

---

*Documentation only. No Swift, Xcode, or Core Data files were modified.*
