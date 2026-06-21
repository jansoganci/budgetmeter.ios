# P0 Task 2: Localize HomeDisplayMapping.swift Pace Status Copy

## Problem
`HomeDisplayMapping.swift` has hardcoded English strings for the Home screen's financial pace status. These are the main user-facing copy on the hero card.

## What to fix

Read `Features/HomeFeature/ViewModel/HomeDisplayMapping.swift` and find the functions that return pace status strings.

The pace copy functions return strings like:
- "Moving forward: +$12.50/day"
- "Slowing down: -$5.00/day"
- "Holding steady: $0.00/day"

These need proper localization using keys in either `Home.xcstrings` or `UI.xcstrings`.

## How to fix

1. Read the current `HomeDisplayMapping.swift` file
2. Find ALL string literals that are user-facing pace status copy
3. Replace each with `String(localized: "home.pace.KEY", defaultValue: "English", table: "Home")` or `String(localized: "home.pace.KEY", defaultValue: "English", table: "UI")`
4. Add the new keys to `Resources/Home.xcstrings` or `Resources/UI.xcstrings` as needed
5. Do NOT use `Text("string", comment: "...")` — that's not proper runtime localization

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Build must succeed.
