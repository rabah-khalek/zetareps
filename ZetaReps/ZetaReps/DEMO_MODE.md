# Demo Mode Documentation

## Overview

The ZetaReps app includes a built-in demo data system that allows you to populate the app with realistic workout data for testing, screenshots, and demonstrations.

## Features

- **Toggle Demo Mode**: Enable or disable demo mode with a simple toggle
- **Multiple Scenarios**: Choose from pre-configured workout patterns
- **Realistic Data**: Generated data mimics real workout habits and progression
- **Debug Only**: Demo mode is only available in DEBUG builds (automatically disabled in production)

## How to Use

### Enabling Demo Mode

1. Open the app in a DEBUG build
2. Navigate to **Settings** tab
3. Scroll down to **Debug & Demo** section
4. Toggle **Demo Mode** to ON

### Loading Demo Data

Once demo mode is enabled, you'll see:

- **Load Demo Scenario** menu with the following options:
  - **Empty (Clear All)**: Removes all workout data
  - **Beginner**: 2 weeks of data, 2-3 workouts per week, low volume
  - **Intermediate**: Full month, 4-5 workouts per week, moderate volume
  - **Advanced**: Full month, 6-7 workouts per week, high volume
  - **Streak Chaser**: Perfect daily workout for 30 days
  - **Inconsistent**: Sporadic workouts with large gaps
  - **Realistic Month**: Algorithmically generated month of varied workout patterns

- **Clear All Workouts** button (destructive): Removes all workout data

## Demo Scenarios Explained

### Beginner
- **Duration**: 2 weeks
- **Frequency**: 2-3 times per week
- **Reps**: 10-25 per workout
- **Difficulty**: Moderate to Hard (3-5)
- **Use Case**: Testing onboarding, early metrics

### Intermediate
- **Duration**: 30 days
- **Frequency**: 4-5 times per week (65% daily probability)
- **Reps**: 25-45 per workout
- **Difficulty**: Easy to Moderate (2-4)
- **Use Case**: Testing consistency metrics, weekly patterns

### Advanced
- **Duration**: 30 days
- **Frequency**: 6-7 times per week (90% daily probability)
- **Reps**: 40-70 per workout
- **Difficulty**: Easy to Moderate (2-4)
- **Use Case**: Testing high-volume scenarios, intensity metrics

### Streak Chaser
- **Duration**: 30 days
- **Frequency**: Every single day
- **Reps**: 30-50 per workout
- **Difficulty**: Easy to Moderate (2-4)
- **Use Case**: Testing streak calculations, perfect consistency

### Inconsistent
- **Duration**: 30 days
- **Frequency**: 9 workouts with large gaps (days: 0, 2, 5, 7, 13, 14, 20, 27, 29)
- **Reps**: 15-40 per workout
- **Difficulty**: Variable (2-5)
- **Use Case**: Testing low consistency, irregular patterns

### Realistic Month
- **Duration**: 30 days
- **Algorithm**:
  - 70% probability of working out each day
  - 10% probability of second workout on workout days
  - Progressive overload (50% increase in reps over 30 days)
  - Duration based on rep count (roughly 1 rep per 2 seconds + rest)
  - Difficulty scales with intensity
  - 20% chance of workout notes
- **Use Case**: Most realistic demo for screenshots and presentations

## Technical Details

### Flag System

The demo mode flag is stored in `UserDefaults` with key `"DemoModeEnabled"`:

```swift
// Check if demo mode is enabled
DemoDataManager.isDemoModeEnabled

// Set demo mode
DemoDataManager.setDemoMode(true) // or false
```

### Compilation

Demo mode is protected by compiler directives:

```swift
#if DEBUG
// Demo mode code
#else
return false // Always disabled in production
#endif
```

This ensures that:
- Demo mode UI only appears in DEBUG builds
- Demo mode cannot accidentally be enabled in production/TestFlight/App Store builds
- No demo code is included in release builds

### Data Generation

All demo data is inserted into the SwiftData `ModelContext`:

```swift
DemoDataManager.generateDemoData(context: modelContext)
```

### Data Clearing

The system can clear all workouts:

```swift
DemoDataManager.clearAllData(context: modelContext)
```

## Best Practices

1. **Always clear before loading**: Each scenario automatically clears existing data before generating new data
2. **Test all scenarios**: Different scenarios stress-test different parts of the metrics system
3. **Use Realistic Month for demos**: This scenario provides the most natural-looking data
4. **Disable for actual testing**: Turn off demo mode when testing real user workflows

## Safety

- ⚠️ **Demo mode clears real data**: When loading a scenario, all existing workouts are deleted
- ✅ **Production safe**: Demo mode cannot be enabled in production builds
- ✅ **Debug only**: All demo UI is stripped from release builds

## Examples

### Taking Screenshots
1. Enable Demo Mode
2. Load "Realistic Month" scenario
3. Navigate to History view for charts
4. Navigate to Home view for stats
5. Take screenshots
6. Disable Demo Mode when done

### Testing Edge Cases
1. Enable Demo Mode
2. Load "Empty" scenario to test zero state
3. Load "Beginner" scenario to test sparse data
4. Load "Inconsistent" scenario to test low consistency metrics
5. Check all calculations and UI states

### Testing Performance
1. Enable Demo Mode
2. Load "Advanced" scenario (high volume)
3. Navigate through all views
4. Check scroll performance in History
5. Check chart rendering speed
