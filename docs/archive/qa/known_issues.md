# BudgetMeter Known Issues — Release QA

Track open issues during Phase 10. Assign severity per `phase10_release_qa_scope.md` Section 6.

| ID | Severity | Area | Description | Owner phase | Status |
|----|----------|------|-------------|-------------|--------|
| KI-001 | Minor | Build | 8 duplicate `.xcstrings` in Copy Bundle Resources | Infra | Open |
| KI-002 | Minor | Tests | `NSEntityDescription` duplicate warnings in in-memory Core Data tests | Tests | Open |
| KI-003 | Major | Widget | `BudgetMeterWidgets` scheme not configured for build action | Phase 8 | Resolved 2026-06-18 — scheme build succeeds on simulator |
| KI-004 | Major | Widget | Widget extension target build fails: no provisioning profile | Phase 8 | Open — needs device/Release signing verification |
| KI-005 | Major | Localization | Hardcoded English in `SavingsGoalDetailView` (Target Date, Add Money, Withdraw, Notes) | Phase 6/10 | Resolved 2026-06-18 |
| KI-006 | Minor | Localization | Hardcoded strings in DesignSystem previews (`MiniBarChart`, `TrendIndicator`, `PremiumUpgradeBanner`) | Phase 4 | Open — preview-only |
| KI-007 | Minor | Dev | Debug/test views with hardcoded English (`CustomCategoryTestView`, `CustomCategoryFlowTest`) | Dev | Open — not ship surfaces |
| KI-008 | Critical | Stage B | Live cloud backup QA blocked until Supabase SQL + Apple Sign In provider configured | Phase 9 | Resolved 2026-06-18 — user completed config |
| KI-009 | Major | Privacy | Privacy policy copy may still describe iCloud-only storage | Phase 9 | Resolved 2026-06-18 — updated for local + Supabase + legacy iCloud |
| KI-010 | Minor | Naming | Custom `LocalizedError` struct in `RecurringTransactionsViewModel` shadows `Foundation.LocalizedError` | Phase 5/9 | Mitigated in auth/backup via `Foundation.LocalizedError` |

## Ship waivers

None approved.

## Resolved this session

| ID | Resolution |
|----|------------|
| — | G0 build/test baseline: 147/147 tests pass (2026-06-17) |
