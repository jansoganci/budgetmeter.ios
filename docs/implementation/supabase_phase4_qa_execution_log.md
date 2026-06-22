# Phase 4 QA Execution Log

Track manual and automated Phase 4 validation. Update as tests complete.

Plan: [supabase_phase4_production_deploy_qa_plan.md](./supabase_phase4_production_deploy_qa_plan.md)

---

## Automated validation (local)

| Check | Date | Result | Notes |
|-------|------|--------|-------|
| iOS unit tests (226) | 2026-06-22 | **PASS** | `xcodebuild test` iPhone 17 simulator |
| iOS build | 2026-06-22 | **PASS** | Prior Phase 3B build green |
| `pre_deploy_check.sh` | 2026-06-22 | **PASS** | Migrations 0001–0009, delete-account coverage, no service role in Swift |
| Supabase `db push` | | **BLOCKED** | Requires `supabase login` + link |
| delete-account deploy | | **BLOCKED** | Requires authenticated CLI |
| `verify_schema_and_rls.sql` | | Pending | After migrations applied remotely |

---

## Pre-deploy checklist (§5)

- [ ] Supabase CLI linked to production ref `mqbtbtlbpcjzleghvrkv`
- [ ] `SupabaseConfig.projectID` matches linked project
- [ ] Service role not in app (automated in `pre_deploy_check.sh`)
- [ ] Migrations 0001–0009 ordered
- [ ] delete-account reviewed
- [ ] Rollback approach understood
- [ ] Staging/branch migration apply completed before production

---

## RLS / security (§6)

Tester: _______________  Date: _______________

| Test ID | Table / scope | Pass? | Notes |
|---------|---------------|-------|-------|
| SEC-01 | Anonymous read (all 13) | | |
| SEC-02 | Anonymous insert | | |
| SEC-03 | A reads own | | |
| SEC-04 | A cannot read B | | |
| SEC-05 | A cannot update B | | |
| SEC-06 | A cannot insert as B | | |
| SEC-07 | Soft delete upsert | | |
| SEC-08 | No client DELETE on financial tables | | |
| DEL-01 | delete-account success | | |
| DEL-02 | delete-account 401 without token | | |
| DEL-03 | All user rows removed | | |
| DEL-05 | User B unaffected | | |

---

## Core Data migration (§7)

| ID | Scenario | Device | Pass? | Notes |
|----|----------|--------|-------|-------|
| CD-01 | Upgrade pre-sync → sync build | Real device | | |
| CD-02 | Populated v3 store upgrade | Simulator | | |
| CD-03 | One-time entries retained | | | |
| CD-06 | Fresh install seeds categories | Simulator | | |
| CD-07 | iCloud signed in upgrade | Real device | | |

---

## End-to-end sync (§8)

| ID | Flow | Pass? | Notes |
|----|------|-------|-------|
| E2E-01 | Fresh install + sign in | | |
| E2E-02 | Existing local + sign in | | |
| E2E-03 | Reinstall restore | | |
| E2E-04 | Offline create → online | | |
| E2E-06 | Delete/tombstone | | |
| E2E-08 | Second device LWW | | |
| E2E-09 | User A / B isolation | | |

---

## Entity matrix (§9)

| Entity | Create | Update | Delete | Restore | Offline | Dedupe |
|--------|--------|--------|--------|---------|---------|--------|
| settings | | | N/A | | | |
| notification prefs | | | N/A | | | |
| savings goals | | | | | | |
| subscriptions | | | | | | |
| bills | | | | | | |
| bill payments | | | | | | |
| recurring transactions | | | | | | |
| one-time tx | | | | | | |
| custom categories | | | | | | |
| seeded overrides | | | | | | |

---

## Go / no-go (§16)

- [ ] Migrations deployed
- [ ] delete-account deployed
- [ ] RLS validated
- [ ] Core Data upgrade on real device
- [ ] Manual QA matrix passed
- [ ] Privacy policy reviewed
- [ ] Known MVP risks accepted

**Decision:** _______________  **Date:** _______________

---

## Blockers log

| Date | Blocker | Resolution |
|------|---------|------------|
| 2026-06-22 | Supabase CLI not authenticated (`supabase login` required) | User must run login locally, then `deploy_sequence.sh` |
