# Active Docs Completion Summary

Date: 2026-06-15

## Completed Documents

- `docs/active/auth_plan.md`
- `docs/active/database_sync_plan.md`
- `docs/active/expense_flow_plan.md`
- `docs/active/onboarding_plan.md`
- `docs/active/premium_plan.md`
- `docs/active/savings_goals_plan.md`
- `docs/active/ui_redesign_plan.md`
- `docs/active/widgets_plan.md`

Already-filled reference documents were not changed:

- `docs/active/core_dashboard_plan.md`
- `docs/active/income_flow_plan.md`

## Main Decisions Added

- Auth should only be introduced if sync, backup, or cross-device access requires it.
- The app should support local-first use unless the database/sync strategy says otherwise.
- Database and sync should serve the financial pace product, not turn the app into heavy accounting.
- Supabase is the preferred cloud option if auth, sync, and cloud storage are needed.
- Expense Flow should mirror Income Flow with a simple split between regular/fixed and surprise/one-time expenses.
- Basic fixed vs surprise expense tracking should remain free.
- Onboarding should be short, optional where possible, and focused on making the first dashboard useful.
- Premium should be positioned as a one-time lifetime purchase unless product direction changes.
- Free product value remains income entry, expense entry, core dashboard, net result, money pace, and basic savings target.
- Premium adds deeper control, convenience, insights, widgets, export, biometric lock, themes, history, forecasting, sync, and backup.
- Savings goals should stay simple and focused on savings speed and timeline.
- UI redesign should center the whole app around the Financial Pace concept.
- Widgets should be simple, glanceable extensions of the Home dashboard's financial pace/status idea.

## Remaining Open Questions

- Is auth needed for the next revision, or only for a future sync/backup release?
- Will the app stay local-first or introduce optional cloud sync?
- Will Supabase be used for sync/auth/storage?
- What are the exact Core Data changes for income, expense, savings, and history?
- What is the exact recurring vs one-time model for income and expense?
- How should bills and subscriptions relate to the main Expense Flow?
- Which recurring automation features are free vs premium?
- Is the final premium offer definitely lifetime one-time purchase?
- Will RevenueCat be used or direct StoreKit handling remain enough?
- Are widgets fully premium, or should one basic status widget be free?
- Should savings goals support one basic target or multiple goals in the next revision?
- What is the exact onboarding question set and screen order?
- What is the final UI style direction and navigation structure?

## Contradictions Or Risks Found

- The main plan lists recurring transactions under Premium, while `income_flow_plan.md` keeps recurring income inside the core Income Flow unless product direction changes. This needs a split between basic recurring entry and premium automation.
- Widgets are listed as Premium in the main plan, but widgets also naturally extend the core Financial Pace value. The final premium matrix should decide whether any basic widget remains free.
- Auth is planned only if sync/backup/cross-device access is needed, while onboarding says it should be defined after auth. If the next revision stays local-first, onboarding should still exist as lightweight first-run setup without account auth.
- Database/sync decisions affect many plans. Implementation should not begin on auth, widgets, sync, or history until the local-first vs cloud-sync direction is decided.
- Savings goals are part of the free core value at a basic level, but existing product inventory includes richer savings goals. The final scope should distinguish basic savings target from advanced goal management.
