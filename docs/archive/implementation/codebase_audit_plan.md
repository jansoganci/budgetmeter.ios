# Codebase Audit Plan

## Purpose

BudgetMeter is a live iOS app. Before implementation starts, the current codebase must be audited so the redesign does not break existing user data, financial calculations, premium access, localization, tests, or App Store readiness.

The redesign is significant. It touches the product core:

- Financial pace / live money meter
- Playful Momentum FinTech UI
- Pulsey mascot
- Dark-first design system
- Shared calculation engine
- Revised income and expense flows
- Premium features
- Apple Sign In
- Supabase
- Stable user IDs
- Premium cloud backup/sync

This audit reduces the risk of:

- Losing or corrupting live user data
- Breaking CoreData / CloudKit persistence
- Duplicating calculation logic across screens
- Rebuilding reusable UI unnecessarily
- Breaking premium entitlements
- Shipping non-functional widgets
- Creating migration work without understanding the current schema
- Regressing localized strings across supported languages
- Starting Supabase/Auth work before local architecture is understood

The audit must document current reality only. It must not implement fixes.

## Scope

Audit these areas:

- App architecture
- CoreData model
- PersistenceService
- CloudKit status
- CalculationEngine
- HomeFeature
- IncomeFeature
- ExpensesFeature
- SavingsGoalsFeature
- PremiumFeature / PremiumManager
- Widgets
- DesignSystem
- Localization
- Tests
- App Store / live user data risks

## Audit Rules

- Do not modify app code during the audit
- Do not change CoreData during the audit
- Do not change Xcode targets during the audit
- Do not start UI redesign during the audit
- Do not introduce Supabase or Auth during the audit
- Do not add dependencies during the audit
- Do not remove files during the audit
- Do not run destructive commands
- Only document current reality

## Area Audit Checklist

### 1. App Architecture

What to inspect:

- Current app entry point
- Current tab/navigation structure
- Feature module organization
- View/ViewModel/service boundaries
- Existing dependency patterns
- Any direct CoreData access from Views
- Any business logic embedded in Views

Files/folders to check:

- `budgetmeter.ios/App/`
- `budgetmeter.ios/Features/`
- `budgetmeter.ios/CoreKit/Sources/`
- `CLAUDE.md`

Questions to answer:

- What screen does the app start on?
- What is the current navigation/tab structure?
- Which features are primary vs secondary?
- Are Views using ViewModels consistently?
- Are services/managers clearly separated from UI?
- Which modules will be affected by the redesign?
- Are there architectural patterns that should be preserved?

Risks to look for:

- Business logic in SwiftUI Views
- ViewModels that are too large or tightly coupled
- Feature duplication
- Direct persistence calls from Views
- Navigation structure that conflicts with Home-first direction
- Hidden dependencies between features

Output to document:

- Current architecture summary
- Current navigation map
- Reusable architecture patterns
- Architecture risks
- Modules likely to need refactor

### 2. CoreData Model

What to inspect:

- Active CoreData entities
- Attributes and relationships
- Optional vs required fields
- Existing model versions
- Migration history
- Entity usage across the app

