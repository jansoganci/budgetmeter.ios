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
* Preserve existing names.
* If file structure differs, STOP and ask.
* After completion: files changed, exact changes, build/test result, QA checklist, rollback note.
* Stop after this phase.

⸻

PHASE 11 — New-User-Only Skippable Onboarding

Goal:
Add a lightweight, skippable onboarding flow for NEW users only (not forced on existing users).

Allowed files ONLY:
* budgetmeter.ios/Features/OnboardingFeature/ (create new folder)
* budgetmeter.ios/Features/AuthFeature/View/RootAuthView.swift (add onboarding gate)
* Resources/UI.xcstrings (add onboarding.* keys)

Forbidden:
* Core Data schema changes
* Auth provider logic
* StoreKit
* CalculationEngine
* Feature screens (Home, Income, Expense, Settings, etc.)
* Xcode project files

Implement:

1. Create `budgetmeter.ios/Features/OnboardingFeature/View/OnboardingView.swift`:
   * A simple paging onboarding with 2-3 screens
   * Screen 1: "Track your money pace" — brief intro to the pace concept
   * Screen 2: "Add your income & expenses" — intro to the main flow
   * Screen 3: "Stay on top of your finances" — summary + "Get Started" button
   * Use v2 design tokens (glass surfaces, v2 colors, SF Pro typography)
   * Skip button on every screen
   * "Get Started" on last screen

2. Create `budgetmeter.ios/Features/OnboardingFeature/ViewModel/OnboardingViewModel.swift`:
   * Simple state management
   * Tracks current page
   * Marks onboarding as completed via @AppStorage("hasCompletedOnboarding")

3. Modify `budgetmeter.ios/Features/AuthFeature/View/RootAuthView.swift`:
   * After successful auth (phase == .signedIn), check if onboarding is completed
   * If NOT completed → show OnboardingView first, then ContentView
   * If completed → show ContentView directly
   * This ensures existing users never see onboarding

4. Add UI.xcstrings keys for onboarding.* (all 10 languages).

Acceptance criteria:
* App compiles.
* New users see onboarding once after first sign-in.
* Existing users (hasCompletedOnboarding = true) skip onboarding.
* Skip button dismisses onboarding.
* "Get Started" completes onboarding and goes to main app.
* No Core Data, auth, or feature logic changed.
* Onboarding uses v2 design tokens.

Manual QA checklist:
* Fresh install → sign in → onboarding appears.
* Swipe through 3 pages.
* Tap Skip → goes to main app.
* Kill app, reopen → onboarding NOT shown again.
* Existing user (hasCompletedOnboarding = true) → no onboarding.
* Verify dark + light mode.

Rollback note: Delete OnboardingFeature/ folder, revert RootAuthView.swift, revert UI.xcstrings.
