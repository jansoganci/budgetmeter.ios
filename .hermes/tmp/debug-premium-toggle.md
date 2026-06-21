# Add DEBUG Premium Toggle to Settings

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Goal
Add a DEBUG-only toggle in Settings that makes the current user premium (unlocks all premium features). When disabled, user is free. This allows testing premium features without StoreKit sandbox.

## Requirements

1. Add a toggle in **Settings screen** (not in production builds)
2. When ON → `PremiumManager.shared.isPremium = true` → all premium features unlocked
3. When OFF → `PremiumManager.shared.isPremium = false` → normal free user
4. **MUST be DEBUG-only** — wrapped in `#if DEBUG` so it never ships to App Store

## Implementation

### Option A: Modify PremiumManager

In `CoreKit/Sources/Premium/PremiumManager.swift`:
- Check if the `isPremium` computed property or the underlying `_isPremium` storage can be overridden
- If there's a `@Published private(set) var isPremium` or `var isPremium: Bool`, add a debug write access

Add a debug-only method:
```swift
#if DEBUG
func setDebugPremium(_ enabled: Bool) {
    // Override the premium state
    // This might need to update AppSettings.isPremiumUser or a local flag
}
#endif
```

### Option B: AppSettings override

In `SettingsView.swift` or create a DEBUG section:
- Add a `@AppStorage("debug_premium_override")` or use `UserDefaults`
- When toggled, update `PremiumManager.shared` state

### Where to put the toggle

Add a section to `Features/SettingsFeature/View/SettingsView.swift`:
```swift
#if DEBUG
Section("🧪 DEBUG") {
    Toggle("Premium Mode (Debug)", isOn: $debugPremiumEnabled)
        .onChange(of: debugPremiumEnabled) { _, newValue in
            PremiumManager.shared.setDebugPremium(newValue)
        }
}
#endif
```

Important: The toggle's state must be persisted so it survives app restarts during testing. Use `@AppStorage` for this.

## Check existing PremiumManager implementation first
Read `CoreKit/Sources/Premium/PremiumManager.swift` to understand the current isPremium implementation before deciding the exact approach.

## Localization
Use hardcoded English for the debug toggle (no localization needed for debug UI).

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Build must succeed.
