//
//  DemoDataManager.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Manager for generating realistic demo workout data
class DemoDataManager {

    // MARK: - Demo Mode Flag

    enum DemoPreset: String, CaseIterable, Codable {
        case disabled = "Disabled"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var displayName: String { rawValue }
    }

    /// Toggle this to enable/disable demo data
    /// Set to `true` to populate with demo data, `false` for production
    static var isDemoModeEnabled: Bool {
        #if DEBUG
        return currentDemoPreset != .disabled
        #else
        return false // Always disabled in production
        #endif
    }

    static var currentDemoPreset: DemoPreset {
        #if DEBUG
        guard let data = UserDefaults.standard.data(forKey: "DemoPreset"),
              let preset = try? JSONDecoder().decode(DemoPreset.self, from: data) else {
            return .disabled
        }
        return preset
        #else
        return .disabled
        #endif
    }

    static func setDemoMode(_ enabled: Bool) {
        #if DEBUG
        if enabled {
            setDemoPreset(.intermediate)
        } else {
            setDemoPreset(.disabled)
        }
        #endif
    }

    static func setDemoPreset(_ preset: DemoPreset) {
        #if DEBUG
        if let data = try? JSONEncoder().encode(preset) {
            UserDefaults.standard.set(data, forKey: "DemoPreset")
        }
        #endif
    }

    // MARK: - Demo Data Generation

    /// Generate demo data based on current preset
    /// - Parameter context: SwiftData ModelContext to insert workouts into
    static func generateDemoData(context: ModelContext) {
        let preset = currentDemoPreset

        switch preset {
        case .disabled:
            clearAllData(context: context)
        case .beginner:
            generateBeginnerData(context: context)
        case .intermediate:
            generateIntermediateData(context: context)
        case .advanced:
            generateAdvancedData(context: context)
        }
    }

    /// Generate Beginner profile demo data: 2-3 sets × 5-10 reps, 3-4 days/week
    private static func generateBeginnerData(context: ModelContext) {
        clearAllData(context: context)

        let calendar = Calendar.current
        let now = Date()
        let daysToGenerate = 30 // 1 month of data

        // Beginner: 3-4 days/week = ~0.5-0.57 probability per day (average 0.5)
        let workoutFrequency = 0.5
        let targetSets = 2...3
        let targetRepsPerSet = 5...10

        for daysAgo in 0..<daysToGenerate {
            let shouldWorkout = Double.random(in: 0...1) < workoutFrequency

            if shouldWorkout {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

                // Beginner profile: 2-3 sets, 5-10 reps per set
                let sets = Int.random(in: targetSets)
                let repsPerSet = Int.random(in: targetRepsPerSet)
                let totalReps = sets * repsPerSet

                // Duration: ~2 seconds per rep + rest between sets
                let duration = TimeInterval(totalReps * 2 + sets * 30) // 30s rest per set

                // Difficulty: beginners often find it harder (3-4 range)
                let difficulty = Int.random(in: 3...4)

                let workout = Workout(
                    date: date,
                    duration: duration,
                    sets: sets,
                    repsCompleted: totalReps,
                    difficultyRating: difficulty,
                    notes: ""
                )
                context.insert(workout)
            }
        }

        try? context.save()
    }

    /// Generate Intermediate profile demo data: 3-4 sets × 10-20 reps, 4-5 days/week
    private static func generateIntermediateData(context: ModelContext) {
        clearAllData(context: context)

        let calendar = Calendar.current
        let now = Date()
        let daysToGenerate = 30 // 1 month of data

        // Intermediate: 4-5 days/week = ~0.57-0.71 probability per day (average 0.65)
        let workoutFrequency = 0.65
        let targetSets = 3...4
        let targetRepsPerSet = 10...20

        for daysAgo in 0..<daysToGenerate {
            let shouldWorkout = Double.random(in: 0...1) < workoutFrequency

            if shouldWorkout {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

                // Intermediate profile: 3-4 sets, 10-20 reps per set
                let sets = Int.random(in: targetSets)
                let repsPerSet = Int.random(in: targetRepsPerSet)
                let totalReps = sets * repsPerSet

                // Duration: ~2 seconds per rep + rest between sets
                let duration = TimeInterval(totalReps * 2 + sets * 45) // 45s rest per set

                // Difficulty: intermediate users moderate difficulty (2-4 range)
                let difficulty = Int.random(in: 2...4)

                let workout = Workout(
                    date: date,
                    duration: duration,
                    sets: sets,
                    repsCompleted: totalReps,
                    difficultyRating: difficulty,
                    notes: ""
                )
                context.insert(workout)
            }
        }

        try? context.save()
    }

