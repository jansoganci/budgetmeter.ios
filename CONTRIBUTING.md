# Contributing to BudgetMeter iOS

Thank you for your interest in contributing to BudgetMeter! This guide will help you get started.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Architecture](#project-architecture)
- [Code Style](#code-style)
- [Git Workflow](#git-workflow)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)

---

## Development Setup

### Requirements

- **Xcode 15.0+**
- **iOS 17.0+ SDK**
- **macOS Sonoma 14.0+** (recommended)
- **Apple Developer Account** (for CloudKit and device testing)

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/jansoganci/budgetmeter.ios.git
   cd budgetmeter.ios
   ```

2. **Open in Xcode**
   ```bash
   open budgetmeter.ios.xcodeproj
   ```

3. **Configure Signing**
   - Select the project in Navigator
   - Go to "Signing & Capabilities"
   - Select your Team
   - Xcode will auto-manage provisioning

4. **Build and Run**
   - Select an iOS 17+ simulator
   - Press `⌘R` to build and run

### CloudKit Setup (Optional)

For CloudKit sync to work:
1. Enable iCloud capability in Xcode
2. Select CloudKit and create/select a container
3. Use container: `iCloud.com.budgetmeter.ios`

---

## Project Architecture

### MVVM + Clean Architecture

```
View (SwiftUI) → ViewModel (@MainActor) → Service → CoreKit → CoreData
```

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `Features/` | Feature modules (View + ViewModel) |
| `CoreKit/` | Business logic, services, persistence |
| `DesignSystem/` | Reusable UI components |
| `Resources/` | Localization files |

### Creating a New Feature

1. Create folder: `Features/{Name}Feature/`
2. Add `ViewModel/{Name}ViewModel.swift`
3. Add `View/{Name}View.swift`
4. Follow existing patterns (see `HomeFeature` as reference)

---

## Code Style

### Swift Conventions

#### Naming

| Type | Convention | Example |
|------|------------|---------|
| Types | PascalCase | `HomeViewModel` |
| Variables | camelCase | `isLoading` |
| Constants | camelCase | `maxRetryCount` |
| Protocols | PascalCase + suffix | `DataLoadable` |

#### File Organization

```swift
import Foundation
import SwiftUI

// MARK: - Type Definition
@MainActor
final class ExampleViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var data: [Item] = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private let service: SomeService

    // MARK: - Initialization
    init(service: SomeService = .shared) {
        self.service = service
    }

    // MARK: - Public Methods
    func loadData() async {
        // Implementation
    }

    // MARK: - Private Methods
    private func processData() {
        // Implementation
    }
}
```

#### SwiftUI Views

```swift
struct ExampleView: View {
    @StateObject private var viewModel = ExampleViewModel()

    var body: some View {
        content
            .navigationTitle("Example")
    }

    // Extract complex views into computed properties
    @ViewBuilder
    private var content: some View {
        // View content
    }
}
```

### Do's and Don'ts

#### Do

- Use `@MainActor` on all ViewModels
- Use `async/await` for asynchronous code
- Add `// MARK: -` comments for code organization
- Keep functions focused and small (< 30 lines ideally)
- Write self-documenting code with clear names
- Use DesignSystem components for UI consistency
- Localize all user-facing strings

#### Don't

- Don't add external dependencies (zero-dep policy)
- Don't put business logic in Views
- Don't use force unwrapping (`!`) except for IBOutlets
- Don't use `DispatchQueue` - use Swift Concurrency
- Don't hardcode colors - use `BrandColors`
- Don't hardcode strings - use localization
- Don't commit commented-out code

---

## Git Workflow

### Branch Naming

| Type | Format | Example |
|------|--------|---------|
| Feature | `feature/short-description` | `feature/dark-mode` |
| Bug Fix | `fix/short-description` | `fix/crash-on-launch` |
| Refactor | `refactor/short-description` | `refactor/home-view` |
| Docs | `docs/short-description` | `docs/readme-update` |

### Commit Messages

Use conventional commits format:

```
type(scope): description

[optional body]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```
feat(home): add daily budget card
fix(expenses): resolve crash when deleting category
refactor(core): simplify calculation engine
docs: update contributing guide
test(engine): add edge case tests for negative values
```

### Keeping Up to Date

```bash
# Fetch latest changes
git fetch origin

# Rebase your branch on main
git rebase origin/main

# Or merge (if you prefer)
git merge origin/main
```

---

## Pull Request Process

### Before Opening a PR

1. **Run Tests**
   ```bash
   ⌘U in Xcode
   ```

2. **Build Successfully**
   ```bash
   ⌘B in Xcode
   ```

3. **Run SwiftLint** (if installed)
   ```bash
   swiftlint lint
   ```

4. **Self-Review**
   - Check for debug code (`print` statements)
   - Verify localization
   - Test on multiple simulators

### PR Template

```markdown
## Summary
Brief description of changes.

## Changes
- Change 1
- Change 2

## Testing
- [ ] Tested on iPhone simulator
- [ ] Tested on iPad simulator (if applicable)
- [ ] Unit tests pass
- [ ] No SwiftLint warnings

## Screenshots
(If UI changes)
```

### Review Process

1. Open PR against `main` branch
2. Ensure CI checks pass (if configured)
3. Request review from maintainers
4. Address feedback
5. Squash and merge when approved

---

## Testing Guidelines

### What to Test

| Priority | What | Where |
|----------|------|-------|
| High | Calculation logic | `CalculationEngineTests` |
| High | ViewModel logic | `ViewModelTests` |
| Medium | Service methods | `ServiceTests` |
| Lower | UI components | Manual testing |

### Writing Tests

```swift
import XCTest
@testable import budgetmeter_ios

final class ExampleTests: XCTestCase {

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        // Setup
    }

    // MARK: - Tests

    func test_exampleFunction_withValidInput_returnsExpectedResult() {
        // Arrange
        let input = "test"

        // Act
        let result = someFunction(input)

        // Assert
        XCTAssertEqual(result, expectedValue)
    }
}
```

### Test Naming Convention

```
test_[methodName]_[condition]_[expectedResult]
```

Examples:
- `test_calculateMonthlyExpense_withDailyAmount_returnsCorrectMonthly`
- `test_healthScore_withZeroExpenses_returnsMaxScore`

### Running Tests

```bash
# Xcode
⌘U

# Command Line
xcodebuild test -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Localization

### Adding New Strings

1. Identify the appropriate `.xcstrings` file in `Resources/`
2. Add the key with English value
3. Add translations for all 10 supported languages

### Supported Languages

| Code | Language |
|------|----------|
| en | English |
| tr | Turkish |
| de | German |
| fr | French |
| es | Spanish |
| it | Italian |
| pt | Portuguese |
| ja | Japanese |
| zh-Hans | Chinese (Simplified) |
| ar | Arabic |

### Using Localized Strings

```swift
// In SwiftUI
Text("home_title", tableName: "Home")

// In code
let title = String(localized: "home_title", table: "Home")
```

---

## Questions?

If you have questions:
1. Check existing documentation in `/docs`
2. Review similar code in the codebase
3. Open an issue for discussion

Thank you for contributing!
