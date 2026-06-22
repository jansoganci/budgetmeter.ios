#!/usr/bin/env bash
# Phase 4 pre-deploy checks (non-destructive). Safe to run anytime.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "== BudgetMeter Phase 4 pre-deploy check =="
echo "Repo: $ROOT"
echo

FAIL=0

check() {
  if "$@"; then
    echo "  OK: $*"
  else
    echo "  FAIL: $*"
    FAIL=1
  fi
}

echo "-- Migration files (0001-0009) --"
for i in 1 2 3 4 5 6 7 8 9; do
  PREFIX=$(printf "%04d" "$i")
  COUNT=$(find supabase/migrations -maxdepth 1 -name "${PREFIX}_*.sql" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$COUNT" -eq 1 ]]; then
    echo "  OK: migration ${PREFIX}_*.sql"
  else
    echo "  FAIL: expected exactly one migration for prefix ${PREFIX}_ (found $COUNT)"
    FAIL=1
  fi
done

echo
echo "-- delete-account table coverage --"
TABLES=(
  bill_payments bills subscriptions recurring_transactions
  one_time_transactions financial_categories seeded_category_overrides
  savings_goals notification_preferences user_settings profiles
  user_backup_versions user_backups
)
for t in "${TABLES[@]}"; do
  if grep -q "\"$t\"" supabase/functions/delete-account/index.ts; then
    echo "  OK: delete-account references $t"
  else
    echo "  FAIL: delete-account missing $t"
    FAIL=1
  fi
done

echo
echo "-- Service role must NOT be in iOS app --"
if rg -q "service_role|SERVICE_ROLE" budgetmeter.ios --glob '*.swift' 2>/dev/null; then
  echo "  FAIL: service role string found in Swift sources"
  FAIL=1
else
  echo "  OK: no service_role in Swift"
fi

echo
echo "-- SupabaseClientProvider uses anon key only --"
if rg -q "anonKey" budgetmeter.ios/CoreKit/Sources/Auth/SupabaseClientProvider.swift; then
  echo "  OK: SupabaseClientProvider references anonKey"
else
  echo "  WARN: verify SupabaseClientProvider manually"
fi

echo
echo "-- Core Data current version --"
if grep -q "BudgetMeter 7" budgetmeter.ios/BudgetMeter.xcdatamodeld/.xccurrentversion; then
  echo "  OK: Core Data model v7"
else
  echo "  WARN: expected BudgetMeter 7.xcdatamodel as current"
fi

echo
echo "-- Supabase CLI link (optional) --"
if supabase migration list >/dev/null 2>&1; then
  echo "  OK: supabase migration list succeeded"
  supabase migration list || true
else
  echo "  SKIP: run 'supabase login' && 'supabase link --project-ref mqbtbtlbpcjzleghvrkv'"
fi

echo
echo "-- iOS unit tests (optional, slow) --"
if [[ "${SKIP_TESTS:-0}" == "1" ]]; then
  echo "  SKIP: SKIP_TESTS=1"
else
  if xcodebuild test \
    -project budgetmeter.ios.xcodeproj \
    -scheme budgetmeter.ios \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -quiet 2>&1 | tail -3; then
    echo "  OK: xcodebuild test"
  else
    echo "  FAIL: xcodebuild test"
    FAIL=1
  fi
fi

echo
if [[ "$FAIL" -eq 0 ]]; then
  echo "Phase 4 pre-deploy check: PASSED"
  exit 0
else
  echo "Phase 4 pre-deploy check: FAILED"
  exit 1
fi
