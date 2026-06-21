# Fix Widget "adapt container background api" Error

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Problem
When adding the widget on iOS 26, it shows "Please adapt container background api". This means the widget view is missing the required `.containerBackground()` modifier.

## Fix

Read `BudgetMeterWidgets/NetDailyPaceWidget.swift` (or wherever the widget View is defined).

For each widget view (Provider.Entry view), add `.containerBackground()` modifier:

```swift
struct NetDailyPaceWidgetEntryView: View {
    var entry: WidgetSnapshot

    var body: some View {
        VStack {
            // existing content
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)  // or any color/gradient
        }
    }
}
```

Also check if there are any other widget views (locked state, insufficient data state) that need the same fix.

The modifier should be on the OUTERMOST container of the widget body, using `for: .widget`.

## Search for all widget entry views
Search the BudgetMeterWidgets/ directory for any `struct *View: View` that's used as a widget entry view and add `.containerBackground(for: .widget)` to each.

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme BudgetMeterWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Must succeed.
