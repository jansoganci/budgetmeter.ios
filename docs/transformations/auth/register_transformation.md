# Register Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Register / Create Account screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines structure, component usage, copy direction, token constraints, safety boundaries, and acceptance criteria for the Register screen only.

## 2. Register Product Role

- Register is the account creation step in the auth flow.
- It should feel calm, trustworthy, simple, and low-friction.

It should not feel like:

- a bank onboarding flow
- a payment account setup
- a wallet setup
- a crypto signup
- an enterprise finance form

## 3. Current Problem Summary

Likely current Register issues:

- screen may feel too generic or plain
- form may feel visually heavy or cramped
- weak premium calm fintech feeling
- CTA hierarchy may need improvement
- legal/supporting copy may need better spacing

## 4. Target Design Direction

Register transformation should follow:

- premium calm fintech
- light mode first
- slate/off-white canvas
- medium glass form card
- Coral Default accent
- clear form hierarchy
- readable input fields
- calm and trustworthy copy
- no banking/payment/wallet visuals
- no dashboard preview

## 5. Layout Hierarchy

Use this hierarchy:

1. Lightweight brand/header area
2. Screen title
3. Short supportive subtitle
4. Register form fields that already exist
5. Main create account CTA
6. Existing sign-in/back link
7. Existing legal text/links if present

## 6. Components to Use

Map Register to shared components:

- `AppBackground`
- `BudgetHeader` or lightweight brand header
- `GlassCard`
- `PrimaryCTAButton`
- `SecondaryCTAButton` if needed
- `SectionHeader` only if already useful
- `StatusBadge` only for validation/status if already present
- `BudgetBottomTabBar` must not be used

## 7. Form Rules

- Keep existing register fields only.
- Do not add new fields.
- Do not remove required existing fields.
- Preserve password validation behavior if present.
- Preserve keyboard/content type behavior where possible.
- Keep input fields readable and accessible.
- Do not change register/auth logic.

## 8. CTA Rules

- Main CTA should be clear and visually dominant.
- Sign in/back link should remain secondary but visible.
- Do not add new auth providers.
- Do not create onboarding steps from this screen.
- Do not change navigation logic.

## 9. Copy Direction

Use short, human Turkish copy.

Preferred copy:

- `Hesap oluştur`
- `Paranı daha sakin takip etmeye başla.`

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
  - consistent spacing between fields and validation/help text
- **glass treatment**
  - medium glass form card only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surface
- **light/dark mode parity**
  - both modes remain readable and consistent

## 11. Stitch Reference Rules

- Stitch can guide spacing, calm mood, form card direction, and CTA hierarchy.
- Stitch should not be copied exactly.
- Final UI must follow `DESIGN.md`, `auth_transformation.md`, `welcome_transformation.md`, and shared components.

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

- [ ] Register feels calm, trustworthy, and premium.
- [ ] Existing register fields are preserved.
- [ ] Existing register/auth logic is preserved.
- [ ] Existing navigation is preserved.
- [ ] Main CTA is clear.
- [ ] Sign in/back link remains available if present.
- [ ] No new onboarding flow is introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Shared tokens and components are used.
- [ ] Light and dark mode remain readable.
- [ ] Accessibility remains intact.
