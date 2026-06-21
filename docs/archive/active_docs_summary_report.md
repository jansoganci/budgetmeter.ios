# Active Documents Summary Report

Date: 2026-06-15  
Source folder: `/Users/jans/Desktop/nexus/budgetmeter.ios/docs/active`  
Scope: Markdown planning documents only. No app source code was analyzed for this report.

## Executive Summary

The `docs/active` folder currently contains 10 active planning documents. Only two documents contain substantive planning content: `core_dashboard_plan.md` and `income_flow_plan.md`. The remaining eight documents are placeholders with the same section structure and `To define` entries.

The strongest direction across the active documents is clear: the next BudgetMeter revision should return the product focus to a simple, free, core financial pace experience. The Home dashboard should make the user's earn/lose pace immediately understandable, while the Income flow should support both recurring and one-time income through a simpler, normalized model.

The biggest planning gaps are Expense flow, onboarding, database/sync, premium strategy, widgets, savings goals, auth, and broader UI redesign. These areas exist as planning shells but do not yet contain decisions.

## Documents Reviewed

| Document | Status | Primary Theme |
|---|---:|---|
| `auth_plan.md` | Placeholder | Authentication/security planning |
| `core_dashboard_plan.md` | Substantive | Home dashboard and financial pace |
| `database_sync_plan.md` | Placeholder | Persistence, database, sync |
| `expense_flow_plan.md` | Placeholder | Expense entry flow |
| `income_flow_plan.md` | Substantive | Income entry flow and normalization |
| `onboarding_plan.md` | Placeholder | First-run user setup |
| `premium_plan.md` | Placeholder | Premium feature and gating strategy |
| `savings_goals_plan.md` | Placeholder | Savings goal experience |
| `ui_redesign_plan.md` | Placeholder | App-wide redesign |
| `widgets_plan.md` | Placeholder | Widget strategy |

## Per-Document Summary

### `auth_plan.md`

This is a planning placeholder for authentication. It contains sections for UI, user flow, services, data model, backend/database, premium rules, and open questions, but every section is marked `To define`.

Main decisions, requirements, and recommendations:
- No concrete decisions yet.
- The document implies auth/security needs a dedicated plan before implementation.

Planning category:
- Technical
- App Store-related, indirectly, because authentication can affect privacy/security review
- Product-related if auth becomes part of user trust or premium positioning

### `core_dashboard_plan.md`

This is the most important active planning document. It defines the Home dashboard as the core product experience and centers the product around a main Financial Pace card.

Main decisions:
- Home should prioritize one main Financial Pace card.
- The earn/lose meter is the top priority metric.
- The default selected time unit should be `day`.
- Time selector should support hour, day, week, and month.
- Savings progress should remain visible.
- Charts should exist on Home, but the screen must stay simple.
- The core dashboard and live money flow must remain free.

Requirements:
- Home must be read/status-first, not action-heavy.
- Users should immediately understand whether they are positive or negative.
- Dashboard calculations must support hour/day/week/month pace values.
- Dashboard should support simple chart data and savings progress display.
- Backend/database support should remain practical and scoped to dashboard needs.

Recommendations:
- Financial Health Score should stay but become secondary.
- The health concept may need a simpler status-style name.
- Home insights should be limited to practical signals: positive/negative status, biggest expense drain, savings progress, and simple period comparison.
- Deeper insights should live outside Home.

Planning category:
- Product-related
- UI/UX-related
- Technical
- Premium-related, because it explicitly says the core dashboard must remain free

### `database_sync_plan.md`

This is a placeholder for database and sync planning. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete decisions yet.
- It is a critical missing plan because both dashboard and income documents depend on backend/database support.

Planning category:
- Technical
- App Store-related, indirectly, if iCloud/CloudKit/privacy/data deletion are involved

### `expense_flow_plan.md`

This is a placeholder for expense entry planning. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete decisions yet.
- The Income Flow document says its style direction should later be reused for the Expense screen, so this placeholder is expected to mirror or complement Income Flow.

Planning category:
- Product-related
- UI/UX-related
- Technical, once data model and calculation decisions are defined

### `income_flow_plan.md`

This document defines the intended next Income flow. It is the second substantive active plan.

Main decisions:
- Income screen should be summary-first.
- Recurring and one-time income should be visually separate.
- User should first select income type.
- After income type, user chooses recurring or one-time.
- Recurring income and one-time income both belong inside the main Income module.
- All income values should normalize to daily value as the base calculation.
- Core income flow should stay free.
- Recurring income should remain core/free unless product strategy changes later.

Requirements:
- Keep the default income categories small.
- Custom income categories should be a secondary extension, not the main structure.
- Stable/variable classification should be optional and only apply to recurring income.
- Backend/database should support recurring and one-time income separately if needed.
- Stored income values must support daily normalization.

Open questions:
- Exact default category list.
- Exact summary metrics.
- Exact Core Data changes.
- ViewModel changes.
- Recurring income implementation.
- One-time income model.
- Daily normalization logic.
- Backend/database dependency.
- Implementation tasks.

