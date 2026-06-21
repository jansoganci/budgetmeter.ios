# Final Docs Cleanup — Archive Everything to docs/archive/

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Goal
Archive ALL remaining active docs to docs/archive/. Keep ONLY docs/legal/, docs/supabase/, and docs/archive/.

## What to archive

### 1. docs/implementation/ (4 files)
Move to docs/archive/implementation/:
- implementation_planning_index.md

### 2. docs/qa/ (entire folder)
Move to docs/archive/qa/:
- release_tracker.md
- known_issues.md
- fixtures/README.md

### 3. docs/ root files
Move to docs/archive/:
- active_docs_summary_report.md
- active_docs_completion_summary.md
- design_rulebook.mdx (keep in root, it's permanent reference)
- general_rulebook.mdx (keep in root)
- MARKETING_STRATEGY.md
- mobile-app-market-strategist.md
- roadmap.v2.mdx (keep in root)

### 4. Keep in place
- docs/legal/ (all files — GitHub Pages privacy)
- docs/supabase/ (SQL migration)
- docs/archive/ (everything already there)

## After cleanup, final docs/ structure should be:
```
docs/
├── archive/
│   ├── active/
│   ├── implementation/
│   ├── qa/
│   ├── research/
│   └── (root-level archived files)
├── legal/
├── supabase/
├── design_rulebook.mdx
├── general_rulebook.mdx
└── roadmap.v2.mdx
```

## Verification
```sh
xcodebuild build -scheme budgetmeter.ios
```
Must succeed (archiving docs never affects build).
