# UI/UX Core Screen Alignment Plan

## 1. Executive Summary

This plan documents how to adapt the Welcome/Auth, Insights, and Settings areas to match the current real BudgetMeter design language established by Home, Income, and Expenses. It is an implementation plan only. It does not authorize Swift code changes, Xcode project changes, business logic changes, auth behavior changes, or premium entitlement changes.

The current core app language is already visible and usable in:

- `budgetmeter.ios/Features/HomeFeature/View/HomeView.swift`
- `budgetmeter.ios/Features/IncomesFeature/View/IncomeView.swift`
- `budgetmeter.ios/Features/ExpensesFeature/View/ExpenseView.swift`
- `budgetmeter.ios/DesignSystem/Colors/BrandColors.swift`
- `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift`
- `budgetmeter.ios/DesignSystem/Typography/TextStyles.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/*`
- `budgetmeter.ios/DesignSystem/Components/Rows/*`
- `budgetmeter.ios/DesignSystem/Components/Sections/*`

The screens needing adaptation currently diverge in predictable ways:

- Settings uses native `List` rows and default iOS styling much more than the core screens.
- Insights is partly custom, but chart cards still use system backgrounds, raw colors, and ad hoc spacing.
- Welcome/Auth uses some tokens on the first screen, but the email auth flows use native `Form` styling and weak loading/error presentation.
- Premium entry points are inconsistent across Settings, Insights, Account/Backup, and the shared premium wrapper.
- Several files still use raw `.primary`, `.secondary`, `.red`, `.green`, `.blue`, `Color(.systemBackground)`, `Color(uiColor:)`, and legacy `Color(hex: "4A90E2")` instead of semantic tokens.

Recommended implementation order:

1. Settings first.
2. Insights second.
3. Welcome/Auth third.
4. Shared token cleanup last.

This order addresses the largest visual mismatch first, then the highest-content dashboard surface, then auth entry and secondary sheets, while postponing shared-token cleanup until the target screen patterns are clear.

## 2. Current Reference Design Language From Home / Income / Expenses

### Layout Structure

Home uses a full-screen `NavigationView` with a `ZStack` and explicit `Color.appBackground.ignoresSafeArea()`. Its main content is a compact dashboard in a vertical scroll stack using `Spacing.lg` and horizontal `Spacing.lg` padding.

Income and Expenses use `NavigationView > ScrollView > VStack`, with:

- `Color.appBackground` as the scroll background.
- `Spacing.lg` between major blocks.
- `Spacing.md` between financial sections.
- `Spacing.lg` horizontal padding on hero summary cards.
- Large navigation titles.
- Pull-to-refresh.

### Surfaces and Cards

The source-of-truth surfaces are:

- `Color.appBackground` / `Color.surfaceObsidian` for the screen base.
- `Color.surfaceCard` / `Color.cardBackground` for cards.
- `Color.surfaceRaised` for elevated card variants.
- `Color.surfaceInset` for nested wells.
- `Color.surfaceOverlay` for sheet/overlay panels.
- `surfaceCard`, `smallCard`, `surfaceInset`, and `surfaceOverlay` as preferred modifiers.

Cards consistently use:

- `CornerRadius.card` for main cards.
- `CornerRadius.button` for compact action surfaces.
- `Color.borderSubtle` for outlines.
- `ShadowStyle.card` or `ShadowStyle.small`.

### Typography

The current app language favors custom semantic styles:

- `paceHeroStyle` for dashboard pace and major values.
- `metricCompactStyle` for compact financial values.
- `sectionTitleStyle` for section headers.
- `cardLabelStyle` for card/row labels.
- `captionStyle` for supporting text.
- `badgeStyle` for compact uppercase state labels.
- `bodyStyle` for regular readable body text.

Raw `.font(.body)`, `.font(.caption)`, `.font(.headline)`, etc. still exist in places, but the core direction is tokenized text styles.

### Colors and Meaning

The core semantic palette:

- `.brandPositive` / `.financialPositive`: income, forward movement, healthy state.
- `.brandExpense` / `.financialNegative`: expense, drain, negative pace.
- `.brandProgress` / `.accentPrimary`: progress, primary CTA, neutral app accent.
- `.financialCaution`: warning or attention state.
- `.financialNeutral`: insufficient or stable data.
- `.textPrimary`, `.textSecondary`, `.textTertiary`: text hierarchy.
- `.borderSubtle`, `.dividerSubtle`, `.chartTrack`, `.chartInactive`: structure and charts.

