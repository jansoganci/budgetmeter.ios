# BudgetMeter Product Decisions v1

This document resolves the open planning blockers across the active planning documents. It defines the product contract for the next BudgetMeter revision.

BudgetMeter remains a financial pace app. The product should answer: "Am I financially moving forward or backward, and how fast?" It should not become a heavy budgeting, accounting, or envelope-management app.

## 0. Brand And UI Direction

### Decision

BudgetMeter will use a **Playful Momentum FinTech** direction.

The app should feel fun, gamified, consumer-friendly, and modern while still feeling trustworthy, polished, readable, and useful.

BudgetMeter should not feel childish, casino-like, or like a heavy accounting app.

### Pulsey Mascot

The mascot direction is selected: **Pulsey**.

Pulsey is a small abstract finance creature. Pulsey represents momentum, pulse, financial heartbeat, and forward motion.

Pulsey should be cute but not childish. Pulsey should feel calm, positive, encouraging, and trustworthy.

Pulsey appears mainly during the app launch splash animation for about 3 seconds. Pulsey may later appear lightly in onboarding, empty states, success states, weekly recap, and milestone moments.

Pulsey must not dominate the Home dashboard, slow down transaction entry, or joke about negative financial states or user money stress.

### Visual Identity

BudgetMeter is dark-first.

The visual system should use:

- Obsidian / dark navy background
- Slate card surfaces
- Lively accent colors, not pale tones
- Vivid cyan / blue / indigo as the main accent family
- Emerald / green for positive momentum
- Amber for caution
- Coral for negative drain

The visual system should avoid obvious AI-looking purple/pink gradient overuse, childish pastel overload, and casino-style gold glow.

Modern iOS glass / Liquid Glass styling can be used carefully for navigation, sheets, overlays, and secondary surfaces. Critical financial numbers should appear on solid or near-solid readable surfaces.

### Gamification

v1 gamification includes:

- Momentum ring
- Haptic feedback after successful entry
- Small success animation after entry
- Savings milestone
- Awareness streak
- Simple weekly recap

Awareness streak should track regular check-ins / money awareness, not financial success or wealth.

Gamification must reward awareness, consistency, and improvement. It must never shame users for bad financial days.

## 1. Shared Financial Data Model

### Decision

All core surfaces must read from the same financial data model and the same aggregation logic.

Home, income, expenses, savings, charts, and widgets should not calculate money pace independently. They should consume the same normalized financial summary generated from the user's income and expense entries.

### Income Types

Income has two product-level types:

1. Recurring income
   - Predictable income that repeats on a schedule.
   - Examples: salary, regular freelance retainer, rental income, pension, predictable passive income.
   - Included in the ongoing financial pace while active.
   - Basic recurring income entry is free.

2. One-time income
   - Dated income that does not repeat.
   - Examples: bonus, gift, one-off freelance payment, refund, sale of an item.
   - Included in the period where it occurs.
   - Included in history and charts.
   - Not treated as permanent ongoing pace after its period ends.

### Expense Types

Expenses have two product-level types:

1. Fixed / regular expense
   - Predictable expense that repeats or is expected.
   - Examples: rent, mortgage, insurance, phone bill, subscription, loan payment.
   - Included in the ongoing expense pace while active.
   - Basic fixed / regular expense entry is free.

2. Surprise / one-time expense
   - Dated expense that is not expected to repeat.
   - Examples: repair, medical payment, emergency purchase, one-off shopping, travel cost.
   - Included in the period where it occurs.
   - Included in history and charts.
   - Not treated as permanent ongoing pace after its period ends.

### Daily Normalization Rules

Recurring entries are normalized to a daily base before any pace value is shown.

| Frequency | Daily value |
| --- | --- |
| Daily | `amount` |
| Weekly | `amount / 7` |
| Monthly | `amount / 30.4375` |
| Yearly | `amount / 365.25` |

Derived pace values come from the daily value:

| Pace | Formula |
| --- | --- |
| Per minute | `daily / 1440` |
| Per hour | `daily / 24` |
| Per day | `daily` |
| Per week | `daily * 7` |
| Per month | `daily * 30.4375` |

One-time entries are not normalized into the ongoing baseline. They are assigned to their occurrence date and included in the selected period total. If a period average is needed, the one-time total may be divided by the number of days in that selected period, but only for that period's view.

### Shared Read Model

The app should expose one shared financial summary for product surfaces.

The summary should include:

- Total recurring income pace
- Total recurring expense pace
- Net recurring pace
- One-time income for the selected period
- One-time expenses for the selected period
- Net result for the selected period
- Biggest drain for the selected period
- Savings target progress
- Chart series for the selected period range
- Previous-period comparison where enough data exists

### Surface Usage

Home reads the shared summary and shows the current financial status first.

Savings reads the same net pace and uses it to estimate time to target.

Charts read the same period totals and summaries used by Home.

Widgets read the same Home summary. Widgets must not introduce separate calculations or simplified formulas that can disagree with the app.

## 2. Free vs Premium Matrix

### Decision

