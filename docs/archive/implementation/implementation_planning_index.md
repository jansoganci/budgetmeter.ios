# Implementation Planning Index

## 1. Documents Created

- `docs/implementation/codebase_audit_plan.md`
- `docs/implementation/data_model_migration_plan.md`
- `docs/implementation/calculation_engine_contract_plan.md`
- `docs/implementation/home_dashboard_implementation_plan.md`
- `docs/implementation/design_system_redesign_plan.md`
- `docs/implementation/navigation_flow_plan.md`
- `docs/implementation/income_expense_flow_implementation_plan.md`
- `docs/implementation/savings_gamification_plan.md`
- `docs/implementation/premium_entitlement_plan.md`
- `docs/implementation/auth_supabase_sync_plan.md`
- `docs/implementation/widgets_plan.md`
- `docs/implementation/localization_accessibility_qa_plan.md`
- `docs/implementation/release_phase_plan.md`
- `docs/implementation/app_store_privacy_auth_readiness_audit.md`
- `docs/implementation/app_store_readiness_execution_plan.md`
- `docs/implementation/legal_privacy_github_pages_plan.md`

## 2. Recommended Implementation Order

1. codebase audit / safety check
2. calculation engine contract
3. data model safety
4. Home dashboard redesign
5. DesignSystem redesign
6. income/expense flow updates
7. basic savings integration
8. premium cleanup
9. widget v1
10. Supabase Auth/database migration
11. release QA

Implementation starts with core app work and does not start with auth/sync migration.

## 3. Dependency Order

Calculation work depends on:

- Codebase audit
- Data model audit/migration plan

Home work depends on:

- Calculation contract
- Design system plan

Income/Expense work depends on:

- Data model migration plan
- Calculation contract

Savings/Gamification depends on:

- Home summary
- Calculation contract
- Savings data model decision

Premium depends on:

- Feature inventory
- Current StoreKit audit
- Final free/premium matrix

Widgets depend on:

- Home summary contract
- Premium gate plan
- Shared storage plan

Auth/Supabase depends on:

- Data model migration plan
- Premium boundary
- Stable ID strategy
- CoreData/CloudKit audit

Release depends on:

- All implementation plans
- Test strategy
- Localization/accessibility plan

## 3.1 QA Staging Rule

QA is split into two stages so core redesign progress is not blocked by cloud/auth volatility.

Stage A: Core redesign QA (before auth/sync implementation)

- Home
- DesignSystem
- Calculation engine
- Income/expense flows
- Basic savings
- Localization
- Accessibility

Stage B: Auth/sync QA (after auth/sync scope is frozen)

- Apple Sign In
- Supabase backup/sync
- Account/session states
- Account deletion/data deletion
- Restore behavior
- Sync error states
- Migration from local/CoreData/CloudKit states

## 4. Highest-Risk Areas

- CoreData migration
- Existing CloudKit data
- Supabase introduction
- Stable user ID mapping
- CalculationEngine refactor
- HomeViewModel rewrite
- Premium StoreKit entitlement/restore
- Widget target/App Group setup
- Localization across 10 languages
- Live App Store user data compatibility

## 5. What Should Be Implemented First

After audit and planning, start with core local architecture and shared calculation outputs.

Do not start with Supabase/Auth migration before core app contracts are stable.

## 6. What Should Be Postponed

- Supabase true sync
- Cloud conflict resolution
- CloudKit migration
- Advanced widgets
- Lock screen widgets
- Advanced weekly recap
- Multiple savings goals if core savings is unstable
- Advanced forecasting
- PDF export
- App icon variants
- Pulsey variants
- Push notifications
- Advanced bill/subscription automation
- AI features
- Bank sync
- Mascot progression systems

CloudKit removal/deactivation remains postponed until migration and live-data safety criteria are met.

## 6.1 Implementation Readiness

- Documentation blockers are resolved.
- Implementation can start.
- Core app implementation starts first.
- Auth/Supabase migration starts after core model/contracts and widget v1 are stable.

## 7. What Must Be Audited Before Coding

- Current architecture and navigation
- CoreData entities and relationships
- PersistenceService behavior
- CloudKit production status
- CalculationEngine formulas and tests
- HomeFeature data flow
- Income/Expense current data mapping
- Bills/subscriptions relationship
- SavingsGoal usage
- PremiumManager/StoreKit status
- Widget target status
- DesignSystem reuse
- Localization coverage
- Test reliability
- App Store/live user data risk

