# Legal & Privacy GitHub Pages Plan — BudgetMeter

**Created:** 2026-06-18  
**Status:** Planning only — no HTML, no GitHub Pages deployment, no app changes  
**Repository:** `https://github.com/jansoganci/budgetmeter.ios`  
**Related docs:** `app_store_privacy_auth_readiness_audit.md`, `app_store_readiness_execution_plan.md`, `phase9_supabase_auth_database_migration_scope.md`, `localization_accessibility_qa_plan.md`

---

## 1. Executive Summary

### What is needed for App Store submission

Apple requires **public, HTTPS URLs** that reviewers and users can open without signing in:

| Requirement | Status today | Needed |
|-------------|--------------|--------|
| Privacy Policy URL | In-app sheet only (`SettingsView.swift`) | **Hosted public URL** |
| Terms of Service URL | In-app sheet only | **Hosted public URL** (required for paid IAP) |
| Account deletion explanation | In-app copy + Account & Backup | **Public page recommended** (Apple Guideline 5.1.1) |
| App Privacy labels accuracy | `PrivacyInfo.xcprivacy` incomplete | Align after policy finalized |
| Legal copy accuracy | Terms still describe **subscription**; privacy updated for Supabase | Rewrite before publish |

Minimum for submission: **Privacy Policy** + **Terms of Service** URLs that match actual app behavior.

### Why GitHub Pages is acceptable

- **Free HTTPS** on `*.github.io` — meets App Store URL requirements.
- **No custom domain required** for v1.
- **Same repo** as the app — legal copy can be reviewed in PRs alongside `UI.xcstrings`.
- **Static HTML/CSS/JS** — no server, no cookies, no tracking, aligns with privacy positioning.
- **Version controlled** — last-updated dates and diffs are auditable.

**Note:** Copy is a **draft** for implementation. Optional: user may seek professional legal review later — **not required** to start HTML or copy work.

---

## Final Decisions Locked (2026-06-18)

Product and legal identity decisions below are **locked** for GitHub Pages copy and in-app alignment.

| # | Decision | Value / rule |
|---|----------|--------------|
| 1 | **Email/password registration** | **Enabled for v1** — Privacy/Terms cover email auth, confirmation, password reset |
| 2 | **Apple Sign In** | **Enabled for v1** — alongside email/password |
| 3 | **Supabase** | Cloud backend for **auth** + **manual premium backup/restore** only (not automatic financial sync) |
| 4 | **Reset All Data** | **Local full wipe** only — fresh start on device; not account deletion |
| 5 | **Delete Account** | **Cloud/account deletion** — Supabase auth user + stored backups; local data stays unless user resets |
| 6 | **Support email** | **umursoganci@gmail.com** |
| 7 | **Legal entity** | **Umurcan Soganci** (personal name only — **no** company/entity wording) |
| 8 | **Governing law** | **Selected draft default:** laws of **Türkiye**; courts of **Istanbul** (use in Terms until changed) |
| 9 | **Professional legal review** | **Optional** — user may seek later; **does not block** implementation |

### Supabase persistence — verified from code (2026-06-18)

| Layer | Automatic? | What happens |
|-------|------------|--------------|
| **Supabase Auth** | Yes (on successful sign-in) | Apple Sign In or email/password creates/restores an auth session (`AuthService`, `Supabase Auth`). |
| **Financial data in Supabase DB** | **No — not automatic sync** | Data is written to `user_backups` only when the user taps **Back Up Now** (`BackupService.backupNow`). |
| **Restore** | **Manual only** | User taps **Restore from Cloud** (`BackupService.restoreFromCloud`); wipe-and-replace import to Core Data. |
| **Premium gate** | Yes | Backup/restore requires Premium + signed-in user (`AccountBackupSettingsView`). |
| **Background sync** | **None found** | No code path uploads Core Data changes on save, schedule, or sign-in. |

**Legal wording rule:** Do **not** describe financial data as “automatically synced to Supabase” or “real-time cloud sync.” Use:

- **“Manual premium cloud backup and restore”** (accurate), or  
- **“Optional cloud backup stored in Supabase when you choose to back up”**

Supabase remains the **cloud database/backend** for auth identity and user-initiated backup payloads — not a continuous sync engine in the current build.

### Reset All Data vs Delete Account — product intent

| Action | Scope | Cloud / account | Local app data |
|--------|-------|-----------------|----------------|
| **Reset All Data** | Settings → Data & Privacy | **Does not** delete account or cloud backups | **Must** delete all local user data and re-seed defaults so user can start fresh |
| **Delete Account** | Settings → Account & Backup | Deletes Supabase auth user + `user_backups` + `user_backup_versions` | **Does not** wipe local data unless user also resets |

