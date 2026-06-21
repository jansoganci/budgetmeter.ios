Phase 7 Premium Cleanup — Gap Analysis for Codex.

You are analyzing the BudgetMeter iOS codebase. The project is at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Background

Phase 7 implemented a `BudgetMeterCapability` matrix in `PremiumManager.swift` with 22 capabilities. Two of them are marked `.premium` in the matrix but are NOT gated in the actual UI/service code:

### Gap 1: `subscriptionTracking` — Expense screen subscriptions section
- The matrix says `subscriptionTracking` is `.premium`
- But on the Expense screen, the subscriptions section is visible and accessible to free users
- Need to wrap the subscriptions section with a premium gate

### Gap 2: `recurringAutomation` — BackgroundProcessingService
- The matrix says `recurringAutomation` is `.premium`
- But `BackgroundProcessingService` runs recurring transaction automation without checking premium status
- Need to add a premium check before running automation

## Your Task (READ ONLY — do not modify any files)

1. Read `CoreKit/Sources/Premium/PremiumManager.swift` to understand how `hasAccess(to:)` works and how `BudgetMeterCapability` is defined

2. Read these files to understand the subscription tracking on Expense screen:
   - `Features/ExpensesFeature/View/ExpenseView.swift` — find the subscriptions section
   - `Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift` — subscription data loading

3. Read these files to understand recurring automation:
   - Search for `BackgroundProcessingService` — find where recurring automation is triggered
   - Read the relevant service file that handles recurring transaction generation

4. For each gap, produce a brief analysis:
   - Where exactly is the gate missing?
   - Which file, which function, which line?
   - How should the premium check be added? (exact pattern from existing gates)
   - What is the risk of NOT fixing this? (can free users actually use the feature, or is it theoretical?)

Output a structured analysis to `.hermes/tmp/phase7-gap-analysis.md` with:
- Executive summary
- Gap 1: subscriptionTracking — exact location, impact, fix approach
- Gap 2: recurringAutomation — exact location, impact, fix approach
- Recommended implementation order
