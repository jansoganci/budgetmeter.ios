# Phase 7 — Premium Cleanup Audit Prompt

## Goal
Create a comprehensive audit document at `docs/implementation/phase7_premium_cleanup_audit.md` that analyzes the current Phase 7 implementation status. DO NOT modify any source code — this is a read-only audit.

## Background
Read first: `docs/implementation/implementation_planning_index.md` (Phase 7 section) and `docs/implementation/phase7_premium_cleanup_scope.md`

## What to audit

### 1. BudgetMeterCapability Matrix
Read `CoreKit/Sources/Premium/PremiumManager.swift` and verify:
- List ALL capabilities in the `BudgetMeterCapability` enum
- For each capability, what is its `accessLevel`: `.free`, `.premium`, or `.postponed`?
- Does every major feature have a capability entry?
- Are there features that are premium-gated in code but NOT in the matrix?
- Are there features in the matrix that don't exist in the app anymore?

### 2. PremiumManager API
Read `PremiumManager.swift` fully:
- Does `hasAccess(to:)` work correctly for all capabilities?
- Is there a static variant `hasAccess(to:)`?
- What StoreKit product ID is used?
- How does restore flow work? Is "no previous purchase found" implemented?
- Are there any crash-prone force-unwraps or unsafe optionals?

### 3. Premium Gates in Services
Check these services for proper premium gating:
- `DataExportService.swift` — CSV/PDF premium gate?
- `BiometricManager.swift` — biometric lock gated?
- `ThemeManager.swift` — non-default themes gated?

### 4. Premium UI Surfaces
Check:
- `PremiumPaywallView.swift` — paywall copy, feature list, buttons
- `PremiumFeatureView.swift` — gated feature wrapper
- `SettingsView.swift` — premium section, purchase/restore buttons
- Any other premium-related views

### 5. Free Core Preservation
Verify these features remain FREE and accessible without purchase:
- Home dashboard with pace
- Income entry (recurring + one-time)
- Expense entry (recurring + one-time)
- One basic savings goal
- Default theme

### 6. Gap Analysis
Compare against the scope doc:
- What was planned vs what's actually implemented?
- Are there any planned premium gates that are missing?
- Are there any tests for premium boundaries?

### 7. Known Issues
- Are there hardcoded premium text strings not yet localized?
- Check `UI.xcstrings` for existing `premium.*` keys

## Output
Write everything to `docs/implementation/phase7_premium_cleanup_audit.md` as a structured audit report with:
- Executive summary
- Feature-by-feature audit table
- Gap analysis
- Risk assessment
- Test coverage analysis
