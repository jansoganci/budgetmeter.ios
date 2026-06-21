# Widget Transformation

## 1. Purpose

This document is an implementation handoff for the BudgetMeter iOS Home Screen Widget redesign.

It is not production SwiftUI code.  
It defines WidgetKit-focused layout intent, token usage, data constraints, interaction rules, safety boundaries, and acceptance criteria.

## 2. Widget Product Role

- The widget should show BudgetMeter’s daily money pace at a glance.
- It should answer quickly whether money is moving forward, slowing down, or stable today.
- It must be simpler than the in-app Home screen.

It must not feel like:

- a dashboard
- a banking widget
- a payment widget
- a wallet widget
- a crypto widget
- an analytics card

## 3. Rejected Stitch Output

- The Google Stitch widget output should not be used.
- It was too generic, too empty, and not WidgetKit-native enough.
- The widget should be designed directly for WidgetKit constraints.

## 4. Widget Scope

- Small widget layout
- Medium widget layout
- Lock screen widget only if already exists
- Do not add new widget families unless explicitly requested later
- Do not change widget data source logic in this phase

## 5. Core Widget Hierarchy

Use this hierarchy:

1. App identity / small label
2. Hero metric: daily money pace
3. Short status label
4. Small supporting context if space allows
5. Minimal status indicator

## 6. Small Widget Rules

- one hero metric only
- no charts
- no lists
- no multiple cards
- no Pulsey
- no dense text
- selected currency must be dynamic
- readable at a glance

Preferred small widget copy:

- `Bugünkü tempo`
- `+₺120 / gün`
- `İleri gidiyorsun`

## 7. Medium Widget Rules

- one hero metric remains dominant
- one supporting line or mini secondary metric is allowed
- optional tiny trend indicator if existing data supports it
- no dense dashboard layout
- no transaction list
- no charts unless extremely minimal and already supported
- no Pulsey

Preferred medium widget copy:

- `Bugünkü tempo`
- `+₺120 / gün`
- `Bu hafta tempo dengeli görünüyor.`

## 8. Status Rules

- positive state: green/mint accent + positive label
- negative state: coral/red accent + caution label
- neutral state: slate/gray accent + neutral label
- color must not be the only signal
- include sign, label, icon, or short text
- no full green/red backgrounds

Suggested labels:

- Positive: `İleri gidiyorsun`
- Negative: `Tempo yavaşladı`
- Neutral: `Dengedesin`
- No data: `Henüz veri yok`

## 9. Token Rules

Use `DESIGN.md` as source of truth.  
Do not invent a new visual system.

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
- **Positive/negative/neutral status colors**
  - positive: `#00C853`
  - calm positive option: `#00BFA5`
  - negative: `#FF5A5F` (or `#EA4335` where semantically needed)
  - neutral: slate/gray token
- **Spacing**
  - widget padding: `16`
  - keep compact internal spacing to preserve glanceability
- **Radius**
  - widget radius: `22`
- **Typography**
  - hero number: SF Pro Rounded (28-32pt target range)
  - supporting UI text: SF Pro/system
- **Light/Dark mode parity**
  - equal readability and contrast in both modes
- **WidgetKit readability constraints**
  - no overflow-heavy text blocks
  - avoid tiny unreadable labels
  - keep hierarchy obvious in constrained sizes

## 10. Currency Rules

- no hardcoded currency symbols
- use selected user currency
- numbers must remain readable in small widget sizes
- compact formatting is allowed only if already supported or implemented safely

## 11. Data Rules

- use existing widget/app data source only
- no fake data
- no fake trend
- no fake AI insight
- no new data model
- no Core Data schema changes
- no persistence changes

## 12. Interaction Rules

- widget tap should preserve existing deep link behavior if currently present
- do not add new deep links unless explicitly requested later
- do not add interactive widget controls unless already supported

## 13. Accessibility Rules

- readable contrast in light/dark mode
- large hero number
- concise accessibility label
- no color-only meaning
- avoid tiny text
- avoid overfilled layout

## 14. Implementation Safety Rules

- no business logic changes
- no widget data source logic changes
- no app navigation changes
- no persistence changes
- no auth changes
- no subscription logic changes
- no Core Data schema changes
- no currency hardcoding
- no fake widget data
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility where possible

## 15. Acceptance Checklist

- [ ] Widget is simple and glanceable.
- [ ] Small widget has one hero metric.
- [ ] Medium widget keeps one hero metric dominant.
- [ ] Currency is dynamic.
- [ ] Positive/negative/neutral states are clear.
- [ ] No full green/red backgrounds are used.
- [ ] No Pulsey appears on the live widget surface.
- [ ] No fake data is introduced.
- [ ] No dashboard/banking/payment/wallet UI is introduced.
- [ ] Widget respects WidgetKit constraints.
- [ ] Light and dark mode are readable.
- [ ] Existing widget data and tap behavior are preserved.