**Code gap (implementation, not legal):** `SettingsViewModel.resetAllData()` today only batch-deletes `FinancialCategory` and `AppSettings` — **not** a full local wipe. Legal copy must reflect **intended** full local reset; code must be fixed before publish (see checklist below).

### Email/password auth — product intent

- `WelcomeView` exposes Sign in with Apple, **Sign in with Email**, and **Create Account** (`RegisterView`, `SignInView`, `ForgotPasswordView`).
- Supabase **email confirmation is enabled** (team decision).
- Legal pages must document registration, confirmation email, verified sign-in, and password reset.
- **Implementation gap:** email confirmation deep link / verification UI not complete in app — must be implemented before release; legal copy describes **intended** supported flow.

### Apple Sign In + email/password — account linking (pre-release test)

Before release, run and **document** this QA scenario; legal copy must match observed behavior:

| Step | Action |
|------|--------|
| 1 | Register with **email/password** using address `test@example.com` (or test alias); confirm email |
| 2 | Sign out |
| 3 | Sign in with **Apple Sign In** using the **same email** |
| 4 | Inspect Supabase Auth: **one user** (linked identities) vs **two separate users** |
| 5 | Document expected product behavior in Privacy/Terms (e.g. “accounts with the same email may be linked” or “separate sign-in methods may create separate accounts”) |

**Status:** Not tested yet — **verify before release**; update legal copy after result.

### CloudKit / iCloud — disclosure rule (not purchases)

- **CloudKit** = Apple’s **iCloud data sync/storage** for on-device database replication. It is **not** related to App Store purchases or Premium.
- Do **not** use vague “legal CloudKit” phrasing in public copy.
- **Disclose iCloud/CloudKit only if** the production build actually uses or may use iCloud-backed persistence (`NSPersistentCloudKitContainer` + active iCloud entitlement).
- **Repo state:** `PersistenceService` uses `NSPersistentCloudKitContainer`; checked-in entitlements have **no** iCloud capability — **verify CloudKit active/inactive in production/archive build** before emphasizing in public legal copy.
- If **inactive** in production: omit or use one short note only if needed for legacy installs; do **not** emphasize iCloud alongside Supabase.
- If **active**: disclose optional iCloud sync of local app data to user’s private iCloud account (separate from Supabase manual backup).

---

## Pre-publish verification checklist

Use before publishing GitHub Pages or App Store submission:

| Item | Owner | Status |
|------|-------|--------|
| **Email confirmation setup** — Supabase Site URL + redirect URLs (`budgetmeter://auth/callback` per `docs/auth_implementation_plan.md`); email templates; confirm-email enabled; app handles callback + verification gate | Supabase dashboard + Code | Not started |
| **Email auth legal copy** — Privacy/Terms cover email, password (hashed by Supabase), verification, reset; Apple Sign In + email coexist; no Apple-only auth wording | Legal docs | Not started |
| **Supabase persistence behavior** — Public copy uses **manual backup/restore** language; no “automatic sync” for financial data; auth session vs backup payload distinguished | Legal docs | **Verified in code** — copy must follow table above |
| **Reset All Data — full local wipe** — Code deletes all user financial entities + resets app state; does not call account deletion; widget snapshot refreshed | Code + Manual QA | **Not implemented** — current code partial |
| **Delete Account — cloud/account deletion** | Edge Function removes auth user + backup tables; local data retained; live QA pass documented | Supabase + Manual QA | Verify before release |
| **Apple + email same-address linking** | Register email/password → sign out → Apple Sign In same email → document one user vs two in Supabase; align Privacy/Terms | Manual QA + Legal docs | Verify before release |
| **CloudKit active in production build** | Confirm iCloud entitlement + sync behavior in archive build; only disclose iCloud in public copy if active | Manual QA | Verify before release |

---

### What should be implemented later (not in this step)

1. Authoritative legal copy (English first, then 9 translations).
2. Static site under `docs/legal/` (HTML, CSS, JS, JSON i18n).
3. GitHub Pages enabled (source: `/docs` on `main`).
4. App links from Settings → open Safari to canonical URLs.
5. App Store Connect URL fields updated.
6. `PrivacyInfo.xcprivacy` updated to match published policy.
7. In-app `UI.xcstrings` synced with hosted copy (lifetime IAP Terms fix).

---

## 2. Required Public Pages

