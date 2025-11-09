# Phase 1C: Smart Notifications UI - Implementation Plan

**Duration:** 2-3 days
**Goal:** Build notification settings screen with full backend integration
**Status:** PLANNING

---

## 📋 Overview

**What we're building:**
A complete notification settings screen where users can control all notification types, set schedules, and manage preferences. Premium users get access to advanced notifications.

**Backend status:** ✅ COMPLETE (Phase 1A)
- NotificationService.swift exists with all methods
- AppSettings entity has notification fields
- Background processing integrated

**Frontend status:** ❌ NOT STARTED
- Need to build entire settings UI
- Need to connect to existing backend

---

## 🎯 What Will Users Get?

### Free Users:
- ✅ Weekly summary notifications (Sundays)
- ✅ Milestone alerts (positive streaks, goals)
- ✅ Spending alerts (when up >20%)
- ✅ Control notification times
- ❌ Daily encouragement (premium only)

### Premium Users:
- ✅ All free features
- ✅ Daily encouragement notifications
- ✅ Advanced customization
- ✅ More notification types in future

---

## 📱 UI Components to Build

### 1. **NotificationSettingsView.swift** (~250 lines)
Main settings screen with all controls

**Sections:**
1. **Header**
   - Title: "Notifications"
   - Description: "Stay on top of your finances"
   - Permissions status banner (if denied)

2. **Notification Types Section**
   - Weekly Summary toggle + time picker
   - Milestone Alerts toggle
   - Spending Alerts toggle
   - Daily Encouragement toggle (premium badge)

3. **Test Notification Button**
   - Send test notification to verify setup
   - Helps users confirm permissions

4. **Info Section**
   - How notifications work
   - Link to iOS settings

**Premium Integration:**
- Show premium badge on locked features
- Tap locked feature → show paywall
- Auto-enable when user upgrades

---

### 2. **NotificationSettingsViewModel.swift** (~200 lines)
ViewModel managing state and backend connection

**Properties:**
```swift
@Published var weeklyEnabled: Bool
@Published var weeklyTime: Date
@Published var milestonesEnabled: Bool
@Published var spendingEnabled: Bool
@Published var dailyEnabled: Bool // premium only
@Published var dailyTime: Date
@Published var isPremium: Bool
@Published var permissionStatus: UNAuthorizationStatus
@Published var showPaywall: Bool
@Published var isLoading: Bool
```

**Methods:**
```swift
func loadSettings() // Load from AppSettings
func saveSettings() // Save to AppSettings
func toggleWeekly(Bool) // Enable/disable weekly
func updateWeeklyTime(Date) // Change weekly time
func toggleMilestones(Bool)
func toggleSpending(Bool)
func toggleDaily(Bool) // Premium check
func requestPermissions() // Ask for notification access
func sendTestNotification() // Send test
func openSystemSettings() // Deep link to iOS settings
```

**Backend Connections:**
- Read/Write AppSettings via PersistenceService
- Call NotificationService methods
- Check PremiumManager for premium status
- Request UNUserNotificationCenter permissions

---

### 3. **NotificationToggleRow.swift** (~80 lines)
Reusable toggle row component

**Props:**
- `title: String` - "Weekly Summary"
- `description: String` - "Every Sunday at 6:00 PM"
- `icon: String` - SF Symbol name
- `isOn: Binding<Bool>` - Toggle state
- `isPremium: Bool` - Show premium badge?
- `onTap: () -> Void` - Action when tapped (if locked)

**Design:**
```
┌─────────────────────────────────────┐
│ [Icon] Weekly Summary      [Toggle] │
│        Every Sunday at 6:00 PM      │
│                           [Premium] │
└─────────────────────────────────────┘
```

---

### 4. **NotificationPermissionBanner.swift** (~60 lines)
Banner shown when permissions denied

**Content:**
- Warning icon
- "Notifications Disabled" title
- "Enable in Settings to receive alerts" description
- "Open Settings" button

---

## 🔧 Backend Integration Points

### AppSettings Entity (Already exists)
Fields we'll read/write:
```swift
notificationsEnabled: Bool
weeklyNotificationsEnabled: Bool
weeklyNotificationTime: Date?
milestoneNotificationsEnabled: Bool
spendingAlertsEnabled: Bool
dailyEncouragementEnabled: Bool // premium
dailyEncouragementTime: Date?
```

### NotificationService Methods (Already exist)
Methods we'll call:
```swift
NotificationService.shared.requestPermissions() // Ask for access
NotificationService.shared.scheduleWeeklySummary() // Schedule weekly
NotificationService.shared.checkMilestones() // Check milestones
NotificationService.shared.checkSpendingAlert() // Check spending
NotificationService.shared.scheduleDailyEncouragement() // Premium only
```

### PremiumManager (Already exists)
```swift
PremiumManager.shared.hasAdvancedNotifications // Check premium
PremiumManager.shared.isPremium // General check
```

---

## 📝 Implementation Steps

### **Day 1: Foundation (3-4 hours)**

