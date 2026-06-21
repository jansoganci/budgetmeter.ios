# Core Dashboard Plan

## UI

- Home is the center of the app
- Home should answer immediately: am I financially moving forward or slowing down, and how fast?
- Center the dashboard on a hybrid momentum ring + live financial pace number
- Make net financial pace the top priority metric
- Use status copy such as "Moving forward: +$12/day"
- Negative state copy should use gentle wording such as "Slowing down" instead of shame, guilt, or panic
- Default main unit: Day
- Time options should include minute, hour, day, week, and month
- Minute should be a small live secondary metric, not the main default tab
- Keep the savings module visible and focused on progress
- Include a lightweight chart on the Home dashboard
- Include a biggest drain card, but keep it non-judgmental
- Keep the UI simple and easy to scan
- Avoid complex choices on the Home screen
- Pulsey should not dominate Home; at most, Pulsey can appear as a small brand mark or contextual empty/success state outside the main pace number
- Critical financial numbers should appear on solid or near-solid readable surfaces, not heavy blur

## User Flow

- Home should be read/status-first
- Users should understand their current money pace immediately
- Users should quickly understand whether they are moving forward or slowing down
- Users should be able to switch time view simply
- Users should not face complex choices
- Home should not feel action-heavy
- Other areas of the app should support Home rather than compete with it
- Premium and onboarding cards can appear contextually, but they should not push the main pace hero out of focus

## Services

- Dashboard should depend on one shared normalized financial pace calculation model
- Dashboard should depend on live money flow calculations
- Dashboard should support pace calculations across minute, hour, day, week, and month
- Dashboard should support summary and chart data generation for Home
- Dashboard should support savings progress display
- Dashboard should support awareness streak and weekly recap display where those features are included
- Home, charts, savings, and widgets should not use separate calculation logic

## Data Model

- Financial pace values for minute, hour, day, week, and month
- Day as default selected unit
- Minute as optional live secondary display
- Positive/negative momentum summary state
- Gentle status copy state
- Savings progress state
- Biggest drain state
- Chart data for dashboard visuals
- Awareness streak state
- Simple weekly recap state

## Backend / Database

- Dashboard should read the financial data needed for live flow, pace, savings progress, biggest drain, charts, awareness streak, and weekly recap
- Backend/database support should stay practical and only cover dashboard needs defined by the product plan
- Supabase-backed backup/sync should preserve the same dashboard data contract for premium users
- Local free use should continue to support the core dashboard

## Premium Rules

- Core dashboard should remain part of the free product
- Live money flow should remain part of the core product
- Momentum ring should remain part of the free product
- Basic savings progress should remain part of the free product
- Awareness streak can be free if it tracks regular check-ins / money awareness and avoids shame
- The Home dashboard should deliver the main app value without requiring premium
- Premium can unlock widgets, advanced insights, advanced history/reporting, forecasting, multiple savings goals, chart style options, and richer weekly recap

## Recommendations

- Financial Health Score should not be a primary dashboard element
- If retained, it should become a secondary simple status-style concept
- Home insights should stay very limited and practical
- Recommended Home insights:
- moving forward / slowing down status
- biggest expense drain
- simple savings progress
- short period comparison such as this period vs previous period
- awareness streak or weekly recap only if they do not crowd the hero
- Do not overload Home with too many insight types
- Deeper insight details should stay outside the main Home dashboard

## Technical Planning Later

- exact ViewModel changes TBD
- exact service changes TBD
- chart data source TBD
- awareness streak storage TBD
- weekly recap data source TBD
- backend/database dependency TBD
- implementation tasks TBD