| Page | Required for App Store | Purpose |
|------|----------------------|---------|
| **Privacy Policy** | **Yes** | Data collection, use, storage, rights, contact |
| **Terms of Service** | **Yes** (paid IAP) | License, IAP, disclaimers, liability, contact |
| **Account Deletion / Data Deletion** | **Strongly recommended** | How to delete cloud **account** and stored backups; distinct from Reset All Data |
| **Data Retention** | **Recommended** | How long local/cloud data is kept |
| **Support / Contact** | **Recommended** | Support email, response expectations |
| **Legal index** | **Optional** | Hub linking all pages + language selector |

### Page relationship

```
Legal index (optional)
├── Privacy Policy          ← App Store Connect primary privacy URL
├── Terms of Service        ← IAP / license reference
├── Account Deletion        ← Linked from Privacy + in-app delete flow
├── Data Retention          ← Linked from Privacy
└── Support                 ← App Store Support URL (optional)
```

---

## 3. Recommended GitHub Pages Structure

### Repository layout (recommended)

Publish from **`/docs` folder** on `main` (GitHub Pages setting: *Deploy from branch → main → /docs*).

```
docs/
├── legal/
│   ├── index.html                 # Legal hub (optional but useful)
│   ├── privacy/
│   │   └── index.html
│   ├── terms/
│   │   └── index.html
│   ├── account-deletion/
│   │   └── index.html
│   ├── data-retention/
│   │   └── index.html
│   ├── support/
│   │   └── index.html
│   └── assets/
│       ├── styles.css             # BudgetMeter dark theme
│       ├── legal.js               # Language selector + i18n loader
│       └── i18n/
│           ├── common.json        # Nav, footer, language names, dates
│           ├── privacy.json
│           ├── terms.json
│           ├── account-deletion.json
│           ├── data-retention.json
│           └── support.json
└── implementation/                # Existing planning docs (unchanged)
```

### Why this structure

- **`index.html` per section** — clean URLs without `.html` filenames in the path.
- **Shared `assets/`** — one theme, one JS module, no duplication.
- **JSON i18n per page** — easier to maintain than 60 separate HTML files (6 pages × 10 languages).
- **Keeps implementation docs** in `docs/implementation/` without mixing them into the public legal root (legal lives under `docs/legal/` only).

### Alternative considered (not recommended for v1)

| Structure | Pros | Cons |
|-----------|------|------|
| `docs/legal/en/privacy.html` per language | Best SEO per locale | 60 HTML files; drift risk |
| Single HTML with embedded `<template>` per lang | No extra requests | Huge files; hard to diff |
| Separate repo for legal | Clean separation | Extra repo overhead for solo dev |

---

## 4. Multilingual Strategy

### Supported approaches analyzed

| Approach | Verdict |
|----------|---------|
| One HTML + embedded translations in HTML | ❌ Hard to maintain at 10 languages |
| One folder per language (`legal/en/`, `legal/tr/`) | ⚠️ Valid for SEO; high file count |
| **One HTML per page + JSON translation files** | ✅ **Recommended** |
| Build step (Jekyll/Vite) | ❌ Extra tooling; not needed for 6 pages |

### Recommended method: JSON i18n + small vanilla JS

**How it works:**

1. Each page (`privacy/index.html`, etc.) loads `legal.js` + page-specific JSON (e.g. `i18n/privacy.json`).
2. JSON structure: top-level keys = locale codes (`en`, `tr`, `de`, …); values = section objects (`title`, `sections[]`, `lastUpdated`).
3. `legal.js` renders content into semantic HTML landmarks (`<main>`, `<h1>`, `<section>`).
4. Language selector (globe icon + current language) in fixed header calls `setLanguage(code)`.

### Language selector UX

- **Control:** Globe icon (`🌐` or SVG) + current language label in top-right of every legal page.
- **Interaction:** Tap/click opens simple dropdown or bottom sheet on mobile listing all 10 languages (native names from `common.json`).
- **Persistence:** `localStorage` key `budgetmeter-legal-lang`.
- **URL override:** `?lang=tr` sets language and updates storage (shareable links).
- **No heavy frameworks.** No React/Vue on legal pages.

### Fallback language

1. `?lang=` query param (if valid)
2. `localStorage` saved preference
3. Browser `navigator.language` mapped to supported code (e.g. `zh-CN` → `zh-Hans`)
4. **Default: `en`**

### Browser language auto-detection

**Yes — on first visit only** (no saved preference). Improves UX for international users. App Store Connect URLs should still use **English canonical paths** (no required `?lang=`).

