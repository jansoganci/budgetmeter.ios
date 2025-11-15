# Premium Themes - App Icon Setup Guide

## Overview

The Premium Themes feature supports automatic app icon switching based on the selected theme. The code infrastructure is ready, but alternate icon assets need to be added to enable this feature.

## Current Status

✅ Theme system fully implemented
✅ App icon switching code ready
❌ Alternate icon assets not yet added (optional)

## How to Add Alternate App Icons

### Step 1: Create Icon Assets

For each theme, you'll need icon images in these sizes:
- **iPhone**: 60x60@2x, 60x60@3x
- **iPad**: 76x76@1x, 76x76@2x
- **App Store**: 1024x1024@1x

**Icon Names (already configured in code)**:
- `AppIcon-Ocean` - Cyan/blue themed icon
- `AppIcon-Forest` - Green themed icon
- `AppIcon-Sunset` - Orange themed icon
- `AppIcon-Purple` - Purple themed icon
- `AppIcon-Midnight` - Indigo/dark themed icon

### Step 2: Add to Assets.xcassets

1. Open `budgetmeter.ios/Assets.xcassets` in Xcode
2. Right-click → New iOS App Icon
3. Name it exactly as shown above (e.g., `AppIcon-Ocean`)
4. Drag your icon images into the appropriate slots
5. Repeat for each theme

### Step 3: Configure Info.plist

Add alternate icons to your Info.plist or project settings:

```xml
<key>CFBundleIcons</key>
<dict>
    <key>CFBundleAlternateIcons</key>
    <dict>
        <key>AppIcon-Ocean</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-Ocean</string>
            </array>
        </dict>
        <key>AppIcon-Forest</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-Forest</string>
            </array>
        </dict>
        <!-- Repeat for Sunset, Purple, Midnight -->
    </dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
        <key>CFBundleIconFiles</key>
        <array>
            <string>AppIcon</string>
        </array>
    </dict>
</dict>
```

**Or in Xcode (modern approach)**:
1. Select your app target
2. Go to Build Settings
3. Search for "Icon"
4. Configure alternate icons in the asset catalog

### Step 4: Test

1. Run the app
2. Go to Settings → Premium Themes
3. Select a theme
4. Tap "Apply Theme"
5. The app icon should change! (May require force-quitting)

## Design Tips for Theme Icons

**Ocean** 🌊: Use cyan/blue gradient, water motifs
**Forest** 🌲: Use green gradient, nature motifs
**Sunset** 🌅: Use orange/pink gradient, warm colors
**Purple** ✨: Use purple/pink gradient, mystical feel
**Midnight** 🌙: Use dark indigo/purple, night theme

Keep the base design consistent, only varying the color scheme to match each theme.

## Fallback Behavior

If alternate icons are not configured:
- App will continue using the default icon
- Theme colors will still work throughout the app
- No errors will occur
- Console will log: "Alternate icons not supported"

## Code References

- **ThemeManager.swift**: `applyAppIcon(for:)` method
- **AppTheme enum**: `appIconName` property
- **Info.plist**: Icon configuration (when added)

## Questions?

Check Apple's documentation:
https://developer.apple.com/documentation/uikit/uiapplication/2806818-setalternateiconname