The core financial pace loop stays free. Premium adds convenience, deeper control, automation, widgets, sync, export, security, appearance, and advanced insights.

| Area | Free | Premium |
| --- | --- | --- |
| Income entry | One-time income and basic recurring income entry | Advanced recurring income management and automation |
| Expense entry | One-time expenses and basic fixed / regular expenses | Advanced recurring expense automation, bill/subscription management, reminders, richer controls |
| Core dashboard | Net result, financial pace, positive/negative status, basic biggest drain, basic comparison | Advanced insights, richer comparisons, deeper explanations |
| Pace intervals | Hour, day, week, month, plus minute as a small live secondary metric | Advanced forecasting and history-based pace analysis |
| Savings | One basic savings target with estimated timeline | Multiple goals, advanced goal tracking, history, target dates, forecasting |
| Widgets | No widget access in v1 premium boundary | Premium Home Screen `systemSmall` widget only (v1) |
| Sync / backup | Local-only usage | Cloud sync and backup |
| Export | Not included | Data export |
| Security | Standard device/app behavior | Biometric lock |
| Themes / personalization | Polished default theme | Controlled accent packs, premium themes, app icon variants, chart style options, Pulsey accent variants |
| History / reports | Basic recent history needed for dashboard and charts | Advanced history and reporting |
| Forecasting | Basic end-of-period estimate only if available from local data | Advanced forecasting |
| Ads | No ads in v1 | Ads-free may exist as a future premium benefit after ads are introduced |
| Categories | Default categories | Custom categories |

### Recurring Entry vs Recurring Automation

Basic recurring income and basic fixed / regular expense entry are free because they are required for the core money pace calculation.

Premium owns recurring automation:

- Due-date handling
- Renewal tracking
- Reminders
- Auto-generated period records
- Advanced recurring rules
- Bill and subscription management beyond simple recurring expense entry

### Widgets Boundary

Widgets are premium in this revision.

The free product already gives the full core value inside the app. Widgets are treated as convenience and ambient access, so they fit the premium layer.

v1 widget scope is fixed:

- Home Screen `systemSmall` only
- Show net daily pace status + value
- Deep link to Home hero section
- Premium-gated with locked teaser state for non-premium users
- No lock screen widgets in v1
- No medium widgets in v1
- No complex charts in v1
- Pulsey should not appear in v1 widget except a tiny static brand mark if trivial

### Savings Boundary

Free includes one basic savings target:

- Target amount
- Optional current saved amount
- Estimated time to target based on shared Home net pace
- If current saved amount is unavailable, use `0`
- Default baseline uses daily net pace from shared calculation outputs
- Display can be shown in days/weeks/months for readability

The current app already contains savings goal entry surfaces. Redesign may improve UX, but should preserve user ability to enter a goal and get a timeline estimate.

Premium includes advanced savings goals:

- Multiple goals
- Target dates
- Goal history
- Goal forecasting
- More detailed progress views

### Sync / Backup Boundary

The app should keep a local-first user experience. Local-only use is free.

Cloud sync and cloud backup are planned premium features. Authentication exists to support stable user identity, backup, restore, and future cross-device access.

Apple Sign In is the preferred auth method for iOS.

Supabase is the preferred backend/database platform for user-linked financial data.

Ads are deferred for v1. Ad-related monetization decisions are postponed.

## 3. Architecture Direction

### Decision

The next BudgetMeter revision should use a local-first UX with Supabase-backed cloud backup/sync as part of the product direction.

Local persistence remains the fast app experience. The product should work for free users without an account, without network access, and without cloud setup.

Premium users should be able to unlock cloud backup/sync. That requires auth, stable user identity, and user-linked financial data.

CloudKit is current/legacy infrastructure in the existing app and will be removed after audit + migration planning. It is not the long-term sync system.

Do not keep both CloudKit and Supabase as long-term parallel sync systems unless a strong reason is explicitly documented.

### Cloud Sync and Auth

Cloud sync and authentication are planned.

Auth should support:

- Stable user identity
- Cloud backup
- Restore
- Future cross-device access

Stable user identity should come from authenticated account identity, not random local-only identifiers.

Apple Sign In is the preferred auth method for iOS.

Auth should stay simple:

- Sign in
- Sign out
- Restore session

Email/password should be avoided for now unless explicitly needed later.

Auth should not block local free usage. Free users can keep using BudgetMeter locally without signing in.

### Supabase

Supabase is the preferred backend/database platform.

Supabase should support user-linked financial data for premium cloud backup, restore, and future cross-device access.
Supabase Auth with Apple Sign In is the target auth approach.
Supabase database is the target cloud data layer for user-linked financial records.
Supabase Edge Functions should be used only if needed for secure backend logic.

Detailed Supabase schema, migrations, RLS, and conflict handling are technical planning later. Product planning should not invent those details yet.

CloudKit removal requires migration safety planning so live user data is not lost.

### StoreKit vs RevenueCat

StoreKit is preferred for now.

The current premium direction is a one-time lifetime purchase, and StoreKit is sufficient for that scope. RevenueCat can be reconsidered later if the app moves toward subscriptions, more complex entitlement management, cross-platform entitlement sync, or remote paywall experimentation.