#### Step 1: Create ViewModel
**File:** `NotificationSettingsViewModel.swift`
**Location:** `Features/SettingsFeature/ViewModel/`

**Tasks:**
1. Define all @Published properties
2. Create init() that loads settings from AppSettings
3. Implement loadSettings() method
4. Implement saveSettings() method
5. Add observers for AppSettings and PremiumManager changes
6. Request notification permissions in init

**Code:**
```swift
import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    // Published properties
    @Published var weeklyEnabled = false
    @Published var weeklyTime = Date()
    @Published var milestonesEnabled = false
    @Published var spendingEnabled = false
    @Published var dailyEnabled = false
    @Published var dailyTime = Date()
    @Published var isPremium = false
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var showPaywall = false
    @Published var isLoading = false

    // Services
    private let persistenceService: PersistenceService
    private let notificationService: NotificationService
    private let premiumManager: PremiumManager
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize services
        // Load settings
        // Setup observers
        // Check permissions
    }

    func loadSettings() { /* Load from AppSettings */ }
    func saveSettings() { /* Save to AppSettings + call NotificationService */ }
    func toggleWeekly(_ enabled: Bool) { /* Toggle + schedule/cancel */ }
    func updateWeeklyTime(_ time: Date) { /* Update + reschedule */ }
    func toggleMilestones(_ enabled: Bool) { /* Toggle */ }
    func toggleSpending(_ enabled: Bool) { /* Toggle */ }
    func toggleDaily(_ enabled: Bool) { /* Premium check + toggle */ }
    func requestPermissions() async { /* Ask iOS for permission */ }
    func sendTestNotification() { /* Send test */ }
    func openSystemSettings() { /* Open iOS settings */ }
}
```

#### Step 2: Create Reusable Components
**Files:**
- `NotificationToggleRow.swift`
- `NotificationPermissionBanner.swift`

**Location:** `Features/SettingsFeature/View/Components/`

---

### **Day 2: Main UI (3-4 hours)**

#### Step 3: Create Main View
**File:** `NotificationSettingsView.swift`
**Location:** `Features/SettingsFeature/View/`

**Structure:**
```swift
NavigationStack {
    ScrollView {
        VStack(spacing: 24) {
            // Permission banner (if needed)
            if viewModel.permissionStatus == .denied {
                NotificationPermissionBanner()
            }

            // Notification types section
            notificationTypesSection

            // Test notification
            testNotificationButton

            // Info section
            infoSection
        }
    }
    .navigationTitle("Notifications")
    .sheet(isPresented: $viewModel.showPaywall) {
        PremiumPaywallView(feature: .advancedNotifications)
    }
}
```

#### Step 4: Build Sections
1. **Notification Types Section:**
   - Weekly Summary toggle + time picker
   - Milestone Alerts toggle
   - Spending Alerts toggle
   - Daily Encouragement toggle (with premium badge)

2. **Test Button:**
   - "Send Test Notification" button
   - Sends sample notification
   - Shows confirmation

3. **Info Section:**
   - Explanation of each notification type
   - Link to manage iOS settings

---

### **Day 3: Integration & Polish (2-3 hours)**

#### Step 5: Connect to Existing Backend
**Tasks:**
1. Test loading settings from AppSettings
2. Test saving settings to AppSettings
3. Verify NotificationService methods are called
4. Test permission requests
5. Test premium gating

#### Step 6: Add to Navigation
**Update:** `SettingsView.swift`

Add navigation link to NotificationSettingsView:
```swift
NavigationLink {
    NotificationSettingsView()
} label: {
    SettingsRow(
        icon: "bell.fill",
        title: "Notifications",
        subtitle: "Manage alerts and reminders"
    )
}
```

#### Step 7: Testing
**Test Cases:**
1. ✅ Load settings on first launch
2. ✅ Save settings when toggled
3. ✅ Request permissions when needed
4. ✅ Show banner if permissions denied
5. ✅ Premium features locked for free users
6. ✅ Premium features unlock after purchase
7. ✅ Weekly time picker updates correctly
8. ✅ Test notification sends
9. ✅ Background scheduling works
10. ✅ Settings persist across app restarts

---

## 🔌 Backend Connections Summary

### What Exists (Phase 1A):
```
AppSettings Entity
├── notificationsEnabled
├── weeklyNotificationsEnabled
├── weeklyNotificationTime
├── milestoneNotificationsEnabled
├── spendingAlertsEnabled
├── dailyEncouragementEnabled
└── dailyEncouragementTime

NotificationService
├── requestPermissions()
├── scheduleWeeklySummary()
├── checkMilestones()
├── checkSpendingAlert()
└── scheduleDailyEncouragement()

PremiumManager
└── hasAdvancedNotifications
```

### What We'll Add (Phase 1C):
```
NotificationSettingsViewModel
├── Reads from AppSettings ✅
├── Writes to AppSettings ✅
├── Calls NotificationService methods ✅
├── Checks PremiumManager ✅
└── Manages UI state ✅

NotificationSettingsView
├── Displays current settings ✅
├── Updates AppSettings on change ✅
├── Shows premium paywall ✅
└── Handles permissions ✅
```

