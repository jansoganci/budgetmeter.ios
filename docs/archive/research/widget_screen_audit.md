# Widget UI/UX Audit (Current State)

Sources reviewed:
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
- `BudgetMeterWidgets/NetDailyPaceWidget.swift`
- `budgetmeter.ios/WidgetShared/WidgetSnapshot.swift`
- `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift`
- Screenshot:
  - `docs/uiux/screenshots/current/widget.light.png`

## 1. Current Screen Summary

Current widget shown is a small Home Screen widget focused on daily net pace.
It displays:

- top-left compact brand/status row,
- primary value (`+₺286/day` style),
- short status copy (`Moving forward ...`),
- neutral light background in screenshot.

Overall structure is simple and glanceable, with one hero metric and minimal supporting text.

## 2. What Works

- Core information priority is correct: daily pace is dominant.
- Layout is compact and readable for system small size.
- Widget appears calm in light mode screenshot (not full red/green background).
- Status is communicated via text/value treatment, not by flooding the whole background.
- Data pipeline is modular (`WidgetSnapshotWriter` -> `WidgetSnapshot` -> widget rendering).
- Widget supports multiple states (unlocked, locked teaser, stale, missing, insufficient data).

## 3. Problems

- Only light screenshot is available; dark mode behavior is not visually validated.
- Header title is truncated (`BudgetMe...`) in screenshot; branding readability is reduced.
- Secondary line (`Moving forward ...`) can be repetitive with primary line and may feel text-heavy in small space.
- Visual polish is good but still slightly utility-oriented vs premium/glass emotional tone target.
- Locked/teaser/premium visual behavior is not shown in provided screenshot, so premium messaging quality is unverified.
- Accent and typography balance may need refinement for very large dynamic type conditions.

## 4. v2 Alignment Gap

Compared to v2 requirements, widget is relatively close but still needs final validation:

- **Neutral background rule:** appears aligned in light mode screenshot.
- **No full green/red background:** aligned in provided state.
- **Main value = daily pace:** aligned.
- **User currency display:** appears aligned (`₺` shown), but full locale coverage should still be validated.
- **Status expression via text/small indicator:** mostly aligned.
- **Apple-like calm tone:** mostly aligned, could be further refined in typography rhythm and copy compactness.
- **Dark mode parity:** not verified from screenshot set.
- **Widget final layout lock-in:** still needs complete state review (locked/stale/missing/neutral).

## 5. Design Opportunities

Potential directions (documentation only):

- Improve header label fit to avoid excessive truncation in compact mode.
- Tighten secondary text verbosity for cleaner glance experience.
- Refine micro-typography spacing to increase premium feel without increasing density.
- Validate a dark-mode version against v2 neutral slate rules.
- Review locked/teaser state visuals so premium messaging remains calm and non-aggressive.

## 6. Recommended Next Step (Stitch or Direct)

Recommendation: **Short Stitch exploration, then direct SwiftUI polish**.

Why:
- Widget information architecture is already strong.
- Remaining work is mostly visual precision (spacing, copy compactness, title fit, state polish).
- A quick 1-2 concept pass can de-risk small-size readability before implementation.

## 7. Questions / Decisions Needed

1. Do we keep explicit `BudgetMeter` brand text in small widget header, or prioritize full metric width?
2. Should secondary copy always be shown, or hidden for certain states to keep a cleaner card?
3. In dark mode, do we use the same neutral hierarchy with only subtle status accents, or slightly stronger contrast for glanceability?
4. Should locked teaser prioritize crown/upgrade cue more, or stay minimal and calm?

## Final Readiness Verdict

This widget is **partially ready** for final implementation polish and **ready for Stitch exploration**.
It is close to v2 direction, but a short visual validation pass is recommended before locking final compact layout rules.