### Persistence Direction

The current iOS codebase should keep local persistence as the fast local layer.

The data model should be designed so user financial data can sync across devices in the future. Each signed-in user must have a stable user ID.

CoreData can remain local storage while Supabase becomes the cloud backup/sync layer.

No self-managed VPS should be introduced for BudgetMeter data.

## 4. Home Dashboard Data Contract

### Decision

Home is the product's primary surface. It must show financial status first, not lists or budgeting tools.

The Home dashboard should consume a shared financial summary with a clear contract.

### Pace Intervals

Home supports these pace intervals:

- Minute
- Hour
- Day
- Week
- Month

The default Home view should emphasize Day because it is the easiest to understand quickly.

Hour, week, and month should be available as primary comparison intervals. Minute should appear as a small live secondary pace value, not the main default tab.

### Required Home Metrics

Home should show:

- Net financial pace
- Income pace
- Expense pace
- Positive or negative status
- Gentle status copy such as "Moving forward: +$12/day" or "Slowing down"
- Selected interval value
- Small live minute value where useful
- Current period net result
- Biggest drain
- Savings target progress
- Basic chart
- Current period vs previous equivalent period comparison
- Awareness streak
- Simple weekly recap where it does not crowd the hero

### Chart Source

Home charts must be generated from the same financial entries and period summaries as the main dashboard metrics.

Charts should not use mock, random, or independently calculated data once implementation begins.

If there is not enough history, the chart should show the available current period data and avoid fake trend claims.

### Savings Input

Home savings uses the basic savings target:

- Target amount
- Optional current saved amount
- Estimated time to target from net pace

If current saved amount is missing, it should default to zero for calculation purposes.

Savings should use the same net pace as Home. It should not have a separate hidden formula.

### Biggest Drain Calculation

Biggest drain is the highest expense category or expense source in the selected period.

For recurring expenses, the selected interval uses normalized recurring expense values.

For one-time expenses, the selected period uses the actual dated expense amount.

If both recurring and one-time expenses exist in the selected period, they should be combined by category before ranking the biggest drain.

### Period Comparison Scope

Period comparison means current selected period vs the immediately previous equivalent period.

Examples:

- Current hour vs previous hour
- Today vs yesterday
- This week vs previous week
- This month vs previous month

If there is not enough data for the previous period, Home should hide the comparison or show a clear unavailable state.

## 5. Expense Flow Integration

### Decision

Expense Flow should mirror Income Flow in structure and feed the same financial pace engine.

The app should not maintain separate financial realities for expenses, bills, subscriptions, dashboard, and widgets.

### Bills and Subscriptions

Bills and subscriptions are specialized fixed / regular expenses.

They should roll up into the same expense totals, biggest drain calculation, charts, and Home pace values as other regular expenses.

In v1 product planning:

- A subscription can be entered as a basic regular expense for free.
- A bill can be entered as a basic regular expense for free.
- Dedicated subscription management, bill management, reminders, renewal tracking, and automation are premium.

### Recurring Expense Automation Boundary

Free recurring expense support means the user can enter a regular expense and have it count toward financial pace.

Premium recurring expense automation means the app adds convenience and control around that recurring expense.

Premium automation includes:

- Reminders
- Due dates
- Renewal awareness
- Bill/subscription status
- Advanced recurring rules
- Auto-generated period entries
- Advanced recurring history

### One-Time Expense Effect

One-time expenses affect the current selected period immediately.

They should:

- Reduce the current period net result
- Affect the chart bucket for their date
- Affect biggest drain for the selected period
- Affect current period comparison and forecast where applicable
- Remain visible in history

They should not:

- Become part of the permanent recurring expense baseline
- Continue reducing future long-term pace after the occurrence period ends
- Be treated as a subscription or bill unless the user converts or re-enters them as regular expenses

### Long-Term Pace Rule

Long-term pace is based on active recurring income and active recurring expenses.

One-time income and one-time expenses can affect current period reality and historical analysis, but they do not change the user's ongoing pace unless the user explicitly creates a recurring entry.

## Implementation Planning Gate

Before app-source implementation starts, planning should align around these decisions:

- One shared aggregation engine for Home, charts, savings, and widgets
- Playful Momentum FinTech as the final UI/UX direction
- Pulsey as the selected small abstract mascot
- Dark-first visual identity with vivid cyan / blue / indigo, emerald, amber, and coral accents
- Hybrid momentum ring + live financial pace number as the Home hero
- Day as the default unit and minute as a small live secondary metric
- v1 gamification: momentum ring, haptics, small success animation, savings milestone, awareness streak, simple weekly recap
- Local-first UX with Supabase-backed premium cloud backup/sync
- Apple Sign In for stable user identity
- StoreKit for the current lifetime premium scope
- RevenueCat optional later, not required now
- Basic recurring entries free, recurring automation premium
- Widgets premium
- v1 widget scope: Home Screen `systemSmall` only (premium), lock screen/medium postponed
- Basic savings target free, advanced savings goals premium
- Bills and subscriptions modeled as regular expenses with premium management features