Avoid introducing more raw hue families unless they come from category-specific data or a clearly named semantic token.

### Buttons and Interactions

Core buttons are plain SwiftUI buttons styled as custom surfaces:

- Primary CTA: `.background(Color.brandProgress)` with white text and `CornerRadius.button`.
- Secondary CTA: card background plus subtle border.
- Compact action cards: icon above label, `TouchTarget.large`, card surface.
- Row actions: full-row `contentShape(Rectangle())`, icon/label/value layout, haptics where already established.

### Navigation and Sheets

Home, Income, and Expenses use large navigation titles at top-level. Sheets are used for entry/edit flows:

- Home opens Income and Expense as sheets.
- Home uses detents for utility sheets like savings goal and daily budget info.
- Income/Expenses use sheets for edit and create-category flows.

Future alignment should preserve behavior but normalize presentation styling.

### Loading and Empty States

Home has the clearest empty state: a centered welcome hero, tokenized colors, and two clear CTAs. Income/Expenses have simpler loading states and currently do not fully use `EmptyStateRow`, but their structure still establishes the intended surface and section language.

## 3. Welcome/Auth Screen Gap Analysis

Files inspected:

- `budgetmeter.ios/Features/AuthFeature/View/RootAuthView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/SplashView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/WelcomeView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/SignInView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/RegisterView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/ForgotPasswordView.swift`

### Current Strengths

- `WelcomeView` already uses `Spacing.xl`, `.brandProgress`, and `.textSecondary`.
- The auth entry is simple and avoids changing auth behavior.
- `SignInWithAppleButton` uses the correct platform-provided control.
- Auth routing is isolated in `RootAuthView`, which should remain behaviorally untouched.

### Layout Gaps

- `WelcomeView` does not explicitly set `Color.appBackground.ignoresSafeArea()`, so its base can read as default SwiftUI rather than BudgetMeter.
- The welcome hero is visually sparse compared with Home's first-run state. It has an icon, title, subtitle, and CTA stack, but no dashboard-like momentum signal, card grouping, or rich app surface.
- `SplashView` is minimal and lacks the same full-screen background and vertical spacing conventions as Home's loading state.
- `SignInView`, `RegisterView`, and `ForgotPasswordView` are native `Form` screens. This is the largest Auth divergence.

### Surface and Card Gaps

- Email sign-in button on `WelcomeView` uses `Color.cardBackground` and radius but no `surfaceCard`, border, or shadow.
- Auth forms use default `Form` row backgrounds instead of `surfaceCard` or `surfaceOverlay`.
- Error/status messages are free text in form rows rather than styled banners or inset surfaces.

### Typography Gaps

- Welcome uses raw `.largeTitle` and `.fontWeight(.bold)` rather than app semantic styles.
- Auth forms use native text fields and form labels; they do not use `bodyStyle`, `captionStyle`, or app-styled field labels.
- Error and status text use raw `.caption`.

### Button Gaps

- "Create Account" is a bare text button; visually weaker than the primary/secondary CTA patterns used in Home.
- Auth submit buttons are default form buttons, not full-width BudgetMeter CTAs.
- Disabled/loading state is behavioral but not visibly expressive enough.

### Color/Token Gaps

- Auth errors use raw `.red`.
- Forgot password success uses raw `.green`.
- Platform Apple button can remain platform-native, but the surrounding screen should carry the app styling.

### Modal/Sheet Gaps

- `WelcomeView` opens Sign In and Register as sheets without detents or consistent overlay styling.
- `SignInView` opens Forgot Password as a nested sheet, which can feel stacked and less intentional than a navigation push inside the auth sheet.
- Later implementation should not change auth behavior; it should only adapt presentation if the same route semantics are preserved.

### Accessibility/Readability Notes

- Add explicit accessibility labels/hints to custom auth CTAs during implementation.
- Preserve Apple button accessibility.
- Loading states should announce progress and not only disable forms.
- Ensure long localized auth strings wrap cleanly within CTA buttons.

## 4. Insights Screen Gap Analysis

Files inspected:

- `budgetmeter.ios/Features/InsightsFeature/View/InsightsView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/SpendingBreakdownView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/MonthComparisonView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/BalanceTrendView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/ChartLegendView.swift`
- `budgetmeter.ios/Features/InsightsFeature/ViewModel/InsightsViewModel.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumFeatureView.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift`

### Current Strengths

- `InsightsView` uses a dashboard-like `ScrollView` and grouped sections.
- `InsightCardView` uses `Color.cardBackground`, `CornerRadius.card`, and some app text styles.
- Loading, empty, content, and paywall states are separated clearly.
- Chart components are modular.

### Layout Gaps

- `InsightsView` uses `NavigationStack`, while Home/Income/Expenses use `NavigationView`. This is not necessarily a functional issue, but the peer top-level screens are inconsistent.
- Main content does not explicitly apply `Color.appBackground` at the screen level.
- The `VStack(spacing: Spacing.xl)` creates a larger vertical rhythm than Income/Expenses' `Spacing.lg` major stack. This may be acceptable for charts, but should be intentional.
- Chart card internals use local constants such as `16`, `20`, and fixed heights, rather than `Spacing` and shared chart/card tokens.

### Surface and Card Gaps

- `InsightCardView` uses `.background(Color.cardBackground).cornerRadius(CornerRadius.card)` but does not use `surfaceCard`; it lacks the border/shadow language of Home cards.
- Chart cards use `Color(.systemBackground)`, ad hoc `cornerRadius(16)`, and hardcoded shadow values.
- Chart nested stat panels use `Color(.secondarySystemBackground)` instead of `surfaceInset`.
- Chart overlays use `Color(.systemBackground)`, making them feel native rather than BudgetMeter.

### Typography Gaps

- `InsightsView` paywall, loading, and empty states use raw `.title`, `.headline`, `.subheadline`, `.caption2`.
- Chart headers and labels use raw font styles throughout.
- Metric values in charts should use `metricCompactStyle` or a chart-specific metric style derived from the current text system.

### Color/Token Gaps

- Chart components use `.blue`, `.green`, `.red`, `.orange`, `.gray`, `.purple`, `.pink`, `.cyan`, `.indigo`, `.mint`.
- Positive/negative trend states should use `.financialPositive`, `.financialNegative`, and `.financialCaution` unless the color is category-specific.
- Premium wrapper uses legacy `Color(hex: "4A90E2")`, while the current app accent is `.brandProgress` / `.accentPrimary`.

### Premium Gate Gaps

- `ContentView` wraps `InsightsView` in `PremiumFeatureView`, but `InsightsView` also contains internal paywall state and sheet presentation.
- `PremiumFeatureView` has its own gated screen, `InsightsView` has another, Settings has banner-based entry, and Account/Backup has another paywall sheet.
- Later implementation should select one gate ownership pattern for Insights while preserving premium logic. Prefer keeping entitlement checks centralized and presentation consistent.

### Empty/Loading State Gaps

- Loading is full-screen but visually minimal.
- Empty state is clear but not styled with the richer Home empty state pattern.
- Skeleton cards use raw gray opacity and lack design-system surface treatment.

### Accessibility/Readability Notes

- Chart accessibility labels are currently plain English strings in some places; review localization/accessibility consistency later.
- Fixed legend widths and four-item horizontal legends may break with localization or Dynamic Type.
- Chart touch selection should remain reachable, but visual focus/selected state should use semantic colors.

## 5. Settings Screen Gap Analysis

Files inspected:

- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/CurrencyPickerView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/LanguagePickerView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/AppearancePickerView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/NotificationSettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/Components/NotificationPermissionBanner.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/Components/NotificationToggleRow.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/NotificationSettingsViewModel.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`

### Current Strengths

- Settings has clear information architecture: Premium, General, Account, Data & Privacy, About, Debug.
- `PremiumUpgradeBanner` is already close to the card language and uses `surfaceCard`.
- Picker sheets use detents and drag indicators where appropriate.
- Rows are easy to scan because the native `List` provides familiar structure.

### Layout Gaps

- `SettingsView` is a native `List`, while core screens are custom `ScrollView` stacks on `Color.appBackground`.
- Native section grouping makes Settings look like iOS Settings rather than BudgetMeter.
- Row spacing uses hardcoded `12` and `2` values instead of `Spacing.md` and `Spacing.xs`.
- The Settings visual density is not aligned with Income/Expenses rows, which use custom icon/name/value/edit layouts.

### Surface and Card Gaps

- Most Settings rows rely on default list row surfaces.
- Picker sheets use default `List` and inset grouped styles.
- Legal sheets use raw text in a `ScrollView`, with no `Color.appBackground` and no surface treatment.
- Account/Backup and Notification settings also use native `List` or system backgrounds.

### Typography Gaps

- Settings rows use raw `.body` and `.caption`.
- Section headers are native list headers, not `sectionTitleStyle` or a settings-specific app header style.
- Legal documents use `.largeTitle`, `.headline`, `.body`, `.caption`; acceptable for document readability, but visually disconnected from app surfaces.

### Button and Row Gaps

- Some rows have icons, some do not. General rows lack leading icons, while Premium, Account, Data & Privacy, and About rows usually include them.
- Chevron handling is manual in button rows but native in `NavigationLink` rows.
- Destructive rows use raw `.red`.
- Contact Support directly opens `mailto:` from Settings; keep behavior unchanged later, but align row styling.

### Color/Token Gaps

- Frequent `.primary` and `.secondary` usage.
- Raw `.red` for destructive actions.
- Legacy `Color(hex: "4A90E2")` in Currency/Language checkmarks.
- Some nested settings screens use `Color(.systemBackground)` or default list background.

### Premium Gate Gaps

- Non-premium Settings uses `PremiumUpgradeBanner`, which is good.
- Account/Backup uses a separate "Upgrade for Cloud Backup" row with `PremiumPaywallView(feature: nil)`.
- Premium feature rows for signed-in premium users are simple list rows, not card-like or grouped by the same visual system as core financial rows.
- Later implementation should not alter premium logic; only normalize presentation and feature-specific messaging.

### Modal/Sheet Gaps

- Currency and Language use `.medium, .large`; Appearance uses fixed `.height(280)`. That may be acceptable, but presentation should follow consistent sheet surface rules.
- Privacy and Terms sheets are full `NavigationView` sheets with long text and no detents. Later implementation should decide whether legal sheets remain full-height for readability.

### Accessibility/Readability Notes

- Native `List` provides good accessibility by default. Replacing it with custom rows later must preserve accessibility traits, labels, values, and dynamic type behavior.
- Account status can show a raw user ID; it is line-limited in Account/Backup, but Settings account row should avoid unreadable long identifiers.
- Legal text should remain readable; do not over-card or compress long legal content.

## 6. Shared Problems Across These Screens

### Default iOS Styling

The biggest shared gap is reliance on native `List` and `Form` surfaces in Auth and Settings, and system-background chart cards in Insights. Home/Income/Expenses look like a custom product; these areas often look like default iOS scaffolding.

### Hardcoded Colors

Common divergences:

- `.primary`
- `.secondary`
- `.red`
- `.green`
- `.blue`
- `.orange`
- `.gray`
- `Color(.systemBackground)`
- `Color(.secondarySystemBackground)`
- `Color(uiColor:)`
- `Color(hex: "4A90E2")`

These should be replaced with semantic tokens unless the value is platform-mandated or intentionally category-specific.

### Inconsistent Premium Presentation

Premium entry exists as:

- Settings upgrade banner.
- Premium wrapper gated view.
- Insights internal paywall.
- Account/Backup premium row.
- Expense subscriptions locked section.
- Paywall sheets with and without `feature`.

Presentation should be unified without changing entitlement checks or purchase/restore behavior.

### Inconsistent Navigation Containers

Top-level screens mix `NavigationView` and `NavigationStack`. Later implementation should choose a practical alignment strategy. If migration is too broad, leave functionality untouched and normalize only visual presentation.

### Inconsistent Loading and Empty States

Home has the clearest first-run pattern. Insights/Auth/Settings nested flows use simpler loaders, disabled forms, or default empty messages. Later implementation should define reusable empty/loading surfaces.

### Typography Drift

Raw SwiftUI fonts are scattered across Auth, Insights charts, Settings rows, Premium wrappers, and legal sheets. Later implementation should either use existing semantic text styles or introduce narrowly scoped new styles only if the current set cannot express settings/legal/chart needs.

### Accessibility Regression Risk

Replacing `List` and `Form` with custom UI can reduce accessibility if not done carefully. Custom rows must preserve button traits, selected state, values, hints, and dynamic type wrapping.

## 7. Exact Files Likely To Change Later

### Settings First

- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/CurrencyPickerView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/LanguagePickerView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/AppearancePickerView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/NotificationSettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/Components/NotificationPermissionBanner.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/Components/NotificationToggleRow.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`

