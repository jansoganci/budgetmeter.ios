# BudgetMeter iOS
BudgetMeter is a privacy-first iOS app for people who want to track income, expenses, and savings goals with live financial feedback, and it is currently in active development (not publicly live yet).

## What it does
- Calculates your live money flow in real time while the app is open, so you can see how your budget changes moment by moment.
- Lets you log income and expenses by category with daily, monthly, and yearly frequencies for consistent tracking.
- Shows a financial dashboard with net flow, health scoring, and day/month snapshots from your stored data.
- Tracks savings goals with progress indicators and time-to-goal estimates based on your current financial patterns.
- Supports 21+ currencies and 10 languages, while keeping data local-first with private iCloud sync.

## How I built this
I built this project with an AI-orchestrated workflow using Cursor for implementation speed, Claude for architecture and edge-case reasoning, and Copilot for in-editor code completion during SwiftUI and ViewModel work. I used AI to draft view structures, service scaffolding, and repetitive localization/test patterns, then personally reviewed business logic, data flow boundaries, and all finance-related calculations before keeping changes. Final technical decisions around module boundaries, persistence behavior, and user experience trade-offs were made manually.

## Tech Stack
- **Frontend:** SwiftUI (iOS 17.0+), Swift 5.9, MVVM, Swift Concurrency (`async/await`)
- **Backend:** No external backend (local-first architecture on device)
- **Database:** Core Data with CloudKit private database sync
- **Integrations:** iCloud/CloudKit, Apple localization via String Catalogs (`.xcstrings`)
- **Deployment:** Xcode 15+ build pipeline, iOS app target (`budgetmeter.ios`)

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+** deployment target
- **Apple Developer Account** (for device testing and CloudKit)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/jansoganci/budgetmeter.ios.git
   cd budgetmeter.ios
   ```

2. **Open in Xcode**
   ```bash
   open budgetmeter.ios.xcodeproj
   ```

3. **Configure CloudKit** (Required for data sync)
   - Sign in with your Apple Developer account in Xcode
   - Select your development team in project settings
   - CloudKit container will be automatically configured

4. **Build and Run**
   - Select your target device or simulator
   - Press `⌘ + R` to build and run

### 🔧 Development Setup

The project uses **zero external dependencies** - everything is built with Apple's native frameworks for maximum stability and performance.

## 📊 Core Features Deep Dive

### 🏠 Live Financial Meter
- **Real-time calculation** of financial flow based on your income/expense data
- **Session-based tracking** - shows money flow since you opened the app
- **Background state handling** - preserves calculation state when app goes to background
- **Precise timing** - uses high-resolution timers for accurate calculations

### 💰 Income & Expense Management
- **Predefined categories** for quick data entry
- **Multiple frequency support** - daily, monthly, yearly amounts
- **Decimal precision** for accurate financial calculations
- **Instant persistence** - all changes saved immediately to Core Data

### 📈 Financial Dashboard
- **Net financial flow** calculation
- **Financial health scoring** system
- **Cumulative tracking** - total financial flow since first app use
- **Today's snapshot** - daily and monthly flow summaries

### 🎯 Savings Goal Management
- **Custom goal setting** - set any savings target amount
- **Progress tracking** - visual progress indicators
- **Time-to-goal projections** - calculated based on current financial patterns
- **Goal modification** - easily update or remove goals anytime

### 💰 Multi-Currency System
- **21+ supported currencies** - USD, EUR, TRY, JPY, GBP, CAD, CHF, CNY, and more
- **Language-based defaults** - automatically selects appropriate currency for your language
- **Consistent formatting** - standardized number formatting across all currencies
- **Real-time conversion** - seamless currency switching with data preservation

## 🔒 Privacy & Security

BudgetMeter is built with **privacy-by-design** principles:

- ✅ **No external servers** - All processing happens on your device
- ✅ **No analytics or tracking** - We don't collect any usage data
- ✅ **No third-party dependencies** - Built entirely with Apple frameworks
- ✅ **Private CloudKit sync** - Your data stays in your personal iCloud account
- ✅ **Local-first architecture** - App works completely offline

## 🧪 Testing

The project includes comprehensive unit tests, especially for financial calculations:

```bash
# Run all tests
⌘ + U in Xcode

# Test coverage focuses on:
# - Financial calculation engine accuracy
# - Core Data persistence operations
# - ViewModel business logic
# - Currency formatting and parsing
```

## 🌍 Localization

Currently supported languages:
- **English** (Primary)
- **Turkish** (Native support)
- **German** (Deutsch)
- **French** (Français)
- **Spanish** (Español)
- **Italian** (Italiano)
- **Portuguese** (Português)
- **Japanese** (日本語)
- **Chinese Simplified** (简体中文)
- **Arabic** (العربية)

All user-facing strings are externalized using Xcode's modern String Catalogs system (.xcstrings) with complete translations for all supported languages. The app automatically selects appropriate currency defaults based on the chosen language.

## 🎨 Design Philosophy

BudgetMeter follows Apple's **Human Interface Guidelines** with:

- **Minimalist design** - Focus on essential features only
- **Native iOS patterns** - Familiar navigation and interactions
- **Accessibility first** - Full VoiceOver support and Dynamic Type
- **Dark Mode support** - Seamless light/dark theme switching
- **Performance optimized** - Sub-3-second launch times

## 📈 Roadmap

### Version 1.0 (Current)
- [x] Core financial tracking functionality
- [x] Live meter with real-time calculations
- [x] Basic income/expense categories
- [x] CloudKit sync
- [x] iOS HIG compliance
- [x] Multi-currency support (21+ currencies)
- [x] Multi-language support (10 languages)
- [x] Savings goal tracking with progress visualization
- [x] Financial health scoring system
- [x] Cumulative financial flow tracking

### Version 1.1 (Planned)
- [ ] Custom category creation
- [ ] Advanced charts and visualizations
- [ ] Export functionality (CSV, PDF)
- [ ] Widgets for iOS home screen
- [ ] Apple Watch companion app
- [ ] Enhanced savings goal features (multiple goals)

### Version 2.0 (Future)
- [ ] Advanced budgeting features
- [ ] Trend analysis and insights
- [ ] Financial forecasting
- [ ] Category spending limits
- [ ] Recurring transaction templates

## 🤝 Contributing

This is currently a personal project, but feedback and suggestions are welcome! Please feel free to:

1. **Report bugs** via GitHub Issues
2. **Suggest features** for future versions
3. **Submit pull requests** for bug fixes
4. **Share feedback** on user experience

### Development Guidelines

- Follow Swift API Design Guidelines
- Maintain 100% test coverage for financial calculations
- Ensure all UI changes are accessible
- Test on multiple iOS versions and device sizes
- Respect privacy-first principles
- Test with all supported languages and currencies
- Verify savings goal calculations and projections

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Jan Soganci**
- GitHub: [@jansoganci](https://github.com/jansoganci)
- Project: [BudgetMeter iOS](https://github.com/jansoganci/budgetmeter.ios)

## 🙏 Acknowledgments

- Built with ❤️ using Apple's native iOS frameworks
- Inspired by the need for privacy-focused financial tools
- Designed following Apple's Human Interface Guidelines
- Optimized for the iOS ecosystem and user experience

---

**Made with 🍎 for iOS • Privacy First • Open Source**

*BudgetMeter: Take control of your finances, privately.*
