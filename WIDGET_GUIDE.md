# BudgetMeter iOS - Widget Implementation Guide

**Last Updated:** November 2025

---

## Overview

BudgetMeter supports 7 widgets across Home Screen and Lock Screen, providing users quick access to their financial data without opening the app.

### Available Widgets

| Widget | Sizes | Location | Description |
|--------|-------|----------|-------------|
| **Balance Widget** | Small, Medium | Home Screen | Current balance with trend |
| **Monthly Spending** | Medium, Large | Home Screen | Spending breakdown by category |
| **Savings Goal** | Small, Medium | Home Screen | Savings progress tracker |
| **Balance & Savings** | Small | Home Screen | Compact combined view |
| **Balance Circular** | Circular | Lock Screen | Compact balance (iOS 16+) |
| **Balance Rectangular** | Rectangular | Lock Screen | Balance + daily flow (iOS 16+) |
| **Balance Inline** | Inline | Lock Screen | Text-only balance (iOS 16+) |

---

## Implementation Status

### Completed

- `@main` attribute added to `BudgetMeterWidgets`
- Lock Screen widgets (`LockScreenWidgets.swift`)
- Deep linking with URL scheme `budgetmeter://`
- App Groups configuration in `PersistenceService.swift`
- Widget setup instructions (`WidgetsSetupView.swift`)
- Combined widget added to bundle
- Widget refresh calls in all ViewModels (Home, Income, Expense, Settings)

### Remaining Tasks (Xcode Only)

1. Create Widget Extension target named `BudgetMeterWidgets`
2. Add widget files to extension target membership
3. Add core dependencies to extension target
4. Configure App Groups for both targets

---

## Xcode Setup Instructions

### Step 1: Create Widget Extension Target

1. Open `budgetmeter.ios.xcodeproj` in Xcode
2. Go to **Editor > Add Target**
3. Select **Widget Extension** template
4. Configure:
   - **Product Name:** `BudgetMeterWidgets`
   - **Bundle Identifier:** `com.budgetmeter.budgetmeter-ios.BudgetMeterWidgets`
   - **Include Configuration Intent:** No
   - **Embed in Application:** budgetmeter.ios
5. Delete the auto-generated template files (Xcode creates its own widget files - delete them)

### Step 2: Add Files to Extension Target

Select each file below, open File Inspector (Cmd+Option+1), and check `BudgetMeterWidgets` under Target Membership:

**Widget Files:**
- `budgetmeter.ios/Widgets/BudgetMeterWidgets.swift`
- `budgetmeter.ios/Widgets/CombinedBalanceSavingsWidget.swift`
- `budgetmeter.ios/Widgets/LockScreenWidgets.swift`

**Dependencies:**
- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/CoreKit/Sources/Utilities/CurrencyHelper.swift`
- `budgetmeter.ios/CoreKit/Sources/Utilities/LocalizationManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Utilities/ColorExtension.swift`
- `budgetmeter.ios/BudgetMeter.xcdatamodeld`

### Step 3: Configure App Groups

**For both targets** (budgetmeter.ios AND BudgetMeterWidgets):

1. Select the target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** > **App Groups**
4. Add: `group.com.budgetmeter.shared`

Both targets must use the **exact same** App Group identifier.

### Step 4: Set Deployment Target

For `BudgetMeterWidgets` target:
- Go to **General** tab
- Set **iOS Deployment Target:** 16.0

### Step 5: Build & Test

1. Select the `BudgetMeterWidgets` scheme
2. Build (Cmd+B)
3. Run on simulator or device
4. Long-press home screen > Add widget > Search "BudgetMeter"

---

## Deep Linking

Widgets support deep linking to navigate users to relevant screens:

| URL Scheme | Destination |
|------------|-------------|
| `budgetmeter://home` | Home tab |
| `budgetmeter://expenses` | Expenses tab |
| `budgetmeter://income` | Income tab |

URL handler is implemented in `budgetmeter_iosApp.swift`.

---

## Widget Files

```
budgetmeter.ios/budgetmeter.ios/Widgets/
├── BudgetMeterWidgets.swift           # @main bundle + 3 home screen widgets
├── CombinedBalanceSavingsWidget.swift # Combined balance & savings widget
└── LockScreenWidgets.swift            # 3 lock screen widgets (iOS 16+)

budgetmeter.ios/budgetmeter.ios/Features/WidgetsFeature/
└── View/WidgetsSetupView.swift        # User-facing setup instructions
```

---

## Troubleshooting

### Widgets Not Appearing in Gallery
- Ensure Widget Extension target exists and is embedded in main app
- Clean build folder (Shift+Cmd+K) and rebuild
- Delete app from simulator/device and reinstall

### Widgets Show "Unable to Load"
- Check App Groups configured for both targets with same identifier
- Verify `PersistenceService.swift` has shared container code
- Ensure Core Data model is added to extension target

### Widgets Show Stale Data
- Widget refresh calls are already in place
- Force refresh by editing data in app

### Deep Linking Not Working
- Check URL scheme `budgetmeter` is registered in Info.plist
- Verify URL handler in `budgetmeter_iosApp.swift`

---

## Testing Checklist

### Installation
- [ ] Widgets appear in widget gallery
- [ ] Can add widgets to Home Screen
- [ ] Can add widgets to Lock Screen (iOS 16+)

### Data Display
- [ ] Balance widget shows real data
- [ ] Spending widget shows category breakdown
- [ ] Savings widget shows goal progress
- [ ] Currency symbols display correctly

### Updates
- [ ] Widgets refresh when app data changes
- [ ] Widgets update on timeline schedule

### Interaction
- [ ] Tapping Balance widget opens Home tab
- [ ] Tapping Spending widget opens Expenses tab
- [ ] Lock screen widgets open app

---

## Technical Notes

- Widgets use `CalculationEngine` for financial calculations
- Data is shared via App Groups (`group.com.budgetmeter.shared`)
- Timeline providers handle refresh schedules (hourly for balance, 6hr for spending, 12hr for savings)
- Lock screen widgets require iOS 16.0+
- Premium badges displayed on premium-gated features
