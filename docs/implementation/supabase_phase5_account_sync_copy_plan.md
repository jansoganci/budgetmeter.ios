# Phase 5: Account Sync & Backup UX Copy Plan

**Status:** Implemented (Phase 5A)  
**Scope:** In-app copy and Account screen structure only. No sync logic, BackupService logic, migrations, or App Store files.

**Related:** [Phase 4 production deploy QA](../implementation/supabase_phase4_production_deploy_qa_plan.md) §10 BackupService Overlap

---

## Product model

| Layer | User story | Gating |
|-------|------------|--------|
| Account sign-in | Identity + enables sync | Free |
| Account sync (Phases 1–3) | Structured data saved to Supabase account | Free when signed in |
| Manual Backup & Restore | Full JSON snapshot to `user_backups` | Premium (`.backupSync`) |
| CloudKit | Legacy engineering stack | Not advertised in UI |

---

## EN string key map (source of truth)

### Navigation

| Key | EN value |
|-----|----------|
| `account.title` | Account |
| `settings.account.title` | Account |
| `settings.account.subtitle` | Sign in to sync your data |

### Account section

| Key | EN value |
|-----|----------|
| `account.section.title` | Account |
| `account.footer` | Sign in is free and syncs your data to your account. Manual backup & restore is a Premium feature. |
| `account.sign_in_prompt` | Sign in to sync your account data. |
| `account.delete.message` | This permanently deletes your account and synced data on our servers. Data on this device stays unless you reset it separately in Settings. |

### Account sync section (new)

| Key | EN value |
|-----|----------|
| `sync.section.title` | Account Sync |
| `sync.footer.signed_in` | When you sign in, your BudgetMeter data syncs securely to your account. Sync runs after sign-in and when you make changes. It may take a moment to appear on another device. |
| `sync.footer.signed_out` | Sign in to save your settings and financial data to your account and use it on another device. |
| `sync.status.active` | Sync enabled for your account |
| `sync.status.detail` | Updates when you sign in or save changes |

### Manual backup section (renamed)

| Key | EN value |
|-----|----------|
| `backup.section.title` | Manual Backup & Restore |
| `backup.footer` | Optional full-device snapshot for advanced recovery. This is separate from everyday account sync. Local data is snapshotted before backup or restore. |
| `backup.premium_required` | Upgrade for Manual Backup & Restore |
| `backup.sign_in_required` | Sign in to use manual backup & restore. |
| `backup.never` | No manual backup yet |
| `backup.cloud_summary` | Manual backup: %lld records, %@ |
| `backup.restore` | Restore Manual Backup |
| `backup.restore.confirm.title` | Restore Manual Backup |
| `backup.restore.confirm.message` | This replaces local data on this device with your manual backup. |
| `backup.overlap.message` | This device and your manual backup both contain data. Choose backup or restore carefully. |

### BackupService errors

| Key | EN value |
|-----|----------|
| `backup.error.not_configured` | Manual backup is not configured. |
| `backup.error.not_authenticated` | Sign in to use manual backup & restore. |
| `backup.error.premium_required` | Manual backup & restore requires BudgetMeter Premium. |
| `backup.error.offline` | Manual backup is unavailable offline. |
| `backup.error.no_cloud_backup` | No manual backup found for this account. |

### Privacy policy (in-app sheet)

| Key | EN value |
|-----|----------|
| `settings.privacy.policy.data_collect.content` | • Financial data (income, expenses, categories) — stored locally on your device\n• App preferences (currency, language) — stored locally\n• Account sync data (when signed in) — settings, goals, bills, transactions, and categories stored in your Supabase account\n• Optional Premium manual backup snapshots — separate from everyday sync |
| `settings.privacy.policy.data_use.content` | • To provide financial tracking functionality\n• To sync your account data when you sign in\n• To back up and restore optional Premium manual snapshots when you choose |
| `settings.privacy.policy.data_sharing.content` | We do not sell your personal data. Account sync and optional manual backup use Supabase over HTTPS. We do not share your data with advertisers or other third parties. |
| `settings.privacy.policy.data_storage.content` | • Local: Core Data database on your device\n• Account sync: Supabase (when signed in)\n• Manual backup (Premium, optional): full snapshot in user_backups |
| `settings.privacy.policy.your_rights.content` | • Access: View all your data within the app\n• Delete local data: Reset all data via Settings\n• Delete account: Delete account in Account — removes synced server data\n• Control: Sign out anytime; manual backup is optional and Premium |

### Localizable (legacy privacy sheet strings)

| Key | EN value |
|-----|----------|
| `settings.privacy.sheet.intro` | Your data is stored locally on your device. When you sign in, your account data syncs to Supabase. Premium users can optionally create manual backup snapshots. |
| `settings.privacy.sheet.bullet.icloud` | Premium users can optionally save manual backup snapshots to Supabase. This is separate from everyday account sync. |

---

## Claims to avoid

- Real-time / instant multi-device sync
- End-to-end or client-side encryption (unless implemented)
- Active iCloud sync as a product feature

---

## Locale checklist

All keys above must exist in: `en`, `tr`, `de`, `fr`, `es`, `it`, `pt`, `ja`, `zh-Hans`, `ar`.

---

## Manual QA checklist

- [ ] Signed-out Settings row: "Sign in to sync your data"
- [ ] Account screen order: Account → Account Sync → Manual Backup → Delete
- [ ] No "Cloud Backup" visible in Settings
- [ ] Free signed-in user sees sync section; manual backup shows Premium upsell
- [ ] Premium signed-in user can Back Up Now / Restore Manual Backup
- [ ] Delete account copy matches server vs local behavior
- [ ] In-app privacy: no encrypted/iCloud overclaims
- [ ] Spot-check TR + JA or AR for truncated titles

---

## Phase 5B (deferred)

- `PrivacyInfo.xcprivacy`
- App Store Connect metadata

Implement only after Phase 5A copy is validated against live sync behavior.
