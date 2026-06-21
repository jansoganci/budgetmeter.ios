# P0 Task 4: Localize Widget Strings

## Problem
Widget-related strings are hardcoded in English:
- Widget title/description in the widget extension
- Widget locked teaser copy
- WidgetsSetupView nav title
- Any other widget-facing strings

## What to fix

1. Read these files:
   - `BudgetMeterWidgets/BudgetMeterWidgets.swift`
   - `BudgetMeterWidgets/NetDailyPaceWidget.swift` (or similar widget provider files)
   - Search for any hardcoded user-facing strings in the BudgetMeterWidgets directory

2. Replace hardcoded strings with `String(localized: "widget.KEY", defaultValue: "English", table: "UI")`

3. Add new keys to `Resources/UI.xcstrings`

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Build must succeed.