## 8. Implementation Planning Rule

Implementation should proceed in small, isolated prompts after these plans are reviewed.

Each implementation prompt should include:

- Target files
- Product decision being implemented
- Data risk
- Premium/free boundary
- Localization impact
- Tests to run or add
- Explicit out-of-scope items

No implementation prompt should combine persistence migration, UI redesign, premium gating, and cloud sync in one step.

## 9. Implementation Tracker

Use this tracker as the single status view for implementation rollout.

### Phase 0 — Codebase Audit / Safety Check
- Status: Completed
- Goal: Verify current architecture, persistence, calculations, premium, widgets, localization, and test baseline before edits.
- Related planning docs: `docs/implementation/codebase_audit_plan.md`, `docs/implementation/phase0_codebase_audit_report.md`
- Risk level: High
- Completion criteria: Audit findings documented, critical risks listed, safe first implementation scope confirmed.

### Phase 1 — Calculation Engine Contract
- Status: **Implemented and Verified** (2026-06-17)
- Goal: Lock one shared calculation contract for Home, savings, charts, and widgets.
- Related planning docs: `docs/implementation/calculation_engine_contract_plan.md`, `docs/implementation/phase1_calculation_contract_report.md`
- Risk level: High
- Completion criteria: Contract finalized, shared summary models implemented, builder maps existing Core Data sources, tests pass.
- Implementation files changed:
  - `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
  - `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryModels.swift`
  - `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryBuilder.swift`
  - `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift`
  - `budgetmeter.ios/budgetmeter_iosApp.swift`
  - `budgetmeter.ios.xcodeproj/project.pbxproj`
  - `budgetmeter.iosTests/CalculationEngineTests.swift`
  - `budgetmeter.iosTests/ViewModelCalculationTests.swift`
  - `budgetmeter.iosTests/FinancialSummaryBuilderTests.swift`
- Verification results:
  - Build: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` -> **SUCCEEDED**
  - Tests: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test` -> **84 passed / 0 failed**
- Remaining risks:
  - Core Data test logs still emit duplicate `NSEntityDescription` warnings from repeated in-memory model loads.
  - Build still warns about duplicate `.xcstrings` resources.
  - `PeriodKind.custom` currently has no custom date payload, so builder falls back to month bounds until a later UI/data contract defines custom ranges.
  - Recurring bill rollup excludes paid bills to avoid double-counting historical instances; Phase 5 should confirm bill recurrence semantics before entry-flow changes.
- Notes: Report dated 2026-06-16. Contract now defines and implements `FinancialSummary` / `FinancialSummaryInput`, recurring/one-time lines, period normalization, rollups, biggest drain, savings ETA, and pace status. UI redesign, widgets, premium gates, Supabase/Auth, CloudKit behavior, and Core Data schema were not expanded in this phase.

### Phase 2 — Data Model Safety
- Status: **Implementation Verified** (Steps 1–6 complete)
- Goal: Define safe local/cloud data mapping and migration rules before structural changes.
- Related planning docs: `docs/implementation/data_model_migration_plan.md`, `docs/implementation/phase2_data_model_safety_report.md`
- Risk level: High
- Completion criteria: Migration scenarios documented, stable identity mapping defined, live-data safety gates approved.
- Implementation steps (verified 2026-06-16):
  - Step 1 — Test target + scheme: **Done** (`budgetmeter.iosTests`, shared scheme)
  - Step 2 — `BudgetMeter 3.xcdatamodel`: **Done** (additive `FinancialCategory` fields)
  - Step 3 — Current model version set to v3: **Done** (`.xccurrentversion` → `BudgetMeter 3.xcdatamodel`)
  - Step 4 — `FinancialDataMigrationService`: **Done** (non-destructive, idempotent, wired in app launch)
  - Step 5 — Migration unit tests: **Done** (10/10 pass on in-memory Core Data)
  - Step 6 — Verification: **Done** (build succeeded; migration scope confirmed; tracker updated)
- Verification results:
  - Build: `xcodebuild build -scheme budgetmeter.ios` → **SUCCEEDED**
  - Tests: `xcodebuild test -only-testing:budgetmeter.iosTests` → **59 passed / 19 failed** (all 10 migration tests pass; 19 failures are pre-existing `30` vs `30.4375` assertion drift in calculation tests — not Phase 2 regressions)
  - `FinancialCategory` v3 fields present: `entryKind`, `occurrenceDate`, `sourceType`, `sourceID`, `isActive`, `lastModified`
  - Migration idempotency: guarded by `needsDefaultFieldMigration`, `needsLegacyRecurringFrequencyMigration`, active-goal check, and `test_migration_isIdempotent`
- Remaining before Home/calc unification (Phase 2 report Steps 7–10, not started):
  - `FinancialSummaryBuilder` implementation + builder tests (M5–M7) — **Completed in Phase 1 implementation**
  - Stop `frequency=recurring` category creation in RT automation
  - Manual QA: fresh install, upgrade from v2 store, CloudKit dev container
  - Export-before-upgrade gate for production users
- Notes: v1 approach unchanged — extend `FinancialCategory`, migrate legacy `frequency=recurring` rows to `oneTime`, consolidate `AppSettings.savingsGoalAmount` → `SavingsGoal` when no active goal. CloudKit retained. Supabase/Auth/widgets/UI untouched in Phase 2 scope.

### Phase 3 — Home Dashboard Redesign
- Status: **Implemented and Verified** (2026-06-17)
- Goal: Implement momentum-first Home using shared summary outputs.
- Related planning docs: `docs/implementation/home_dashboard_implementation_plan.md`, `docs/implementation/navigation_flow_plan.md`, `docs/implementation/phase3_home_dashboard_scope.md`
- Risk level: Medium
- Completion criteria: Home hero/sections aligned with decisions, no independent calculations, localization keys planned.
- Implementation files changed:
  - `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
  - `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeDisplayMapping.swift`
  - `budgetmeter.ios/Features/HomeFeature/View/HomeView.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/MomentumHeroCard.swift`
  - `budgetmeter.ios/DesignSystem/Components/Indicators/MomentumRingView.swift`
  - `budgetmeter.iosTests/HomeViewModelMappingTests.swift`
