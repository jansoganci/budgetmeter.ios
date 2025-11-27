# 📱 PHASE 1 MANUAL TESTING GUIDE

**For:** BudgetMeter iOS App - Phase 1 Features
**Features:** Insights Dashboard, Smart Notifications, Financial Health Details
**Estimated Time:** 30-45 minutes

---

## 🎯 BEFORE YOU START

### Prerequisites:
- [ ] Xcode installed (version 15.0+)
- [ ] iPhone simulator available (iPhone 15 recommended)
- [ ] Project builds successfully (⌘B)

### Setup Steps:
1. Open `budgetmeter.ios.xcodeproj` in Xcode
2. Select iPhone 15 simulator from the device dropdown
3. Run the app (⌘R)
4. Verify app launches without crashes

---

## 🧪 TEST SUITE 1: INSIGHTS DASHBOARD

### Feature: Automated Financial Insights

**Location:** Tab Bar → Insights (4th tab)

#### Test 1.1: Basic Navigation ✅
- [ ] Tap "Insights" tab in tab bar
- [ ] Screen loads without crashes
- [ ] Navigation title shows "Insights"
- [ ] Back navigation works (if applicable)

**Expected:** Insights screen appears with charts

#### Test 1.2: Data Display ✅
- [ ] Check if charts are visible
- [ ] Spending Breakdown chart shows
- [ ] Month Comparison chart shows
- [ ] Balance Trend chart shows
- [ ] Insight cards display (if data available)

**Expected:** 3 charts visible, automated insights shown

#### Test 1.3: Pull-to-Refresh ✅
- [ ] Swipe down from top of screen
- [ ] Loading indicator appears
- [ ] Data refreshes
- [ ] Charts update

**Expected:** Smooth refresh with loading indicator

#### Test 1.4: Empty State ✅
*Test this if no financial data exists*
- [ ] Verify empty state shows
- [ ] Message is user-friendly
- [ ] Call-to-action button present

**Expected:** "No insights yet" message with guidance

#### Test 1.5: Loading State ✅
- [ ] Kill and restart app
- [ ] Navigate to Insights quickly
- [ ] Skeleton screens appear
- [ ] Content loads and replaces skeletons

**Expected:** Skeleton screens → Real data

#### Test 1.6: Premium Paywall (if not premium) ✅
- [ ] Try to access premium features
- [ ] Paywall sheet appears
- [ ] "Upgrade to Premium" button visible
- [ ] "Close" button works

**Expected:** Paywall shows for premium features

#### Test 1.7: Accessibility (VoiceOver) ✅
- [ ] Enable VoiceOver (Settings → Accessibility)
- [ ] Navigate through Insights screen
- [ ] All elements have labels
- [ ] Hints are descriptive

**Expected:** VoiceOver reads all content correctly

---

## 🧪 TEST SUITE 2: SMART NOTIFICATIONS

### Feature: Notification Settings & Scheduling

**Location:** Settings Tab → Notifications

#### Test 2.1: Navigation to Notifications ✅
- [ ] Tap "Settings" tab (5th tab)
- [ ] Find "Notifications" section
- [ ] Tap "Notifications" row
- [ ] Settings screen loads

**Expected:** Notification settings screen appears

#### Test 2.2: Weekly Summary Toggle ✅
- [ ] Toggle "Weekly Summary" ON
- [ ] Toggle switches to blue/on state
- [ ] Toggle "Weekly Summary" OFF
- [ ] Toggle switches to gray/off state

**Expected:** Toggle responds immediately

#### Test 2.3: Weekly Time Picker ✅
- [ ] Enable "Weekly Summary"
- [ ] Tap anywhere on the row
- [ ] Time picker expands below
- [ ] Scroll to change time (e.g., 8:00 PM)
- [ ] Tap row again to collapse

**Expected:** Time picker expands/collapses smoothly

#### Test 2.4: Milestone Alerts ✅
- [ ] Toggle "Milestone Alerts" ON/OFF
- [ ] Verify toggle state changes
- [ ] No crashes occur

**Expected:** Toggle works smoothly

#### Test 2.5: Spending Alerts ✅
- [ ] Toggle "Spending Alerts" ON/OFF
- [ ] Verify toggle state changes
- [ ] No crashes occur

**Expected:** Toggle works smoothly

#### Test 2.6: Daily Encouragement (Premium) ✅
- [ ] If premium: Toggle ON/OFF and verify time picker
- [ ] If NOT premium: Tap toggle
- [ ] Premium paywall should appear
- [ ] Close paywall