    /// Generate Advanced profile demo data: 4-5 sets × 20-40 reps, 5-6 days/week
    private static func generateAdvancedData(context: ModelContext) {
        clearAllData(context: context)

        let calendar = Calendar.current
        let now = Date()
        let daysToGenerate = 30 // 1 month of data

        // Advanced: 5-6 days/week = ~0.71-0.86 probability per day (average 0.8)
        let workoutFrequency = 0.8
        let targetSets = 4...5
        let targetRepsPerSet = 20...40

        for daysAgo in 0..<daysToGenerate {
            let shouldWorkout = Double.random(in: 0...1) < workoutFrequency

            if shouldWorkout {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

                // Advanced profile: 4-5 sets, 20-40 reps per set
                let sets = Int.random(in: targetSets)
                let repsPerSet = Int.random(in: targetRepsPerSet)
                let totalReps = sets * repsPerSet

                // Duration: ~2 seconds per rep + rest between sets
                let duration = TimeInterval(totalReps * 2 + sets * 60) // 60s rest per set

                // Difficulty: advanced users can handle higher intensity but may still rate it 2-3 (moderate)
                // or sometimes 4 if pushing limits
                let difficulty = Int.random(in: 2...4)

                let workout = Workout(
                    date: date,
                    duration: duration,
                    sets: sets,
                    repsCompleted: totalReps,
                    difficultyRating: difficulty,
                    notes: ""
                )
                context.insert(workout)
            }
        }

        try? context.save()
    }

    /// Generate a month of realistic workout data (legacy method)
    /// - Parameter context: SwiftData ModelContext to insert workouts into
    static func generateStandardDemoData(context: ModelContext) {
        // Clear existing data first
        clearAllData(context: context)

        let calendar = Calendar.current
        let now = Date()

        // Generate workouts for the past 30 days
        for daysAgo in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

            // Simulate realistic workout patterns:
            // - 5 days per week on average (70% chance per day)
            // - Occasionally 2 workouts per day (10% chance on workout days)
            // - Progressive overload over time

            let shouldWorkout = Double.random(in: 0...1) < 0.7

            if shouldWorkout {
                // Primary workout
                let workout = generateRealisticWorkout(for: date, daysAgo: daysAgo)
                context.insert(workout)

                // Occasional second workout (10% chance)
                if Double.random(in: 0...1) < 0.1 {
                    let secondWorkout = generateRealisticWorkout(
                        for: date.addingTimeInterval(6 * 3600), // 6 hours later
                        daysAgo: daysAgo,
                        isSecondWorkout: true
                    )
                    context.insert(secondWorkout)
                }
            }
        }