- Verification results:
  - Build: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` → **SUCCEEDED**
  - Tests: `xcodebuild ... test` → **90 passed / 0 failed**
- What was implemented:
  - `HomeViewModel` now uses `FinancialSummaryBuilder` as sole pace data source
  - New display fields: `netDailyPace`, `netMinutePace`, `paceStatus`, `paceStatusCopy`, `biggestDrain`, `savingsRemaining`, `savingsTimeToGoal`
  - `MomentumHeroCard` + `MomentumRingView` as first dashboard section
  - Mock chart/trend generation removed from active Home path
  - Legacy published fields preserved for existing cards
- Postponed:
  - Daily budget card removed from hero position (fields retained in ViewModel)
  - Historical chart/sparkline data (empty arrays until Insights/history phase)
  - Trend percentages (nil until historical comparison exists)
  - Time selector, awareness streak, weekly recap, Pulsey-heavy presence
  - Full DesignSystem token rollout (Phase 4) — **completed in Phase 4**
- Remaining risks:
  - `HomeDisplayMapping` pace copy strings not yet in `.xcstrings` catalog
  - Manual device QA for dark-first hero layout not run
  - `PeriodKind.custom` still falls back to month bounds in builder
- Notes: Phase 4 (DesignSystem redesign) can start; Income/Expense flow alignment remains Phase 5.

### Phase 4 — DesignSystem Redesign
- Status: **Implemented and Verified** (2026-06-17)
- Goal: Apply final visual tokens/components for consistent rollout.
- Related planning docs: `docs/implementation/design_system_redesign_plan.md`, `docs/implementation/phase4_design_system_scope.md`
- Risk level: Medium
- Completion criteria: Core tokens/components defined and reusable across redesigned screens.
- Implementation files changed:
  - `budgetmeter.ios/DesignSystem/Colors/BrandColors.swift`
  - `budgetmeter.ios/DesignSystem/Colors/CategoryColors.swift`
  - `budgetmeter.ios/DesignSystem/Typography/TextStyles.swift`
  - `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift`
  - `budgetmeter.ios/DesignSystem/Animations/AnimationCurves.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/MomentumHeroCard.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/FinancialSummaryCard.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/MonthSummaryCard.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/CompactHealthCard.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/CompactSavingsCard.swift`
  - `budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`
  - `budgetmeter.ios/DesignSystem/Components/Indicators/MomentumRingView.swift`
  - `budgetmeter.ios/DesignSystem/Components/Indicators/TrendIndicator.swift`
  - `budgetmeter.ios/DesignSystem/Components/Charts/MiniBarChart.swift`
  - `budgetmeter.ios/DesignSystem/Components/Rows/FinancialRowView.swift`
  - `budgetmeter.ios/DesignSystem/Components/Sections/FinancialSection.swift`
- Verification results:
  - Build: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` → **SUCCEEDED**
  - Tests: `xcodebuild ... -parallel-testing-enabled NO test` → **90 passed / 0 failed**
