//
//  MetricsCalculator.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

// MARK: - Workout Summary

struct WorkoutMetrics {
    let consistency: Double // 0-10 scale
    let intensity: Double   // 0-10 scale
    let totalWorkouts: Int
    let totalReps: Int
    let streakDays: Int
    let evaluationPeriod: Int
}

// MARK: - Personal Records

struct PersonalRecords {
    let bestSingleWorkout: Int
    let bestDailyTotal: Int
    let bestWeekTotal: Int
    let bestMonthTotal: Int
    let longestStreak: Int
}

// MARK: - Metrics Calculator

class MetricsCalculator {

    // MARK: - Public Methods

    /// Calculate both consistency and intensity metrics
    static func calculateMetrics(workouts: [Workout], targetDays: Int = 5, targetReps: Int = 20, targetSets: Int? = nil, targetRepsPerSet: Int? = nil, evaluationPeriod: Int = 30) -> WorkoutMetrics {
        let consistency = calculateConsistency(workouts: workouts, targetDays: targetDays, targetSets: targetSets, targetRepsPerSet: targetRepsPerSet, evaluationPeriod: evaluationPeriod)
        let intensity = calculateIntensity(workouts: workouts, targetReps: targetReps, targetSets: targetSets, targetRepsPerSet: targetRepsPerSet, evaluationPeriod: evaluationPeriod)

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -evaluationPeriod, to: now)!
        let recentWorkouts = workouts.filter { $0.date >= startDate }