### App Store–friendly URLs (canonical)

Use **language-neutral paths**; English is default content when opened without params:

| Page | Canonical URL |
|------|----------------|
| Privacy | `https://jansoganci.github.io/budgetmeter.ios/legal/privacy/` |
| Terms | `https://jansoganci.github.io/budgetmeter.ios/legal/terms/` |
| Account deletion | `https://jansoganci.github.io/budgetmeter.ios/legal/account-deletion/` |
| Data retention | `https://jansoganci.github.io/budgetmeter.ios/legal/data-retention/` |
| Support | `https://jansoganci.github.io/budgetmeter.ios/legal/support/` |
| Legal hub | `https://jansoganci.github.io/budgetmeter.ios/legal/` |

**Verification required:** Confirm exact URL after first GitHub Pages deploy (repo name case sensitivity).

### Sync with app localization

Source of truth for translations should eventually be **aligned with** `UI.xcstrings` keys under `settings.privacy.policy.*` and `settings.terms.policy.*`. For v1 implementation, extract English from catalogs, legal-review, then port to JSON (manual or scripted export — script is later work).

---

## 5. Languages to Support

### Confirmed from app (10 languages)

Matches `SettingsViewModel.LanguageMode` and `UI.xcstrings` privacy policy localizations:

| Code | Language | RTL |
|------|----------|-----|
| `en` | English | No |
| `tr` | Turkish | No |
| `de` | German | No |
| `fr` | French | No |
| `es` | Spanish | No |
| `it` | Italian | No |
| `pt` | Portuguese | No |
| `ja` | Japanese | No |
| `zh-Hans` | Chinese (Simplified) | No |
| `ar` | Arabic | **Yes** |

**Legal pages must support all 10** to match app language picker. Arabic pages need `dir="rtl"` on `<html>` when `ar` is active.

### v1 translation rollout option

| Phase | Scope |
|-------|--------|
| **Publish gate** | English complete + legal approved |
| **Fast follow** | TR, DE, FR, ES (high-traffic locales) |
| **Full parity** | IT, PT, JA, ZH-Hans, AR before marketing in those regions |

App Store Connect privacy URL is typically **one URL** (English default with on-page language switcher is acceptable).

---

## 6. Visual Design Direction

Match **Playful Momentum FinTech** / dark-first product decisions (`docs/archive/product_decisions_v1.md`):

