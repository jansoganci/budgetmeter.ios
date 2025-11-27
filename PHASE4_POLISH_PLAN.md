# 🎨 Phase 4: Polish - Locale-Aware Formatting Plan

## 📋 Overview

Phase 4 focuses on ensuring all numeric formatting (percentages, numbers, dates) respects the user's selected locale and language preferences. This is the final polish step to make the app truly internationalized.

---

## 🔍 What We'll Check

### 1. **Percentage Formatting** 🔴 HIGH PRIORITY

**Current Issues:**
- Hardcoded `%` symbol in many places: `String(format: "%.0f%%", ...)`
- Some locales use different percentage symbols or positioning
- Examples found in:
  - `SavingsGoalsViewModel.swift`: `String(format: "%.0f%%", progress)`
  - `SpendingBreakdownView.swift`: `"\(Int(item.percentage))%"`
  - `TrendIndicator.swift`: `String(format: "%+.1f%%", percentage)`
  - `InsightsService.swift`: `String(format: "%.0f%%", absChange)`
  - `CalculationEngine.swift`: Multiple percentage strings in health tips

**Why This Matters:**
- Different locales may use different percentage symbols (%, pct, p.c., etc.)
- Some languages position the percentage symbol differently (before vs after)
- Arabic and other RTL languages may need special handling

**What We'll Change:**
- Create a `PercentageFormatter` helper that respects locale
- Replace all hardcoded `%.0f%%` patterns with locale-aware formatting
- Use `NumberFormatter` with `.percent` style for proper localization

---

### 2. **Date Formatting Locale Awareness** 🟡 MEDIUM PRIORITY

**Current Issues:**
- `DateFormattingHelper` uses system formatters (good), but:
  - Hardcoded formats like `"MMM d"` and `"MMM yyyy"` may not fully respect locale
  - Month names in these formats might not localize properly
  - Should use `LocalizationManager.currentLocale` instead of `Locale.current`

**Why This Matters:**
- Different locales have different date formats (DD/MM/YYYY vs MM/DD/YYYY vs YYYY/MM/DD)
- Month names need to be localized (Jan vs يناير vs 1月)
- Date separators vary by locale

**What We'll Change:**
- Update `DateFormattingHelper` to use `LocalizationManager.currentLocale`
- Replace hardcoded `dateFormat` patterns with locale-aware alternatives
- Ensure all date formatters respect the app's selected language

---

### 3. **Number Formatting Consistency** 🟡 MEDIUM PRIORITY

**Current Issues:**
- Some places use hardcoded `String(format: "%.2f", ...)` for decimal formatting
- Examples in:
  - `SubscriptionInputView.swift`: `String(format: "%.2f", subscription.amount)`
  - `SavingsGoalInputView.swift`: `String(format: "%.2f", goal.targetAmount)`
  - `BillInputView.swift`: `String(format: "%.2f", bill.amount)`
  - `CurrencyHelper.swift`: Fallback uses `String(format: "%@%.2f", ...)`

**Why This Matters:**
- Different locales use different decimal separators (`.` vs `,`)
- Thousands separators vary (`,` vs `.` vs space)
- Currency formatting should be consistent throughout the app

**What We'll Change:**
- Ensure all number formatting uses `NumberFormatter` or `CurrencyHelper`
- Replace hardcoded decimal formatting with locale-aware formatters
- Verify currency formatting uses the standardized approach consistently

---

### 4. **Locale Usage in Formatters** 🟡 MEDIUM PRIORITY

**Current Issues:**
- `DateFormattingHelper` uses `Locale.current` (system locale)
- Should use `LocalizationManager.currentLocale` (app-selected locale)
- `CurrencyHelper` uses standardized US format (intentional, but should verify)

**Why This Matters:**
- User selects Turkish language → dates should show in Turkish format
- User selects Arabic language → numbers should use Arabic-Indic numerals (optional)
- App language selection should affect all formatting, not just strings

**What We'll Change:**
- Update `DateFormattingHelper` to use `LocalizationManager.currentLocale`
- Ensure all formatters respect the app's language selection
- Add locale parameter to formatting helpers where needed

---

### 5. **Compact Number Formatting** 🟢 LOW PRIORITY

**Current Issues:**
- Compact formats like `"1.2K"`, `"45.5K"` use hardcoded formatting
- Examples in:
  - `FinancialSummaryCard.swift`: `String(format: "%.0f", thousands)K`
  - `LockScreenWidgets.swift`: `String(format: "%@%.1fK", ...)`
  - `MonthComparisonView.swift`: `String(format: "%.1fk", amount / 1000)`

**Why This Matters:**
- Some locales use different compact notation
- "K" for thousands might not be universal (some use "k" or other symbols)
- Should use `NumberFormatter` with `.decimal` style for better localization

**What We'll Change:**
- Create a helper for compact number formatting
- Use `NumberFormatter` for consistent locale-aware formatting
- Consider using `MeasurementFormatter` for better localization

---

## 📝 Detailed Changes

### **Change 1: Create PercentageFormatter Helper**

**File:** `CoreKit/Sources/Utilities/PercentageFormatter.swift` (NEW)

