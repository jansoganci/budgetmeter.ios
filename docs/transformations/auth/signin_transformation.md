# Sign In Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Sign In screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines structure, component usage, copy direction, token constraints, safety boundaries, and acceptance criteria for the Sign In screen only.

## 2. Sign In Product Role

- Sign In is the returning-user entry point.
- It should feel calm, trustworthy, simple, and fast.
- It should help users continue tracking their money pace without friction.

It must not feel like:

- a bank login
- a payment app login
- a wallet login
- a crypto login
- an enterprise finance portal

## 3. Current Problem Summary

Likely current Sign In issues:

- screen may feel too generic or plain
- form hierarchy may need stronger polish
- CTA hierarchy may need improvement
- forgot password link may need clearer placement
- weak premium calm fintech feeling

## 4. Target Design Direction

Sign In transformation should follow:

- premium calm fintech
- light mode first
- slate/off-white canvas
- medium glass form card
- Coral Default accent
- clear form hierarchy
- readable input fields
- calm returning-user copy
- no banking/payment/wallet visuals
- no dashboard preview

## 5. Layout Hierarchy

Use this hierarchy:

1. Lightweight brand/header area
2. Screen title
3. Short supportive subtitle
4. Email input
5. Password input
6. Forgot password link if currently present
7. Main sign in CTA
8. Existing create account/back link if present

## 6. Components to Use

Map Sign In to shared components:

- `AppBackground`
- `BudgetHeader` or lightweight brand header
- `GlassCard`
- `PrimaryCTAButton`
- `SecondaryCTAButton` if needed
- `StatusBadge` only for validation/status if already present
- `BudgetBottomTabBar` must not be used

## 7. Form Rules

- Keep existing sign in fields only.
- Preserve email/password auth behavior.
- Preserve keyboard/content type behavior where possible.
- Preserve validation/error behavior if present.
- Keep input fields readable and accessible.
- Do not change sign in/auth logic.

## 8. CTA Rules

- Main sign in CTA should be clear and visually dominant.
- Forgot password link should remain accessible if currently present.
- Create account/back link should remain secondary but visible if currently present.
- Do not add new auth providers.
- Do not change navigation logic.

## 9. Copy Direction

Use short, human Turkish copy.

Preferred copy:

- `Giriş yap`
- `Paranın temposunu takip etmeye devam et.`

Rules:

- Keep copy short.
- Avoid financial jargon.
- Avoid bank/payment language.
- Avoid pressure or fear.

## 10. Token Rules

Apply approved token rules:

- **background colors**
  - light: `#F8FAFC`
  - dark: `#0F172A`
- **elevated surfaces**
  - light: `#FFFFFF`
  - dark: `#1E293B`
- **text colors**
  - primary: `#0F172A` / `#F8FAFC`
  - secondary: `#64748B` / `#94A3B8`
  - tertiary: `#94A3B8` / `#64748B`
- **Coral Default accent**
  - `#FF5A5F`
- **spacing**
  - screen horizontal: `16`
  - section gap: `20`
  - card padding: `16`
  - card gap: `12`
  - row height: `48` where applicable
  - button height: `52`
- **radius**
  - card: `20`
  - button: `14`
  - modal: `24`
- **typography**
  - SF Pro/system for UI text
  - SF Pro Rounded only for financial numbers if shown
- **input styling**
  - readable contrast in both modes
  - clear field boundaries and labels/placeholders
  - consistent spacing between fields and helper/error text
- **glass treatment**
  - medium glass form card only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surface
- **light/dark mode parity**
  - both modes remain readable and consistent

## 11. Stitch Reference Rules

- Stitch can guide spacing, calm mood, form card direction, and CTA hierarchy.
- Stitch should not be copied exactly.
- Final UI must follow `DESIGN.md`, `auth_transformation.md`, `welcome_transformation.md`, `register_transformation.md`, and shared components.

## 12. Implementation Safety Rules

- no auth logic changes
- no navigation changes
- no persistence changes
- no subscription logic changes
- no Core Data schema changes
- no new auth providers
- no new form fields
- no new onboarding flow
- no unrelated refactors
- no fake banking/payment/wallet UI
- preserve accessibility labels where possible

## 13. Acceptance Checklist

- [ ] Sign In feels calm, trustworthy, and premium.
- [ ] Existing sign in fields are preserved.
- [ ] Existing sign in/auth logic is preserved.
- [ ] Forgot password remains accessible if present.
- [ ] Existing navigation is preserved.
- [ ] Main CTA is clear.
- [ ] Create account/back link remains available if present.
- [ ] No new onboarding flow is introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Shared tokens and components are used.
- [ ] Light and dark mode remain readable.
- [ ] Accessibility remains intact.
