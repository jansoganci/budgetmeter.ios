# Phase 8 — Widget v1 Audit Prompt

## Goal
Create a comprehensive audit document at `docs/implementation/phase8_widget_v1_audit.md` that analyzes the current Phase 8 Widget v1 implementation status. DO NOT modify any source code — this is a read-only audit.

## Background
Read first: `docs/implementation/implementation_planning_index.md` (Phase 8 section) and `docs/implementation/phase8_widget_v1_scope.md`

## What to audit

### 1. Widget Extension Target
- Is the `BudgetMeterWidgets` extension target configured in the Xcode project?
- What's its bundle identifier and deployment target?
- Is `UI.xcstrings` included in the widget extension's Copy Bundle Resources?
- Is the extension properly embedded in the main app build?

### 2. Widget Registration
Read `BudgetMeterWidgets/BudgetMeterWidgets.swift`:
- What widgets are registered in the `WidgetBundle`?
- Is ONLY v1 widget (NetDailyPaceWidget) present? No legacy/lock screen widgets?

### 3. Widget Provider & Timeline
Read the widget provider file (NetDailyPaceWidget.swift or similar):
- How does it fetch data? (WidgetSnapshotStore?)
- Does it handle locked/premium state correctly?
- Does the timeline refresh work properly?

### 4. Snapshot Contract
Read `BudgetMeterWidgets/WidgetShared/` files:
- WidgetSnapshot structure — what fields does it contain?
- WidgetSnapshotWriter — how does it map from FinancialSummary?
- WidgetConstants — deep link URLs?

### 5. Premium Gating
- Is the widget premium-gated via `BudgetMeterCapability.widgets`?
- Is there a locked teaser state for free users?
- Does the locked state deep link to the paywall?

### 6. Deep Links
- What deep links does the widget support?
- Are they wired in `ContentView.swift`?
- budgetmeter://home/hero → navigates to Home hero?
- budgetmeter://premium/widgets → navigates to paywall?

### 7. Build & Test Status
- Does `xcodebuild build -scheme budgetmeter.ios` succeed with the widget extension embedded?
- Does `BudgetMeterWidgets` scheme build standalone?
- Are KI-003 and KI-004 (widget scheme/signing) still open?
- Do WidgetSnapshotStoreTests (5) and WidgetSnapshotWriterTests (5) pass?

### 8. Localization
- Are widget strings localized in `UI.xcstrings` under `widget.*` keys?
- Check if widget strings resolve at runtime

### 9. Gap Analysis vs Scope
Compare against the scope doc:
- What was planned vs what's actually implemented?
- Are there any security/privacy concerns with the widget data?

## Output
Write everything to `docs/implementation/phase8_widget_v1_audit.md` as a structured audit report with:
- Executive summary
- Component-by-component audit table
- Gap analysis
- Risk assessment
- Test coverage analysis