| Token | Value / usage |
|-------|----------------|
| Page background | Obsidian / dark navy (`#0B0F1A` or similar) |
| Content card | Slate surface (`#151B2B`), subtle border |
| Primary text | Near-white (`#F4F6FB`) |
| Secondary text | Muted slate (`#9AA3B2`) |
| Accent / links | Cyan–indigo (`#3B9EFF` / `#5B7CFF`) |
| Semantic | Emerald success, amber caution, coral danger — **legal pages only** for warnings |
| Typography | System UI stack: `-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| Body size | 16–17px base, 1.6 line-height for legal readability |
| Headings | Clear hierarchy `h1` → `h2` → `h3`; no all-caps walls of text |
| Layout | **Mobile-first**; max-width ~720px content column; comfortable padding |
| Navigation | Simple top bar: BudgetMeter wordmark + page title + language control |
| Language selector | Visible globe button; not hidden in footer |
| Motion | **None** required; respect `prefers-reduced-motion` |
| Scripts | **Only** `legal.js` for i18n — no analytics, no fonts CDN unless self-hosted |
| Tracking | **None** — no Google Analytics, no cookie banner needed |

### Logo / brand

- Text wordmark “BudgetMeter” + optional small chart icon (CSS/SVG).
- No Pulsey on legal pages (keep professional tone).

---

## 7. Privacy Policy Content Requirements

Derived from in-app copy (`SettingsView.swift`, `UI.xcstrings`), audit, and Phase 9 scope. Hosted policy must be **accurate and complete**.

### Must disclose

| Topic | What to say |
|-------|-------------|
| **Data controller** | **Umurcan Soganci** (individual); contact: **umursoganci@gmail.com** |
| **Local financial data** | Income, expenses, categories, bills, subscriptions, savings goals, snapshots — stored in Core Data on device |
| **App preferences** | Currency, language, theme — local |
| **Apple Sign In** | Authentication via Apple; email/name may be provided by Apple; account linked to Supabase Auth user ID |
| **Email / password auth** | **v1 enabled.** Email address and password (stored/hashed by Supabase Auth); **email confirmation required** before full access; password reset via email link |
| **Supabase — auth** | Supabase Auth stores account identity (user ID, email when provided); session restored on app launch when valid |
| **Supabase — financial data** | **Not auto-synced.** Optional **manual premium cloud backup and restore** only: user taps Back Up Now / Restore; JSON export stored in `user_backups` (+ version history on backup). No continuous sync of local edits. |
| **Premium purchase status** | Stored locally (`AppSettings.isPremiumUser`); **not** included in backup payload (`BackupSerializer`) |
| **Widgets / App Group** | Non-sensitive **snapshot** (pace display values) in App Group `group.com.budgetmeter.shared` for widget; not full database |
| **iCloud / CloudKit (optional)** | Only if **verified active** in production: Apple iCloud may sync local app data to user’s iCloud account via CloudKit — **not** purchases, **not** Supabase backup. If inactive in production build, do not emphasize in public policy |
| **Account deletion (Delete Account)** | Settings → Account & Backup → Delete Account; removes Supabase auth user + all stored backup rows in Supabase; **does not** delete local app data |
| **Reset All Data (local only)** | Settings → Reset All Data; **deletes all local app data** on device so user can start fresh; **does not** delete cloud account or cloud backups |
| **Sign out** | Clears auth session locally and in Supabase; **does not** delete cloud-stored backups |
| **Data retention** | Link to Data Retention page |
| **No selling data** | Explicit statement |
| **No ads / no tracking** | `PrivacyInfo.xcprivacy`: `NSPrivacyTracking` = false; no third-party ad SDKs found in code |
| **Analytics / crash logs** | **No Firebase/Crashlytics/Sentry found in Swift codebase** — state no third-party analytics unless added later |
| **Subprocessors** | Supabase (auth + database hosting); Apple (Sign in with Apple, App Store, device platform) |
| **Children** | Not directed at children under 13/16 (standard clause — **verification required**) |
| **International rights** | GDPR-style access/delete; CCPA-style do-not-sell (already no sale) |
| **Changes to policy** | How users are notified; last updated date prominent |
| **Contact** | **umursoganci@gmail.com** |

### Must fix vs current in-app copy

- Replace vague “cloud backup” with **manual premium cloud backup and restore** where referring to Supabase financial payloads.
- **Reset All Data** copy must state **local-only** full wipe; **Delete Account** copy must state **cloud/account** deletion — never conflate the two.
- Add **email/password + confirmation** disclosures (registration, verification email, reset link).
- Remove any stale “no external servers” or “automatic sync” language.
- Align **last updated** date across in-app and web.
- **Code must implement** full local reset before legal promises a complete wipe (see checklist).

---

## 8. Terms of Service Content Requirements

### Must include

| Section | Content |
|---------|---------|
| **Acceptance** | Using app = agreement |
| **License** | Personal, non-commercial use |
| **IAP — lifetime non-consumable** | **Critical fix:** replace all subscription language |
| | • Product: BudgetMeter Premium (`com.budgetmeter.premium.lifetime`) |
| | • One-time purchase, lifetime access to premium features |
| | • Payment via Apple App Store |
| | • **Restore Purchases** available in app |
| | • Refunds via Apple only |
| | • No recurring charges |
| **Premium features** | List at high level (widgets, backup, export, etc.) — match `BudgetMeterCapability` |
| **Not financial advice** | Informational only; no professional advice |
| **User responsibility** | Accuracy of entered data; verify important figures |
| **Local data & manual cloud backup** | Day-to-day data stays on device; Premium users may **manually** back up to / restore from Supabase; not real-time sync; user responsible for running backups |
| **Account & authentication** | Apple Sign In and email/password (with email confirmation); link to Account Deletion page |
| **Acceptable use** | No abuse, reverse engineering, illegal use |
| **IP** | BudgetMeter app and content — **Umurcan Soganci** (personal); all rights reserved |
| **Warranty disclaimer** | As-is |
| **Limitation of liability** | Cap at amount paid for app/IAP in prior 12 months — use **“purchase”** not **“subscription”** |
| **Governing law** | **Selected draft default:** laws of **Türkiye**; exclusive jurisdiction of courts in **Istanbul**, unless mandatory consumer protection law requires otherwise |
| **Changes** | Right to update terms |
| **Contact** | **umursoganci@gmail.com** |

### Must remove

- “Auto-renewing subscription”
- Renewal / cancel 24 hours language
- Free trial forfeiture (unless trials added later)

---

## 9. Account Deletion Page Requirements

**This page is about Delete Account — not Reset All Data.** Cross-link to Privacy Policy for local reset.

### In-app path (Delete Account)

1. Open BudgetMeter (signed in).
2. **Settings** → **Account & Backup**.
3. Scroll to **Delete Account** (destructive).
4. Confirm alert: *“This deletes your cloud account and backup. Local data on this device stays unless you reset it separately.”*

### What Delete Account does **not** do

- Does **not** wipe local Core Data, widget snapshot, or premium entitlement cache.
- Does **not** replace **Reset All Data** — users who want a fresh local app without touching the cloud account should use Reset All Data instead.

### Cloud deletion (Supabase)

When deletion succeeds (`delete-account` Edge Function):

| Deleted | Detail |
|---------|--------|
| `user_backup_versions` rows | All versions for user |
| `user_backups` row | Latest backup payload |
| Supabase Auth user | Auth account removed |

**Verification required:** Live QA pass documented in `app_store_readiness_execution_plan.md` Block 2.3.

### What stays unless user acts locally

| Data | After account deletion |
|------|------------------------|
| Core Data on device | **Retained** |
| Widget snapshot (App Group) | **Retained** until app refreshes |
| Premium status (StoreKit) | **Retained** locally — Apple entitlement not revoked by account deletion |
| Apple Sign In | User can sign in again → **new** Supabase user ID |

### Reset All Data (separate action — local only)

- **Settings → Data & Privacy → Reset All Data**
- **Purpose:** Delete **all local app data** on this device and return to a fresh default state.
- **Does not** delete Supabase account or cloud-stored backups.
- **Product requirement:** Must wipe all user financial entities (categories, bills, subscriptions, savings goals, recurring items, snapshots, settings) and re-seed defaults.
- **Code status:** Implementation incomplete today — only `FinancialCategory` + `AppSettings` deleted (`SettingsViewModel.resetAllData()`). Fix required before release.

### Support / timing

- Deletion should be **immediate** after confirmation (target: seconds; depends on network).
- If deletion fails: user sees error; contact support email.
- Page should link to Privacy Policy and Support.

### Apple Sign In note

- Deleting BudgetMeter cloud account does **not** revoke Apple ID relationship with Apple.
- User may need to revoke app access in Apple ID settings separately if desired (optional FAQ sentence).

---

## 10. Data Retention Page Requirements

| Data type | Retention |
|-----------|-----------|
| **Local Core Data** | Until user deletes app or runs **Reset All Data** (full local wipe) |
| **Local auth metadata** | `AuthSessionStore` UserDefaults — cleared on sign out |
| **Local pre-restore snapshots** | `Application Support/BudgetMeterSnapshots/` — **verification required:** retention/cleanup policy not documented in code |
| **Cloud-stored backup (`user_backups`)** | Until user runs a new manual backup (overwrites), **Delete Account**, or account is removed |
| **Cloud backup versions** | Append-only history until account deletion (trigger in migration 0003) — **verification required:** no automatic purge job |
| **Account deletion** | Cloud rows deleted on successful delete flow |
| **Support emails** | **Verification required:** retention period for email correspondence |
| **Server logs** | Supabase platform logs — reference Supabase policy; BudgetMeter does not operate separate log store |

---

## 11. App Integration Requirements (Later)

No app changes in this planning step. When implementing:

| Surface | Change |
|---------|--------|
| **Settings → Data & Privacy** | Add “View online” link or replace sheet with Safari open to canonical Privacy URL |
| **Settings → About → Terms** | Link to hosted Terms URL |
| **Account & Backup → Delete Account** | Optional footer link to Account Deletion page |
| **Welcome / auth screens** | Footer links: Privacy + Terms (common App Store pattern) |
| **Premium paywall** | Optional Terms link near purchase button |
| **App Store Connect** | Privacy Policy URL, Terms URL (if required), Support URL |
| **In-app sheets** | **Decision required:** keep sheets as offline fallback or remove after web publish |

### Files likely touched later

| File | Change |
|------|--------|
| `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift` | `Link` / `openURL` to hosted pages |
| `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift` | Deletion policy link |
| `budgetmeter.ios/Features/AuthFeature/View/WelcomeView.swift` | Privacy + Terms footer |
| `budgetmeter.ios/Resources/UI.xcstrings` | Keys for “View online”, URL constants if localized |
| New `LegalURLs.swift` or `SupabaseConfig`-style constants file | Central canonical URL strings |
| `README.md` | Update outdated “zero backend / iCloud only” marketing |

### URL constants (proposed)

```swift
// Later — not implemented now
enum LegalURLs {
    static let privacy = URL(string: "https://jansoganci.github.io/budgetmeter.ios/legal/privacy/")!
    static let terms = URL(string: "https://jansoganci.github.io/budgetmeter.ios/legal/terms/")!
    static let accountDeletion = URL(string: "https://jansoganci.github.io/budgetmeter.ios/legal/account-deletion/")!
}
```

---

## 12. PrivacyInfo.xcprivacy Impact

After public policy is finalized, likely updates:

| Data type | Current | Likely change |
|-----------|---------|---------------|
| Financial info | Collected, **not linked** | **Linked** when user uses cloud backup (tied to account); still not tracking |
| Email address | **Not declared** | Add if Apple Sign In / auth collects email |
| User ID | **Not declared** | Add for Supabase auth user ID |
| Other data (preferences) | Not linked | May remain not linked if only local |
| Tracking | `false` | Keep `false` unless analytics added |
| Required Reason APIs | UserDefaults, file timestamp, boot time | Keep; ensure reasons still valid |

**App Store Connect App Privacy questionnaire** must be completed to match plist + hosted policy.

---

## 13. Email/Password Auth — v1 Legal Requirements (Locked)

Email/password registration **stays enabled** for v1. Legal pages must cover **both** Apple Sign In and email/password — not Apple-only drafts.

### Must disclose (Privacy + Terms + Support as needed)

| Topic | Disclosure |
|-------|------------|
| Registration | User may create account with email + password |
| Email confirmation | Supabase sends confirmation email; user must verify before full access (**intended behavior**) |
| Sign-in | Email + password after verification |
| Password reset | Forgot-password flow sends reset link to email |
| Password storage | Handled by Supabase Auth (hashed); app does not store plaintext passwords |
| Apple Sign In | Alternative sign-in; email/name may come from Apple; see account-linking test if same email used with email/password |
| Account deletion | Applies to Apple and email/password accounts equally for cloud/auth data |

### Email confirmation — implementation & Supabase (for legal accuracy)

Document the **supported v1 flow** once implemented:

1. User registers in `RegisterView` → Supabase `signUp`.
2. User receives confirmation email (Supabase Auth).
3. User opens link → app deep link `budgetmeter://auth/callback` (planned; **not in app yet**).
4. Session established → user enters app.