Planning category:
- Product-related
- UI/UX-related
- Technical
- Premium-related, because it defines recurring income as likely free/core

### `onboarding_plan.md`

This is a placeholder for onboarding. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete decisions yet.
- The lack of onboarding decisions is notable because both dashboard and income flow depend on users entering enough initial data to make pace meaningful.

Planning category:
- Product-related
- UI/UX-related
- App Store-related, indirectly, because onboarding often covers permissions, privacy explanation, and first-run compliance messaging

### `premium_plan.md`

This is a placeholder for premium strategy. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete premium structure is defined here.
- Existing substantive docs already make two premium decisions: core dashboard must be free, and core income flow should remain free.

Planning category:
- Premium-related
- Product-related
- App Store-related, once pricing, purchase type, paywall copy, and entitlement behavior are defined

### `savings_goals_plan.md`

This is a placeholder for savings goals. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete decisions yet.
- Core dashboard plan says savings progress must remain visible on Home, so this document needs to define how the dedicated savings experience supports that dashboard module.

Planning category:
- Product-related
- UI/UX-related
- Technical
- Premium-related, depending on whether advanced/multiple goals are gated

### `ui_redesign_plan.md`

This is a placeholder for broader UI redesign. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete app-wide design system decisions yet.
- Core Dashboard and Income Flow already imply a direction: simpler, summary-first, easy to scan, minimal choices.

Planning category:
- UI/UX-related
- Product-related

### `widgets_plan.md`

This is a placeholder for widgets. All sections are `To define`.

Main decisions, requirements, and recommendations:
- No concrete decisions yet.
- Core Dashboard plan implies widgets should probably expose the same main financial pace/status concept, but this is not explicitly defined.

Planning category:
- Product-related
- UI/UX-related
- Technical
- Premium-related, if widgets are gated
- App Store-related, because widget extensions require target/capability/configuration planning

## Main Decisions Across Documents

The active documents currently establish these decisions:

1. BudgetMeter's next revision should prioritize the Financial Pace concept.
2. Home should be read/status-first, not a dense action hub.
3. The earn/lose meter should be the most important dashboard metric.
4. Hour/day/week/month pace switching is required, with day as the default.
5. The Home dashboard and live money flow should remain free.
6. Financial Health Score should be secondary, lightweight, and possibly renamed into a simpler status concept.
7. Home insights should be limited and practical, not a full analytics surface.
8. Income should become summary-first.
9. Income should support recurring and one-time entries inside the main flow.
10. Income values should normalize to daily value as the base calculation.
11. Default categories should stay small.
12. Custom categories should be secondary, not the primary entry model.
13. Recurring income should likely remain free/core.

## Requirements and Recommendations

### Product Requirements

- Recenter the product around live financial pace.
- Keep the core value usable without premium.
- Make Home instantly answer whether the user is gaining or losing money.
- Support both recurring and one-time income in the main Income flow.
- Keep Home insight scope narrow and actionable.
- Avoid making category management the primary user experience.

### UI/UX Requirements

- Home must be simple, scan-friendly, and low-choice.
- Financial Pace card should be visually dominant.
- Hour/day/week/month selector should be simple.
- Income entry should be progressive: income type first, recurring/one-time second.
- Recurring and one-time income should be visually separate.
- Savings progress should be visible but not overwhelm the main pace metric.
- Health score should be a small secondary status.

### Technical Requirements

- Implement pace calculations across hour/day/week/month.
- Generate chart data suitable for Home without overbuilding backend scope.
- Normalize all income entries to daily value.
- Introduce or adapt data structures for recurring and one-time income.
- Define Core Data changes before implementation.
- Define database/sync behavior before touching persistence.

### Premium Requirements

- Core dashboard remains free.
- Live money flow remains free.
- Core income flow remains free.
- Recurring income likely remains free unless later product direction changes.
- Premium strategy remains mostly undefined and needs a dedicated plan.

### App Store Requirements

No active document directly defines App Store requirements. However, the placeholders imply future planning is needed for:

- Premium purchase positioning and paywall compliance.
- Widget extension behavior if widgets become part of the revision.
- Auth/privacy messaging if authentication changes.
- Database/sync privacy and data deletion expectations.
- Onboarding copy for permissions, financial data privacy, and user trust.

## Contradictions and Overlaps

### Contradictions

There are no direct contradictions between substantive documents. The existing content is directionally consistent.

Potential future contradiction to watch:
- `core_dashboard_plan.md` says Home should not feel action-heavy.
- A future onboarding, income, expense, or savings plan might try to put too many entry points on Home. This would conflict with the Home direction.

Potential premium contradiction to watch:
- `core_dashboard_plan.md` says the main dashboard and live money flow must be free.
- `income_flow_plan.md` says recurring income should remain core/free unless strategy changes.
- A future `premium_plan.md` should not gate these without explicitly revisiting those decisions.

### Overlaps

Dashboard and Income overlap on calculation architecture:
- Dashboard needs pace values across time periods.
- Income requires daily normalization.
- These should converge into one calculation model rather than separate formulas.