**Connection Flow:**
```
User toggles switch
    ↓
ViewModel.toggle() called
    ↓
ViewModel updates AppSettings (PersistenceService)
    ↓
ViewModel calls NotificationService.schedule()
    ↓
iOS schedules notification
    ↓
UI updates to reflect new state
```

---

## 🎨 UI/UX Features

### Animations:
- ✅ Smooth toggle animations
- ✅ Time picker slide in/out
- ✅ Premium badge pulse
- ✅ Permission banner slide down

### Accessibility:
- ✅ VoiceOver labels for all toggles
- ✅ Hint text for premium features
- ✅ Clear state announcements

### Premium Integration:
- ✅ Premium badge on Daily Encouragement
- ✅ Tap locked feature → paywall
- ✅ Auto-enable after upgrade

### Error Handling:
- ✅ Permission denied → show banner + open settings button
- ✅ Save failed → show error alert
- ✅ Test notification failed → show error

---

## 📦 Files to Create

| File | Lines | Purpose |
|------|-------|---------|
| NotificationSettingsViewModel.swift | ~200 | State management & backend |
| NotificationSettingsView.swift | ~250 | Main settings screen |
| NotificationToggleRow.swift | ~80 | Reusable toggle component |
| NotificationPermissionBanner.swift | ~60 | Permission denied banner |

**Total:** 4 new files, ~590 lines

---

## 🎯 Success Criteria

**Phase 1C is complete when:**
- ✅ Users can enable/disable all notification types
- ✅ Users can set custom times for weekly/daily
- ✅ Premium features are properly gated
- ✅ Settings persist across app restarts
- ✅ Permissions are properly requested
- ✅ Denied permissions show helpful banner
- ✅ Test notification works
- ✅ All toggles update AppSettings
- ✅ NotificationService methods are called
- ✅ Background scheduling works
- ✅ Navigation from Settings works
- ✅ Accessibility is complete

---

## 🚫 What We're NOT Building

**Out of scope for Phase 1C:**
- ❌ Advanced notification customization (frequency, etc.)
- ❌ Notification history/logs
- ❌ Custom notification sounds
- ❌ Notification categories beyond the 5 types
- ❌ Push notifications (only local)
- ❌ Notification actions (buttons in notification)

These can be added in Phase 2 if needed.

---

## 🔄 Integration Points

### Existing Code to Modify:
1. **SettingsView.swift** - Add navigation link (5 lines)
2. **No other changes needed!** Backend is ready.

### Existing Code to Use:
1. **AppSettings** - Read/write notification preferences
2. **NotificationService** - Call scheduling methods
3. **PremiumManager** - Check premium status
4. **PersistenceService** - Save settings
5. **PremiumPaywallView** - Show paywall (already exists)

---

## ⏱️ Time Estimate

**Day 1 (3-4 hours):**
- Create ViewModel
- Create reusable components
- Test backend connections

**Day 2 (3-4 hours):**
- Create main view
- Build all sections
- Connect UI to ViewModel

**Day 3 (2-3 hours):**
- Add navigation
- Testing
- Bug fixes
- Polish

**Total:** 8-11 hours over 2-3 days

---

## 🎨 Design Mockup

```
┌─────────────────────────────────────┐
│ ← Notifications                     │
├─────────────────────────────────────┤
│                                     │
│ ⚠️ Notifications Disabled           │
│    Enable in Settings to receive    │
│    [Open Settings]                  │
│                                     │
├─────────────────────────────────────┤
│ NOTIFICATION TYPES                  │
├─────────────────────────────────────┤
│ [📊] Weekly Summary        [ON]     │
│      Every Sunday at 6:00 PM        │
│      [Time Picker if expanded]      │
├─────────────────────────────────────┤
│ [🎯] Milestone Alerts      [ON]     │
│      Positive streaks & goals       │
├─────────────────────────────────────┤
│ [💸] Spending Alerts       [ON]     │
│      When spending up >20%          │
├─────────────────────────────────────┤
│ [⭐] Daily Encouragement   [OFF]    │
│      Every day at 9:00 AM           │
│                        [Premium]    │
├─────────────────────────────────────┤
│                                     │
│     [Send Test Notification]        │
│                                     │
├─────────────────────────────────────┤
│ HOW IT WORKS                        │
├─────────────────────────────────────┤
│ • Weekly summaries show your        │
│   financial progress                │
│ • Milestone alerts celebrate        │
│   achievements                      │
│ • Spending alerts warn you early    │
│ • Daily tips keep you motivated     │
│   (Premium)                         │
└─────────────────────────────────────┘
```

---

## 📊 Phase 1C Summary

**What we're building:** Complete notification settings UI
**Backend changes:** NONE (already complete)
**Frontend changes:** 4 new files (~590 lines)
**Integration:** Connect UI to existing backend
**Duration:** 2-3 days
**Complexity:** Medium

---

Ready to start Phase 1C! 🚀