**Supabase dashboard (external):** Site URL, redirect URLs, confirm-email enabled, email templates.

**Legal pages:** State that unverified accounts cannot use the app until email is confirmed.

### Auth methods in Terms

- Acceptable registration: **Sign in with Apple** or **email/password with verification**.
- User responsible for credential security on email accounts.

---

## 14. GitHub Pages Deployment Checklist

### Repository

| Item | Recommendation |
|------|----------------|
| Repo | `jansoganci/budgetmeter.ios` (current) |
| Branch | `main` |
| Pages source | **Deploy from branch → `main` → `/docs`** |
| Custom domain | **None for v1** |

### Setup steps (later)

- [ ] Add `docs/legal/**` static files
- [ ] Add minimal `docs/index.html` redirect → `legal/` (optional; avoids empty docs root)
- [ ] GitHub → Settings → Pages → Source: **main /docs**
- [ ] Wait for deploy; confirm HTTPS
- [ ] Test all canonical URLs on desktop + iPhone Safari
- [ ] Test `?lang=tr`, `?lang=ar` (RTL), invalid `?lang=xx` fallback
- [ ] Enter Privacy URL in App Store Connect
- [ ] Enter Support URL if using `legal/support/`
- [ ] Screenshot URLs for release checklist

### Expected final URLs

