# Xcode Project Setup Guide

Quick guide to set up and add all source files to your ZetaReps Xcode project.

## Current File Structure

Your ZetaReps source files are organized like this:

```
/Users/projects/Documents/zetareps/ZetaReps/
├── ZetaRepsApp.swift          # Main app entry
├── ContentView.swift          # Tab view navigation
├── Models/
│   ├── Workout.swift              # SwiftData workout model
│   ├── RestDay.swift              # Rest day tracking
│   ├── AppSettings.swift          # User preferences
│   └── NotificationSchedule.swift # Notification scheduling models
├── Managers/
│   ├── NotificationManager.swift  # Smart notifications
│   ├── SubscriptionManager.swift  # In-app purchases
│   ├── MetricsCalculator.swift    # Performance metrics
│   ├── ShareManager.swift         # Social sharing
│   └── DemoDataManager.swift      # Test data generation
└── Views/
    ├── HomeView.swift
    ├── WorkoutSessionView.swift
    ├── CompleteWorkoutView.swift
    ├── HistoryView.swift
    ├── WorkoutDetailView.swift
    ├── DayWorkoutsView.swift
    ├── RestDayDetailView.swift
    ├── PaywallView.swift
    └── Settings/
        ├── SettingsView.swift
        ├── ScheduleBuilderView.swift
        └── RecommendedStandardsInfoView.swift
```

## Quick Start: Create New Xcode Project

### Step 1: Create Project

1. **Open Xcode**
2. **Create New Project**: File → New → Project (or Cmd+Shift+N)
3. **Select Template**: iOS → App
4. **Configure Project**:
   - **Product Name**: `ZetaReps`
   - **Team**: Select your Apple Developer team
   - **Organization Identifier**: `com.yourname` (or your preferred bundle ID prefix)
   - **Bundle Identifier**: Will auto-generate as `com.yourname.ZetaReps`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: **SwiftData** (✅ check this box)
   - **Include Tests**: Uncheck (optional for now)
5. **Choose Location**: Select where to save project
6. **Create Git Repository**: Check if you want version control

### Step 2: Configure Project Settings

1. **Select Project** in Navigator (blue icon at top)
2. **Select Target** "ZetaReps"
3. **General Tab**:
   - **Minimum Deployments**: iOS 17.0
   - **iPhone Orientation**: Portrait only (uncheck Landscape if preferred)
   - **iPad Orientation**: All (optional)

4. **Signing & Capabilities Tab**:
   - **Automatically manage signing**: Check
   - **Team**: Select your Apple Developer team
   - Click **"+ Capability"** and add:
     - ✅ **In-App Purchase**
     - ✅ **Push Notifications** (for local notifications)

5. **Info Tab**:
   - Add custom key: Click "+" button
   - **Key**: `Privacy - User Notifications Usage Description`
   - **Type**: String
   - **Value**: `We need permission to send you pushup reminders based on your custom schedule.`

## Step-by-Step: Add Source Files

### Method 1: Drag and Drop (Recommended)

This is the easiest method:

1. **Open Finder** alongside Xcode
2. Navigate to `/Users/projects/Documents/zetareps/ZetaReps/`

