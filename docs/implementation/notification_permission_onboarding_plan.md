# Notification Permission Onboarding Plan

## 1) Purpose

This document is **analysis/planning only**.  
It defines an App Store-safe and UX-safe strategy for notification permission timing in BudgetMeter.  
No code changes are included in this document.

---

## 2) Product Question

Should BudgetMeter ask iOS notification permission during first setup, or only when the user intentionally enables Daily Encourage Notification (or explicitly opts in after value explanation)?

---

## 3) Apple / App Store Guidance Summary

Based on Apple Human Interface Guidelines and App Review guidance:

- Request permission **in context**, when users understand the value.
- Avoid asking too early (especially immediate first launch) unless the app cannot function without it.
- Permission copy should be clear, specific, and non-pushy.
- Users should understand **why** notifications are useful before the native prompt appears.
- After denial, do not spam prompt attempts; guide users to **Settings** for recovery.
- App functionality must remain usable even if notification permission is denied (no coercive gating).

Practical interpretation for BudgetMeter:

- Notification permission is optional behavior, not a core boot requirement.
- First-launch native permission prompt is not necessary for MVP and introduces denial risk.

---

## 4) BudgetMeter Product Fit

BudgetMeter direction is calm, low-anxiety, and optional by default.

- `DESIGN.md` and `uiux_design_direction_v1_decisions.md` emphasize calm, non-pressure tone.
- Daily Encourage is intentionally optional and currently default OFF.
- Notification permission should follow this product voice: user-controlled, contextual, and non-disruptive.

Conclusion: a delayed, intentional permission request is a better fit than an immediate first-launch prompt.

---

## 5) Recommended MVP Decision

**Recommended MVP:** request notification permission only after intentional user action.

- Do **not** show native iOS notification prompt on app launch.
- Show contextual explanation in Notifications settings context.
- Trigger system permission request when user enables Daily Encourage (or explicit opt-in).
- Keep Daily Encourage default OFF.

This is the safest App Store/UX path for current scope.

---

## 6) Possible Options

### A) Ask on first launch

**Pros**
- Earliest possible opt-in chance.
- Simple trigger point.

**Cons**
- Low-context request; higher denial risk.
- Interrupts first-run experience.
- Mismatch with calm onboarding direction.

**App Store / UX risk**
- Higher risk of perceived coercion or poor UX quality.

### B) Ask during onboarding after value explanation

**Pros**
- Better context than immediate launch.
- Allows pre-permission education.

**Cons**
- Onboarding flow can become heavier.
- Timing may still be early before meaningful feature use.

**Timing risk**
- User may not yet understand practical value.

### C) Ask only when user toggles Daily Encourage

**Pros**
- Strong user intent signal.
- Clear permission context.
- Minimal interruption and simple MVP behavior.
- Already aligned with current NotificationSettings flow pattern.

**Cons**
- Lower total prompt impressions than early ask.
- Users who never visit settings won’t opt in.

**MVP suitability**
- **Best** for current product stage.

### D) Ask after first meaningful app use (first income/expense/goal)

**Pros**
- Strong contextual relevance.
- Better acceptance potential than first launch.

**Cons**
- Requires extra eligibility/tracking logic.
- More moving parts than MVP.

**Future option**
- Good candidate after onboarding redesign/experimentation.

---

## 7) Final Recommendation

For BudgetMeter MVP:

1. Use **Option C** now (ask on Daily Encourage toggle intent).
2. Keep first launch uninterrupted (no native prompt).
3. Keep notifications optional and default OFF.
4. Consider **Option B** later when onboarding is redesigned with explicit value framing.

---

## 8) Proposed User Flow

1. User opens app.
2. No native notification prompt appears immediately.
3. User navigates to `Settings -> Notifications`.
4. User sees calm explanation of notification value.
5. User enables Daily Encourage toggle:
   - If permission is `.notDetermined` -> request authorization.
   - If permission is denied -> show Open Settings guidance.
   - If permission is authorized/provisional -> enable and schedule Daily Encourage.
6. If user cancels/denies, Daily Encourage remains OFF.

---

## 9) Copy Recommendation (Calm Tone)

Short copy recommendation for future implementation:

- **Title:** `Daily Reminder (Optional)`
- **Subtitle:** `Get a gentle reminder to check your money pace.`
- **Permission explanation:** `Allow notifications so BudgetMeter can send one calm daily reminder at your chosen time.`
- **Denied message:** `Notifications are off for BudgetMeter. You can enable them anytime in Settings.`
- **Buttons:** `Allow Notifications`, `Not Now`, `Open Settings`

Tone rules:

- Calm, optional, respectful.
- No urgency/fear language.
- No streak pressure/gamification pressure.

---

## 10) Technical Scope If Implemented Later

Likely files (minimal scope):

- `Features/SettingsFeature/View/NotificationSettingsView.swift`
- `Features/SettingsFeature/ViewModel/NotificationSettingsViewModel.swift`
- `CoreKit/Sources/Services/NotificationService.swift`
- `BudgetMeter.xcdatamodeld` `AppSettings` usage (no schema change needed for MVP timing change)
- Localization catalogs (copy updates only)

Only if a future onboarding-prompt variant is chosen:

- `Features/OnboardingFeature/*`
- `Features/AuthFeature/View/RootAuthView.swift` (routing trigger only)

---

## 11) What Not To Do

- Do not ask native notification permission at first launch without context.
- Do not enable notifications by default.
- Do not repeatedly prompt after denial.
- Do not use pressure/dark patterns.
- Do not make notification permission required for core app usage.
- Do not make Daily Encourage premium-critical beyond current product rules.
- Do not add complex AI/personalization notification engine in MVP.

---

## 12) Test Plan (For Later Implementation)

- Fresh install: no notification prompt appears immediately.
- Toggle Daily Encourage ON with `.notDetermined`: system prompt appears.
- Grant permission: Daily Encourage schedules successfully.
- Deny permission: toggle returns/stays OFF and Settings guidance appears.
- Previously denied: Open Settings action works.
- English copy correctness for prompt-related messaging.
- Premium mode behavior remains unchanged for existing gates.
- Regression: app remains fully usable with notifications denied.

---

## 13) Acceptance Criteria

- [ ] Permission timing is App Store-safe and contextual.
- [ ] Daily Encourage remains optional.
- [ ] User understands why permission is requested.
- [ ] No first-launch interruption.
- [ ] Notifications are not enabled by default.
- [ ] Existing toggle-based flow remains coherent.
- [ ] Implementation scope stays minimal.

---

## Current-State Notes (Inspection Snapshot)

- `budgetmeter_iosApp.swift`: no first-launch notification permission request.
- `RootAuthView` + `OnboardingView`: no notification permission step today.
- `NotificationSettingsViewModel.toggleDaily`: permission is requested contextually when enabling Daily Encourage and status is `.notDetermined`.
- `NotificationSettingsViewModel` defaults: weekly/milestone/spending ON, daily OFF on fresh settings row.
- `NotificationSettingsView`: denied state has banner + Open Settings path.
- `premium_test_findings.md`: first-setup permission timing is currently marked as open product question.

