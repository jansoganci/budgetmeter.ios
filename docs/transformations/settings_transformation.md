# Settings Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Settings screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines structure, component mapping, token constraints, safety boundaries, and acceptance criteria for Settings transformation.

## 2. Settings Product Role

- Settings is the calm control center of BudgetMeter.
- It should let users manage preferences, currency, theme, premium, account, support, and legal options.
- It must feel simple, trustworthy, and iOS-native.

It must not feel like:

- a technical admin panel
- a banking settings page
- a wallet app
- a payment app
- an enterprise finance tool

## 3. Current Problem Summary

Likely current Settings issues:

- settings may feel too plain or system-default
- sections may lack visual hierarchy
- premium/theme/currency areas may not feel connected to the new design system
- spacing and card treatment may be inconsistent
- icons or rows may feel generic

## 4. Target Design Direction

Settings transformation should follow:

- premium calm fintech
- clean iOS-native settings structure
- medium glass section cards
- slate/off-white canvas
- clear grouped sections
- readable rows
- simple icons only if already used
- no visual clutter
- no mascot in the main Settings list
- light/dark mode parity

## 5. Layout Hierarchy

Use this hierarchy:

1. Header / screen title
2. Account/profile section if present
3. Premium section if present
4. Appearance/theme section if present
5. Currency/preferences section
6. Support/legal section
7. Account actions if present

## 6. Components to Use

Map Settings to shared components:

- `AppBackground`
- `BudgetHeader`
- `GlassCard`
- `SectionHeader`
- `FinanceListRow` or settings row equivalent
- `PremiumBadge` if premium state exists
- `StatusBadge` if needed
- `SecondaryCTAButton` if needed
- `BudgetBottomTabBar` only if current app already uses tab navigation

## 7. Row Rules

- Rows should be readable and calm.
- Row height should follow shared spacing rules.
- Labels should be short.
- Secondary text should be used only when useful.
- Destructive actions must be visually distinct but not aggressive.
- Do not add fake settings.
- Do not add new account actions unless already present.

## 8. Premium / Theme Rules

- Premium should feel like personalization, not pressure.
- Theme options should use existing theme logic only.
- Do not create new subscription logic.
- Do not create new premium entitlement logic.
- Theme accent previews should follow `DESIGN.md` colors if already shown.

## 9. Currency Rules

- Currency must remain user-selected and dynamic.
- No hardcoded currency symbols.
- Do not change currency persistence logic.
- Currency settings should be clear and easy to find.

## 10. Token Rules

Apply approved token rules:

- **Background colors**
  - light: `#F8FAFC`
  - dark: `#0F172A`
- **Elevated surfaces**
  - light: `#FFFFFF`
  - dark: `#1E293B`
- **Text colors**
  - primary: `#0F172A` / `#F8FAFC`
  - secondary: `#64748B` / `#94A3B8`
  - tertiary: `#94A3B8` / `#64748B`
- **Coral Default accent**
  - `#FF5A5F`
- **Neutral slate/gray**
  - use neutral slate/gray tokens for supporting or inactive row states
- **Spacing**
  - screen horizontal: `16`
  - optional dashboard horizontal: `20` where needed
  - section gap: `20`
  - card padding: `16`
  - card gap: `12`
  - row height: `48`
  - button height: `52` where button rows are present
- **Radius**
  - card: `20`
  - button: `14`
  - modal: `24`
- **Typography**
  - SF Pro/system for normal settings text
  - SF Pro Rounded only for financial values if any are shown
- **Glass treatment**
  - medium glass only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surfaces
- **Light/Dark parity**
  - equal readability and quality in both modes

## 11. Stitch Reference Rules

- Stitch can guide section rhythm, card mood, and premium calm fintech polish.
- It should not be copied exactly.
- Final UI must follow `DESIGN.md` and shared components.

## 12. Implementation Safety Rules

- no business logic changes
- no navigation changes
- no persistence changes
- no auth changes
- no subscription logic changes
- no Core Data schema changes
- no currency hardcoding
- no new settings unless explicitly requested
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility labels where possible

## 13. Acceptance Checklist

- [ ] Settings feels calm, premium, and iOS-native.
- [ ] Sections are clearly grouped.
- [ ] Currency setting is easy to find.
- [ ] Premium/theme areas are visually aligned with `DESIGN.md`.
- [ ] Shared components are used.
- [ ] Light and dark mode are supported.
- [ ] No technical/admin-panel feeling is introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Existing settings logic is preserved.
- [ ] Existing navigation is preserved.
- [ ] Accessibility remains intact.
