# P0 Task 5: Fix SavingsGoalDetailView.swift Remaining Comment-Only Text()

## Problem
Some strings in `SavingsGoalDetailView.swift` use `Text("English", comment: "desc")` pattern. The `comment:` parameter in SwiftUI `Text` initializer does NOT trigger runtime localization — it's only for the `genstrings` tool. For proper localization with String Catalogs, we need different approaches.

## SwiftUI String Catalog behavior
In SwiftUI with String Catalogs (.xcstrings files):
- `Text("literal string")` — WILL be localized if the EXACT literal string exists as a key in any xcstrings file
- BUT this makes the key be the literal English string, not a semantic key

## What to fix

Read `Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift` and find these remaining problematic strings:

Check each of these:
- Line 208: `Text("Add Money", comment: ...)` — if "Add Money" doesn't exist as a key in xcstrings, it won't localize
- Line 221: `Text("Withdraw", comment: ...)` — same
- Line 240: `Text("Notes", comment: ...)` — same
- Line 294: `Text("Add Money to Goal", comment: ...)` — same
- Line 316: `Text("Add", comment: ...)` — same
- Line 355: `Text("Withdraw from Goal", comment: ...)` — same
- Line 381: `Text("Withdraw", comment: ...)` — same

For each one:
1. Check if the literal string exists as a key in any .xcstrings file
2. If it does NOT exist, it needs fixing
3. Replace with `Text(String(localized: "savings.KEY", defaultValue: "English", table: "UI"))` and add the key to `UI.xcstrings`

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Build must succeed.
