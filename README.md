# ZetaReps

> **Status: free, final release, no longer maintained.**
> Version 1.0.4 removed the Premium subscription and the 100-pushup limit; every feature is unlocked for everyone.
> The App Store listing is available until late October 2026 and installed copies keep working after that.
> The source is MIT licensed, so anyone can build it with Xcode or fork it. Website: https://www.zetareps.com

A modern iOS fitness app for tracking pushup workouts with set-based training, performance metrics, smart notifications, and science-backed recommendations.

## Features

### Core Functionality
- **Set-Based Workout Tracking**: Track sets, reps, and rest periods with guided workout sessions
- **Dual Performance Metrics**: 0-10 scoring system for Consistency and Intensity
- **Smart Notifications**: Flexible scheduling with context-aware reminders
- **Accurate Timer**: DispatchSourceTimer tracks workout duration and rest periods
- **Manual Rep Entry**: Simple +/- buttons to log completed pushups (no unreliable camera counting)
- **Difficulty Tracking**: Rate each workout on a 1-5 scale with emoji indicators
- **Science-Based Recommendations**: Fitness level system with auto-calculated targets based on 8 authoritative sources
- **On-Device Storage**: All data stored locally using SwiftData
- **Progress Visualization**: Charts showing metrics trends and reps over time

### Additional Features
- **Streak Tracking**: Monitor workout consistency with rest day support
- **Personal Records**: Track best single workout, longest streak, and total pushups
- **Calendar Heatmap**: Visual 7-day intensity view on home screen
- **Performance Optimization Tips**: Based on metric correlation analysis
- **Bento Stats Grid**: Dashboard with today's count, weekly progress, streak, and next workout countdown
- **Recommended Standards**: Toggle between custom targets and fitness-level-based recommendations (Beginner/Intermediate/Advanced)
- **Rest Day Management**: Preserve streaks during legitimate breaks
- **Share Progress**: Export achievements and stats to social media

### Pricing

ZetaReps is completely free. There is no subscription, no in-app purchase and no pushup limit; the full history, all analytics charts, the complete calendar and all-time statistics are included for everyone.
- Non-intrusive: Locked state on start button when limit reached

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Database**: SwiftData (iOS 17+)
- **Notifications**: UserNotifications framework with smart scheduling
- **Timer**: DispatchSourceTimer for accurate tracking
- **Charts**: SwiftUI Charts with horizontal scrolling and performance bands
- **Design**: Glassmorphic UI with adaptive color schemes

## Requirements

