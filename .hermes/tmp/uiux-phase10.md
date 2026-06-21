MASTER RULES — paste at the top of every phase prompt

BudgetMeter UI/UX v2 implementation.

Read first:
* docs/uiux_v2_implementation_plan.md
* docs/uiux_design_system_v2_tokens.md
* docs/uiux_design_direction_v1_decisions.md

Global rules:
* ONLY implement this phase. DO NOT continue.
* ONLY touch allowed files.
* DO NOT touch Core Data, auth, StoreKit, CalculationEngine, networking/sync, Xcode project files.
* Preserve existing names and compatibility aliases.
* If file structure differs, STOP and ask.
* After completion: files changed, exact changes, build/test result, QA checklist, rollback note.
* Stop after this phase.

⸻

PHASE 10 — Pulsey Static Fallback Architecture

Goal:
Add Pulsey-ready architecture without requiring actual image assets.

Allowed files ONLY:
* budgetmeter.ios/DesignSystem/Components/ (new Pulsey components)
* budgetmeter.ios/Features/HomeFeature/View/HomeView.swift (add Pulsey placement only)
* Resources/UI.xcstrings (add Pulsey-related keys)

Forbidden:
* Theme migration files
* Widgets
* Currency files
* Auth files
* StoreKit files
* PremiumManager.swift
* Core Data
* Xcode project files

Implement:

1. Create a new file at `budgetmeter.ios/DesignSystem/Components/Pulsey/PulseyMascotView.swift`:
   * A reusable SwiftUI view that shows a placeholder circle with emoji "💜" or "✨" as static fallback
   * Accept optional `state` parameter: .loading, .success, .empty, .celebration
   * Small size (~40x40) for inline placement
   * Animated pulse/breathing effect using phase animator
   * When actual image assets are added later, replace the emoji with the image

2. Add Pulsey placement to HomeView:
   * Small Pulsey indicator next to the momentum hero card
   * Shows during empty state or as decorative element
   * Subtle, non-intrusive

3. Add UI.xcstrings keys for Pulsey accessibility labels.

Acceptance criteria:
* App compiles.
* Pulsey view renders a placeholder circle (no missing asset errors).
* Home screen shows Pulsey in the specified location.
* Breathing animation works.
* No feature logic changed.
* Accessibility label present.

Manual QA checklist:
* Open Home screen — verify Pulsey placeholder appears.
* Verify animation plays.
* Check VoiceOver reads accessibility label.
* Light + dark mode both render correctly.

Rollback note: Delete PulseyMascotView.swift, revert HomeView changes, revert UI.xcstrings.
