# CLAUDE.md - BudgetMeter iOS Project Context

## Project Overview

BudgetMeter is a privacy-first personal finance iOS app that helps users track income, expenses, and savings goals with real-time calculations and CloudKit sync.

**Key Characteristics:**
- 100% SwiftUI (iOS 17.0+)
- Zero external dependencies
- MVVM + Clean Architecture
- Feature-based modular organization
- CoreData + CloudKit for persistence and sync

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    View Layer                        │
│              (SwiftUI Views in Features/)            │
├─────────────────────────────────────────────────────┤
│                  ViewModel Layer                     │
│    (@MainActor ObservableObject in Features/)        │
├─────────────────────────────────────────────────────┤
│                  Service Layer                       │
│           (Managers in CoreKit/Services/)            │
├─────────────────────────────────────────────────────┤
│               Core Layer (CoreKit/)                  │
│     Persistence | Engine | Utilities | Security      │
├─────────────────────────────────────────────────────┤
│              CoreData + CloudKit                     │
└─────────────────────────────────────────────────────┘
```

## Directory Structure

```
budgetmeter.ios/
├── App/                          # App entry point
│   ├── budgetmeter_iosApp.swift  # @main, app initialization
│   └── ContentView.swift         # Tab navigation (5 tabs)
│
├── CoreKit/Sources/              # Core business logic
│   ├── Models/                   # Domain models (HealthScoreBreakdown, Insight, etc.)
│   ├── Persistence/              # PersistenceService (CoreData + CloudKit)
│   ├── Engine/                   # CalculationEngine (all financial math)
│   ├── Services/                 # Business managers (BillManager, SavingsGoalManager, etc.)
│   ├── Security/                 # BiometricManager
│   ├── Premium/                  # PremiumManager, ThemeManager
│   ├── Export/                   # DataExportService
│   └── Utilities/                # Helpers (Currency, DateFormatting, Localization)
│
├── DesignSystem/                 # UI component library
│   ├── Components/Cards/         # HeroNetFlowCard, HealthScoreCard, DailyBudgetCard
│   ├── Components/Charts/        # MiniBarChart
│   ├── Colors/                   # BrandColors
│   ├── Typography/               # TextStyles
│   └── Spacing/                  # LayoutTokens
│
├── Features/                     # Feature modules (each has ViewModel/ and View/)
│   ├── HomeFeature/              # Live meter, daily budget, overview
│   ├── ExpensesFeature/          # Expense entry and tracking
│   ├── IncomesFeature/           # Income entry and tracking
│   ├── InsightsFeature/          # Charts, trends, analytics
│   ├── SettingsFeature/          # App configuration
│   ├── SavingsGoalsFeature/      # Savings goal management
│   ├── BillsFeature/             # Bill tracking
│   ├── SubscriptionsFeature/     # Subscription management
│   ├── PremiumFeature/           # Premium paywall
│   └── Shared/                   # Cross-feature components
│
├── Widgets/                      # iOS widgets (needs extension setup)
├── Resources/                    # Localization (.xcstrings files)
├── Assets.xcassets/              # Images, colors, app icon
└── BudgetMeter.xcdatamodeld/     # CoreData model (8 entities)
```

## Key Files

| File | Purpose |
|------|---------|
| `CoreKit/Sources/Engine/CalculationEngine.swift` | All financial calculations (ported from JS) |
| `CoreKit/Sources/Persistence/PersistenceService.swift` | CoreData + CloudKit stack |
| `Features/HomeFeature/ViewModel/HomeViewModel.swift` | Main home screen logic |
| `DesignSystem/Components/Cards/` | Reusable card components |
| `BudgetMeter.xcdatamodeld/` | Database schema (8 entities) |

## CoreData Entities

1. **AppSettings** - App configuration (singleton)
2. **FinancialCategory** - Income/expense categories with amounts
3. **RecurringTransaction** - Recurring bills/subscriptions
4. **FinancialSnapshot** - Historical data for analytics
5. **Subscription** - Subscription tracking
6. **Bill** - Bill tracking with due dates
7. **BillPayment** - Payment history
8. **SavingsGoal** - Savings goals with targets

## Coding Conventions

### Swift Style
- Use `@MainActor` on all ViewModels
- Use `@Published` for reactive properties in ViewModels
- Prefer `async/await` over completion handlers
- Use Swift Concurrency for background work

### Naming
- Features: `{Name}Feature/` with `{Name}View.swift` and `{Name}ViewModel.swift`
- Services: `{Name}Manager.swift` or `{Name}Service.swift`
- Views: Suffix with `View` (e.g., `HomeView`, `BillRowView`)
- ViewModels: Suffix with `ViewModel` (e.g., `HomeViewModel`)

### Architecture Rules
- Views only talk to their ViewModel
- ViewModels use Services/Managers for business logic
- Services use PersistenceService for data access
- CalculationEngine is stateless (pure functions)
- Never import UIKit in SwiftUI views (use SwiftUI equivalents)

### Localization
- All user-facing strings must be localized
- Use String Catalogs (.xcstrings format)
- Add strings to appropriate file: `Localizable`, `Home`, `Settings`, `UI`, `Alerts`, `Categories`
- 10 languages supported: EN, TR, DE, FR, ES, IT, PT, JA, ZH, AR

## Build & Test

```bash
# Build (Xcode)
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios build