Likely new shared components:

- `budgetmeter.ios/DesignSystem/Components/Rows/SettingsRowView.swift`
- `budgetmeter.ios/DesignSystem/Components/Sections/SettingsSection.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/SettingsInfoCard.swift`

### Insights Second

- `budgetmeter.ios/Features/InsightsFeature/View/InsightsView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/SpendingBreakdownView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/MonthComparisonView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/BalanceTrendView.swift`
- `budgetmeter.ios/Features/InsightsFeature/View/Charts/ChartLegendView.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumFeatureView.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift`

Likely new shared components:

- `budgetmeter.ios/DesignSystem/Components/Cards/InsightMetricCard.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/ChartCardContainer.swift`
- `budgetmeter.ios/DesignSystem/Components/Rows/ChartLegendRow.swift`

### Welcome/Auth Third

- `budgetmeter.ios/Features/AuthFeature/View/SplashView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/WelcomeView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/SignInView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/RegisterView.swift`
- `budgetmeter.ios/Features/AuthFeature/View/ForgotPasswordView.swift`

Likely new shared components:

- `budgetmeter.ios/Features/AuthFeature/View/AuthFormContainer.swift`
- `budgetmeter.ios/Features/AuthFeature/View/AuthTextFieldRow.swift`
- `budgetmeter.ios/Features/AuthFeature/View/AuthStatusBanner.swift`

### Shared Token Cleanup Last

- `budgetmeter.ios/DesignSystem/Colors/BrandColors.swift`
- `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift`
- `budgetmeter.ios/DesignSystem/Typography/TextStyles.swift`
- `budgetmeter.ios/DesignSystem/Components/Rows/SubscriptionRowView.swift`
- `budgetmeter.ios/DesignSystem/Components/Charts/MiniBarChart.swift`
- `budgetmeter.ios/DesignSystem/Components/Indicators/TrendIndicator.swift`

## 8. Files That Should Not Be Touched

During the later UI alignment implementation, avoid touching files that define data, persistence, entitlement, auth, purchase, backup, or calculation behavior unless a separate non-UI task explicitly requires it.

Do not touch:

- `budgetmeter.ios.xcodeproj/project.pbxproj`
- `budgetmeter.ios.xcodeproj/**`
- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- `budgetmeter.ios/CoreKit/Sources/Auth/AuthService.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseClientProvider.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseConfig.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/AppleSignInCoordinator.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/AuthSessionStore.swift`
- `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Premium/ThemeManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/**`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/CoreKit/Sources/Engine/**`
- `budgetmeter.ios/CoreKit/Sources/Services/**`
- `budgetmeter.ios/CoreKit/Sources/Widget/**`
- `budgetmeter.ios/WidgetShared/**`
- `BudgetMeterWidgets/**`
- `supabase/**`
- `budgetmeter.ios/Resources/*.xcstrings`, unless later copy changes are explicitly requested.

Avoid touching view models unless a visual state cannot be represented from existing published state. Even then, treat that as a separate scoped change and do not alter calculations, auth decisions, premium entitlement checks, backup behavior, or navigation semantics.

## 9. Design Rules To Enforce

1. Use Home, Income, and Expenses as visual source of truth.
2. Every top-level adapted screen should sit on `Color.appBackground`.
3. Prefer `ScrollView` plus custom sections/cards for product screens; use native `List` only when the default platform look is intentionally desired.
4. Use `surfaceCard`, `smallCard`, `surfaceInset`, or `surfaceOverlay` instead of ad hoc `background + cornerRadius + shadow`.
5. Use `Spacing` and `LayoutSpacing` instead of local constants for repeated UI rhythm.
6. Use semantic text styles before raw `.font(...)`.
7. Use `.textPrimary`, `.textSecondary`, and `.textTertiary` instead of `.primary` and `.secondary`.
8. Use `.brandProgress`, `.brandPositive`, `.brandExpense`, `.financialCaution`, and `.financialNeutral` instead of raw hue names.
9. Keep financial semantics consistent: income/positive is green, expense/negative is coral, progress/accent is cyan.
10. Do not use legacy `Color(hex: "4A90E2")` in feature UI.
11. Do not use `Color(.systemBackground)` or `Color(uiColor:)` for primary app cards unless a platform control requires it.
12. Buttons must have stable touch targets of at least `TouchTarget.minimum`.
13. Sheet contents should use app backgrounds and app surfaces, even when presented by platform sheets.
14. Premium gates must preserve existing entitlement behavior; only visual presentation should change.
15. Auth behavior must remain unchanged; only presentation should change.
16. Empty states should include an icon, clear title/message, and an action only when an action is already valid in current behavior.
17. Loading states should be visible, centered or in-card as appropriate, and accessible.
18. Custom replacements for `List`/`Form` must preserve accessibility traits and dynamic type behavior.
19. Legal/document text may be more utilitarian than dashboard UI, but it should still use app background, text colors, and spacing.
20. Avoid broad refactors during screen alignment; keep each phase visually focused.

## 10. Prioritized Implementation Checklist

### Priority 1: Settings

- Replace or visually adapt the root `List` in `SettingsView` to match the app card/section language.
- Define a reusable settings row component with optional icon, title, subtitle/value, trailing chevron/check/action, and destructive mode.
- Define a reusable settings section wrapper with app-styled header and `surfaceCard` content.
- Normalize General rows so Notifications, Language, Currency, and Appearance have consistent icon/title/subtitle/trailing affordances.
- Keep `PremiumUpgradeBanner` but verify its row insets, width, and card surface match the new Settings layout.
- Restyle Account/Backup to use the same settings section and row components.
- Restyle Currency, Language, and Appearance pickers using app background and app row styles while preserving sheet detents and selection behavior.
- Restyle privacy/terms sheets for app background, readable text hierarchy, and consistent toolbar behavior.
- Replace raw `.primary`, `.secondary`, `.red`, and `Color(hex: "4A90E2")` in Settings UI.

### Priority 2: Insights

- Add explicit `Color.appBackground` behind `InsightsView` states.
- Convert `InsightCardView` to `surfaceCard` or a new `InsightMetricCard`.
- Create a shared chart card container using `surfaceCard` and app spacing.
- Replace chart card `Color(.systemBackground)` and `Color(.secondarySystemBackground)` with `surfaceCard` and `surfaceInset`.
- Map chart status colors to financial semantic colors.
- Keep category colors only where they represent actual spending categories.
- Resolve duplicate premium gate ownership between `PremiumFeatureView` and `InsightsView` presentation without changing entitlement logic.
- Make loading, skeleton, empty, and paywall states visually match Home's onboarding/loading patterns.
- Check chart legends for localization and Dynamic Type wrapping.

### Priority 3: Welcome/Auth

- Add app background to `SplashView` and `WelcomeView`.
- Adapt Welcome hero to feel like BudgetMeter, using app text styles and a richer but simple surface composition.
- Restyle email auth button and create account action as primary/secondary app CTAs.
- Replace native `Form`-looking auth sheets with app-styled form containers, or heavily style the forms if behavior risk is lower.
- Add clear loading indicators to Sign In, Register, and Forgot Password while preserving current async behavior.
- Replace raw `.red` and `.green` auth messages with semantic status banner styling.
- Avoid changing Apple sign-in request scopes or completion behavior.
- Avoid changing sign-in, sign-up, password reset, or dismiss semantics.

### Priority 4: Shared Token Cleanup

- Remove UI usage of legacy `Color(hex: "4A90E2")` outside compatibility declarations.
- Add missing semantic tokens only when repeated UI states require them, such as destructive, success, selected, or warning.
- Audit `SubscriptionRowView`, `TrendIndicator`, `MiniBarChart`, and premium components for token drift.
- Do this after the screen-specific implementation settles the needed components.

## 11. Suggested Implementation Order

### 1. Settings First

Settings is the largest visual outlier because it is mostly native `List` UI. It also contains many user-facing routes, picker sheets, premium entry points, legal sheets, and account/backup controls. Aligning Settings first creates reusable settings rows and section patterns that can support Account/Backup and Notification settings.

Keep the first Settings pass visual-only:

- Do not change `SettingsViewModel`.
- Do not change account, backup, premium, reset, contact, or picker behavior.
- Do not edit localized strings unless explicitly requested.

### 2. Insights Second

Insights is partially aligned but has several custom chart components that need a unified card container and semantic colors. It should come after Settings because its premium-gate decisions can reuse any improved premium presentation patterns from Settings.

Keep the Insights pass visual-only:

- Do not change `InsightsViewModel`.
- Do not change premium access checks.
- Do not change chart data generation or calculations.
- Do not change what charts appear; only change their presentation.

### 3. Welcome/Auth Third

Auth comes third because it is behaviorally sensitive. The implementation must be careful not to alter sign-in, sign-up, password reset, Apple sign-in, session restoration, or biometric gating. Once Settings and Insights establish stronger shared components, Auth can reuse button, status, and sheet patterns.

Keep the Auth pass visual-only:

- Do not change `AuthService`.
- Do not change `RootAuthView` routing logic unless purely visual wrappers are needed.
- Do not change Apple requested scopes.
- Do not change auth async flow, error handling semantics, or dismiss timing.

### 4. Shared Token Cleanup Last

Only clean shared tokens after the target screens are aligned. This avoids prematurely adding unused tokens or broad refactors. Shared cleanup should be mechanical and reviewable.

## 12. Risk Notes

- Replacing native `List` and `Form` can regress accessibility. Custom rows must explicitly set accessibility labels, values, hints, and button traits.
- Settings has destructive controls. Visual redesign must not make Reset All Data, Delete Account, or Sign Out easier to trigger accidentally.
- Auth flows are high-risk. Presentation changes must not alter auth state, validation, async task order, or dismissal.
- Premium gates are high-risk. Do not change entitlement checks, feature identifiers, purchase callbacks, restore callbacks, or feature-specific paywall routing unless separately approved.
- Insights charts are data-dense. Card styling should not reduce legibility, chart plot size, or tap target quality.
- Legal sheets should prioritize readability over decorative card density.
- Dark and light mode must both be checked because the design tokens are adaptive.
- Dynamic Type can break compact chart legends, settings rows, and auth CTA buttons if fixed widths are retained.
- Localization can make row subtitles and chart legends much longer than English.
- Snapshot/widget/business data files should not be touched for UI alignment.

## 13. Build/Test Expectations For Later Implementation Phase

When implementation begins later, expected verification should include:

- Build the main app target with Xcode or `xcodebuild`.
- Run existing unit tests if the touched files or dependencies can affect state presentation.
- Manually inspect these flows in simulator:
  - Signed-out welcome screen.
  - Apple sign-in button visual placement.
  - Email sign-in sheet.
  - Create account sheet.
  - Forgot password sheet.
  - Signed-in Settings root.
  - Settings picker sheets: Currency, Language, Appearance.
  - Account & Backup.
  - Privacy Policy and Terms sheets.
  - Insights gated state for non-premium.
  - Insights empty state with insufficient data.
  - Insights populated state with cards and charts.
  - Premium paywall entry from Settings, Account/Backup, and Insights.
- Check light mode and dark mode.
- Check at least default Dynamic Type and one large accessibility size.
- Check narrow device width, such as iPhone SE class.
- Check that destructive actions still present confirmations.
- Check VoiceOver labels for custom rows/buttons when replacing native `List`/`Form`.

No business logic tests should need changes for a visual-only phase. If tests fail because behavior changed, treat that as a regression.

## 14. Success Criteria

The adaptation is successful when:

- Welcome/Auth, Insights, and Settings visually feel like the same app as Home, Income, and Expenses.
- Top-level and sheet backgrounds consistently use app surfaces instead of default system surfaces.
- Cards use `surfaceCard`, `smallCard`, `surfaceInset`, or intentionally equivalent design-system components.
- Settings no longer reads as an unstyled native iOS Settings clone.
- Insights chart cards match the BudgetMeter card system and use semantic colors.
- Auth forms look intentional and app-native without changing sign-in behavior.
- Premium gate entry points are visually consistent and behaviorally unchanged.
- Raw default colors are eliminated or justified where platform controls require them.
- Typography uses app text styles or clearly scoped new styles.
- Loading and empty states are consistent, readable, and accessible.
- Dynamic Type and localization do not cause obvious clipping or overlap.
- No Swift business logic, auth logic, premium logic, Xcode project files, data models, migrations, or resource string files are modified as part of the visual alignment effort.
