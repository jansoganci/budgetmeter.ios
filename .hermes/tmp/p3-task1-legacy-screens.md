# P3 Task 1: Localize Health Score, Premium Themes, Bills & Legacy Screens

## Problem
Several legacy/secondary screens have hardcoded English strings that need localization.

## What to fix

1. Read and analyze these files:
   - Features/PremiumFeature/View/PremiumThemesView.swift — theme names, descriptions
   - DesignSystem/Components/Cards/HealthScoreCard.swift — health score labels
   - DesignSystem/Components/Cards/HealthScoreDetailCard.swift (if exists)
   - DesignSystem/Components/Cards/HealthBreakdownRow.swift (if exists)
   - Features/BillsFeature/View/BillsView.swift — "due", "AutoPay", "Paid" etc.
   - Features/BillsFeature/View/BillRowView.swift — inline labels
   - CoreKit/Sources/Services/BiometricManager.swift — error/display strings (~10)
   - CoreKit/Sources/Theme/ThemeManager.swift — theme display names (Default, Ocean, Forest, etc.)
   - CoreKit/Sources/Engine/CalculationEngine.swift — health rating labels (Excellent, Great, Good, Fair, etc.)

2. For each hardcoded string found:
   - Replace with `String(localized: "health.KEY" or "theme.KEY" or "bills.KEY" or "biometric.KEY" or "KEY", defaultValue: "English", table: "UI")`
   - Add keys to `Resources/UI.xcstrings`

3. Don't waste time on strings that are clearly dev-only or in #Preview blocks.

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Build must succeed.
