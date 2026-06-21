# P0 Task 3: Localize MomentumHeroCard.swift "Live:" Prefix

## Problem
`MomentumHeroCard.swift` has a hardcoded "Live:" prefix string that's user-facing.

## What to fix
Read `DesignSystem/Components/Cards/MomentumHeroCard.swift` and find the "Live: %@" (or similar) hardcoded string.

Replace it with:
```swift
Text(String(localized: "home.pace.live_prefix", defaultValue: "Live: %@", table: "Home"))
```

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Build must succeed.