        return WorkoutMetrics(
            consistency: consistency,
            intensity: intensity,
            totalWorkouts: recentWorkouts.count,
            totalReps: recentWorkouts.map(\.repsCompleted).reduce(0, +),
            streakDays: calculateCurrentStreak(workouts: workouts),
            evaluationPeriod: evaluationPeriod
        )
    }

    // MARK: - Consistency Calculation

    /// Calculate consistency score (0-10) based on workout frequency and set completion
    /// Uses 3-10 most recent workouts for calculation
    /// - Parameters:
    ///   - workouts: All workout records (sorted by date, most recent first)
    ///   - targetDays: Expected workouts per week (default: 5)
    ///   - targetSets: Expected sets per workout (optional, for set completion bonus)
    ///   - targetRepsPerSet: Expected reps per set (optional, for set completion evaluation)
    ///   - evaluationPeriod: Days to evaluate (default: 30, used for context but limited by data points)
    /// - Returns: Consistency score from 0 to 10
    static func calculateConsistency(workouts: [Workout],
                                    targetDays: Int = 5,
                                    targetSets: Int? = nil,
                                    targetRepsPerSet: Int? = nil,
                                    evaluationPeriod: Int = 30) -> Double {

        // Edge case: no workouts
        guard !workouts.isEmpty else { return 0 }
        
        // Edge case: invalid target
        guard targetDays > 0 && targetDays <= 7 else { return 0 }

        // Get most recent workouts, limited to 10
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        let dataPoints = Array(sortedWorkouts.prefix(10))
        
        // Edge case: need at least 3 workouts for meaningful metrics (as stated in info page)
        guard dataPoints.count >= 3 else { return 0 }

        let calendar = Calendar.current
        
        // Calculate frequency: workout days vs expected days
        // Calculate expected days based on data point span
        let oldestDate = dataPoints.map { $0.date }.min() ?? Date()
        let newestDate = dataPoints.map { $0.date }.max() ?? Date()
        let spanDays = max(calendar.dateComponents([.day], from: oldestDate, to: newestDate).day ?? 1, 1)
        let workoutDays = Set(dataPoints.map {
            calendar.startOfDay(for: $0.date)
        }).count

        // Calculate expected workout days in this span based on target frequency
        // For example: if span is 7 days and target is 1 day/week, expected = 1
        //              if span is 7 days and target is 5 days/week, expected = 5
        let expectedDays = max(Double(spanDays) / 7.0 * Double(targetDays), 1.0)
        
        // Edge case: prevent division by zero
        guard expectedDays > 0 else { return 0 }
        
        // Frequency score: workoutDays / expectedDays, capped at 1.0 (60% weight)
        // If user exceeds target, they get full points (1.0)
        // If user meets exactly target, they get full points (1.0)
        // If user is below target, score is proportional
        let frequencyScore = min(Double(workoutDays) / expectedDays, 1.0)
        
        // Set completion evaluation (40% weight): Check if workouts complete target sets AND reps per set
        var setCompletionScore: Double = 1.0
        if let targetSets = targetSets, targetSets > 0 {
            // Check both: sets completion AND reps per set (if available)
            if let targetRepsPerSet = targetRepsPerSet, targetRepsPerSet > 0 {
                // Integrated check: workout must meet both sets AND reps per set targets
                let workoutsMeetingTargets = dataPoints.filter { workout in
                    let repsPerSet = workout.sets > 0 ? Double(workout.repsCompleted) / Double(workout.sets) : 0
                    return workout.sets >= targetSets && repsPerSet >= Double(targetRepsPerSet) * 0.5 // At least 50% of target reps per set
                }.count
                let setCompletionRatio = Double(workoutsMeetingTargets) / Double(dataPoints.count)
                setCompletionScore = setCompletionRatio // 0-1 range
            } else {
                // Fallback: just check sets
                let workoutsWithTargetSets = dataPoints.filter { $0.sets >= targetSets }.count
                let setCompletionRatio = Double(workoutsWithTargetSets) / Double(dataPoints.count)
                setCompletionScore = setCompletionRatio
            }
        }
        
        // Combine: 60% frequency + 40% set completion
        let combinedScore = (frequencyScore * 0.6) + (setCompletionScore * 0.4)

        // Scale to 0-10
        return min(max(combinedScore * 10.0, 0), 10)
    }

    /// Calculate how regular/distributed workouts are
    /// Regularity measures how consistent the spacing is, rewarding both meeting target and consistency
    private static func calculateRegularity(workouts: [Workout], targetDays: Int) -> Double {
        guard workouts.count >= 2 else { return workouts.isEmpty ? 0 : 1.0 }

        let calendar = Calendar.current
        let workoutDates = workouts
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()

        // Calculate gaps between workouts
        var gaps: [Int] = []
        for i in 0..<(workoutDates.count - 1) {
            let daysBetween = calendar.dateComponents([.day],
                                                     from: workoutDates[i],
                                                     to: workoutDates[i + 1]).day ?? 0
            gaps.append(daysBetween)
        }

        guard !gaps.isEmpty else { return 1.0 }

        // Ideal gap based on target frequency
        let idealGap = 7.0 / Double(targetDays)
        let avgGap = Double(gaps.reduce(0, +)) / Double(gaps.count)

        // If average gap is less than or equal to ideal, user is meeting or exceeding target
        // This should be rewarded with a high score (close to 1.0)
        if avgGap <= idealGap {
            // User is meeting or exceeding target frequency
            // If they're working out more frequently than needed, that's still consistent behavior
            // Give them a high score, with slight adjustment for spacing consistency
            let variance = gaps.map { pow(Double($0) - avgGap, 2) }.reduce(0, +) / Double(gaps.count)
            let stdDev = sqrt(variance)
            
            // If workouts are very consistent in spacing, give bonus
            // Coefficient of variation measures relative consistency
            let coefficientOfVariation = avgGap > 0 ? stdDev / avgGap : 0.0
            
            // Base score of 0.95 for meeting/exceeding target (very high)
            // Small bonus (up to 0.05) for very consistent spacing
            let consistencyBonus = coefficientOfVariation < 0.5 ? 0.05 : 0.0
            
            return min(1.0, 0.95 + consistencyBonus)
        } else {
            // Average gap is greater than ideal - not meeting target frequency
            // Calculate how far off from ideal
            let gapRatio = avgGap / idealGap // > 1.0 means spacing is too wide
            
            // Score decreases as gap ratio increases
            // If gapRatio = 2.0 (twice the ideal gap), score should be low
            // If gapRatio = 1.1 (slightly over), score should still be decent
            if gapRatio <= 1.5 {
                // Within 50% of ideal - decent score
                return max(0.5, 1.0 - ((gapRatio - 1.0) * 0.5))
            } else {
                // More than 50% over ideal - score decreases more quickly
                return max(0, 0.5 - ((gapRatio - 1.5) * 0.4))
            }
        }
    }

    /// Calculate current workout streak
    static func calculateCurrentStreak(workouts: [Workout], restDays: [RestDay] = []) -> Int {
        guard !workouts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let restDayDates = Set(restDays.map { calendar.startOfDay(for: $0.date) })
        let sortedWorkouts = workouts
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)

        guard let lastWorkout = sortedWorkouts.first else { return 0 }

        // Check if streak is still active (within last 2 days, or has a rest day)
        let daysSinceLastWorkout = calendar.dateComponents([.day],
                                                          from: lastWorkout,
                                                          to: today).day ?? 0

        // Check if there's a rest day covering the gap
        let hasRestDayCoveringGap = (0...daysSinceLastWorkout).contains { offset in
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                return restDayDates.contains(calendar.startOfDay(for: date))
            }
            return false
        }

        guard daysSinceLastWorkout <= 2 || hasRestDayCoveringGap else { return 0 }

        var streak = 0
        var currentDate = lastWorkout
        var uniqueDates: Set<Date> = []

        for workoutDate in sortedWorkouts {
            // Skip duplicates (multiple workouts same day)
            if uniqueDates.contains(workoutDate) {
                continue
            }
            uniqueDates.insert(workoutDate)

            let daysDiff = calendar.dateComponents([.day],
                                                  from: workoutDate,
                                                  to: currentDate).day ?? 0

            // Check if there are rest days filling the gap
            var hasRestDaysInGap = true
            if daysDiff > 2 {
                let gapDays = (1..<daysDiff).compactMap { offset in
                    calendar.date(byAdding: .day, value: offset, to: workoutDate)
                }
                hasRestDaysInGap = gapDays.allSatisfy { date in
                    restDayDates.contains(calendar.startOfDay(for: date))
                }
            }

            if daysDiff <= 2 || hasRestDaysInGap {  // Allow 1 day gap, or rest days fill gap
                streak += 1
                currentDate = workoutDate
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Intensity Calculation

    /// Calculate intensity score (0-10) based on reps, sets, and difficulty normalized by target
    /// Uses 3-10 most recent workouts for calculation
    /// - Parameters:
    ///   - workouts: All workout records (will be sorted by date, most recent first)
    ///   - targetReps: Target total reps per workout (sets × reps per set, used for normalization)
    ///   - targetSets: Expected sets per workout (optional, for set-based scoring)
    ///   - targetRepsPerSet: Expected reps per set (optional, for reps-per-set scoring)
    ///   - evaluationPeriod: Days to evaluate (default: 30, used for context but limited by data points)
    /// - Returns: Intensity score from 0 to 10
    static func calculateIntensity(workouts: [Workout], targetReps: Int = 20, targetSets: Int? = nil, targetRepsPerSet: Int? = nil, evaluationPeriod: Int = 30) -> Double {
        // Edge case: no workouts
        guard !workouts.isEmpty else { return 0 }
        
        // Edge case: invalid target
        guard targetReps > 0 else { return 0 }
        
        // Get most recent workouts, limited to 10
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        let dataPoints = Array(sortedWorkouts.prefix(10))
        
        // Edge case: need at least 3 workouts for meaningful metrics (as stated in info page)
        guard dataPoints.count >= 3 else { return 0 }

        // Factor 1: Sets and reps combined evaluation (60% weight if sets info available, otherwise just reps)
        var setsRepsScore: Double = 0.0
        
        if let targetSets = targetSets, let targetRepsPerSet = targetRepsPerSet, targetSets > 0 && targetRepsPerSet > 0 {
            // Integrated approach: evaluate both sets AND reps per set
            let avgSets = Double(dataPoints.map { $0.sets }.reduce(0, +)) / Double(dataPoints.count)
            
            // Calculate average reps per set correctly: sum of (reps / sets) for each workout, then average
            let totalReps = dataPoints.map { $0.repsCompleted }.reduce(0, +)
            let totalSets = dataPoints.map { max($0.sets, 1) }.reduce(0, +)
            let avgRepsPerSet = totalSets > 0 ? Double(totalReps) / Double(totalSets) : 0.0
            
            // Normalize sets: 50%-100% of target
            let setsRatio = avgSets / Double(targetSets)
            let setsComponent: Double
            if setsRatio < 0.5 {
                setsComponent = 0.0
            } else if setsRatio >= 1.0 {
                setsComponent = 1.0
            } else {
                setsComponent = (setsRatio - 0.5) / 0.5
            }
            
            // Normalize reps per set: 50%-100% of target
            let repsPerSetRatio = avgRepsPerSet / Double(targetRepsPerSet)
            let repsPerSetComponent: Double
            if repsPerSetRatio < 0.5 {
                repsPerSetComponent = 0.0
            } else if repsPerSetRatio >= 1.0 {
                repsPerSetComponent = 1.0
            } else {
                repsPerSetComponent = (repsPerSetRatio - 0.5) / 0.5
            }
            
            // Combined: 60% sets + 40% reps per set (both must be good for full score)
            setsRepsScore = (setsComponent * 0.6) + (repsPerSetComponent * 0.4)
        } else {
            // Fallback: use total reps if sets info not available
            let avgReps = Double(dataPoints.map { $0.repsCompleted }.reduce(0, +)) / Double(dataPoints.count)
            guard targetReps > 0 else { return 0 }
            let repsRatio = avgReps / Double(targetReps)
            if repsRatio < 0.5 {
                setsRepsScore = 0.0
            } else if repsRatio >= 1.0 {
                setsRepsScore = 1.0
            } else {
                setsRepsScore = (repsRatio - 0.5) / 0.5
            }
        }

        // Factor 2: Difficulty rating (30% weight)
        let avgDifficulty = dataPoints.map { Double($0.difficultyRating) }
            .reduce(0, +) / Double(dataPoints.count)
        
        // Edge case: ensure difficulty is in valid range [1, 5]
        let clampedDifficulty = min(max(avgDifficulty, 1.0), 5.0)
        let difficultyScore = (clampedDifficulty - 1.0) / 4.0  // Normalize from 1-5 to 0-1

        // Factor 3: Total volume bonus (10% weight) - rewards doing more than minimum
        var volumeBonus: Double = 0.0
        if let targetSets = targetSets, let targetRepsPerSet = targetRepsPerSet {
            let avgTotalReps = Double(dataPoints.map { $0.repsCompleted }.reduce(0, +)) / Double(dataPoints.count)
            let targetTotalReps = Double(targetSets * targetRepsPerSet)
            if avgTotalReps > targetTotalReps {
                // Bonus up to 10% for exceeding target (capped at 50% above target)
                let excessRatio = min((avgTotalReps - targetTotalReps) / targetTotalReps, 0.5)
                volumeBonus = excessRatio * 0.2 // 0.0 to 0.1 (10%)
            }
        }

        // Combine scores: sets+reps (60%) + difficulty (30%) + volume bonus (10%)
        let rawScore = (setsRepsScore * 0.6) + (difficultyScore * 0.3) + (volumeBonus * 1.0)

        // Scale to 0-10
        return min(max(rawScore * 10.0, 0), 10)
    }

    /// Calculate volume improvement trend
    /// Compares first half vs second half of workouts
    private static func calculateVolumeTrend(workouts: [Workout]) -> Double {
        guard workouts.count >= 4 else {
            // Not enough data for trend analysis, return neutral score
            return 0.5
        }

        // Workouts should already be sorted by date (most recent first from caller)
        // Reverse to get chronological order for trend analysis
        let sorted = workouts.sorted { $0.date < $1.date }
        let midpoint = sorted.count / 2

        let firstHalf = sorted.prefix(midpoint)
        let secondHalf = sorted.suffix(sorted.count - midpoint)

        let firstHalfAvg = firstHalf.map { $0.repsCompleted }.reduce(0, +) / firstHalf.count
        let secondHalfAvg = secondHalf.map { $0.repsCompleted }.reduce(0, +) / secondHalf.count

        guard firstHalfAvg > 0 else { return 0.5 }

        // Calculate percentage improvement
        let improvement = Double(secondHalfAvg - firstHalfAvg) / Double(firstHalfAvg)

        // -30% = 0, 0% = 0.5, +30% = 1.0
        // Clamp to reasonable range
        let normalizedImprovement = (improvement + 0.3) / 0.6

        return min(max(normalizedImprovement, 0), 1.0)
    }

    // MARK: - Score Interpretation

    static func interpretScore(_ score: Double) -> (label: String, color: String) {
        switch score {
        case 8...10:
            return ("Excellent", "green")
        case 6..<8:
            return ("Good", "blue")
        case 4..<6:
            return ("Fair", "orange")
        case 0..<4:
            return ("Poor", "red")
        default:
            return ("Unknown", "gray")
        }
    }

    // MARK: - Detailed Breakdown

    struct MetricsBreakdown {
        let consistencyFrequency: Double
        let intensityRepsScore: Double
        let intensityDifficulty: Double
    }

    static func getDetailedBreakdown(workouts: [Workout],
                                    targetDays: Int = 5,
                                    targetReps: Int = 20,
                                    evaluationPeriod: Int = 30) -> MetricsBreakdown {

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -evaluationPeriod, to: now)!
        let recentWorkouts = workouts.filter { $0.date >= startDate }

        // Consistency components - only frequency
        let workoutDays = Set(recentWorkouts.map { calendar.startOfDay(for: $0.date) }).count
        let expectedDays = max(Double(evaluationPeriod) / 7.0 * Double(targetDays), 1.0)
        
        // Edge case: prevent division by zero
        guard expectedDays > 0, targetDays > 0 else {
            return MetricsBreakdown(
                consistencyFrequency: 0,
                intensityRepsScore: 0,
                intensityDifficulty: 0
            )
        }
        
        let frequency = min(Double(workoutDays) / expectedDays, 1.0) * 10.0

        // Intensity components - only reps and difficulty, normalized against target reps
        guard targetReps > 0, !recentWorkouts.isEmpty else {
            return MetricsBreakdown(
                consistencyFrequency: frequency,
                intensityRepsScore: 0,
                intensityDifficulty: 0
            )
        }
        
        // Average reps normalized against target
        let avgReps = Double(recentWorkouts.map { $0.repsCompleted }.reduce(0, +)) / Double(recentWorkouts.count)
        let repsRatio = avgReps / Double(targetReps)
        let repsScore: Double
        if repsRatio < 0.5 {
            repsScore = 0.0
        } else if repsRatio >= 1.0 {
            repsScore = 1.0
        } else {
            repsScore = (repsRatio - 0.5) / 0.5
        }
        let repsScoreScaled = repsScore * 10.0

        // Difficulty rating normalized from 1-5 to 0-1, then scaled to 0-10
        let avgDifficulty = recentWorkouts.map { Double($0.difficultyRating) }.reduce(0, +) / Double(recentWorkouts.count)
        let clampedDifficulty = min(max(avgDifficulty, 1.0), 5.0)
        let difficultyScore = ((clampedDifficulty - 1.0) / 4.0) * 10.0

        return MetricsBreakdown(
            consistencyFrequency: frequency,
            intensityRepsScore: repsScoreScaled,
            intensityDifficulty: difficultyScore
        )
    }

    // MARK: - Personal Records Calculation

    /// Calculate all personal records from workout history
    /// - Parameters:
    ///   - workouts: All workout records
    ///   - restDays: All rest day records (for streak calculation)
    /// - Returns: PersonalRecords struct with all-time bests
    static func calculatePersonalRecords(workouts: [Workout], restDays: [RestDay] = []) -> PersonalRecords {
        guard !workouts.isEmpty else {
            return PersonalRecords(
                bestSingleWorkout: 0,
                bestDailyTotal: 0,
                bestWeekTotal: 0,
                bestMonthTotal: 0,
                longestStreak: 0
            )
        }

        let calendar = Calendar.current

        // Best single workout
        let bestSingleWorkout = workouts.map { $0.repsCompleted }.max() ?? 0

        // Best daily total (sum all workouts on the same day)
        let dailyTotals = Dictionary(grouping: workouts) { workout in
            calendar.startOfDay(for: workout.date)
        }.mapValues { dayWorkouts in
            dayWorkouts.reduce(0) { $0 + $1.repsCompleted }
        }
        let bestDailyTotal = dailyTotals.values.max() ?? 0

        // Best week total (rolling 7-day window)
        let bestWeekTotal = calculateBestRollingPeriod(workouts: workouts, days: 7)

        // Best month total (rolling 30-day window)
        let bestMonthTotal = calculateBestRollingPeriod(workouts: workouts, days: 30)

        // Longest streak ever (not just current)
        let longestStreak = calculateLongestEverStreak(workouts: workouts, restDays: restDays)

        return PersonalRecords(
            bestSingleWorkout: bestSingleWorkout,
            bestDailyTotal: bestDailyTotal,
            bestWeekTotal: bestWeekTotal,
            bestMonthTotal: bestMonthTotal,
            longestStreak: longestStreak
        )
    }

    /// Calculate best total reps in a rolling period (e.g., 7 days, 30 days)
    private static func calculateBestRollingPeriod(workouts: [Workout], days: Int) -> Int {
        guard !workouts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedWorkouts = workouts.sorted { $0.date < $1.date }

        guard let firstDate = sortedWorkouts.first?.date,
              let lastDate = sortedWorkouts.last?.date else {
            return 0
        }

        var maxTotal = 0
        var currentDate = calendar.startOfDay(for: firstDate)
        let endDate = calendar.startOfDay(for: lastDate)

        // Iterate through each day as potential period start
        while currentDate <= endDate {
            guard let periodEnd = calendar.date(byAdding: .day, value: days, to: currentDate) else {
                break
            }

            // Sum all reps in this period
            let periodTotal = workouts
                .filter { $0.date >= currentDate && $0.date < periodEnd }
                .reduce(0) { $0 + $1.repsCompleted }

            maxTotal = max(maxTotal, periodTotal)

            // Move to next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }

        return maxTotal
    }

    /// Calculate longest ever streak (not just current streak)
    private static func calculateLongestEverStreak(workouts: [Workout], restDays: [RestDay] = []) -> Int {
        guard !workouts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let restDayDates = Set(restDays.map { calendar.startOfDay(for: $0.date) })
        let sortedWorkouts = workouts
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()

        // Get unique workout days
        let uniqueDays = Array(Set(sortedWorkouts)).sorted()

        guard !uniqueDays.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<uniqueDays.count {
            let daysBetween = calendar.dateComponents([.day], from: uniqueDays[i-1], to: uniqueDays[i]).day ?? 0

            // Check if there are rest days filling the gap
            let gapDays = (1..<daysBetween).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: uniqueDays[i-1])
            }
            let hasRestDaysInGap = gapDays.allSatisfy { date in
                restDayDates.contains(calendar.startOfDay(for: date))
            }

            // Allow up to 2-day gap, or rest days fill gap
            if daysBetween <= 2 || (daysBetween > 2 && hasRestDaysInGap) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }
    
    // MARK: - Performance Optimization Tips
    
    /// Analyze correlation between consistency and intensity to provide optimization tips
    /// - Parameters:
    ///   - consistency: Current consistency score (0-10)
    ///   - intensity: Current intensity score (0-10)
    ///   - targetDays: Current target workout days per week
    /// - Returns: Tip with recommendation and action
    static func analyzePerformanceOptimization(
        consistency: Double,
        intensity: Double,
        targetDays: Int
    ) -> PerformanceTip {
        // Edge case: invalid inputs
        guard consistency >= 0 && consistency <= 10 && intensity >= 0 && intensity <= 10 && targetDays >= 1 && targetDays <= 7 else {
            return PerformanceTip(
                type: .maintain,
                title: "On Track",
                message: "Your consistency and intensity are well balanced. Keep going!",
                action: nil,
                targetDaysChange: nil
            )
        }
        
        // Edge case: both zero or very low (no workouts yet)
        if consistency < 0.5 && intensity < 0.5 {
            return PerformanceTip(
                type: .buildHabit,
                title: "Get Started",
                message: "Start logging workouts! Focus on consistency first - complete your target sets and reps per set.",
                action: "Start workout",
                targetDaysChange: nil
            )
        }
        
        // Define thresholds (inclusive boundaries to avoid gaps)
        let consistencyHigh = consistency >= 7.0
        let consistencyLow = consistency < 5.0
        let consistencyModerate = !consistencyHigh && !consistencyLow  // 5.0 <= consistency < 7.0
        
        let intensityHigh = intensity >= 7.0
        let intensityLow = intensity < 5.0
        let intensityModerate = !intensityHigh && !intensityLow  // 5.0 <= intensity < 7.0
        
        // Case 1: Both high (optimal state)
        if consistencyHigh && intensityHigh {
            return PerformanceTip(
                type: .maintain,
                title: "Keep It Up!",
                message: "Great balance! Your consistency and intensity are both strong. Keep maintaining this pace.",
                action: nil,
                targetDaysChange: nil
            )
        }
        
        // Case 2: Both low (needs habit building)
        if consistencyLow && intensityLow {
            let suggestedDays = max(2, min(targetDays - 1, 3))
            return PerformanceTip(
                type: .buildHabit,
                title: "Build Your Habit",
                message: "Focus on consistency first. Try setting a lower weekly target (\(suggestedDays) days/week) and complete your target sets and reps per set.",
                action: "Focus on schedule",
                targetDaysChange: targetDays > suggestedDays ? suggestedDays : nil
            )
        }
        
        // Case 3: High consistency, low intensity
        // Working out regularly but not reaching target sets/reps - suggest reducing frequency for recovery
        if consistencyHigh && intensityLow {
            let suggestedDays = max(3, targetDays - 1)
            if suggestedDays < targetDays && targetDays > 3 {
                return PerformanceTip(
                    type: .increaseFrequency,
                    title: "Optimize Recovery",
                    message: "Reduce weekly frequency to \(suggestedDays) days for better recovery. More rest enables completing all target sets and reps per set.",
                    action: "Adjust schedule",
                    targetDaysChange: suggestedDays
                )
            } else {
                return PerformanceTip(
                    type: .increaseIntensity,
                    title: "Boost Your Intensity",
                    message: "You're consistent but not completing target sets or reps per set. Complete all sets with target reps per set.",
                    action: nil,
                    targetDaysChange: nil
                )
            }
        }
        
        // Case 4: Low consistency, high intensity
        // Completing sets/reps well but not consistently
        if consistencyLow && intensityHigh {
            return PerformanceTip(
                type: .buildHabit,
                title: "Build Consistency First",
                message: "You're completing your target sets and reps per set but not consistently. Focus on working out more regularly.",
                action: nil,
                targetDaysChange: nil
            )
        }
        
        // Case 5: High consistency, moderate intensity (5-7)
        // Good consistency but intensity could improve
        if consistencyHigh && intensityModerate {
            if consistency > intensity + 1.0 && targetDays > 3 {
                let suggestedDays = max(3, targetDays - 1)
                return PerformanceTip(
                    type: .increaseFrequency,
                    title: "Balance Frequency",
                    message: "Reduce to \(suggestedDays) days/week for better recovery. This helps complete all target sets and reps per set.",
                    action: "Adjust schedule",
                    targetDaysChange: suggestedDays
                )
            } else {
                return PerformanceTip(
                    type: .increaseIntensity,
                    title: "Ramp Up Intensity",
                    message: "Your consistency is good. Focus on completing all target sets and reaching target reps per set.",
                    action: nil,
                    targetDaysChange: nil
                )
            }
        }
        
        // Case 6: Moderate consistency (5-7), high intensity
        // Good intensity but needs more consistency
        if consistencyModerate && intensityHigh {
            return PerformanceTip(
                type: .buildHabit,
                title: "Focus on Consistency",
                message: "Your workouts are intense (completing target sets/reps). Focus on working out more regularly.",
                action: nil,
                targetDaysChange: nil
            )
        }
        
        // Case 7: Moderate consistency, low intensity
        // Some consistency but intensity is too low
        if consistencyModerate && intensityLow {
            if consistency > intensity + 1.0 && targetDays > 3 {
                let suggestedDays = max(3, targetDays - 1)
                return PerformanceTip(
                    type: .increaseFrequency,
                    title: "Balance Frequency",
                    message: "Reduce to \(suggestedDays) days/week for better recovery. This helps you complete all target sets and reps per set.",
                    action: "Adjust schedule",
                    targetDaysChange: suggestedDays
                )
            } else {
                return PerformanceTip(
                    type: .increaseIntensity,
                    title: "Boost Intensity",
                    message: "Focus on completing all target sets and reaching target reps per set. More rest between workouts may help.",
                    action: nil,
                    targetDaysChange: nil
                )
            }
        }
        
        // Case 8: Low consistency, moderate intensity
        // Needs more consistency
        if consistencyLow && intensityModerate {
            return PerformanceTip(
                type: .buildHabit,
                title: "Build Consistency",
                message: "Focus on working out more regularly. You're close to completing target sets/reps - consistency will help.",
                action: nil,
                targetDaysChange: nil
            )
        }
        
        // Case 9: Both moderate (5-7), check relative difference
        if consistencyModerate && intensityModerate {
            let diff = abs(consistency - intensity)
            if diff > 1.0 {
                if consistency > intensity + 1.0 {
                    return PerformanceTip(
                        type: .increaseIntensity,
                        title: "Increase Intensity",
                        message: "Your consistency is better. Focus on completing all target sets and reaching target reps per set.",
                        action: nil,
                        targetDaysChange: nil
                    )
                } else {
                    return PerformanceTip(
                        type: .buildHabit,
                        title: "Improve Consistency",
                        message: "Your intensity is good. Focus on working out more regularly.",
                        action: nil,
                        targetDaysChange: nil
                    )
                }
            }
            // Both moderate and close - slightly favor consistency
            return PerformanceTip(
                type: .increaseIntensity,
                title: "Fine-Tune Intensity",
                message: "Both metrics are good. Try completing all target sets and reaching target reps per set consistently.",
                action: nil,
                targetDaysChange: nil
            )
        }
        
        // Case 10: Remaining edge cases - significant differences
        let diff = consistency - intensity
        if abs(diff) > 1.0 {
            if diff > 1.0 {
                // Consistency significantly better
                if intensityLow && targetDays > 3 {
                    let suggestedDays = max(3, targetDays - 1)
                    return PerformanceTip(
                        type: .increaseFrequency,
                        title: "Balance Frequency",
                        message: "Reduce to \(suggestedDays) days/week for better recovery. Complete all target sets and reps per set.",
                        action: "Adjust schedule",
                        targetDaysChange: suggestedDays
                    )
                } else {
                    return PerformanceTip(
                        type: .increaseIntensity,
                        title: "Ramp Up Intensity",
                        message: "Your consistency is good. Complete all target sets and reach target reps per set to boost intensity.",
                        action: nil,
                        targetDaysChange: nil
                    )
                }
            } else {
                // Intensity significantly better
                return PerformanceTip(
                    type: .buildHabit,
                    title: "Focus on Consistency",
                    message: "You're completing target sets/reps well. Focus on working out more regularly.",
                    action: nil,
                    targetDaysChange: nil
                )
            }
        }
        
        // Default: balanced (both scores are close, neither high nor low)
        // This handles: both exactly 5.0, both between 5-7 and close, etc.
        return PerformanceTip(
            type: .maintain,
            title: "On Track",
            message: "Your consistency and intensity are well balanced. Keep completing your target sets and reps per set!",
            action: nil,
            targetDaysChange: nil
        )
    }
}

// MARK: - Performance Tip

struct PerformanceTip {
    enum TipType {
        case increaseIntensity
        case increaseFrequency
        case buildHabit
        case maintain
    }
    
    let type: TipType
    let title: String
    let message: String
    let action: String?
    let targetDaysChange: Int? // Suggested new target days if different
    
    var color: Color {
        switch type {
        case .increaseIntensity:
            return .orange
        case .increaseFrequency:
            return .blue
        case .buildHabit:
            return .green
        case .maintain:
            return .purple
        }
    }
    
    var icon: String {
        switch type {
        case .increaseIntensity:
            return "flame.fill"
        case .increaseFrequency:
            return "calendar.badge.plus"
        case .buildHabit:
            return "target"
        case .maintain:
            return "checkmark.circle.fill"
        }
    }
}