**Expected:** Premium users can toggle, others see paywall

#### Test 2.7: Permission Banner ✅
*If notifications are denied in iOS Settings*
- [ ] Orange banner appears at top
- [ ] "Notifications Disabled" message shows
- [ ] Tap "Open Settings" button
- [ ] iOS Settings app opens

**Expected:** Banner guides user to enable permissions

#### Test 2.8: Test Notification Button ✅
- [ ] Ensure notifications are allowed in iOS Settings
- [ ] Tap "Send Test Notification"
- [ ] Wait 3-5 seconds
- [ ] Check notification appears in Notification Center

**Expected:** Test notification delivered successfully

#### Test 2.9: Haptic Feedback ✅
- [ ] Toggle any notification switch
- [ ] Feel for haptic vibration
- [ ] Tap time picker
- [ ] Feel for haptic vibration

**Expected:** Subtle haptic feedback on interactions

#### Test 2.10: Accessibility (VoiceOver) ✅
- [ ] Enable VoiceOver
- [ ] Navigate through toggles
- [ ] All toggles have proper labels
- [ ] Hints explain functionality

**Expected:** VoiceOver describes all elements

---

## 🧪 TEST SUITE 3: FINANCIAL HEALTH DETAILS

### Feature: Detailed Health Score & Personalized Tips

**Location:** Home Tab → Tap Health Score Card

#### Test 3.1: Navigation from Home ✅
- [ ] Tap "Home" tab (1st tab)
- [ ] Locate "Health" card (3rd snapshot card)
- [ ] Note the chevron (›) indicator
- [ ] Tap the Health card
- [ ] Health Details screen loads

**Expected:** Navigates to Health Details view

#### Test 3.2: Health Score Display ✅
- [ ] Large circular progress appears
- [ ] Score (0-100) is visible
- [ ] Score text shows (Excellent/Great/Good/Fair)
- [ ] Color matches score level:
  - 90-100: Green
  - 75-89: Blue
  - 60-74: Yellow
  - 40-59: Orange
  - 0-39: Red
- [ ] Animation plays on appear

**Expected:** Animated circular score with correct color

#### Test 3.3: Health Breakdown Expansion ✅
- [ ] Scroll to "HEALTH BREAKDOWN" section
- [ ] See 4 component rows:
  1. Budget Compliance
  2. Savings Rate
  3. Spending Consistency
  4. Income Stability
- [ ] Tap "Budget Compliance"
- [ ] Row expands with description
- [ ] Tap again to collapse
- [ ] Repeat for other 3 rows

**Expected:** Each row expands/collapses smoothly

#### Test 3.4: Progress Bars Animation ✅
- [ ] Kill and restart app
- [ ] Navigate to Health Details
- [ ] Watch breakdown progress bars
- [ ] Bars animate from 0% to actual value

**Expected:** Progress bars animate smoothly

#### Test 3.5: Health Tips Display ✅
- [ ] Scroll to "PERSONALIZED TIPS" section
- [ ] Tips display in priority order:
  - HIGH (red badge)
  - MEDIUM (orange badge)
  - LOW (blue badge)
- [ ] Each tip has title + description
- [ ] Tips are readable and actionable

**Expected:** Tips sorted by priority, easy to read

#### Test 3.6: Premium Tips (if NOT premium) ✅
- [ ] Count total tips
- [ ] First 3 tips are visible
- [ ] Remaining tips show lock message
- [ ] "Unlock All" button appears
- [ ] Tap locked tip or "Unlock All"
- [ ] Premium paywall appears

**Expected:** First 3 free, rest require premium

#### Test 3.7: Pull-to-Refresh ✅
- [ ] Swipe down from top
- [ ] Loading indicator appears
- [ ] Data refreshes
- [ ] Score recalculates

**Expected:** Smooth refresh

#### Test 3.8: Share Health Report ✅
- [ ] Tap share button (top-right)
- [ ] Share sheet appears
- [ ] Preview shows formatted text:
  - Health score
  - 4 breakdown percentages
  - App branding
- [ ] Tap "Cancel" to close

**Expected:** Formatted health report ready to share

#### Test 3.9: Loading State ✅
- [ ] Kill and restart app
- [ ] Navigate to Health Details quickly
- [ ] Loading spinner appears
- [ ] Content loads

**Expected:** Loading indicator while fetching data

#### Test 3.10: Error State ✅
*Simulate by turning off internet/data*
- [ ] Force an error condition
- [ ] Error message appears
- [ ] "Try Again" button shows
- [ ] Tap "Try Again"
- [ ] Data loads

