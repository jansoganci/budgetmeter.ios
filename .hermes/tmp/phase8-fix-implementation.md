# Phase 8 Widget v1 — Fix Implementation

Fix the identified gaps in BudgetMeter iOS Widget v1. The project is at /Users/jans/Desktop/nexus/budgetmeter.ios.

Read `docs/implementation/phase8_widget_v1_audit.md` for context first.

## Fix 1: KI-003 — Fix Widget Scheme Standalone Build

The `BudgetMeterWidgets` scheme fails with "not configured for the build action". 

Read `budgetmeter.ios.xcodeproj/xcshareddata/xcschemes/BudgetMeterWidgets.xcscheme` and fix it so it includes a BuildAction with the BudgetMeterWidgets target. Compare with the main `budgetmeter.ios` scheme for the correct XML structure.

After fixing, verify: `xcodebuild -scheme BudgetMeterWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` should succeed.

## Fix 2: Stale State — Remove Financial Values from Stale Display

Read `BudgetMeterWidgets/NetDailyPaceWidget.swift` (or the provider file).

Find where stale state displays `displayValue` alongside `staleMessage`. Change it so stale state shows ONLY a calm copy like "Data may be outdated" without showing the financial number. The widget should not pretend to show live data when it's stale.

## Fix 3: Privacy — Redact Locked-Teaser Snapshot Data

Read `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift` and the snapshot model.

When `isPremium` is false (locked teaser state), the snapshot should NOT write financial data (netDailyPace, displayValue, etc.) to App Group storage. Only write: `displayState: .lockedTeaser`, `isLockedTeaser: true`, `isPremium: false`, `deepLinkURL`. Zero out all financial fields. This prevents financial data leakage from the shared container.

## Fix 4: Add Widget Deep Link Tests

Read the existing test files in budgetmeter.iosTests/:
- WidgetSnapshotStoreTests.swift
- WidgetSnapshotWriterTests.swift

Add new test file `WidgetDeepLinkRoutingTests.swift` with tests that verify:
- Widget locked teaser uses correct deep link (budgetmeter://premium/widgets)
- Widget unlocked uses correct deep link (budgetmeter://home/hero)
- Deep link URLs are properly formatted

## Important
- Only modify files in BudgetMeterWidgets/, budgetmeter.ios/CoreKit/Sources/Widget/, budgetmeter.ios.xcodeproj/xcshareddata/xcschemes/, and budgetmeter.iosTests/
- Do NOT touch any other files
- After all fixes, run: xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
- Also run: xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
