# Archive Phase 9 and Phase 10 Documentation

BudgetMeter iOS at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Goal
Archive all Phase 9 and Phase 10 documentation from docs/implementation/ to docs/archive/implementation/.

## Files to archive
Move these from docs/implementation/ to docs/archive/implementation/:
- phase9_supabase_auth_database_migration_scope.md
- phase9_supabase_auth_database_migration_audit.md (if exists)
- phase10_release_qa_scope.md
- phase10_release_qa_audit.md (if exists)
- auth_supabase_sync_plan.md
- release_phase_plan.md
- localization_accessibility_qa_plan.md
- premium_entitlement_plan.md
- savings_gamification_plan.md

Also archive these from docs/ root:
- docs/auth_system_analysis.md
- docs/auth_implementation_plan.md
- docs/release_readiness_plan.md
- docs/phases_9_10_status.md
- docs/hardcoded_strings_audit.md

Move them to docs/archive/ (root level, not implementation/).

## Keep in docs/:
- docs/qa/release_tracker.md
- docs/qa/known_issues.md
- docs/qa/fixtures/README.md
- docs/supabase/phase9_user_backups.sql

## Verification
After archiving, run:
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Build must succeed (archiving docs should not affect build).