```swift
/// Locale-aware percentage formatter
struct PercentageFormatter {
    static func format(_ value: Double, locale: Locale? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.locale = locale ?? LocalizationManager.shared.currentLocale
        return formatter.string(from: NSNumber(value: value / 100.0)) ?? "\(Int(value))%"
    }
    
    static func formatInteger(_ value: Double, locale: Locale? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.locale = locale ?? LocalizationManager.shared.currentLocale
        return formatter.string(from: NSNumber(value: value / 100.0)) ?? "\(Int(value))%"
    }
}
```

**Files to Update:**
- `SavingsGoalsViewModel.swift`
- `SpendingBreakdownView.swift`
- `TrendIndicator.swift`
- `InsightsService.swift`
- `CalculationEngine.swift`
- `NotificationService.swift`

---

### **Change 2: Update DateFormattingHelper to Use App Locale**

**File:** `CoreKit/Sources/Utilities/DateFormattingHelper.swift`

**Changes:**
- Replace `Locale.current` with `LocalizationManager.shared.currentLocale`
- Update hardcoded `dateFormat` patterns to use locale-aware alternatives
- Ensure all formatters use the app's selected language

**Key Updates:**
```swift
// Before:
formatter.dateFormat = "MMM d"

// After:
formatter.setLocalizedDateFormatFromTemplate("MMMd") // Locale-aware
// OR use dateStyle instead of dateFormat where possible
```

---

### **Change 3: Standardize Number Formatting**

**Files to Update:**
- `SubscriptionInputView.swift`
- `SavingsGoalInputView.swift`
- `BillInputView.swift`
- `CurrencyHelper.swift` (fallback method)

**Changes:**
- Replace `String(format: "%.2f", ...)` with `NumberFormatter` or `CurrencyHelper`
- Ensure all decimal formatting respects locale

---

### **Change 4: Update Formatters to Use App Locale**

**Files to Update:**
- `DateFormattingHelper.swift` - Use `LocalizationManager.currentLocale`
- All formatter creation should respect app language selection

---

## 🎯 Expected Outcomes

### **After Phase 4:**

1. ✅ **Percentages** display correctly for all 10 languages
   - Turkish: `%50` (same symbol, but properly formatted)
   - Arabic: `٪٥٠` (Arabic-Indic numerals, if supported)
   - All locales use proper percentage formatting

2. ✅ **Dates** respect user's language selection
   - Turkish user sees: `15 Oca 2025` (Turkish month names)
   - Arabic user sees: `١٥ يناير ٢٠٢٥` (Arabic numerals and month names)
   - All date formats match the selected language

3. ✅ **Numbers** use consistent, locale-aware formatting
   - Decimal separators match locale (`.` or `,`)
   - Thousands separators match locale
   - Currency formatting is consistent throughout

4. ✅ **All formatting** respects app language selection
   - Not just strings, but numbers, dates, percentages too
   - User changes language → all formatting updates

---

## ⚠️ Important Notes

### **What We WON'T Change:**

1. **Currency Formatting Standardization** - Already standardized to US format (1,234.56) per design decision. This is intentional for consistency.

2. **RTL Number Support** - Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) are optional. iOS handles this automatically in most cases.

3. **Time Formatting** - Already uses system formatters which are locale-aware.

4. **Currency Symbol Positioning** - Already handled by `CurrencyHelper`.

---

## 📊 Files to Modify

### **New Files:**
- `CoreKit/Sources/Utilities/PercentageFormatter.swift`

### **Files to Update:**
1. `CoreKit/Sources/Utilities/DateFormattingHelper.swift`
2. `CoreKit/Sources/Utilities/CurrencyHelper.swift` (minor)
3. `Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`
4. `Features/InsightsFeature/View/Charts/SpendingBreakdownView.swift`
5. `DesignSystem/Components/Indicators/TrendIndicator.swift`
6. `CoreKit/Sources/Services/InsightsService.swift`
7. `CoreKit/Sources/Engine/CalculationEngine.swift`
8. `CoreKit/Sources/Services/NotificationService.swift`
9. `Features/SubscriptionsFeature/View/SubscriptionInputView.swift`
10. `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift`
11. `Features/BillsFeature/View/BillInputView.swift`

**Estimated Files:** ~11 files
**Estimated Changes:** ~20-30 code changes

---

## 🧪 Testing Checklist

After implementation, test:

- [ ] Percentages display correctly in all 10 languages
- [ ] Dates show localized month names in all languages
- [ ] Number formatting respects locale (decimal/thousands separators)
- [ ] Changing app language updates all formatting immediately
- [ ] Currency formatting remains consistent
- [ ] No regressions in existing functionality

---

## ⏱️ Estimated Time

- **Percentage Formatter Creation:** 15 minutes
- **Date Formatting Updates:** 20 minutes
- **Number Formatting Standardization:** 15 minutes
- **Locale Integration:** 10 minutes
- **Testing & Verification:** 20 minutes

**Total:** ~80 minutes (1.5 hours)

---

## 🚀 Priority Order

1. **Percentage Formatting** (Highest impact, most visible)
2. **Date Formatting Locale** (Important for user experience)
3. **Number Formatting Consistency** (Polish)
4. **Locale Usage** (Foundation for above)
5. **Compact Number Formatting** (Nice to have)

---

**Status:** 📋 **PLANNED** - Ready for implementation
**Next Step:** Begin with Percentage Formatter creation

