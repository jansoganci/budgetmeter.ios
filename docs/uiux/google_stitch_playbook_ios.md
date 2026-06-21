# Google Stitch Playbook (BudgetMeter iOS)

## Purpose

This document defines how our team should use Google Stitch for BudgetMeter iOS UI work.
It combines:

- official Google Stitch guidance,
- real community feedback,
- a practical workflow for our app.

## Short Answer

Yes, we should maintain **one main Stitch guide**.

Why:
- Keeps prompting style consistent across team members.
- Reduces random output and rework.
- Makes handoff from Stitch to implementation faster.

## Official Sources Reviewed (Google)

- Google Developers Blog (Stitch launch):
  - https://developers.googleblog.com/en/stitch-a-new-way-to-design-uis/
- Google Blog (Stitch AI-native canvas update):
  - https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-ai-ui-design/
- Google Blog (real-time design update):
  - https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-updates/
- Stitch official llms summary:
  - https://stitch.withgoogle.com/llms.txt
- Official Stitch prompt guide (Google AI Developers Forum):
  - https://discuss.ai.google.dev/t/stitch-prompt-guide/83844
- Official Stitch SDK README:
  - https://raw.githubusercontent.com/google-labs-code/stitch-sdk/main/README.md

## Community Sources Reviewed (Experience)

- Google AI Developers Forum user feedback thread:
  - https://discuss.ai.google.dev/t/stitch-is-becoming-almost-unusable-for-real-design-work/170296
- Industry walkthroughs and reviews (used as secondary signals):
  - LogRocket tutorial/review
  - UXPin analysis
  - multiple independent review posts comparing Stitch vs Figma

Notes:
- Product Hunt page exists but direct scraping may be blocked (403 in our run).
- Community claims are useful but not always equally reliable; official Google docs are the primary source of truth.

## What Google Officially Recommends (Condensed)

1. Start from natural language or image/sketch.
2. Iterate quickly with prompt edits.
3. Use specific, incremental changes (screen-by-screen).
4. Set the vibe explicitly (adjectives, tone).
5. Move to downstream tools via export (Figma/code) or SDK/MCP workflows.
6. Use DESIGN.md as design-rules transport for consistency across tools/projects.

## What Users Consistently Report

Positive:
- Very fast first drafts.
- Great for exploring multiple directions.
- Useful for early stakeholder alignment.

Pain points:
- Prompt adherence can drift during long sessions.
- Can generate generic/"AI-looking" output if prompts are weak.
- Fine-grained manual control is limited compared to Figma.
- Complex multi-change prompts often break existing layout intent.

Most common practical advice from users:
- Keep prompts short and focused.
- Make one major change per prompt.
- Work screen-by-screen.
- Export and polish in Figma (or code) instead of trying to finish everything inside Stitch.

## Recommended Team Model for BudgetMeter iOS

Use Stitch as an **exploration engine**, not as final UI source of truth.

### Stage 1 - Frame the Screen
- Start from one target screen (Welcome, Home, Income, etc.).
- Include:
  - user goal,
  - emotional tone,
  - key constraints (light/dark, calm fintech, readable metrics).

### Stage 2 - Generate 2-3 Variants
- Request 2-3 directions only.
- Compare hierarchy, emotional tone, and scanability.
- Pick one winner quickly.

### Stage 3 - Controlled Iteration
- Apply edits in tiny steps:
  - spacing pass,
  - typography pass,
  - CTA pass,
  - copy pass.
- Avoid combining unrelated edits in one prompt.

### Stage 4 - Lock and Handoff
- Export selected version.
- Convert into implementation prompt for Cursor.
- Use our v2 tokens (`BrandColors`, `TextStyles`, `LayoutTokens`) as hard constraints.

### Stage 5 - Implement + Verify
- Implement only allowed files per phase.
- Build/test.
- Compare with screenshot and audit expectations.

## Prompting Rules (Team Standard)

Use this structure for each Stitch prompt:

1. **Context**
   - Screen name and purpose.
2. **Structure**
   - Main blocks and information priority.
3. **Visual Tone**
   - Calm premium fintech, not childish/noisy.
4. **Constraints**
   - Design system rules, accessibility, localization, currency behavior.
5. **Single Requested Change**
   - Exactly one major adjustment per prompt.

### Example Prompt Template (iOS Screen)

```
Design a [SCREEN_NAME] for BudgetMeter iOS.

Context:
- This screen helps users [PRIMARY_GOAL].

Structure:
- Top: [HEADER]
- Middle: [PRIMARY CARD/BLOCKS]
- Bottom: [ACTIONS/SECONDARY CONTENT]
- Keep hierarchy clear: primary metric first, support text second.

Visual tone:
- Premium, calm, friendly fintech.
- Light/Dark ready.
- Subtle glass feel only where it helps readability.
- Not childish, not noisy, not casino-like.

Constraints:
- Respect existing v2 token intent (color/typography/spacing/radius).
- Accessibility first (contrast, readable text).
- Keep copy short and human.

Change request:
- [ONE SPECIFIC CHANGE ONLY]
```

## BudgetMeter-Specific Guardrails

- Accent colors are accents, not full-screen backgrounds.
- Widgets stay calm and Apple-like.
- Financial values must stay legible at a glance.
- Pulsey is emotional support, not visual distraction.
- Copy must remain short, warm, non-shaming.

## Should We Write One Main Document?

Yes. This file should be that main document.

Suggested usage:
- Keep this playbook stable.
- For each screen, add a short companion brief:
  - `docs/uiux/stitch_briefs/<screen>_stitch_brief.md`
- Keep implementation prompts separate from design prompts.

## Practical Do / Don't

Do:
- Use incremental prompts.
- Validate one screen at a time.
- Keep hard constraints visible in prompt.
- Move to implementation once direction is stable.

Don't:
- Ask for full app redesign in one prompt.
- Mix multiple layout/visual/content changes together.
- Treat Stitch output as production-ready by default.
- Skip manual review for accessibility and hierarchy.

## Final Recommendation

For BudgetMeter iOS, the best approach is:

**Stitch for direction -> Cursor for implementation -> build/test verification.**

This gives speed without losing product quality and consistency.
