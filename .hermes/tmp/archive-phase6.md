Archive Phase 6 documentation for BudgetMeter iOS.

Phase 6 is complete. Move the following files from docs/implementation/ to docs/archive/implementation/:

- phase6_basic_savings_integration_scope.md
- phase6_basic_savings_integration_audit.md
- phase6_savings_audit_fix_plan.md

Also archive these Phase 6 related files if they exist:
- docs/implementation/savings_gamification_plan.md (this one is NOT Phase 6 specific - check if it's still needed for later phases)
- docs/active/ that are savings-related (already archived)

Steps:
1. Create docs/archive/implementation/ if not exists
2. Move phase6_* files from docs/implementation/ to docs/archive/implementation/ using git mv for tracking
3. Verify: ls docs/implementation/ should show no phase6_* files, ls docs/archive/implementation/ should show 3 phase6_* files
