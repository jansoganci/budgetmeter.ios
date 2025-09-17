# 💰 BudgetMeter iOS

**A minimalist, privacy-first personal finance app for iOS**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Core Data](https://img.shields.io/badge/Core%20Data-CloudKit-red.svg)](https://developer.apple.com/documentation/coredata)

## 🎯 Overview

BudgetMeter is a native iOS application that provides a **real-time, continuous view** of your financial flow. Built with privacy-first principles, all your financial data stays on your device and syncs privately through your personal iCloud account.

### ✨ Key Features

- **📊 Live Financial Meter** - Real-time tracking of your money flow since app launch
- **💸 Income & Expense Tracking** - Simple category-based financial input
- **📈 Smart Dashboard** - Comprehensive financial health overview
- **🔒 Complete Privacy** - No external servers, no tracking, no data collection
- **☁️ Private iCloud Sync** - Your data syncs securely across your devices
- **🎨 Native iOS Experience** - Built with SwiftUI, follows Apple's Human Interface Guidelines

## 📱 Screenshots

*Coming soon - App Store screenshots will be added here*

## 🏗️ Architecture

BudgetMeter follows a **modular, feature-based architecture** built entirely on Apple's native frameworks:

### 🧩 Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **UI Framework** | SwiftUI | Modern, declarative iOS interface |
| **Architecture** | MVVM Pattern | Clean separation of concerns |
| **Data Layer** | Core Data + CloudKit | Local storage with private cloud sync |
| **Concurrency** | Swift Concurrency | Responsive UI with async operations |
| **Localization** | String Catalogs (.xcstrings) | Multi-language support |

### 📁 Project Structure

```
BudgetMeter.app/
├── 📱 App/
│   ├── BudgetMeterApp.swift          # Main app entry point
│   └── ContentView.swift             # Root view with tab navigation
│
├── 🔧 CoreKit/                       # Core business logic
│   ├── Models/                       # Core Data entities
│   ├── Engine/                       # Financial calculation engine
│   ├── Persistence/                  # Data management services
│   └── Utilities/                    # Shared utilities and extensions
│
└── 🎯 Features/                      # Feature-based modules
    ├── HomeFeature/                  # Dashboard and live meter
    ├── IncomesFeature/               # Income tracking interface
    ├── ExpensesFeature/              # Expense tracking interface
    └── SettingsFeature/              # App configuration
```

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
- **Savings goal tracking** with progress visualization
- **Time-to-goal** projections based on current spending patterns

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

All user-facing strings are externalized using Xcode's modern String Catalogs system for easy localization.

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

### Version 1.1 (Planned)
- [ ] Custom category creation
- [ ] Advanced charts and visualizations
- [ ] Export functionality
- [ ] Widgets for iOS home screen
- [ ] Apple Watch companion app

### Version 2.0 (Future)
- [ ] Multi-currency support
- [ ] Advanced budgeting features
- [ ] Financial goal setting
- [ ] Trend analysis and insights

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