Dashboard and Savings Goals overlap on Home presentation:
- Dashboard plan requires savings progress to stay visible.
- Savings Goals plan is empty and should define what data Home needs from savings.

Income and Expense overlap by intended design:
- Income Flow states its structure should support the same style direction later used for Expense.
- Expense Flow is empty, so Income Flow currently acts as the template.

Dashboard and Widgets likely overlap:
- Widgets plan is empty, but widget value should probably mirror Home's primary financial pace/status.

Premium overlaps with almost every plan:
- Dashboard and Income already make free/core decisions.
- Savings, widgets, insights, custom categories, and auth may later need premium rules.
- Premium plan must consolidate these instead of defining gates independently.

Database Sync overlaps with all feature plans:
- Dashboard charts, income recurring/one-time support, savings progress, widgets, and premium entitlement state all require persistence decisions.

## Category Mapping

### Product-Related Items

- Financial Pace as the core value proposition.
- Home as read/status-first.
- Positive/negative status clarity.
- Limited practical Home insights.
- Income flow supporting recurring and one-time income.
- Small default category set.
- Custom categories as secondary.
- Savings progress visible on Home.
- Future onboarding, expense flow, widgets, premium, and savings goals plans.

### UI/UX-Related Items

- Main Financial Pace card.
- Simple time selector: hour/day/week/month.
- Day as default time unit.
- Summary-first Income screen.
- Separate visual treatment for recurring vs one-time income.
- Simple, scan-friendly Home.
- Secondary health indicator.
- Reduced complexity and fewer choices.

### Technical Items

- Live money flow calculations.
- Pace calculations by interval.
- Dashboard chart data source.
- Daily normalization.
- Recurring income implementation.
- One-time income model.
- Core Data changes.
- Backend/database dependency.
- Widget technical plan.
- Auth technical plan.
- Database/sync technical plan.

### Premium-Related Items

- Core dashboard must remain free.
- Live money flow must remain free.
- Core income flow must remain free.
- Recurring income should remain core/free unless intentionally changed.
- Premium plan is currently undefined and must reconcile all feature-level premium assumptions.

### App Store-Related Items

- Not explicitly defined in active docs.
- Future implications include premium/paywall compliance, widget extension setup, privacy/data handling, auth messaging, sync/data deletion expectations, and onboarding disclosures.

## Implications for the Next BudgetMeter Revision

### Revision Direction

The next revision should be treated as a product refocus, not just a UI refresh. The active docs imply BudgetMeter should move away from feeling like a generic budgeting suite and toward a clear financial pace product:

- "Am I gaining or losing money?"
- "How fast?"
- "Over which period?"
- "What is the simplest next signal I need?"

### Recommended Planning Order

1. Finalize the Core Dashboard plan.
2. Finalize the shared calculation model for pace and daily normalization.
3. Finish Income Flow details.
4. Create the matching Expense Flow plan using Income Flow as the template.
5. Define Database/Sync changes before implementation.
6. Define Savings Goals integration with Home.
7. Define Premium rules after core/free boundaries are confirmed.
8. Define Onboarding after the required first-run data model is known.
9. Define Widgets after the new dashboard data contract is stable.
10. Define Auth last unless it is required for App Store/privacy positioning.

### Implementation Implications

- Home should be redesigned around a dominant Financial Pace card.
- Existing health score should be reduced in prominence.
- Charts should be practical and limited to Home's main status needs.
- Income data model likely needs a clearer distinction between recurring and one-time entries.
- Daily normalization should become a shared calculation primitive.
- Expense Flow should not be designed independently from Income Flow.
- Premium gates should be reviewed to avoid blocking the core product value.
- Database/sync work should be planned before modifying persistence.

### Key Open Risks

- Most active planning files are still empty placeholders.
- There is no explicit App Store readiness plan in `docs/active`.
- Database/sync implications are not yet defined even though other plans depend on them.
- Premium strategy is not defined, but feature-level docs already make free/core assumptions.
- Expense Flow is empty, creating a gap in the main budgeting loop.
- Widgets and savings goals are not yet tied to the new Financial Pace strategy.

## Recommended Next Actions

1. Convert `database_sync_plan.md` from placeholder to a real technical plan before model changes.
2. Expand `expense_flow_plan.md` using the Income Flow structure as the baseline.
3. Decide the exact Home dashboard metrics and chart data source.
4. Define the shared calculation contract: daily normalization, interval pace, one-time handling, recurring handling.
5. Write a premium gating matrix that explicitly marks core/free vs premium features.
6. Define the minimum onboarding questions required to make the first dashboard useful.
7. Clarify whether widgets are free, premium, or mixed.
8. Add an active App Store readiness plan or merge App Store requirements into each feature plan.

## Bottom Line

The active documents point to a strong next revision: simplify the app around the Financial Pace idea, keep the core value free, and rebuild income/expense data entry around clearer recurring and one-time flows. The direction is coherent, but most supporting plans are still empty. Before implementation, the team should fill the technical, premium, expense, sync, onboarding, and App Store gaps so the revision does not become a collection of disconnected feature edits.