- What was implemented:
  - v4 semantic color tokens: obsidian base, slate surfaces (card/raised/inset/overlay), cyan accent, emerald/amber/coral financial states, chart/border/divider tokens
  - Typography aliases: `paceHeroStyle`, `metricLarge/Medium/Compact`, `statusTitleStyle`, `sectionTitleStyle`, `bodyStyle`, `captionStyle`, `badgeStyle` (monospaced digits on metrics)
  - Layout aliases: `LayoutSpacing.*`, `surfaceCard` / `surfaceInset` / `surfaceOverlay` / `smallCard` modifiers
  - Animation v4 aliases: `buttonPress`, `cardReveal`, `paceUpdate`, `heroReveal`, `chartBar`
  - Core components migrated to tokens (hero, summary cards, rows, sections, trend, chart, premium banner visual-only)
- Postponed:
  - Secondary cards not in Phase 4 scope: `HeroNetFlowCard`, `DailyBudgetCard`, `CompactDailyBudgetCard`, `HealthScoreCard`, `SavingsGoalCard`, `IntervalMetricCard`, `CompactIntervalCard`, `GreetingHeader`
  - Row components: `SubscriptionRowView`, `EmptyStateRow`, `AddFinancialItemRow`
  - Settings / Income / Expense screen-wide token adoption (Phase 5+)
  - Pulsey mascot integration
  - Light-mode manual QA pass on obsidian/slate contrast
- Remaining risks:
  - Legacy cards outside scope still use v2 gradients and `chartInactive` naming
  - `badgeStyle` applies uppercase — verify localized badge strings in future phases
  - Dark-first tokens may need contrast tuning on light mode for non-migrated screens
- Notes: Phase 7 (Premium Cleanup) can start.

### Phase 5 — Income / Expense Flow Updates
- Status: **Implemented and Verified** (2026-06-17)
- Goal: Align entry flows with recurring/one-time model and shared pace pipeline.
- Related planning docs: `docs/implementation/income_expense_flow_implementation_plan.md`, `docs/implementation/phase5_income_expense_flow_scope.md`
- Risk level: Medium
- Completion criteria: Flow mappings finalized, premium/free boundaries enforced, rollup behavior covered by tests.
- Implementation files changed:
  - `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift`
  - `budgetmeter.ios/Features/IncomesFeature/View/IncomeView.swift`
  - `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`
  - `budgetmeter.ios/Features/ExpensesFeature/View/ExpenseView.swift`
  - `budgetmeter.ios/Features/Shared/CreateCategoryModal.swift`
  - `budgetmeter.ios/Features/Shared/FinancialEditSheet.swift`
  - `budgetmeter.ios/Features/RecurringTransactionsFeature/ViewModel/RecurringTransactionsViewModel.swift`
  - `budgetmeter.iosTests/IncomeExpenseFlowTests.swift`