# Run tests
xcodebuild test -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 15'

# Or use Xcode shortcuts
# ⌘B - Build
# ⌘U - Run tests
# ⌘R - Run app
```

## Important Constants

Located in `CalculationEngine.swift`:
- `daysPerMonth = 30.4375` (365.25 / 12)
- `daysPerYear = 365.25`
- `hoursPerDay = 24`
- `weeksPerMonth = 4.348` (52.18 / 12)

## Common Tasks

### Adding a New Feature
1. Create folder: `Features/{Name}Feature/`
2. Create `ViewModel/{Name}ViewModel.swift` with `@MainActor class`
3. Create `View/{Name}View.swift` with SwiftUI view
4. Add navigation in `ContentView.swift` if needed

### Adding a New Service
1. Create in `CoreKit/Sources/Services/{Name}Manager.swift`
2. Use PersistenceService for data access
3. Make it a singleton if needed: `static let shared = {Name}Manager()`

### Adding Localized Strings
1. Add key to appropriate `.xcstrings` file in `Resources/`
2. Provide translations for all 10 languages
3. Use `NSLocalizedString("key", comment: "")` or `String(localized:)`

### Modifying CoreData Model
1. Create new model version in `BudgetMeter.xcdatamodeld`
2. Add migration mapping if needed
3. Update PersistenceService if schema changes significantly

## Do's and Don'ts

### Do
- Keep CalculationEngine pure and stateless
- Use DesignSystem components for UI consistency
- Test calculation logic in `CalculationEngineTests`
- Follow existing feature module structure
- Use `@MainActor` for all UI-related code
- Respect the MVVM boundaries

### Don't
- Don't add external dependencies (keep zero-dep policy)
- Don't put business logic in Views
- Don't access CoreData directly from Views
- Don't hardcode strings (use localization)
- Don't skip localization for any user-facing text
- Don't use UIKit when SwiftUI has equivalent

## Testing

- **CalculationEngineTests.swift** - 65+ tests for financial math
- **ViewModelCalculationTests.swift** - ViewModel consistency tests
- Run with `⌘U` in Xcode

## Documentation

| File | Content |
|------|---------|
| `README.md` | Project overview |
| `docs/blueprint.mdx` | Technical architecture |
| `docs/design_rulebook.mdx` | UI/UX standards |
| `docs/general_rulebook.mdx` | Coding standards |
| `FEATURE_ROADMAP.md` | Version roadmap |

## Current Status

- **Version**: ~1.0 (MVP feature complete)
- **Widgets**: Designed but non-functional (needs extension target)
- **Premium/IAP**: Partially implemented
- **App Store**: Ready after widget fixes

## Debugging

- Use `DebugView.swift` for development utilities
- Console logs use standard `print()` statements
- CoreData issues: Check PersistenceService error handling
