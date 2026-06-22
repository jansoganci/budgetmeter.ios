# Phase 4 — Production Deploy + QA Scripts

Runnable helpers for [supabase_phase4_production_deploy_qa_plan.md](../../docs/implementation/supabase_phase4_production_deploy_qa_plan.md).

## Prerequisites

1. Supabase CLI installed (`supabase --version`)
2. Authenticated: `supabase login`
3. Project linked from repo root:

```bash
cd /path/to/budgetmeter.ios
supabase link --project-ref mqbtbtlbpcjzleghvrkv
```

## Scripts

| File | Purpose |
|------|---------|
| `pre_deploy_check.sh` | Non-destructive local checks (migrations present, no service role in app, tests) |
| `verify_schema_and_rls.sql` | Run in Supabase SQL Editor after deploy — RLS, triggers, table inventory |
| `deploy_sequence.sh` | **Requires approval** — `db push` + `functions deploy delete-account` |

## Recommended order

1. `./scripts/phase4/pre_deploy_check.sh`
2. Staging: `supabase db push` on branch project (preferred)
3. Production: `supabase db push` (after staging pass)
4. `./scripts/phase4/deploy_sequence.sh` (or deploy function manually)
5. Paste `verify_schema_and_rls.sql` in Dashboard → SQL → Run
6. Complete manual QA in [supabase_phase4_qa_execution_log.md](../../docs/implementation/supabase_phase4_qa_execution_log.md)

## Do not

- Commit service role keys
- Run `deploy_sequence.sh` against production without go/no-go sign-off
- Skip RLS verification after migration apply