**Expected:** User-friendly error with retry option

#### Test 3.11: Haptic Feedback ✅
- [ ] Tap any breakdown row
- [ ] Feel haptic vibration
- [ ] Tap share button
- [ ] Feel haptic vibration

**Expected:** Subtle haptic on all taps

#### Test 3.12: Accessibility (VoiceOver) ✅
- [ ] Enable VoiceOver
- [ ] Navigate through screen
- [ ] Health score has label
- [ ] Breakdown rows have labels + hints
- [ ] Tips have priority + content read

**Expected:** Full VoiceOver support

---

## 🧪 TEST SUITE 4: INTEGRATION TESTS

### Cross-Feature Functionality

#### Test 4.1: Premium Flow Consistency ✅
- [ ] Trigger paywall in Insights
- [ ] Dismiss and trigger paywall in Notifications
- [ ] Dismiss and trigger paywall in Health Details
- [ ] All paywalls look consistent
- [ ] All have "Upgrade" and "Close" buttons

**Expected:** Consistent paywall across all features

#### Test 4.2: Navigation Consistency ✅
- [ ] Navigate to all 3 features
- [ ] Use back navigation from each
- [ ] Return to home screen
- [ ] No crashes or stuck screens

**Expected:** Smooth navigation throughout

#### Test 4.3: Data Persistence ✅
- [ ] Enable "Weekly Summary" in Notifications
- [ ] Set time to 8:00 PM
- [ ] Kill app completely
- [ ] Relaunch app
- [ ] Navigate back to Notifications
- [ ] Verify "Weekly Summary" still ON
- [ ] Verify time still shows 8:00 PM

**Expected:** Settings persist across app launches

#### Test 4.4: Background Task Simulation ✅
- [ ] Use app normally
- [ ] Send to background (home button/gesture)
- [ ] Wait 30 seconds
- [ ] Return to app
- [ ] No crashes, data intact

**Expected:** App handles backgrounding correctly

---

## 🧪 TEST SUITE 5: STRESS TESTS

### App Stability Under Load

#### Test 5.1: Rapid Navigation ✅
- [ ] Quickly tap between all tabs
- [ ] Tap back and forth rapidly
- [ ] Navigate in and out of features quickly
- [ ] No crashes or UI glitches

**Expected:** App remains stable

#### Test 5.2: Memory Test ✅
- [ ] Navigate through all features
- [ ] Pull-to-refresh multiple times
- [ ] Expand/collapse all breakdown rows
- [ ] Watch Xcode memory gauge
- [ ] Memory should not grow excessively

**Expected:** Memory usage stays reasonable

#### Test 5.3: Rotation Test ✅
- [ ] Rotate device to landscape
- [ ] Check if UI adapts
- [ ] Rotate back to portrait
- [ ] Check if UI adapts
- [ ] No layout issues

**Expected:** UI handles rotation gracefully

---

## 📋 TEST RESULT CHECKLIST

Mark tests as you complete them:

### Insights Dashboard:
- [ ] 7/7 tests passed

### Smart Notifications:
- [ ] 10/10 tests passed

### Financial Health Details:
- [ ] 12/12 tests passed

### Integration:
- [ ] 4/4 tests passed

### Stress Tests:
- [ ] 3/3 tests passed

**Total:** ___/36 tests passed

---

## 🐛 BUG REPORTING TEMPLATE

If you find issues, document them using this format:

```
BUG #[number]
Feature: [Insights/Notifications/Health Details]
Test: [Test number/name]
Severity: [Critical/High/Medium/Low]

Steps to Reproduce:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Expected Behavior:
[What should happen]

Actual Behavior:
[What actually happened]

Device: [iPhone model]
iOS Version: [e.g., 17.0]
Screenshot: [If available]
```

---

## ✅ COMPLETION CRITERIA

Phase 1 testing is complete when:
- [ ] All 36 tests executed
- [ ] At least 34/36 tests pass (94%+)
- [ ] All critical bugs documented
- [ ] No crashes during normal usage
- [ ] UI is responsive and smooth
- [ ] Accessibility works with VoiceOver

---

## 🎉 AFTER TESTING

Once all tests pass:
1. ✅ Mark Phase 1 as production-ready
2. 📝 Document any minor issues found
3. 🚀 Prepare for App Store submission (or next phase)
4. 👥 Consider beta testing with real users

---

**Good luck with testing!** 🚀

If you encounter any issues, refer back to the code or reach out for help.
