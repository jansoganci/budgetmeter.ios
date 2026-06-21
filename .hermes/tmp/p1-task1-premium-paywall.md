# P1 Task 1: Localize Premium Paywall & Purchase Error Strings

## Problem
Premium-related screens and errors have hardcoded English strings that need localization.

## What to fix

1. Read and analyze these files:
   - Features/PremiumFeature/View/PremiumPaywallView.swift
   - Features/PremiumFeature/View/PremiumFeatureView.swift
   - CoreKit/Sources/Premium/PremiumManager.swift (PurchaseError enum messages, feature descriptions)

2. Find ALL user-facing hardcoded English strings and replace with `String(localized: "premium.KEY", defaultValue: "English", table: "UI")`

3. Add all new keys to `Resources/UI.xcstrings`

4. Pay special attention to:
   - Premium paywall copy (title, subtitle, feature list, CTA buttons)
   - Purchase error messages (restore failed, purchase failed, etc.)
   - Premium feature names and descriptions
   - "Restore Purchases" button text
   - Any "Upgrade to Premium" or "Unlock" CTAs

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Build must succeed.
