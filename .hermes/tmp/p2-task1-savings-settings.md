# P2 Task 1: Localize Savings Goals List Screen & Remaining Settings Strings

## Problem
The savings goals list screen and some Settings section labels have hardcoded English strings.

## What to fix

1. Read and analyze:
   - Features/SavingsGoalsFeature/View/SavingsGoalsView.swift (list screen titles, empty states, headers)
   - Features/SettingsFeature/ (check all views for hardcoded section labels)

2. For savings goals:
   - "Savings Goals" nav title, empty state copy, section headers
   - "Add Goal" / "Create Goal" buttons
   - Any remaining hardcoded strings

3. For settings:
   - Section labels like "Account", "Notifications", "Appearance", "Data", "About"
   - Any Settings row descriptions that are hardcoded

4. Replace with `String(localized: "savings.KEY" or "settings.KEY", defaultValue: "English", table: "UI")`

5. Add keys to `Resources/UI.xcstrings` (check if Homes.xcstrings or Settings.xcstrings already has some keys first)

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Build must succeed.
