# Insights Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Insights screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines layout intent, component mapping, token usage, safety rules, and acceptance criteria for Insights transformation.

## 2. Insights Product Role

- Insights helps users understand money patterns calmly.
- It should explain what is changing in their money pace.
- It should support clarity, not anxiety.

Insights must not feel like:

- a dense analytics dashboard
- an accounting report
- an investment app
- a banking dashboard
- a crypto app
- a BI tool

## 3. Current Problem Summary

Likely current Insights issues:

- charts may feel too generic or too dashboard-like
- too many competing metrics can weaken clarity
- recommendations may feel disconnected from money pace
- visual hierarchy may need stronger premium polish
- bottom navigation and icon treatment may need refinement

## 4. Target Design Direction

Insights transformation should follow:

- premium calm fintech
- simple insights before complex analytics
- one clear primary insight
- calm chart presentation
- medium glass cards
- slate/off-white canvas
- fresh accent colors from `DESIGN.md`
- light/dark mode parity
- no dense dashboards
- no fake banking/payment/wallet visuals

## 5. Layout Hierarchy

Use this hierarchy:

1. Header / screen title
2. Primary insight summary card
3. Simple trend chart card
4. Spending or category breakdown if already present
5. Recommendation / observation card
6. Secondary details only if already present

## 6. Components to Use

Map Insights to shared components:

- `AppBackground`
- `BudgetHeader`
- `SummaryHeroCard`
- `ChartCard`
- `MetricCard` if needed
- `SectionHeader`
- `FinanceListRow` if list-style breakdown exists
- `StatusBadge` if needed
- `EmptyStateCard` if no insight data exists
- `BudgetBottomTabBar` only if the current app already uses tab navigation

## 7. Primary Insight Rules

- One primary insight should be visually dominant.
- Insight should explain the user’s money pace in simple language.
- Do not overload the screen with multiple hero metrics.
- Do not use fear-based language.
- Do not imply financial advice beyond available app data.

Preferred copy examples:

- `İçgörüler`
- `Parandaki değişimi sade şekilde gör.`
- `Harcama tempon bu hafta biraz hızlandı.`
- `Gelir-gider dengesi geçen haftaya göre daha sakin.`

## 8. Chart Rules

- Charts should be simple and readable.
- Use `ChartCard`.
- No dense chart grids.
- No stock/crypto-style charts.
- No excessive colors.
- Color must not be the only signal.
- Use existing chart data only.
- Do not create fake chart data.

## 9. Recommendation Card Rules

- Recommendations should be short, human, and calm.
- Recommendations must be based only on existing app data.
- They should not sound like professional financial advice.
- No aggressive warnings.
- No shame language.
- No fake AI claims unless already implemented.

## 10. Empty State Rules

- Use `EmptyStateCard` when there is not enough data.
- Empty state should explain that insights improve after more income/expense data exists.
- Pulsey may be documented as a possible future emotional support element, but do not implement it in this phase.

Preferred empty state copy:

- `Henüz yeterli veri yok.`
- `Birkaç gelir ve gider ekledikten sonra içgörülerin burada görünür.`

## 11. Token Rules

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
  - `#FF5A5F` (brand/action accent where semantically needed)
- **Green/mint positive accent**
  - `#00C853`
  - calm option: `#00BFA5`
- **Neutral slate/gray**
  - use neutral slate/gray tokens for non-positive/non-negative states
- **Spacing**
  - screen horizontal: `16`
  - optional dashboard horizontal: `20` when needed
  - section gap: `20`
  - card padding: `16`
  - card gap: `12`
  - row height: `48`
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
  - Reduce Transparency fallback to opaque elevated surfaces
- **Light/Dark parity**
  - equal readability and visual quality in both modes

## 12. Stitch Reference Rules

- Latest Insights Stitch output is a good visual reference.
- It can guide hierarchy, chart simplicity, and calm insight card direction.
- It should not be copied exactly.
- Final UI must follow `DESIGN.md` and shared components.

## 13. Implementation Safety Rules

- no business logic changes
- no analytics logic changes
- no navigation changes
- no persistence changes
- no auth changes
- no subscription logic changes
- no Core Data schema changes
- no currency hardcoding
- no fake insight data
- no fake chart data
- no fake AI labels
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility labels where possible

## 14. Acceptance Checklist

- [ ] Insights feels calm and understandable.
- [ ] One primary insight is visually dominant.
- [ ] Charts are simple and readable.
- [ ] Recommendations are short and non-judgmental.
- [ ] Screen follows `DESIGN.md`.
- [ ] Shared components are used.
- [ ] Light and dark mode are supported.
- [ ] No dense analytics dashboard is introduced.
- [ ] No fake banking/payment/crypto/wallet UI is introduced.
- [ ] Existing analytics/data logic is preserved.
- [ ] Existing navigation and logic are preserved.
- [ ] Accessibility remains intact.