```
https://jansoganci.github.io/budgetmeter.ios/legal/
https://jansoganci.github.io/budgetmeter.ios/legal/privacy/
https://jansoganci.github.io/budgetmeter.ios/legal/terms/
https://jansoganci.github.io/budgetmeter.ios/legal/account-deletion/
https://jansoganci.github.io/budgetmeter.ios/legal/data-retention/
https://jansoganci.github.io/budgetmeter.ios/legal/support/
```

### Device testing

- Open Privacy URL from Notes app on iOS.
- Confirm no mixed-content warnings (all HTTPS).
- Confirm readable on small iPhone without horizontal scroll.

---

## 15. Accessibility / SEO / Compliance Basics

| Requirement | Approach |
|-------------|----------|
| Semantic HTML | `<header>`, `<nav>`, `<main>`, `<footer>`, heading order |
| `lang` attribute | Update `<html lang="…" dir="…">` on language change |
| Contrast | WCAG AA for body text on dark background |
| Focus states | Visible focus for language selector (keyboard) |
| Responsive | Mobile-first CSS; no tables for layout |
| `last updated` | Visible on every page; ISO or human date |
| SEO | `<title>`, meta description per page (English + i18n via JS `document.title`) |
| Cookies | **None** — no cookie banner |
| Analytics | **None** unless explicitly added later |
| `robots` | Allow indexing (public legal pages should be findable) |
| Open Graph | Optional `og:title` / `og:description` — low priority |

