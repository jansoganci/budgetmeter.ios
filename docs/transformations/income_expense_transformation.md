# Income & Expense Transformation

## 1. Purpose

This document is an implementation handoff for transforming BudgetMeter Income and Expense screens into one aligned UI/UX system.

It is not production SwiftUI code.  
It defines layout alignment, shared component usage, token constraints, safety boundaries, and acceptance criteria.

## 2. Product Role

- Income helps users understand money coming in.
- Expense helps users understand money going out.
- Both screens support BudgetMeter's main money pace concept.

These screens must not feel like:

- accounting ledgers
- payroll tools
- banking dashboards
- wallet apps
- payment apps

## 3. Core Alignment Rule

Income and Expense must use the same layout structure.

Income layout is the visual base.  
Expense should reuse that structure with expense-specific copy, data, and coral/red accent treatment.

## 4. Current Problem Summary

- Income is cleaner and should be used as the base.
- Expense is less consistent and should be realigned to Income.
- Both screens need shared hierarchy, card structure, list rows, and action treatment.
- Dense accounting-table behavior must be avoided.

## 5. Shared Layout Hierarchy

Use this hierarchy for both screens:

1. Header / screen title
2. Main monthly summary hero card
3. Primary add action
4. Recurring section
5. One-time / recent section
6. Empty state if no data exists

## 6. Components to Use

Map both screens to shared components:

- `AppBackground`
- `BudgetHeader`
- `SummaryHeroCard`
- `MetricCard` if needed
- `SectionHeader`
- `FinanceListRow`
- `PrimaryCTAButton`
- `SecondaryCTAButton` if needed
- `StatusBadge` if needed
- `EmptyStateCard`
- `BudgetBottomTabBar` only if current app already uses tab navigation

## 7. Income-Specific Rules

- Use green/mint accent only as an accent.
- Preferred labels:
  - `Gelir`
  - `Aylık toplam gelir`
  - `Düzenli gelirler`
  - `Tek seferlik gelirler`
- Income tone should feel positive but calm.
- Do not make the screen look like payroll software.
- Do not add fake income data.

## 8. Expense-Specific Rules

- Use Coral Default/red accent only as an accent.
- Preferred labels:
  - `Giderler`
  - `Bu ay toplam gider`
  - `Düzenli giderler`
  - `Son harcamalar`
- Expense tone should be calm and non-judgmental.
- Do not make the screen shameful, alarming, or aggressive.
- Do not add fake expense data.
- Expense must visually match Income structure.

## 9. Add Action Rules

- Use existing add income/add expense actions only.
- Do not change business logic.
- Do not add new transaction types unless already present.
- Primary action should be clear but should not dominate the summary card.

## 10. List Row Rules

- Use `FinanceListRow` for recurring and one-time/recent items.
- Keep rows readable and calm.
- Use icon/category only if already available.
- Keep amounts aligned and currency dynamic.
- No hardcoded currency symbols.
- No dense spreadsheet/table layout.

## 11. Empty State Rules

- Use `EmptyStateCard` if no data exists.
- Empty states should be supportive and short.
- Pulsey may be documented as future emotional support, but do not implement it in this phase.
- Empty state should include one clear add action.

## 12. Token Rules

Apply transformations using approved token rules:

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
- **Income accent (green/mint)**
  - positive: `#00C853`
  - calm positive option: `#00BFA5`
- **Expense accent (coral/red)**
  - primary negative: `#FF5A5F`
  - alternative red: `#EA4335` where semantically needed
- **Spacing**
  - screen horizontal: `16`
  - optional dashboard horizontal: `20` when needed
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
  - equal readability and polish in both modes

## 13. Stitch Reference Rules

- Latest Income Stitch output is the stronger visual reference.
- Expense should be aligned to Income, not treated as a separate design language.
- Stitch should guide hierarchy and mood only.
- Stitch outputs must not be copied pixel-perfect.
- Final UI must follow `DESIGN.md` and shared components.

## 14. Implementation Safety Rules

- no business logic changes
- no navigation changes
- no persistence changes
- no auth changes
- no subscription logic changes
- no Core Data schema changes
- no currency hardcoding
- no fake income/expense data
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility labels where possible

## 15. Acceptance Checklist

- [ ] Income and Expense feel like the same product system.
- [ ] Income uses green/mint accent.
- [ ] Expense uses coral/red accent.
- [ ] Both screens use the same layout hierarchy.
- [ ] Both screens use shared components.
- [ ] Currency is dynamic.
- [ ] Empty states are supported.
- [ ] No accounting ledger/table UI is introduced.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Existing navigation and logic are preserved.
- [ ] Light/dark mode and accessibility remain intact.
