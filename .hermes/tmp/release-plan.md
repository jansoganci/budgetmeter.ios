Create a release readiness action plan for BudgetMeter iOS at docs/release_readiness_plan.md.

Read docs/implementation/phase10_release_qa_audit.md, docs/qa/release_tracker.md, and docs/qa/known_issues.md first.

The user needs a step-by-step plan organized by:

1. **What Cursor/Codex can do** (automated fixes, tests, code changes)
2. **What the user must do manually** (simulator QA, StoreKit sandbox, Apple Developer config)

For each step, include:
- What needs to be done
- Who does it (Cursor vs User)
- Estimated effort
- Dependencies (what must be done first)

Focus on the actual remaining blockers from the audit:
- Stage A checklist items (SAV-01 through OFF-04)
- Manual Scripts A-E
- StoreKit sandbox (G3)
- KI-005, KI-008, KI-009
- Stage B auth/sync QA
- App Store readiness (G9)
- Go/no-go decision (G10)

Output to docs/release_readiness_plan.md