        try? context.save()
    }

    /// Generate a single realistic workout
    private static func generateRealisticWorkout(
        for date: Date,
        daysAgo: Int,
        isSecondWorkout: Bool = false
    ) -> Workout {
        // Progressive overload: more recent workouts tend to have more reps
        let progressionFactor = 1.0 + (Double(30 - daysAgo) / 30.0) * 0.5 // 0% to 50% increase

        // Base reps range: 15-50 for main workout, 10-30 for second
        let baseMin = isSecondWorkout ? 10 : 15
        let baseMax = isSecondWorkout ? 30 : 50
        let baseReps = Int.random(in: baseMin...baseMax)
        let reps = Int(Double(baseReps) * progressionFactor)

        // Duration: roughly 30-90 seconds for main sets, plus rest time
        // Assume ~1 rep per 2 seconds, plus rest between sets
        let workTime = TimeInterval(reps * 2)
        let restTime = TimeInterval.random(in: 30...120)
        let duration = workTime + restTime

        // Difficulty correlates with intensity
        // Higher reps relative to base = harder
        let intensityRatio = Double(reps) / Double(baseMax)
        let difficulty: Int
        switch intensityRatio {
        case 0..<0.4: difficulty = 1
        case 0.4..<0.6: difficulty = 2
        case 0.6..<0.75: difficulty = 3
        case 0.75..<0.9: difficulty = 4
        default: difficulty = 5
        }

        // Random notes (20% chance)
        let notes: String
        if Double.random(in: 0...1) < 0.2 {
            notes = ["Felt strong!", "Good form", "Tough today", "Quick session", "Added pause reps", "Drop sets"].randomElement() ?? ""
        } else {
            notes = ""
        }

        // Calculate sets based on reps (roughly 3-4 sets for intermediate level)
        let sets = max(2, min(5, reps / 10))
        return Workout(
            date: date,
            duration: duration,
            sets: sets,
            repsCompleted: reps,
            difficultyRating: difficulty,
            notes: notes
        )
    }

    /// Clear all workout data
    static func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: Workout.self)
            try context.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }

    // MARK: - Quick Demo Scenarios

    /// Generate specific demo scenarios for testing
    enum DemoScenario {
        case empty
        case beginner // Low volume, recent start
        case intermediate // Moderate consistency
        case advanced // High consistency and volume
        case streakChaser // Perfect daily streak
        case inconsistent // Sporadic workouts
        case weeklyDecay // Test 3-week exponential decay: Week 1 (5 workouts), Week 2 (3 workouts), Week 3 (1 workout)
        case skipWeek // Test decay after break: Week 1 (0 workouts), Week 2 (5 workouts), Week 3 (5 workouts)
        case recovery // Test recovery: Week 1 (3 workouts), Week 2 (0 workouts), Week 3 (0 workouts)
    }

    static func generateScenario(_ scenario: DemoScenario, context: ModelContext) {
        clearAllData(context: context)

        let calendar = Calendar.current
        let now = Date()

        switch scenario {
        case .empty:
            // No data
            break

        case .beginner:
            // Only 2 weeks of data, 2-3 times per week
            for daysAgo in 0..<14 where daysAgo % 3 == 0 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: TimeInterval.random(in: 60...120),
                    repsCompleted: Int.random(in: 10...25),
                    difficultyRating: Int.random(in: 3...5),
                    notes: ""
                )
                context.insert(workout)
            }

        case .intermediate:
            // Full month, 4-5 times per week, decent volume
            for daysAgo in 0..<30 where Double.random(in: 0...1) < 0.65 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: TimeInterval.random(in: 90...180),
                    repsCompleted: Int.random(in: 25...45),
                    difficultyRating: Int.random(in: 2...4),
                    notes: ""
                )
                context.insert(workout)
            }

        case .advanced:
            // Full month, 6-7 times per week, high volume
            for daysAgo in 0..<30 where Double.random(in: 0...1) < 0.9 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: TimeInterval.random(in: 120...240),
                    repsCompleted: Int.random(in: 40...70),
                    difficultyRating: Int.random(in: 2...4),
                    notes: ""
                )
                context.insert(workout)
            }

        case .streakChaser:
            // Perfect daily workout for 30 days
            for daysAgo in 0..<30 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: TimeInterval.random(in: 80...150),
                    repsCompleted: Int.random(in: 30...50),
                    difficultyRating: Int.random(in: 2...4),
                    notes: ""
                )
                context.insert(workout)
            }

        case .inconsistent:
            // Random sporadic workouts with large gaps
            let workoutDays = [0, 2, 5, 7, 13, 14, 20, 27, 29]
            for daysAgo in workoutDays {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: TimeInterval.random(in: 60...180),
                    sets: Int.random(in: 2...4),
                    repsCompleted: Int.random(in: 15...40),
                    difficultyRating: Int.random(in: 2...5),
                    notes: ""
                )
                context.insert(workout)
            }

        case .weeklyDecay:
            // Week 1 (0-6 days ago): 5 good workouts meeting targets
            // Week 2 (7-13 days ago): 3 moderate workouts
            // Week 3 (14-20 days ago): 1 workout
            // Target: 5 days/week, 3 sets × 10 reps

            // Week 1: Days 0, 1, 2, 4, 6
            for daysAgo in [0, 1, 2, 4, 6] {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: 180,
                    sets: 3,
                    repsCompleted: 30, // 3 sets × 10 reps (meets target)
                    difficultyRating: 3,
                    notes: "Week 1 - Meeting targets"
                )
                context.insert(workout)
            }

            // Week 2: Days 8, 10, 12
            for daysAgo in [8, 10, 12] {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: 150,
                    sets: 3,
                    repsCompleted: 24, // 3 sets × 8 reps (slightly below)
                    difficultyRating: 3,
                    notes: "Week 2 - Moderate"
                )
                context.insert(workout)
            }

            // Week 3: Day 16
            guard let date3 = calendar.date(byAdding: .day, value: -16, to: now) else { break }
            let workout3 = Workout(
                date: date3,
                duration: 120,
                sets: 2,
                repsCompleted: 20, // 2 sets × 10 reps
                difficultyRating: 3,
                notes: "Week 3 - Single workout"
            )
            context.insert(workout3)

        case .skipWeek:
            // Week 1 (0-6 days ago): 0 workouts (current break)
            // Week 2 (7-13 days ago): 5 good workouts
            // Week 3 (14-20 days ago): 5 good workouts
            // Tests decay when you stop after consistent period

            // Week 2: Days 7, 8, 9, 11, 13
            for daysAgo in [7, 8, 9, 11, 13] {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: 180,
                    sets: 3,
                    repsCompleted: 30,
                    difficultyRating: 3,
                    notes: "Week 2 - Consistent"
                )
                context.insert(workout)
            }

            // Week 3: Days 14, 15, 16, 18, 20
            for daysAgo in [14, 15, 16, 18, 20] {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: 180,
                    sets: 3,
                    repsCompleted: 30,
                    difficultyRating: 3,
                    notes: "Week 3 - Consistent"
                )
                context.insert(workout)
            }

        case .recovery:
            // Week 1 (0-6 days ago): 3 workouts (recovering)
            // Week 2 (7-13 days ago): 0 workouts (break)
            // Week 3 (14-20 days ago): 0 workouts (break)
            // Tests recovery after extended break

            // Week 1: Days 1, 3, 5
            for daysAgo in [1, 3, 5] {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
                let workout = Workout(
                    date: date,
                    duration: 150,
                    sets: 3,
                    repsCompleted: 24, // 3 sets × 8 reps (building back up)
                    difficultyRating: 4, // Feels harder after break
                    notes: "Week 1 - Recovery mode"
                )
                context.insert(workout)
            }
        }

        try? context.save()
    }
}