3. **Delete Default Files First**:
   - In Xcode Navigator, right-click these files and select "Delete" → "Move to Trash":
     - `Item.swift` (SwiftData default model - not needed)
     - The default `ContentView.swift` (we'll replace it)
     - The default app file (`ZetaRepsApp.swift` or similar - we'll replace it)

4. **Add Main Files**:
   - From Finder, drag `ZetaRepsApp.swift` into Xcode project root (next to Assets)
   - In dialog: ✅ Check "Copy items if needed"
   - Click "Finish"
   - Repeat for `ContentView.swift`

5. **Create Folder Groups**:

   **Models Group:**
   - Right-click on "ZetaReps" folder (yellow) in Navigator
   - Select "New Group"
   - Name it: `Models`
   - Drag from Finder into this group:
     - `Models/Workout.swift`
     - `Models/RestDay.swift`
     - `Models/AppSettings.swift`
     - `Models/NotificationSchedule.swift`
   - ✅ Check "Copy items if needed"
   - Click "Finish"

   **Managers Group:**
   - Right-click → "New Group" → name: `Managers`
   - Drag from Finder:
     - `Managers/NotificationManager.swift`
     - `Managers/SubscriptionManager.swift`
     - `Managers/MetricsCalculator.swift`
     - `Managers/ShareManager.swift`
     - `Managers/DemoDataManager.swift`
   - ✅ Check "Copy items if needed"

   **Views Group:**
   - Right-click → "New Group" → name: `Views`
   - Drag from Finder:
     - `Views/HomeView.swift`
     - `Views/WorkoutSessionView.swift`
     - `Views/CompleteWorkoutView.swift`
     - `Views/HistoryView.swift`
     - `Views/WorkoutDetailView.swift`
     - `Views/DayWorkoutsView.swift`
     - `Views/RestDayDetailView.swift`
     - `Views/PaywallView.swift`
   - ✅ Check "Copy items if needed"

   **Settings Subgroup:**
   - Right-click on "Views" group → "New Group" → name: `Settings`
   - Drag from Finder:
     - `Views/Settings/SettingsView.swift`
     - `Views/Settings/ScheduleBuilderView.swift`
     - `Views/Settings/RecommendedStandardsInfoView.swift`
   - ✅ Check "Copy items if needed"

### Method 2: Add Files Dialog

Alternative method if drag-and-drop isn't working:

1. **Right-click** on "ZetaReps" folder in Navigator
2. Select **"Add Files to 'ZetaReps'..."**
3. Navigate to `/Users/projects/Documents/zetareps/ZetaReps/`
4. **Hold Cmd** and select all files/folders you want to add
5. In dialog:
   - ✅ Check "Copy items if needed"
   - ✅ "Create groups" (not folder references)
   - ✅ Add to target: "ZetaReps"
6. Click "Add"

You may need to reorganize into groups afterward for cleaner structure.

## Add StoreKit Configuration

1. **Create StoreKit File**:
   - File → New → File (or Cmd+N)
   - Scroll to "Resource" section
   - Select **"StoreKit Configuration File"**
   - Click "Next"
   - Name: `Configuration` (will become Configuration.storekit)
   - Save location: Project root (same level as ZetaRepsApp.swift)
   - Click "Create"

2. **Add Subscription Products**:
   - Select `Configuration.storekit` in Navigator
   - Click "+" at bottom left
   - Select **"Add Auto-Renewable Subscription"**

   **Product 1: Monthly**
   - Reference Name: `Premium Monthly`
   - Product ID: `com.zetareps.premium.monthly`
   - Price: $0.99
   - Subscription Duration: 1 Month
   - Free Trial Duration: 7 Days

   **Product 2: Annual**
   - Click "+" again → "Add Auto-Renewable Subscription"
   - Reference Name: `Premium Annual`
   - Product ID: `com.zetareps.premium.annual`
   - Price: $5.99
   - Subscription Duration: 1 Year
   - Free Trial Duration: 7 Days

3. **Configure Scheme to Use StoreKit**:
   - Click scheme selector (next to play button)
   - Select "Edit Scheme..." (or Cmd+<)
   - Select "Run" in left sidebar
   - Go to "Options" tab
   - **StoreKit Configuration**: Select `Configuration.storekit`
   - Click "Close"

## Verify Your Project Structure

After adding all files, your Xcode Navigator should look like:

```
ZetaReps (project)
└── ZetaReps (folder)
    ├── ZetaRepsApp.swift
    ├── ContentView.swift
    ├── Models/
    │   ├── Workout.swift
    │   ├── RestDay.swift
    │   ├── AppSettings.swift
    │   └── NotificationSchedule.swift
    ├── Managers/
    │   ├── NotificationManager.swift
    │   ├── SubscriptionManager.swift
    │   ├── MetricsCalculator.swift
    │   ├── ShareManager.swift
    │   └── DemoDataManager.swift
    ├── Views/
    │   ├── HomeView.swift
    │   ├── WorkoutSessionView.swift
    │   ├── CompleteWorkoutView.swift
    │   ├── HistoryView.swift
    │   ├── WorkoutDetailView.swift
    │   ├── DayWorkoutsView.swift
    │   ├── RestDayDetailView.swift
    │   ├── PaywallView.swift
    │   └── Settings/
    │       ├── SettingsView.swift
    │       ├── ScheduleBuilderView.swift
    │       └── RecommendedStandardsInfoView.swift
    ├── Assets.xcassets
    │   └── AppIcon
    └── ZetaReps.entitlements (if exists)

ZetaReps (parent folder)
└── Configuration.storekit
```

## Optional: Add App Icon

1. **Prepare Icon**:
   - Create or find a 1024×1024 px PNG image
   - Should represent pushups/fitness theme
   - Use `logo.png` in project root if available

2. **Add to Xcode**:
   - In Navigator, go to `Assets.xcassets`
   - Select `AppIcon`
   - Drag your 1024×1024 PNG into the "1024pt" slot
   - Xcode will auto-generate all required sizes

3. **Alternative: Generate Icons**:
   - Use `generate_app_icons.py` script if available
   - Or use online tools like appicon.co

## Build and Test

### Step 1: Build Project

1. **Select Simulator**: iPhone 15 Pro (or any iOS 17+ device)
2. **Clean Build Folder**: Shift+Cmd+K
3. **Build Project**: Cmd+B

**Fix Common Build Errors:**

- **"Cannot find type 'X' in scope"**
  - Solution: Check file is added to target
  - Select file → File Inspector (right panel) → Target Membership → ✅ ZetaReps

- **"Multiple commands produce..."**
  - Solution: Duplicate file in target
  - Project Settings → Build Phases → Compile Sources → Remove duplicates

- **"No such module 'StoreKit'"**
  - Solution: Ensure deployment target is iOS 17.0+
  - Project Settings → General → Minimum Deployments → iOS 17.0

### Step 2: Run App

1. **Press Cmd+R** or click Play button
2. **Wait for launch** (first build takes longer)
3. **Grant Permissions**:
   - Allow notifications when prompted (important for testing)
4. **Explore App**:
   - Home screen shows stats (all zeros initially)
   - Tap "Start Workout" → Complete sets → Save
   - Go to History → See charts
   - Go to Settings → Configure targets and notifications

### Step 3: Test Key Features

**Basic Workout Flow:**
- ✅ Start workout from Home
- ✅ Rest timer appears between sets
- ✅ Complete workout and save
- ✅ View workout in History

**Performance Metrics:**
- ✅ Complete 3+ workouts to see Consistency & Intensity scores
- ✅ Check metrics chart in History (requires Premium after 100 pushups)

**Subscription Testing:**
- ✅ Complete workouts until 100 total pushups reached
- ✅ See locked state on Home screen
- ✅ Tap "Upgrade to Premium"
- ✅ Subscribe with StoreKit test sheet
- ✅ Verify premium features unlock

**Notifications:**
- ✅ Settings → Enable Reminders
- ✅ Configure schedule (Daily/Hourly/Custom)
- ✅ Check scheduled notifications: Settings app → Notifications → ZetaReps

**Recommended Standards:**
- ✅ Settings → Toggle "Recommended Standards"
- ✅ Select fitness level (Beginner/Intermediate/Advanced)
- ✅ Verify targets auto-update

### Step 4: Debug Mode Features

The app includes debug features (only in DEBUG builds):

1. **Settings → Debug Section** (at bottom):
   - **Generate Demo Data**: Creates realistic workout history
     - Beginner Preset: 3 weeks of beginner workouts
     - Intermediate Preset: 3 weeks of intermediate workouts
     - Advanced Preset: 3 weeks of advanced workouts
   - **Test Notifications**: Schedule test notification for 5 seconds
   - **View Scheduled Notifications**: Check what's scheduled

## Testing on Physical Device

### Prerequisites:
- Apple Developer account ($99/year) OR free personal team
- Physical iPhone running iOS 17+

### Steps:

1. **Connect iPhone** via USB
2. **Trust Computer**: Unlock iPhone → Trust prompt → Trust
3. **Select Device**: In Xcode, select your iPhone from device dropdown
4. **Fix Signing**:
   - If error: "Failed to create provisioning profile"
   - Project Settings → Signing & Capabilities
   - Change Bundle Identifier to unique value (e.g., add your initials)
5. **Build and Run**: Cmd+R
6. **Trust Developer**:
   - On iPhone: Settings → General → VPN & Device Management
   - Tap your developer profile → Trust

**Benefits of Testing on Device:**
- Real-world performance testing
- Actual notifications (simulators may behave differently)
- True haptic feedback
- Test subscription flow with real App Store sandbox

## Next Steps

After successfully building and testing:

1. ✅ **Complete Testing**:
   - Test all features thoroughly
   - Complete 100 pushups to trigger paywall
   - Verify subscription flow works
   - Test restore purchases

2. ✅ **Customize (Optional)**:
   - Modify recommended standards in [AppSettings.swift](ZetaReps/Models/AppSettings.swift)
   - Adjust metrics weights in [MetricsCalculator.swift](ZetaReps/Managers/MetricsCalculator.swift)
   - Change performance bands in [HistoryView.swift](ZetaReps/Views/HistoryView.swift)

3. ✅ **Prepare for App Store**:
   - Follow [APP_STORE_SETUP.md](APP_STORE_SETUP.md) for complete guide
   - Create app in App Store Connect
   - Configure subscriptions
   - Submit for review

4. ✅ **Read Full Documentation**:
   - [README.md](README.md) for complete feature list and customization
   - [APP_STORE_SETUP.md](APP_STORE_SETUP.md) for submission process

## Troubleshooting

### Build Errors

**"Cannot find 'Workout' in scope"**
- **Cause**: Model files not added to target
- **Fix**:
  1. Select `Workout.swift` in Navigator
  2. Open File Inspector (right panel)
  3. Under "Target Membership", check ✅ ZetaReps

**"Multiple commands produce 'ContentView.swift'"**
- **Cause**: File added twice or old default file remains
- **Fix**:
  1. Project Settings → Build Phases → Compile Sources
  2. Find duplicate `ContentView.swift` entries
  3. Delete one (click "-" button)

**"No such module 'StoreKit'"**
- **Cause**: Deployment target too low
- **Fix**: Project Settings → General → Minimum Deployments → iOS 17.0

**"Ambiguous use of 'body'"**
- **Cause**: SwiftUI view syntax error or missing import
- **Fix**: Check error location, ensure `import SwiftUI` at top of file

### Runtime Errors

**App crashes on launch**
- **Check Console**: Look for error messages in Xcode console (bottom panel)
- **Common causes**:
  - SwiftData model mismatch (delete app from simulator and reinstall)
  - Missing StoreKit configuration (ensure Configuration.storekit exists)

**Notifications not appearing**
- **Simulator**: Local notifications may be delayed or not appear
- **Test on device**: Physical device is more reliable
- **Check permissions**: Settings app → Notifications → ZetaReps → Allow

**Subscription products not loading**
- **StoreKit configuration**: Ensure scheme is set to use Configuration.storekit
- **Product IDs**: Verify they match in SubscriptionManager.swift and Configuration.storekit
- **Wait**: Initial load can take 5-10 seconds

**Metrics showing 0.0**
- **Need data**: Requires at least 3 completed workouts
- **Use demo data**: Settings → Debug → Generate Demo Data (if DEBUG mode)

### File Organization

**Files not showing in groups**
- Groups are visual only in Xcode Navigator
- Files are still in project even if not organized
- To reorganize: Drag files into groups in Navigator

**Files appear red/missing**
- **Cause**: File moved in Finder but Xcode reference broken
- **Fix**:
  1. Select red file in Navigator
  2. File Inspector → Location → Click folder icon
  3. Navigate to actual file location

## Performance Optimization

**Slow simulator performance**
- Use newer simulator (iPhone 15 Pro)
- Clean build folder: Shift+Cmd+K
- Restart Xcode and simulator

**Charts rendering slowly**
- Expected with demo data (100+ workouts)
- Optimize by limiting visible domain (already implemented)
- Test on device for real-world performance

## Additional Resources

**Xcode Help:**
- Xcode → Help → Xcode Help
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

**SwiftData:**
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Modeling Data Guide](https://developer.apple.com/documentation/swiftdata/modeling-data)

**StoreKit:**
- [StoreKit 2 Guide](https://developer.apple.com/documentation/storekit)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases)

---

**Ready to build and test! 🏗️**
