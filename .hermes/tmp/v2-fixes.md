# UI/UX v2 — Fix 3 Remaining Gaps

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

Read `docs/uiux_v2_completion_audit.md` for context.

## Fix 1 — Phase 5: LayoutTokens naming alignment

File: `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift`

Add explicit semantic aliases so the required names from the spec resolve:

```swift
// Add these as computed properties or typealiases:
static let screenHorizontalPadding: CGFloat = LayoutSpacing.screenHorizontalPadding ?? 16
static let cardRadius: CGFloat = CornerRadius.card // should be 20
static let buttonRadius: CGFloat = 14
static let modalRadius: CGFloat = 24
static let widgetRadius: CGFloat = 22
```

Do NOT break existing names. Just add the missing ones.

## Fix 2 — Phase 12: Legacy view still using old tokens

Search for any feature view that still uses old color names (like `chartInactive`, old gradient names, deprecated colors from v1). Likely in:
- Features/BillsFeature/
- Features/SubscriptionsFeature/
- Features/InsightsFeature/

Update them to use v2 tokens. Replace with equivalent v2 colors:
- Old gradients → use v2 surface colors
- chartInactive → use chartTrack or textTertiary

## Fix 3 — Phase 13: Accessibility coverage

Add VoiceOver labels to any remaining unlabeled interactive elements across:
- Features/HomeFeature/View/
- Features/IncomesFeature/View/
- Features/ExpensesFeature/View/
- Features/SavingsGoalsFeature/View/

Focus on:
- Icon-only buttons (add `.accessibilityLabel()`)
- Cards without labels
- Chart/indicator components

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Must succeed.
