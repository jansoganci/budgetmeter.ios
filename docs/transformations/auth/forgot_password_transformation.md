# Forgot Password Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Forgot Password screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines structure, component usage, copy direction, token constraints, safety boundaries, and acceptance criteria for the Forgot Password screen only.

## 2. Forgot Password Product Role

- Forgot Password is a recovery step inside the auth flow.
- It should feel calm, safe, simple, and reassuring.
- It should help users recover access quickly without friction.

It must not feel like:

- a banking recovery portal
- a payment account recovery flow
- a wallet recovery setup
- a crypto security dashboard
- an enterprise admin reset panel

## 3. Current Problem Summary

Likely current Forgot Password issues:

- screen may feel too generic or plain
- recovery flow hierarchy may feel unclear
- primary and secondary actions may need stronger visual separation
- supportive/reassuring copy may be too weak
- premium calm fintech feeling may be inconsistent with other auth screens

## 4. Target Design Direction

Forgot Password transformation should follow:

- premium calm fintech
- light mode first
- slate/off-white canvas
- medium glass recovery form card
- Coral Default accent
- clear recovery flow hierarchy
- readable form fields and status text
- calm and reassuring tone
- no banking/payment/wallet visuals
- no dashboard preview

## 5. Layout Hierarchy

Use this hierarchy:

1. Lightweight brand/header area
2. Screen title
3. Short supportive subtitle
4. Recovery input field(s) that already exist
5. Main reset action CTA
6. Existing back/sign-in action if present
7. Existing legal/help text/links if present

## 6. Components to Use

Map Forgot Password to shared components:

- `AppBackground`
- `BudgetHeader` or lightweight brand header
- `GlassCard`
- `PrimaryCTAButton`
- `SecondaryCTAButton` if needed
- `StatusBadge` only for validation/status if already present
- `BudgetBottomTabBar` must not be used

## 7. Form Rules

- Keep existing forgot password fields only.
- Do not add new fields.
- Do not remove required existing fields.
- Preserve existing validation/error behavior if present.
- Preserve keyboard/content type behavior where possible.
- Keep input fields readable and accessible.
- Do not change recovery/auth logic.

## 8. CTA Rules

- Main reset CTA should be clear and visually dominant.
- Back/sign-in link should remain secondary but visible if currently present.
- Do not add new auth providers.
- Do not add extra auth steps from this screen unless already implemented.
- Do not change navigation logic.

## 9. Copy Direction

Use short, human Turkish copy.

Preferred copy:

- `Şifremi unuttum`
- `Hesabına tekrar erişmen için e-posta adresini gir.`

Rules:

- Keep copy short.
- Avoid technical jargon.
- Avoid bank/payment language.
- Avoid fear, blame, or pressure.

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
  - consistent spacing between field/help/status text
- **glass treatment**
  - medium glass form card only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surface
- **light/dark mode parity**
  - both modes remain readable and consistent

## 11. Stitch Reference Rules

- Stitch can guide spacing, calm mood, card direction, and CTA hierarchy.
- Stitch should not be copied exactly.
- Final UI must follow `DESIGN.md`, `auth_transformation.md`, `welcome_transformation.md`, `signin_transformation.md`, `register_transformation.md`, and shared components.

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

- [ ] Forgot Password feels calm, trustworthy, and premium.
- [ ] Existing recovery fields are preserved.
- [ ] Existing recovery/auth logic is preserved.
- [ ] Existing navigation is preserved.
- [ ] Main reset CTA is clear.
- [ ] Back/sign-in link remains available if present.
- [ ] No new onboarding flow is introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Shared tokens and components are used.
- [ ] Light and dark mode remain readable.
- [ ] Accessibility remains intact.