- Verification results:
  - Build: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` → **SUCCEEDED**
  - Tests: `xcodebuild ... -parallel-testing-enabled NO test` → **100 passed / 0 failed**
- What was implemented:
  - Income/Expense summary cards consume `FinancialSummaryBuilder` (`recurringIncomeMonthly`, `recurringExpenseMonthly`, daily/yearly projections)
  - Expense summary includes subscriptions and bills via builder rollup (no manual double-count)
  - Recurring category lists filter by `entryKind` / frequency; legacy `frequency = "recurring"` rows excluded from editable sections
  - One-time income/expense entry via CreateCategoryModal (entry kind + occurrence date)
  - `FinancialCategoryWriteSupport` sets `entryKind`, `isActive`, `lastModified` on writes
  - Recurring automation emits one-time rows (`entryKind = oneTime`, `frequency = once`) instead of legacy `frequency = recurring`
  - Minimal one-time collapsible sections on Income/Expense screens
- Postponed:
  - Weekly frequency section in Income/Expense UI
  - Bills visibility section on Expense screen (included in summary only)
  - CategoryValidationService `entryKind` defaults (set in CreateCategoryModal after create)
  - Localization catalog entries for new entry-type strings
  - ViewModelCalculationTests still assert legacy formula patterns (not ViewModel instances)
- Remaining risks:
  - `SubscriptionManager.shared` still uses app singleton persistence in ExpenseViewModel subscription list (summary uses injected builder)
  - Seeded categories without `entryKind` rely on migration-on-launch for recurring default
  - One-time add row opens modal with monthly frequency preset — user must switch entry type in modal
- Notes: Phase 7 (Premium Cleanup) can start.

### Phase 6 — Basic Savings Integration
- Status: **Implemented and Verified** (2026-06-17)
- Goal: Keep one basic savings goal aligned with shared Home net pace and existing app behavior.
- Related planning docs: `docs/implementation/savings_gamification_plan.md`, `docs/implementation/phase6_basic_savings_integration_scope.md`
- Risk level: Medium
- Completion criteria: Savings timeline uses shared pace contract, fallback behavior (`0`) confirmed, no hidden formulas.
- Implementation files changed:
  - `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift`
  - `budgetmeter.ios/CoreKit/Sources/Engine/FinancialSummaryBuilder.swift`
  - `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
  - `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeDisplayMapping.swift`
  - `budgetmeter.ios/Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`
  - `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalsView.swift`
  - `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift`
  - `budgetmeter.iosTests/BasicSavingsIntegrationTests.swift`
  - `budgetmeter.iosTests/FinancialSummaryBuilderTests.swift`
- Verification results:
  - Focused Phase 6 tests: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:budgetmeter.iosTests/FinancialSummaryBuilderTests -only-testing:budgetmeter.iosTests/BasicSavingsIntegrationTests test` -> **27 passed / 0 failed**
  - Full tests: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -parallel-testing-enabled NO test` -> **121 passed / 0 failed**
  - Build: `xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build` -> **SUCCEEDED**
- What was implemented:
  - Deterministic primary savings goal selection with in-progress goals preferred over completed goals.
  - Shared `SavingsGoalManager.resolvedSavingsTargetAndCurrent(in:)` rule: primary active `SavingsGoal` first, `AppSettings.savingsGoalAmount` fallback only, current fallback `0`.
  - `FinancialSummaryBuilder` savings target/current/remaining/ETA uses the shared savings source and recurring net pace.
  - Savings ETA is nil for zero or negative recurring pace and ignores one-time income/expense.
  - Home quick savings save updates/creates the primary basic `SavingsGoal` instead of relying on `AppSettings`.
  - Home and Savings use shared summary ETA/display values for the primary goal.
  - Free users remain limited to one active basic savings goal; premium users can create multiple goals through existing entitlement state.
- Postponed:
  - Multiple-goal redesign.
  - Advanced forecasts, goal history charts, awareness streak, weekly recap, Pulsey savings variants.
  - Broad premium gate cleanup.
  - Health/Insights/Notification/Historical savings fallback alignment outside Home/Savings.
- Remaining risks:
  - Existing project warnings remain: duplicate `.xcstrings` build resources and CoreData duplicate entity warnings in tests.
  - `AppSettings.savingsGoalAmount` remains as legacy fallback and should not be removed until a later migration cleanup.
  - Target-date monthly contribution remains secondary UI and must not be treated as Home/shared savings ETA.
- Notes: Phase 7 (Premium Cleanup) can start.

### Phase 7 — Premium Cleanup
- Status: **Implemented and Verified**
- Goal: Centralize gating for current premium scope without affecting free core value.
- Related planning docs: `docs/implementation/premium_entitlement_plan.md`, `docs/implementation/phase7_premium_cleanup_scope.md`
- Risk level: Medium
- Completion criteria:
  - Canonical `BudgetMeterCapability` gate matrix added.
  - `PremiumManager` now exposes feature/capability-specific access helpers.
  - Existing premium wrappers and selected premium surfaces use feature-specific gates.
  - Premium-only side effects for export, biometric enablement, and non-default theme application are guarded.
  - StoreKit lifetime purchase ID remains unchanged.
  - Restore flow now reports a no-purchase-found state.
  - Free core capabilities are protected by tests.
  - Focused Phase 7 tests pass: 7/7.
  - Full test suite passes: 128/128.
  - Build passes.
