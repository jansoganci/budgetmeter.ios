#!/usr/bin/env bash
# Phase 4 deployment sequence — DO NOT RUN until go/no-go approved.
# Requires: supabase login, supabase link, staging validation complete.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [[ "${PHASE4_DEPLOY_APPROVED:-}" != "yes" ]]; then
  echo "ERROR: Set PHASE4_DEPLOY_APPROVED=yes to confirm intentional deploy."
  echo "Example: PHASE4_DEPLOY_APPROVED=yes ./scripts/phase4/deploy_sequence.sh"
  exit 1
fi

echo "== BudgetMeter Phase 4 deploy sequence =="
echo "Project link:"
cat supabase/.temp/linked-project.json 2>/dev/null || echo "(no linked-project.json)"
echo

echo "-- Step 1: pre-deploy check --"
./scripts/phase4/pre_deploy_check.sh

echo
echo "-- Step 2: apply pending migrations --"
supabase db push

echo
echo "-- Step 3: deploy delete-account Edge Function --"
supabase functions deploy delete-account

echo
echo "-- Step 4: migration list --"
supabase migration list

echo
echo "Deploy sequence finished."
echo "Next: run scripts/phase4/verify_schema_and_rls.sql in Dashboard SQL Editor"
echo "Next: complete docs/implementation/supabase_phase4_qa_execution_log.md"
