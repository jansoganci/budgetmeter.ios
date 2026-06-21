# P0 Task 1: Repair UI.xcstrings Structure

## Problem
`UI.xcstrings` has a structural corruption. The `strings` JSON dictionary closes prematurely around line 719. After that point, roughly 139+ keys (savings.*, bill.*, subscriptions.*, category modal, health errors, etc.) were appended as siblings or nested inside other keys instead of being inside the `strings` dict.

This means all these keys exist in the file and have translations, but the iOS runtime CANNOT look them up because they're at the wrong JSON path.

## Instructions

1. Read `Resources/UI.xcstrings` fully
2. Parse it as JSON
3. Find ALL keys that should be in the `strings` dictionary but are:
   - Nested inside another key's object (e.g., inside `income.summary.yearly`)
   - Orphaned at the root level outside `strings`
   - Any structural issue where a key is not a direct child of the `strings` object
4. Reconstruct the JSON so:
   - `strings` contains ALL string keys at the top level of the `strings` dict
   - No keys are nested under other keys
   - No keys are outside the `strings` dict
   - The `sourceLanguage` and other metadata fields remain intact
5. Write the fixed file back to `Resources/UI.xcstrings`
6. Verify the file is valid JSON (use `python3 -m json.tool` or similar)

## Safety
- Make a backup first: `cp budgetmeter.ios/Resources/UI.xcstrings budgetmeter.ios/Resources/UI.xcstrings.backup`
- Do NOT lose any existing translations
- Every key that was in the file before must still be in the file after, just at the correct location

## Verification
After fixing run from budgetmeter.ios directory:
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
The build must succeed.
