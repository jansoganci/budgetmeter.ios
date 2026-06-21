# Home Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Home screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines the Home transformation intent, component usage, token constraints, safety boundaries, and acceptance criteria.

## 2. Home Screen Product Role

Home is the most important product screen in BudgetMeter.

Its core job is to answer one question fast:

> Am I moving forward or slowing down today?

BudgetMeter is a money pace app.  
Home must not feel like:

- a banking dashboard
- a payment app
- a wallet app
- a crypto app
- an accounting ledger
- a dense analytics dashboard

## 3. Current Problem Summary

Likely current Home screen issues to resolve:

- too dashboard-like in presentation
- too visually noisy in some sections
- weak daily money pace hierarchy
- too many competing metrics on first glance
- old dark/glow-heavy visual habits in certain states
- insufficient premium calm fintech feeling

## 4. Target Design Direction

Home transformation should follow these rules:

- premium calm fintech
- simple before decorative
- daily money pace as hero
- spacious layout with clear breathing room
- medium glass cards for elevated surfaces
- slate/off-white canvas foundation
- Coral Default as brand accent baseline
- positive/negative colors as accents only (not full-surface fills)
- SF Pro Rounded-style financial numbers
- light/dark mode parity
- no fake banking/payment/wallet visuals

## 5. Layout Hierarchy

Use this screen hierarchy:

1. Header / greeting area
2. Daily money pace hero card
3. Short status explanation
4. Key secondary metrics
5. Quick actions
6. Recent activity or compact summaries if already present

The daily money pace hero must be the most dominant element on the screen.

## 6. Components to Use

Map Home to shared components:

- `AppBackground`
- `BudgetHeader`
- `MoneyPaceHeroCard`
- `SummaryHeroCard` if needed
- `MetricCard`
- `SectionHeader`
- `FinanceListRow` if recent activity exists
- `PrimaryCTAButton` / `SecondaryCTAButton` if actions exist
- `StatusBadge`
- `ChartCard` only if a chart already exists and remains simple
- `BudgetBottomTabBar` only if the current app already uses tab navigation

## 7. Money Pace Hero Rules

- Show one main hero value only.
- Currency must be dynamic from selected user currency.
- Do not hardcode currency symbols.
- Positive, negative, and neutral states must be visually distinct.
- Color must not be the only signal (pair with sign, icon, and/or short text).
- Include short explanation text under the hero value.
- Do not place Pulsey inside the primary financial metric area.

Preferred copy:

- `Bugünkü tempo`
- `Paran bugün ileri mi gidiyor, yavaşlıyor mu?`

## 8. Quick Actions Rules

- Quick actions should be accessible but secondary to the pace hero.
- Action buttons must not compete with the hero metric.
- Use existing actions only.
- Do not create new business logic.
- Do not create fake banking/payment actions.

## 9. Recent Activity / Summary Rules

- Show this section only if already present in the current Home screen.
- Keep it compact and calm.
- Avoid dense transaction tables.
- Use `FinanceListRow` for list-style items where needed.
- Do not add fake transactions.

## 10. Token Rules

Apply Home transformation with approved token rules:

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
- **Status accents**
  - positive: `#00C853`
  - calm positive option: `#00BFA5`
  - negative: `#FF5A5F` (or `#EA4335` where semantically needed)
- **Spacing**
  - screen horizontal: `16` (dashboard-specific `20` only if needed)
  - section gap: `20`
  - card padding: `16`
  - card gap: `12`
  - row height: `48`
  - button height: `52`
- **Radius**
  - card: `20`
  - button: `14`
  - modal: `24`
- **Typography**
  - SF Pro Rounded for financial numbers
  - SF Pro/system for normal UI text
- **Glass treatment**
  - medium glass only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surface
- **Light/Dark parity**
  - equal quality and readability in both modes

## 11. Stitch Reference Rules

- The latest Stitch Home output can guide spacing, hierarchy, and overall calm mood.
- It must not be copied exactly.
- Bottom tab treatment, icon polish, and typography may need stronger premium refinement in final implementation.
- Final UI must follow `DESIGN.md` and shared components, not Stitch pixel output.

## 12. Implementation Safety Rules

- no business logic changes
- no navigation changes
- no persistence changes
- no auth changes
- no subscription logic changes
- no Core Data schema changes
- no currency hardcoding
- no fake transactions
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility labels where possible

## 13. Acceptance Checklist

- [ ] Home clearly answers whether money is moving forward or slowing down today.
- [ ] Daily money pace is the visual hero.
- [ ] Screen follows `DESIGN.md`.
- [ ] Shared components are used.
- [ ] Light and dark mode are supported.
- [ ] Currency is dynamic.
- [ ] No dashboard clutter is introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Existing navigation and logic are preserved.
- [ ] Accessibility remains intact.
