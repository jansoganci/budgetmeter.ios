# QA Migration Fixtures

Fixture IDs from `docs/implementation/phase10_release_qa_scope.md` Section 10.

**Do not commit real user SQLite files.** Store test stores in a team vault or local-only path.

## Fixture catalog

| ID | Purpose | How to create |
|----|---------|---------------|
| FIX-FRESH | Clean install | Delete app from simulator → install current build |
| FIX-V2 | Pre-`entryKind` store | Restore archived v2 test store if available |
| FIX-V3 | Current mixed data | Seed recurring + one-time + run app on v3 |
| FIX-SAV-LEGACY | `AppSettings.savingsGoalAmount` only | Use store with no `SavingsGoal` entity |
| FIX-SAV-GOAL | Goal + legacy setting | Active goal plus legacy amount in settings |
| FIX-PREM | Premium user | StoreKit sandbox purchase or test `AppSettings.isPremiumUser` in Debug |
| FIX-CLOUDKIT | iCloud sync user | Physical device + test Apple ID with iCloud |
| FIX-CORRUPT | Negative test | Engineering-truncated sqlite (local only) |

## QA calculation seed — QA-CALC-SET-01

Use for cross-surface consistency (Section 11):

- Recurring income: $5,000/month
- Recurring expense: $2,000/month rent + $500/month subscriptions (via builder rollup)
- One-time expense: $300 today
- One-time income: $1,000 bonus
- Savings goal: $10,000 target, $2,000 current

Record Home, Income, Expense, Savings, and widget values in `release_tracker.md` or a spreadsheet.

## Storage location

Recommended local path (gitignored):

```
~/BudgetMeterQA/fixtures/
```

Add fixture creation notes here as fixtures are built during manual QA.