Files/folders to check:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/`
- `budgetmeter.ios/CoreKit/Sources/Persistence/`
- Any generated or manual CoreData model files

Questions to answer:

- Which entities are actively used?
- Which entities are unused, partially used, or duplicated?
- How are income and expense records represented today?
- How are recurring transactions represented today?
- How do Bill, Subscription, and RecurringTransaction relate?
- Is SavingsGoal active and reliable?
- What schema fields are risky for migration?
- Does the current model support one-time vs recurring money clearly?

Risks to look for:

- Entity duplication
- Ambiguous financial category usage
- Missing migration path
- Optional fields that could crash assumptions
- Existing live data that would not map cleanly to the new shared financial model
- CloudKit/CoreData constraints that affect future Supabase migration

Output to document:

- Entity inventory
- Entity usage status
- Relationship map
- Migration risks
- Fields requiring migration planning
- Candidate deprecated entities or fields

### 3. PersistenceService

What to inspect:

- CoreData stack setup
- Save/fetch/update/delete behavior
- Error handling
- CloudKit configuration
- App settings initialization
- Threading/concurrency behavior
- Data reset or sample data behavior

Files/folders to check:

- `budgetmeter.ios/CoreKit/Sources/Persistence/`
- `budgetmeter.ios/CoreKit/Sources/Services/`
- Any persistence-related code in feature ViewModels

Questions to answer:

- How is the persistent container configured?
- Is CloudKit currently enabled?
- How are errors surfaced?
- Are saves synchronous or async?
- Is PersistenceService used consistently?
- Are there multiple data access patterns?
- Is there a safe path for local-first behavior?

Risks to look for:

- Silent save failures
- Force unwraps / force tries
- Main-thread blocking work
- Direct CoreData access outside persistence layer
- Inconsistent fetch logic
- Data reset paths that could affect live users
- CloudKit assumptions that conflict with future Supabase planning

Output to document:

- Persistence architecture summary
- Data access patterns
- Error handling gaps
- Local-first readiness
- Migration planning needs

### 4. CloudKit Status

What to inspect:

- Whether CoreData + CloudKit is active
- Container identifiers
- Entitlements
- Sync behavior
- Conflict behavior
- User-visible sync status
- Any CloudKit-specific assumptions in code

Files/folders to check:

- `budgetmeter.ios/CoreKit/Sources/Persistence/`
- Xcode project settings and entitlements
- `budgetmeter.ios/*.entitlements` if present
- App configuration files

Questions to answer:

- Is CloudKit currently enabled in production builds?
- What data syncs through CloudKit today?
- Is sync reliable or only partially configured?
- Is there any user-facing sync UI?
- Would existing CloudKit data need migration or deprecation planning?
- How does CloudKit affect the future Supabase direction?

Risks to look for:

- Unknown production CloudKit data
- Sync conflicts
- Hidden dependency on iCloud account state
- Removing CloudKit without migration planning
- Conflicting future cloud strategies

Output to document:

- CloudKit status
- Entitlement/container summary
- Current sync behavior
- Live user data risk
- Required migration planning

### 5. CalculationEngine

What to inspect:

- Existing financial formulas
- Daily/monthly/yearly normalization constants
- Pace calculations
- Savings calculations
- Forecast calculations
- Health score or insight calculations
- Test coverage

Files/folders to check:

- `budgetmeter.ios/CoreKit/Sources/Engine/CalculationEngine.swift`
- `budgetmeter.iosTests/`
- Any ViewModel calculation logic

Questions to answer:

- Which calculations already match the new product decisions?
- Are minute/hour/day/week/month values already supported?
- Are one-time and recurring records handled distinctly?
- Is daily normalization centralized?
- Do Home, savings, charts, and widgets share the same logic?
- Are there duplicate formulas outside CalculationEngine?
- Which tests are reliable?

Risks to look for:

- Duplicate calculation logic
- Different screens showing inconsistent values
- Incorrect recurring normalization
- One-time transactions being treated as permanent pace
- Missing tests for new product rules
- ViewModel-specific calculations that bypass the engine

Output to document:

- Current CalculationEngine capability map
- Formula inventory
- Duplicate logic list
- Test coverage summary
- Required contract planning for the next step

### 6. HomeFeature

What to inspect:

- Current Home screen structure
- Current HomeViewModel state
- Data sources
- Current cards/components
- Charts
- Savings display
- Net direction display
- Any hardcoded UI copy or calculations

Files/folders to check:

- `budgetmeter.ios/Features/HomeFeature/`
- `budgetmeter.ios/DesignSystem/Components/Cards/`
- `budgetmeter.ios/DesignSystem/Components/Charts/`

Questions to answer:

- What does Home show today?
- Which current Home components can be reused?
- Does Home already show live money pace?
- Which values come from CalculationEngine?
- Which values are duplicated or calculated locally?
- What must change for the momentum ring + live pace hero?
- Are charts real, mocked, or partial?

Risks to look for:

- Home ViewModel doing too much
- Hardcoded display logic
- Mock/random chart data
- Inconsistent pace logic
- Components that cannot support dark-first redesign
- Dashboard crowded with secondary metrics

Output to document:

- Current Home structure
- Reusable components
- Required refactors
- Calculation dependencies
- UI redesign risks

### 7. IncomeFeature

What to inspect:

- Current income entry flow
- Recurring income support
- One-time income support
- Income categories
- ViewModel logic
- Persistence mapping
- Calculation integration

Files/folders to check:

- `budgetmeter.ios/Features/IncomesFeature/`
- Related CoreKit services/managers
- CoreData entity usage for income

Questions to answer:

- How does the user add income today?
- Is recurring income currently supported?
- Is one-time income clearly modeled?
- Are frequencies daily/weekly/monthly/yearly supported?
- How does income feed Home and CalculationEngine?
- Are default/custom categories supported?
- Which parts are reusable for the new flow?

Risks to look for:

- Income stored as generic category without clear type
- Missing recurring/one-time distinction
- Duplicate category logic
- Calculations inside ViewModel
- Migration mismatch with new shared financial model

Output to document:

- Current income flow map
- Income data model mapping
- Reusable UI/service pieces
- Required refactors
- Migration concerns

### 8. ExpensesFeature

What to inspect:

- Current expense entry flow
- Fixed/regular vs surprise/one-time support
- Expense categories
- ViewModel logic
- Persistence mapping
- Calculation integration
- Relationship to bills/subscriptions

Files/folders to check:

- `budgetmeter.ios/Features/ExpensesFeature/`
- `budgetmeter.ios/Features/BillsFeature/`
- `budgetmeter.ios/Features/SubscriptionsFeature/`
- Related CoreKit services/managers
- CoreData entity usage for expenses

Questions to answer:

- How does the user add expenses today?
- Are fixed/regular expenses clearly modeled?
- Are surprise/one-time expenses clearly modeled?
- Do one-time expenses affect only their selected/current period?
- How do bills and subscriptions relate to expenses?
- Are bills/subscriptions separate financial realities today?
- How does expense data feed Home and CalculationEngine?

Risks to look for:

- Bills/subscriptions duplicating recurring expense logic
- One-time expenses affecting permanent pace incorrectly
- Expense categories used as financial records
- Missing date/frequency data
- Premium automation mixed with free basic expense entry

Output to document:

- Current expense flow map
- Bills/subscriptions relationship
- Expense data model mapping
- Reusable pieces
- Required refactors
- Migration concerns

### 9. SavingsGoalsFeature

What to inspect:

- Current savings goal flow
- Goal model
- Current saved amount handling
- Target amount handling
- Timeline calculation
- Multiple goal support
- Home integration
- Premium gating

Files/folders to check:

- `budgetmeter.ios/Features/SavingsGoalsFeature/`
- `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift` if present
- `BudgetMeter.xcdatamodeld`
- Home savings display code

Questions to answer:

- Is SavingsGoal actively used?
- Does the current app support one goal or multiple goals?
- How is current saved amount determined?
- Does timeline use net pace from the shared calculation model?
- Does Home read the same savings data?
- Which features are currently premium-gated?

Risks to look for:

- Savings calculation separate from Home net pace
- Multiple goals implemented without premium boundary
- SavingsGoal entity unused or partially used
- Missing current saved amount behavior
- Forecast logic not covered by tests

Output to document:

- Current savings flow map
- Savings data model summary
- Home integration status
- Premium boundary conflicts
- Required refactors

### 10. PremiumFeature / PremiumManager

What to inspect:

- Current premium purchase implementation
- StoreKit usage
- Product IDs
- Restore purchase
- PremiumManager entitlement state
- Feature gates
- ThemeManager
- Ads-free assumptions
- RevenueCat absence/presence

Files/folders to check:

- `budgetmeter.ios/Features/PremiumFeature/`
- `budgetmeter.ios/CoreKit/Sources/Premium/`
- `budgetmeter.ios/CoreKit/Sources/Security/`
- `budgetmeter.ios/CoreKit/Sources/Export/`
- Settings screens that expose premium features

Questions to answer:

- Is premium currently functional or partial?
- Is StoreKit implemented directly?
- Are product identifiers real or placeholders?
- Does restore purchase work?
- Where are feature gates checked?
- Are premium checks centralized?
- Which premium features are already implemented?
- Which premium features are UI-only or incomplete?

Risks to look for:

- Scattered entitlement checks
- Mock premium state
- Broken restore flow
- Feature gates that block free core value
- Premium logic mixed into calculations
- Theme/customization logic that conflicts with controlled personalization

Output to document:

- Premium implementation status
- Feature gate inventory
- Reusable entitlement logic
- Broken/risky premium areas
- Required test coverage

### 11. Widgets

What to inspect:

- Widget target status
- Widget files
- Xcode target membership
- App Group/shared storage
- Widget data source
- Premium gating
- Deep links
- Refresh behavior

Files/folders to check:

- `budgetmeter.ios/Widgets/`
- Xcode project target configuration
- Entitlements
- Any shared data writer/reader

Questions to answer:

- Does a widget target exist?
- Are widget files attached to a target?
- Do widgets compile?
- What data do widgets read?
- Is App Group configured?
- Are widgets currently functional or only designed?
- How would widgets consume the shared Home summary?

Risks to look for:

- Widget code not part of a target
- No shared storage
- Widget data using stale or separate calculations
- Widget premium gating missing
- Widget refresh unreliable

Output to document:

- Widget target status
- Widget functionality status
- Data sharing status
- Premium gating needs
- Required widget planning

### 12. DesignSystem

What to inspect:

- Existing color tokens
- Typography tokens
- Spacing tokens
- Card components
- Chart components
- Button styles
- Theme system
- Dark mode support
- Premium theme support

Files/folders to check:

- `budgetmeter.ios/DesignSystem/`
- `budgetmeter.ios/CoreKit/Sources/Premium/ThemeManager.swift` if present
- Feature screens using custom styling outside DesignSystem

Questions to answer:

- Which components are reusable for Playful Momentum FinTech?
- Does the DesignSystem already support dark-first UI?
- Are current colors compatible with the new brand direction?
- Are cards and charts reusable?
- Are there screens bypassing DesignSystem?
- How much design debt exists?

Risks to look for:

- One-off styling across screens
- Hardcoded colors
- Poor dark mode consistency
- Components too rigid for Home redesign
- Premium themes conflicting with default readability
- Lack of accessibility support

Output to document:

- DesignSystem inventory
- Reusable components
- Components needing redesign
- Styling inconsistencies
- Accessibility gaps

### 13. Localization

What to inspect:

- String catalogs
- Supported languages
- Hardcoded user-facing strings
- Feature-specific localization files
- Formatting for currency, dates, and numbers
- RTL behavior where relevant

Files/folders to check:

- `budgetmeter.ios/Resources/`
- Feature Views/ViewModels for hardcoded strings
- Utility localization helpers

Questions to answer:

- Are all user-facing strings localized?
- Are all 10 languages still supported?
- Are translations complete or placeholder?
- How many new strings will the redesign introduce?
- Are currency and date formats centralized?
- Are Arabic/RTL layouts currently safe?

Risks to look for:

- Hardcoded strings
- Missing translations
- Text overflow in localized UI
- Broken dynamic type layouts
- Currency formatting inconsistencies
- Mascot/gamification copy hard to translate

Output to document:

- Localization coverage summary
- Hardcoded string inventory
- Missing/placeholder translation list
- Formatting risks
- Redesign localization impact

### 14. Tests

What to inspect:

- Unit tests
- CalculationEngine tests
- ViewModel tests
- Persistence tests if any
- Premium tests if any
- Build/test reliability
- Test data assumptions

Files/folders to check:

- `budgetmeter.iosTests/`
- Any UI test targets
- CI/build scripts if present

Questions to answer:

- Do tests currently build and run?
- How many CalculationEngine tests exist?
- Which calculation rules are covered?
- Are ViewModel tests current?
- Is persistence tested?
- Is premium tested?
- Which tests are trustworthy before redesign?

Risks to look for:

- Failing or stale tests
- Tests depending on old product assumptions
- No migration tests
- No premium entitlement tests
- No localization/accessibility tests
- Calculation edge cases missing

Output to document:

- Test inventory
- Passing/failing status
- Reliable test list
- Stale test list
- Required coverage for redesign

### 15. App Store / Live User Data Risks

What to inspect:

- Bundle ID
- App Store/live version assumptions
- Entitlements
- App icons/assets
- Premium product IDs
- CloudKit production container
- Existing user data compatibility
- Privacy/legal docs

Files/folders to check:

- Xcode project settings
- Entitlements
- `Assets.xcassets`
- StoreKit configuration if present
- App metadata docs if present
- Privacy/support/legal docs

Questions to answer:

- What bundle ID is used by the live app?
- Is the current codebase aligned with the live App Store version?
- What user data must be preserved?
- Are App Store assets current?
- Are premium products configured?
- Are privacy claims still accurate if Supabase/Auth is added later?
- What migration risks could block release?

Risks to look for:

- Breaking live user data
- Changing bundle or entitlement behavior
- CloudKit production data mismatch
- Premium purchase mismatch
- Privacy policy becoming inaccurate
- App Store rejection risks from unfinished widgets, auth, or purchases

Output to document:

- Live app risk summary
- Bundle/entitlement status
- Premium/App Store readiness risks
- Data preservation requirements
- Migration planning requirements

## Audit Output Format

The final audit document should classify every finding into one of these statuses:

### Reusable

Current code or structure can likely be kept with minor adaptation.

Document:

- File/folder
- Why it is reusable
- Any constraints

### Needs Refactor

Current code works but conflicts with the new direction or architecture.

Document:

- File/folder
- Current behavior
- Why refactor is needed
- Downstream dependencies

### Broken / Risky

Current code is non-functional, fragile, unsafe, or likely to break live behavior.

Document:

- File/folder
- Failure mode
- User impact
- Release risk

### Deprecated / Candidate For Removal

Current code appears unused, duplicated, obsolete, or superseded by the new direction.

Document:

- File/folder
- Why it may be obsolete
- What depends on it
- What must be verified before removal

### Requires Migration Planning

Current data, schema, persistence, entitlement, or cloud behavior cannot be changed safely without a migration plan.

Document:

- Entity/service/feature
- Existing data shape
- New target direction
- Migration risk
- Required planning document

### Requires Test Coverage

Current or planned behavior is not safely covered by tests.

Document:

- Behavior
- Existing coverage
- Missing cases
- Suggested test category

## Final Audit Deliverable

The audit should produce a separate final report after the audit is performed.

Recommended structure for that report:

1. Executive summary
2. Current architecture map
3. Current data model inventory
4. Persistence and CloudKit status
5. CalculationEngine status
6. Feature-by-feature findings
7. DesignSystem status
8. Premium status
9. Widget status
10. Localization status
11. Test status
12. App Store/live data risks
13. Reusable components and services
14. Refactor candidates
15. Broken/risky areas
16. Deprecated/removal candidates
17. Migration planning requirements
18. Required test coverage
19. Recommended next planning documents

## Success Criteria

The audit is complete when:

- All scoped areas have been inspected and documented
- The current app architecture is clearly mapped
- All active CoreData entities are inventoried
- PersistenceService and CloudKit status are documented
- CalculationEngine capabilities and duplicate calculation risks are documented
- Home, Income, Expense, Savings, Premium, Widgets, and DesignSystem status are documented
- Localization coverage and hardcoded string risks are documented
- Test status is documented
- Live user data and App Store risks are documented
- Findings are classified using the required output statuses
- Migration-planning needs are clearly identified
- No code, schema, target, dependency, or UI changes were made during the audit

When these criteria are met, BudgetMeter is ready for the next implementation planning document: the data model and migration plan.

