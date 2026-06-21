# Paywall Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Paywall screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines structure, component usage, copy direction, token rules, implementation safety boundaries, and acceptance criteria.

## 2. Paywall Product Role

- Paywall should present Premium as personalization and deeper clarity.
- It should not feel aggressive, manipulative, or like a hard-sell screen.
- Premium should feel like a natural upgrade for users who want themes, widgets, and deeper insights.
- It must not feel like banking, payment, crypto, trading, or enterprise finance software.

## 3. Current Problem Summary

Likely current Paywall issues:

- paywall may feel too generic
- premium value may not be clearly connected to BudgetMeter’s money pace concept
- feature list may feel visually plain
- CTA may feel either too weak or too sales-heavy
- layout may need stronger premium calm fintech polish

## 4. Target Design Direction

Paywall transformation should follow:

- premium calm fintech
- friendly but not pushy
- medium glass hero card
- slate/off-white canvas
- Coral Default accent
- clear premium value hierarchy
- short feature explanations
- soft premium visual treatment
- light/dark mode parity
- no aggressive scarcity patterns
- no fake banking/payment/wallet visuals

## 5. Layout Hierarchy

Use this hierarchy:

1. Header / premium title
2. Hero area
3. Short value proposition
4. Premium feature list
5. Price / plan section if already present
6. Main CTA
7. Restore purchase / terms / privacy links if already present

## 6. Components to Use

Map Paywall to shared components:

- `AppBackground`
- `BudgetHeader`
- `GlassCard`
- `SummaryHeroCard` if useful
- `PremiumBadge`
- `SectionHeader`
- `PrimaryCTAButton`
- `SecondaryCTAButton` if needed
- `FinanceListRow` or feature row equivalent
- `StatusBadge` only if needed

## 7. Premium Value Rules

Premium benefits should emphasize:

- premium themes
- widgets
- deeper insights
- more personal experience
- clearer money pace understanding

Do not introduce new premium features unless they already exist or are documented in `DESIGN.md`.

## 8. Feature List Rules

- Feature rows should be short and readable.
- Use calm positive language.
- No fake guarantees.
- No fake AI claims unless already implemented.
- No banking/payment/trading language.
- Icons may be used only if they stay simple and consistent.

## 9. CTA Rules

- CTA should be clear and confident.
- No manipulative urgency.
- No fake discounts.
- No countdowns.
- No “limited time” unless already implemented legally and intentionally.
- Restore purchase and legal links must remain accessible if currently present.

## 10. Pulsey Rule

- Pulsey may appear in the paywall hero/header only.
- Pulsey should not appear beside every feature row.
- Pulsey should support warmth, not distract from premium value.
- Do not implement Pulsey yet unless existing assets are available and implementation is explicitly requested later.

## 11. Copy Direction

Use short, human Turkish copy.

Preferred copy:

- `BudgetMeter’ı sana özel yap.`
- `Temalar, widget’lar ve daha derin içgörülerle devam et.`

Possible feature labels:

- `Premium temalar`
- `Ana ekran widget’ları`
- `Daha derin içgörüler`
- `Daha kişisel deneyim`

## 12. Token Rules

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
- **Premium accent treatment**
  - use accent color for CTA and key premium emphasis only
  - keep premium visuals soft and controlled
- **Spacing**
  - screen horizontal: `16`
  - section gap: `20`
  - card padding: `16`
  - card gap: `12`
  - button height: `52`
- **Radius**
  - card: `20`
  - button: `14`
  - modal: `24`
- **Typography**
  - SF Pro/system for UI copy
  - SF Pro Rounded only for financial numbers if shown
- **Glass treatment**
  - medium glass only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surfaces
- **Light/Dark parity**
  - equal readability and polish in both modes

## 13. Stitch Reference Rules

- Stitch can guide premium mood, spacing, hero treatment, and feature hierarchy.
- It should not be copied exactly.
- Final UI must follow `DESIGN.md` and shared components.

## 14. Implementation Safety Rules

- no subscription logic changes
- no purchase logic changes
- no StoreKit logic changes
- no entitlement logic changes
- no business logic changes
- no navigation changes
- no persistence changes
- no auth changes
- no Core Data schema changes
- no fake pricing
- no fake discounts
- no fake premium features
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility labels where possible

## 15. Acceptance Checklist

- [ ] Paywall feels premium but not aggressive.
- [ ] Premium value is clear.
- [ ] Premium benefits connect to BudgetMeter’s money pace concept.
- [ ] Shared components are used.
- [ ] CTA is clear and accessible.
- [ ] Restore/legal links remain accessible if present.
- [ ] Light and dark mode are supported.
- [ ] No fake pricing/discounts/features are introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Existing purchase/subscription logic is preserved.
- [ ] Accessibility remains intact.
