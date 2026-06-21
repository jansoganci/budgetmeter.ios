# UI Redesign Plan

## UI

- Final UI direction: Playful Momentum FinTech
- BudgetMeter should feel fun, gamified, consumer-friendly, modern, polished, and trustworthy
- The app should not feel childish, casino-like, or like a heavy accounting app
- Redesign the app around the Financial Pace core
- Home should center on a hybrid momentum ring + live financial pace number
- The main status copy should use plain momentum language, such as "Moving forward: +$12/day"
- Negative states should use gentle wording such as "Slowing down" instead of guilt, shame, or panic language
- Default main unit should be Day
- Minute should exist as a small live secondary metric, not the main default tab
- Time options should support minute, hour, day, week, and month through the shared normalized calculation model
- Income and Expense screens should become simple, summary-first flows
- Use clear separation between recurring and one-time money movement
- Keep the interface fast, personal, and easy to scan
- Use dark-first visual identity with obsidian / dark navy background and slate card surfaces
- Use lively accents: vivid cyan / blue / indigo as the main accent family, emerald for positive momentum, amber for caution, and coral for negative drain
- Avoid obvious AI-looking purple/pink gradient overuse, childish pastel overload, and casino-style gold glow
- Use modern iOS glass / Liquid Glass style carefully for navigation, sheets, overlays, and secondary surfaces
- Critical financial numbers should sit on solid or near-solid readable surfaces
- Do not place the main pace number on heavy blur if readability suffers
- Pulsey is the selected mascot direction and should appear mostly in the launch splash animation, with possible light future use in onboarding, empty states, success states, weekly recap, and milestones
- Pulsey must not dominate Home, slow transaction entry, or joke about negative financial states

## User Flow

- Users should understand the product through the first screen
- Main navigation should make Home feel central
- Other areas should support Home, not compete with it
- Users should quickly understand whether they are financially moving forward or slowing down
- Users should not need to learn a complex budgeting system
- Home should be status-first
- Income and Expense should be entry-first but still summary-aware
- Quick entry should stay fast and should not be interrupted by mascot moments or premium prompts
- Deeper insight and reporting should not crowd the core flows
- The redesign should reduce friction before adding more feature depth

## Services

- UI should depend on one shared normalized financial pace calculation service
- UI should depend on normalized income and expense data
- All pace values across minute, hour, day, week, and month should come from the same calculation model
- UI should support simple chart and comparison data where needed
- UI should use savings progress and net direction consistently
- UI should not require separate calculation paths for Home, charts, savings, widgets, or premium views
- UI components should be reusable across Income and Expense where the flows match

## Data Model

- UI should reflect the main product concepts: pace, net direction, recurring money, one-time money, savings progress, awareness streak, and weekly recap
- Data shown on screens should be minimal and decision-focused
- Income and expense structures should support daily, weekly, monthly, yearly, recurring, and one-time values
- Dashboard state should support selected time unit, Day default, and optional minute live secondary display
- Gamification state should reward awareness, consistency, and improvement, not wealth level
- Avoid exposing raw database structure directly in the UI

## Backend / Database

- UI redesign should not drive unnecessary backend complexity
- Backend/database changes should only support product needs defined in feature plans
- Dashboard, income, expense, savings, widgets, and premium should share a consistent data contract
- Apple Sign In, Supabase, stable user IDs, and premium cloud backup/sync are part of the broader product direction
- Local free use should remain possible
- Backend/sync UI should stay clear and practical, not technical

## Gamification Rules

- v1 gamification should include momentum ring, haptic feedback after successful entry, small success animation after entry, savings milestone, awareness streak, and simple weekly recap
- Awareness streak should track regular check-ins / money awareness, not financial success or wealth
- Gamification should reward awareness, consistency, and improvement
- Gamification must never shame users for bad financial days
- Avoid RPG systems, leaderboards, social comparison, casino mechanics, punishment loops, and mascot dependency mechanics

## Premium Rules

- The redesigned core experience should remain free
- Premium visual treatment should not make free users feel blocked from the main product value
- Premium personalization should be controlled, not unlimited free color editing
- Premium personalization can include accent color packs, premium themes, app icon variants, chart style options, and Pulsey accent variants
- Premium can use subtle premium glass, refined lock/badge treatment, and soft gold/indigo edge treatment
- Premium should avoid loud glow, casino-like gold, and purple/pink AI-style upgrade visuals
- Premium entry points should be secondary to core pace clarity
- Premium should unlock deeper control, convenience, personalization, and insight, not basic usability

## Open Questions

- What exact bottom navigation structure should be used?
- Should Home use a persistent bottom quick action tray or a central add action?
- Which Pulsey states are needed beyond launch splash for the first redesign?
- What exact accent color packs should be included in premium?
- What exact weekly recap content should ship in v1?

## Technical Planning Later

- exact navigation changes TBD
- exact design system tokens TBD
- component inventory TBD
- screen-by-screen redesign tasks TBD
- chart component requirements TBD
- accessibility requirements TBD
- reduced motion behavior TBD
- localization impact TBD
- implementation tasks TBD