- **iOS**: 17.0 or later
- **Xcode**: 15.0 or later
- **Device**: iPhone (iPad compatible)
- **Mac**: Required for development

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Click "Create New Project"
3. Select "iOS" → "App"
4. Configure project:
   - Product Name: `ZetaReps`
   - Team: Select your development team
   - Organization Identifier: Your bundle identifier (e.g., `com.yourname.zetareps`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (check the box)
5. Click "Next" and choose save location

### 2. Add Source Files

Copy all the Swift files from this repository into your Xcode project:

```
ZetaReps/
├── ZetaRepsApp.swift          # Main app entry point
├── ContentView.swift          # Tab view controller
├── Models/
│   ├── Workout.swift              # SwiftData workout model
│   ├── RestDay.swift              # Rest day tracking
│   ├── AppSettings.swift          # User preferences manager
│   └── NotificationSchedule.swift # Notification scheduling models
├── Managers/
│   ├── NotificationManager.swift  # Smart notification scheduling
│   ├── SubscriptionManager.swift  # Feature access (everything unlocked)
│   ├── MetricsCalculator.swift    # Performance metrics calculation
│   ├── ShareManager.swift         # Social sharing
│   └── DemoDataManager.swift      # Test data generation
└── Views/
    ├── HomeView.swift             # Home screen with bento grid & stats
    ├── WorkoutSessionView.swift   # Active workout timer with rest periods
    ├── CompleteWorkoutView.swift  # Post-workout entry form
    ├── HistoryView.swift          # History with charts and statistics
    ├── WorkoutDetailView.swift    # Individual workout details
    ├── DayWorkoutsView.swift      # All workouts for a specific day
    ├── RestDayDetailView.swift    # Rest day notes
    └── Settings/
        ├── SettingsView.swift                   # App settings
        ├── ScheduleBuilderView.swift            # Advanced notification scheduling
        └── RecommendedStandardsInfoView.swift   # Scientific references
```

**To add files in Xcode**:
1. Right-click on the project folder in the navigator
2. Select "New Group" to create folders (Models, Managers, Views)
3. Right-click on each folder and select "New File"
4. Choose "Swift File" and paste the content from each file

### 3. Configure Info.plist

Add required privacy descriptions:

1. In Xcode, select your project in the navigator
2. Select your target
3. Go to the "Info" tab
4. Add these keys by clicking the "+" button:

```xml
Privacy - User Notifications Usage Description
Value: "We need permission to send you pushup reminders based on your custom schedule."
```

### 4. Enable In-App Purchase Capability

1. Select your project target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability"
4. Add "In-App Purchase"
5. Add "Push Notifications" (for local notifications)

### 6. Configure App Icon (Optional)

1. Prepare an icon image (1024×1024 PNG)
2. In Xcode, go to Assets.xcassets
3. Select "AppIcon"
4. Drag your icon into the 1024×1024 slot
5. Xcode will generate all required sizes

### 7. Build and Run

1. Select your target device (iPhone simulator or physical device)
2. Press Cmd+R or click the Play button
3. Allow notifications when prompted
4. Configure your reminder schedule in Settings tab

## Project Structure

### Models
- **Workout**: SwiftData model storing date, duration, sets, repsCompleted, difficultyRating, notes
- **RestDay**: Tracks designated rest days to preserve streaks
- **AppSettings**: ObservableObject managing all user preferences with UserDefaults persistence
- **NotificationSchedule**: Granular scheduling system with ScheduleRule, TimeComponents, Weekday

### Managers
- **NotificationManager**: Smart notifications with context-awareness (checks rest days, recent workouts)
- **SubscriptionManager**: Feature access; everything is unlocked for everyone
- **MetricsCalculator**:
  - Consistency Score (0-10): Based on frequency (60%) and set completion (40%)
  - Intensity Score (0-10): Based on sets/reps (60%), difficulty (30%), volume bonus (10%)
  - Personal records tracking and performance optimization tips
- **ShareManager**: Generates shareable text from workout metrics
- **DemoDataManager**: Creates realistic demo data for testing

### Views
- **HomeView**: Bento stats grid, performance metrics card, personal records, calendar heatmap, free limit indicator
- **WorkoutSessionView**: Set-based UI with workout timer, rest timer, animated backgrounds
- **CompleteWorkoutView**: Sets/reps adjustment, difficulty selector, save & share options
- **HistoryView**: Time range filters, metrics progress chart, reps progress chart with scrolling
- **SettingsView**: Appearance, workout targets (custom/recommended), notifications
- **ContentView**: TabView navigation between all main screens

## Usage Guide

### Setting Up Workout Targets

1. Open the **Settings** tab
2. Choose between **Custom** or **Recommended Standards**:
   - **Recommended**: Select your fitness level (Beginner/Intermediate/Advanced)
     - Beginner: 3 sets × 8 reps, 4 days/week, 60s rest
     - Intermediate: 4 sets × 15 reps, 5 days/week, 60s rest
     - Advanced: 5 sets × 30 reps, 6 days/week, 60s rest
   - **Custom**: Use steppers to set your own targets
3. Configure appearance (System/Light/Dark mode)

### Setting Up Reminders

1. Open the **Settings** tab
2. Toggle "Enable Reminders" on
3. Grant notification permission when prompted
4. Choose notification schedule:
   - **Daily**: Single reminder per day
   - **Hourly**: Multiple reminders throughout the day
   - **Twice Daily**: Morning and evening reminders
   - **Every X Hours**: Custom interval
   - **Custom Times**: Specific times you choose
5. Select active days (exclude rest days)
6. Set optional time range (e.g., 8 AM - 8 PM)

### Starting a Workout

1. Go to the **Home** tab
2. View your stats: today's count, weekly progress, streak, next workout
3. Check your Performance Metrics (Consistency & Intensity scores)
4. Tap "Start Workout" (disabled if free limit reached)
5. Complete sets with automatic rest timers between each set
6. Timer tracks total workout duration
7. Tap "Complete Workout" when finished

### Logging Your Workout

1. Review auto-calculated sets and reps
2. Use +/- buttons to adjust actual performance
3. Select difficulty rating (1-5 scale):
   - 😊 Easy
   - 🙂 Light
   - 😐 Moderate
   - 😓 Hard
   - 😰 Very Hard
4. Add optional notes
5. Tap "Save Workout" or "Save & Share"

### Viewing Progress

1. Go to the **History** tab
2. Use segmented control to filter by:
   - Week: Last 7 days
   - Month: Last 30 days
   - All Time: Complete history
3. View statistics summary (total reps, workouts, averages, total time)
4. Scroll through **Metrics Progress Chart** showing Consistency & Intensity trends with performance bands
5. Scroll through **Reps Progress Chart** with difficulty-based color coding
6. Tap any day on calendar to see all workouts
7. Long-press calendar day to toggle rest day

## Performance Metrics Details

### Consistency Score (0-10)
- **Frequency (60%)**: Workout days / expected days in period
- **Set Completion (40%)**: % of workouts meeting target sets AND reps per set
- Calculated from 3-10 most recent workouts

### Intensity Score (0-10)
- **Sets/Reps Achievement (60%)**: Combined evaluation of hitting targets
- **Difficulty Rating (30%)**: Average difficulty normalized from 1-5 scale
- **Volume Bonus (10%)**: Rewards exceeding targets
- Includes performance optimization tips based on metric correlation

### Streak Calculation
- Allows 2-day gaps OR rest days to preserve streaks
- Rest days don't break streaks
- Displayed prominently on home screen

## Notification Scheduling Details

The app uses smart context-aware notifications:

- **Priority System**: Custom Times > Schedule Rule > Legacy Frequency
- **Context Filters**: Skips notifications on rest days, after recent workouts
- **Free Limit Check**: Stops all reminders at 100 pushups
- **iOS Limit Protection**: Manages 64-notification system limit
- **Granular Scheduling**: ScheduleRule supports weekday filtering and time ranges

## Troubleshooting

### Notifications Not Appearing

1. Check Settings app → Notifications → ZetaReps
2. Ensure "Allow Notifications" is enabled
3. In app Settings, verify notification schedule is configured
4. Check active days selection

### Metrics Not Calculating

- Metrics require at least 3 completed workouts
- Ensure workouts are within the selected time range
- Check that set completion data is recorded

### Charts Not Showing

- Charts require at least 1 completed workout
- Try different time ranges (Week/Month/All Time)
- Free users: Limited to weekly charts
- Scroll horizontally for long date ranges

## Customization Ideas

### Modify Recommended Standards

Edit [AppSettings.swift](ZetaReps/Models/AppSettings.swift) in the `RecommendedStandards` struct to adjust fitness level targets.

### Change Metrics Calculation Weights

Edit [MetricsCalculator.swift](ZetaReps/Managers/MetricsCalculator.swift):
- Adjust consistency weights (frequency vs set completion)
- Adjust intensity weights (sets/reps vs difficulty vs volume)

### Customize Performance Bands

Edit chart views in [HistoryView.swift](ZetaReps/Views/HistoryView.swift) to modify performance band thresholds (Excellent/Good/Fair/Poor).

### Add More Personal Records

Edit [MetricsCalculator.swift](ZetaReps/Managers/MetricsCalculator.swift) to track additional records like:
- Best average reps per set
- Most consecutive workout days
- Highest difficulty average

## Future Enhancement Ideas

- [ ] Apple Health integration (export workouts to Health app)
- [ ] Apple Watch companion app with standalone workouts
- [ ] iCloud sync for backup and multi-device support
- [ ] Achievements and badges system
- [ ] Custom workout programs beyond pushups
- [ ] Social features (leaderboards, challenges)
- [ ] Form video tutorials
- [ ] Widget support for lock screen and home screen
- [ ] Siri shortcuts for quick workout logging
- [ ] Apple Fitness+ integration

## Performance Considerations

- **SwiftData**: Optimized for <10,000 workout records per user
- **Notifications**: Smart management stays within iOS 64-notification limit
- **Memory**: Lightweight design, minimal background usage
- **Battery**: Timer uses minimal CPU when in foreground
- **Charts**: Horizontal scrolling with visible domain management for performance

## Privacy & Data

- **All data stored locally**: Nothing sent to external servers
- **No analytics**: Zero tracking or telemetry
- **No account required**: Completely offline app
- **User control**: Delete any workout or rest day anytime
- **iOS standard**: Follows Apple's privacy guidelines

## License

This project is available for personal and educational use. Feel free to customize and extend it for your own needs!

## Credits

Built with modern iOS development best practices using:
- Swift 5.9+
- SwiftUI
- SwiftData
- UserNotifications
- SwiftUI Charts

Based on science-backed fitness research from 8 authoritative sources including MedicineNet, Peloton, The Citadel, and more.

---

**Happy Pushing! 💪**