- Postponed:
  - StoreKit sandbox/manual purchase QA.
  - Widget premium implementation, which remains Phase 8.
  - Supabase/Auth entitlement sync, which remains Phase 9.
  - RevenueCat, subscriptions, ads, ads-free entitlement, and remote paywalls.
- Remaining risks:
  - Existing project warnings remain: duplicate `.xcstrings` build resources and CoreData duplicate entity warnings in tests.
  - Existing Settings still uses top-level `isPremium` to show or hide the grouped premium section; individual premium actions now use the canonical gates where Phase 7 touched them.
  - JSON export remains present in existing export UI/service; product docs emphasize CSV/PDF premium and still need a product decision.

### Phase 8 — Widget v1
- Status: **Implemented and Verified** (2026-06-17)
- Goal: Deliver premium Home Screen `systemSmall` widget (net daily pace status/value) with correct deep link and locked teaser state.
- Related planning docs: `docs/implementation/widgets_plan.md`, `docs/active/widgets_plan.md`, `docs/implementation/phase8_widget_v1_scope.md`
- Risk level: Medium-High
- Completion criteria: v1 scope enforced (no lock/medium), data source matches Home summary, premium gating works.
- Notes: Implemented `WidgetSnapshot` App Group contract, `NetDailyPaceWidget` extension target, deep links to Home hero and premium paywall, removed legacy balance/spending/savings/lock-screen widgets. Build and full test suite pass.

### Phase 9 — Supabase Auth / Database Migration
- Status: **Implemented and Verified (v1 backup/account deletion slice)** — core auth/backup layer, versioned Supabase backup schema, Settings UI, and account deletion verified 2026-06-18
- Goal: Implement Apple Sign In + Supabase Auth/database migration with data preservation and CloudKit removal path.
- Related planning docs: `docs/implementation/auth_supabase_sync_plan.md`, `docs/implementation/data_model_migration_plan.md`, `docs/implementation/phase9_supabase_auth_database_migration_scope.md`, `docs/supabase/phase9_user_backups.sql`, `supabase/migrations/0001_user_backups_base.sql`, `supabase/migrations/0002_user_backup_versions.sql`, `supabase/migrations/0003_backup_version_capture_trigger.sql`
- Risk level: High
- Completion criteria: First sign-in safety flow defined, migration/recovery checks passed, CloudKit removal criteria met.
- Notes: v1 delivers AuthService, BackupService, serializer/snapshot/restore, Account & Backup settings, `.backupSync` premium gate, Sign in with Apple entitlement, ordered Supabase migrations, latest backup + version history tables, RLS, backup capture trigger, and `delete-account` Edge Function hard-delete path. User reported Supabase migrations and live QA passed on 2026-06-18. CloudKit remains active; CloudKit removal and true row-level sync remain postponed.

### Phase 10 — Release QA
- Status: **In progress** — G0 baseline passed 2026-06-17 (147/147 tests, build succeeded)
- Goal: Complete Stage A and Stage B QA and confirm release safety.
- Related planning docs: `docs/implementation/release_phase_plan.md`, `docs/implementation/localization_accessibility_qa_plan.md`, `docs/implementation/phase10_release_qa_scope.md`, `docs/qa/release_tracker.md`, `docs/qa/known_issues.md`, `docs/implementation/app_store_privacy_auth_readiness_audit.md`, `docs/implementation/app_store_readiness_execution_plan.md`
- Risk level: High
- Completion criteria: Core + auth/sync QA gates passed, localization/accessibility validated, release checklist complete, go/no-go documented.
- G0 results (2026-06-17):
  - Build: `xcodebuild -scheme budgetmeter.ios` → **SUCCEEDED**
  - Tests: `xcodebuild test -parallel-testing-enabled NO` → **147 passed / 0 failed**
  - Widget extension build: scheme/signing issue (see `docs/qa/known_issues.md` KI-003, KI-004)
- Next steps: Script A manual QA on simulator; StoreKit sandbox on device; fix widget signing; Stage B after Supabase config.