---

## 16. Implementation Sequence (Later)

Execute in this order after plan approval:

| Step | Task | Owner |
|------|------|-------|
| 1 | **Write legal copy** — English master in `docs/legal/source/` (markdown) for Privacy, Terms, Account Deletion, Retention, Support | Legal docs / user |
| 2 | Fix Terms IAP + reset-all-data accuracy in copy before translation | Legal + code awareness |
| 3 | **Create HTML/CSS/JS shell** under `docs/legal/` | Code |
| 4 | **Add JSON translations** — port from `UI.xcstrings` where possible; translate per locale | Code + translators |
| 5 | **Test language switcher** — all 10 codes, RTL for `ar`, fallback | Manual QA |
| 6 | **Publish GitHub Pages** — enable `/docs` deploy | GitHub settings |
| 7 | **Update app links** — Settings, Welcome footer, optional Account Deletion link | Code |
| 8 | **Update App Store Connect** — Privacy URL, Support URL | App Store Connect |
| 9 | **Update `PrivacyInfo.xcprivacy`** + Connect App Privacy | Code + Connect |
| 10 | **Sync in-app `UI.xcstrings`** with hosted English copy | Code |
| 11 | **QA gate** — Block 1 acceptance from `app_store_readiness_execution_plan.md` | Manual QA |

---

## 17. Remaining verification items only

Decisions in **Final Decisions Locked** are set — do not re-open without explicit user change.

| Item | What to verify | Blocks release? |
|------|----------------|-----------------|
| **Email confirmation** | Supabase + app `auth/callback` flow works end-to-end | Yes |
| **Apple + email linking** | Same email → one vs two Supabase users; document in legal copy | Yes (copy accuracy) |
| **CloudKit in production build** | iCloud sync active or not; tune public iCloud disclosure | Yes (copy accuracy) |
| **Reset All Data** | Code performs full local wipe | Yes |
| **Delete Account live QA** | Cloud rows + auth user removed | Yes |
| **GitHub Pages URL** | Confirm exact `*.github.io` path after first deploy | Before Connect submit |
| **Local snapshot retention** | Document device retention in Data Retention page | Copy only |
| **README marketing** | Update stale iCloud-only / zero-backend README | No |

**Optional (non-blocking):** user may seek professional legal review of published copy at any time.

---

## 18. Recommendation

### Preferred page structure

**`docs/legal/{page}/index.html` + `docs/legal/assets/i18n/*.json`** — as defined in Section 3.

### Preferred multilingual method

**Single HTML per page + JSON locale files + `legal.js` selector** — stable canonical URLs, manageable translations, no build tooling.

### Preferred auth/legal wording direction

- **Apple Sign In and email/password (with confirmation)** for v1.
- Disclose **local-first** daily use; financial data stays on device unless user runs **manual premium backup** to Supabase.
- Do **not** use “automatic cloud sync” for Supabase financial data.
- Mention **iCloud/CloudKit** in public copy **only if verified active** in production (Apple data sync — not purchases).
- **Lifetime non-consumable** IAP language everywhere (web + app + Connect).
- **Clearly separate Reset All Data (local wipe) vs Delete Account (cloud/account).**
- **Governing law:** Türkiye / Istanbul (selected draft default).
- **Contact:** umursoganci@gmail.com · **Controller:** Umurcan Soganci (personal).

### Is implementation ready to start?

| Gate | Status |
|------|--------|
| Planning + user decisions | ✅ Locked |
| English legal copy drafting | ✅ **Start now** (`docs/legal/source/` then JSON) |
| HTML/CSS/JS shell | ✅ **Start after** English master draft |
| GitHub Pages deploy | After copy + shell ready |
| App Store release | After verification items in §17 |

**Next implementation step:** Draft English legal copy in `docs/legal/source/` using locked decisions, then build `docs/legal/` HTML/CSS/JS structure per Section 3.

---

*Documentation only. No HTML, GitHub Pages config, Swift, or Xcode files were created or modified.*
