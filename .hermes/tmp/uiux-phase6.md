# BudgetMeter UI/UX v2 — Phase 6: Glass Surface Primitive + Reduce Transparency Fallback

Read first:
* docs/uiux_v2_implementation_plan.md
* docs/uiux_design_system_v2_tokens.md
* docs/uiux_design_direction_v1_decisions.md

## Global rules
* ONLY implement this phase. DO NOT continue to the next.
* ONLY touch the allowed files listed below.
* DO NOT touch Core Data schema, auth logic, StoreKit, CalculationEngine, networking/sync, Xcode project files, or unrelated features.
* Preserve existing public token/modifier names wherever possible.
* After completion: report files changed, exact changes, build result.

## Phase 6 — Glass Surface Primitive + Reduce Transparency Fallback

Goal: Create a reusable v2 glass surface/card primitive with Reduce Transparency fallback.

Allowed files:
* budgetmeter.ios/DesignSystem/Components/Surfaces/ (create if not exists)
* budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift (add glass-related tokens if needed)

Forbidden:
* Feature screens, widgets, currency, theme migration, paywall, auth, Core Data

Implement:

1. Create a new file at `budgetmeter.ios/DesignSystem/Components/Surfaces/GlassSurface.swift` with:

```swift
import SwiftUI

struct GlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    func body(content: Content) -> some View {
        if reduceTransparency {
            // Fallback: solid card background
            content
                .background(colorScheme == .dark ? Color.slate800 : Color.white)
                .cornerRadius(20)
        } else {
            // Glass effect
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? 
                            Color.white.opacity(0.12) : 
                            Color.black.opacity(0.08),
                            lineWidth: 0.5)
                )
        }
    }
}

extension View {
    func glassSurface() -> some View {
        modifier(GlassSurfaceModifier())
    }
}
```

2. The glass surface should:
   - Use medium-strength glass (`.ultraThinMaterial`)
   - Add subtle border: dark `rgba(248,250,252,0.12)`, light `rgba(15,23,42,0.08)`
   - When Reduce Transparency is ON: fall back to solid `slate800` (dark) / `white` (light) background
   - Default card radius: 20pt

3. Verify Build:
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
