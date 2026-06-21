# P2 Task 2: Localize Export, Recurring Transactions, & Legacy Feature Screens

## Problem
Export, recurring transactions, and other feature screens have hardcoded English strings.

## What to fix

1. Read and analyze these files for hardcoded strings:
   - Features/ExportFeature/ (DataExportView, etc.) — export.* keys (22 expected)
   - Features/RecurringTransactionsFeature/ — edit_recurring.* + recurring.* keys (33 expected)
   - Any remaining feature screens mentioned in docs/hardcoded_strings_audit.md as P2 items

2. For each hardcoded string found:
   - Replace with `String(localized: "export.KEY" or "recurring.KEY", defaultValue: "English", table: "UI")`
   - Add keys to `Resources/UI.xcstrings`

3. Key strings to look for:
   - Export: "Export Data", "CSV", "PDF", format options, date ranges
   - Recurring: "Edit Recurring", frequency labels, automation status

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Build must succeed.
