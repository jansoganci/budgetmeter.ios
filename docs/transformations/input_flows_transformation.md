# Input Flows Transformation

## 1. Purpose

This document is an implementation handoff for transforming BudgetMeter input modals/sheets into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines structure, component usage, copy direction, token constraints, safety boundaries, and acceptance criteria for input flows.

## 2. Input Flow Product Role

- Input flows are where users add or edit the data that powers BudgetMeter.
- They should feel fast, calm, and low-friction.

They should not feel like:

- accounting forms
- banking forms
- payment flows
- wallet setup
- enterprise finance tools

## 3. Covered Screens / Flows

- Set Goal
- Add Income
- Add Expense
- Edit Income (if present)
- Edit Expense (if present)
- Shared amount/date/category/name input patterns already in the app

## 4. Shared Modal / Sheet Rules

- Use iOS-native sheet/modal behavior.
- Use medium glass or elevated surface treatment.
- Keep a clear title.
- Use short helper text only if needed.
- Keep form fields readable and scannable.
- Keep a clear primary CTA.
- Keep a clear cancel/back action.
- Avoid dense forms.
- No dashboard previews.
- No banking/payment/wallet visuals.
- No Pulsey in these modals unless later explicitly requested for empty/support states.

## 5. Set Goal Rules

Example goal context: user may enter a target like saving 100,000 USD.

- Include goal amount input.
- Selected currency must be dynamic.
- No hardcoded currency symbols.
- Include optional goal name only if already present.
- Include optional target date only if already present.
- Main CTA should be clear.
- Do not add investment, bank, or savings account logic.
- Do not add fake forecasting unless already implemented.

Preferred copy:

- `Hedef belirle`
- `Ne kadar biriktirmek istiyorsun?`

## 6. Add Income Rules

- Include amount input.
- Include income name/source input if present.
- Include recurring/one-time selector if present.
- Include date/frequency controls if present.
- Use green/mint only as accent.
- Preserve existing data model and save logic.
- No payroll/accounting UI.

Preferred copy:

- `Gelir ekle`
- `İçeri giren parayı kaydet.`

## 7. Add Expense Rules

- Include amount input.
- Include expense name/category input if present.
- Include recurring/one-time selector if present.
- Include date/frequency controls if present.
- Use coral/red only as accent.
- Keep tone calm and non-judgmental.
- Preserve existing data model and save logic.
- No payment/banking UI.

Preferred copy:

- `Gider ekle`
- `Paranın nereye aktığını kaydet.`

## 8. Form Field Rules

- Amount fields should use financial number styling where appropriate.
- Currency should come from selected user currency.
- No hardcoded symbols.
- Field labels must be short.
- Validation errors must be clear and calm.
- Keyboard/content type behavior should be preserved.
- Dynamic Type should remain readable.

## 9. Component Mapping

Use or define:

- `AppBackground` where applicable
- `GlassCard` or modal surface equivalent
- `SectionHeader` if needed
- `PrimaryCTAButton`
- `SecondaryCTAButton`
- `StatusBadge` for validation/success/error if already present
- `FinanceListRow` only if selector rows already exist
- Do not use `BudgetBottomTabBar` inside modals

## 10. Token Rules

Apply approved token rules:

- **modal background/surface**
  - base canvas: `#F8FAFC` (light) / `#0F172A` (dark)
  - elevated surface: `#FFFFFF` (light) / `#1E293B` (dark)
- **elevated surfaces**
  - use opaque elevated fallback where needed
- **text colors**
  - primary: `#0F172A` / `#F8FAFC`
  - secondary: `#64748B` / `#94A3B8`
  - tertiary: `#94A3B8` / `#64748B`
- **Coral Default accent**
  - `#FF5A5F`
- **green/mint income accent**
  - `#00C853`
  - calm option: `#00BFA5`
- **coral/red expense accent**
  - `#FF5A5F`
  - alternative red where needed: `#EA4335`
- **spacing**
  - screen horizontal: `16`
  - section gap: `20`
  - card/modal padding: `16` (or modal-specific `24` when needed)
  - card gap: `12`
  - button height: `52`
- **radius**
  - card: `20`
  - button: `14`
  - modal: `24`
- **typography**
  - SF Pro/system for general UI text
  - SF Pro Rounded for financial numbers where appropriate
- **input styling**
  - clear boundaries
  - readable contrast
  - consistent label/help/error spacing
- **glass treatment**
  - medium glass only
  - subtle border + soft shadow
  - Reduce Transparency fallback to elevated opaque surface
- **light/dark mode parity**
  - equal readability and polish in both modes

## 11. Implementation Safety Rules

- no business logic changes
- no save logic changes
- no validation logic changes unless explicitly requested later
- no data model changes
- no Core Data schema changes
- no navigation changes
- no auth changes
- no subscription logic changes
- no currency hardcoding
- no fake data
- no fake forecasting
- no fake banking/payment/wallet UI
- no unrelated refactors
- preserve accessibility labels where possible

## 12. Acceptance Checklist

- [ ] Set Goal, Add Income, and Add Expense feel visually aligned.
- [ ] Modals/sheets feel native, calm, and premium.
- [ ] Fields are readable and accessible.
- [ ] Primary CTAs are clear.
- [ ] Currency is dynamic.
- [ ] Save behavior is preserved.
- [ ] Existing data models are preserved.
- [ ] No banking/payment/accounting UI is introduced.
- [ ] Light and dark mode are supported.
- [ ] Accessibility remains intact.
