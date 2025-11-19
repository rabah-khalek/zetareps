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

        let calendar = Calendar.current
        let now = Date()

        // Filter workouts to last 21 days (3 weeks)
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        let threeWeeksAgo = calendar.date(byAdding: .day, value: -21, to: now) ?? now
        let recentWorkouts = sortedWorkouts.filter { $0.date >= threeWeeksAgo }

        // Edge case: need at least 1 workout for meaningful metrics
        guard !recentWorkouts.isEmpty else { return 0 }

        // Split into 3 weeks with exponential weights: 1.0, 0.5, 0.25
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let week1 = recentWorkouts.filter { $0.date >= oneWeekAgo }      // Last 7 days, weight = 1.0
        let week2 = recentWorkouts.filter { $0.date >= twoWeeksAgo && $0.date < oneWeekAgo }  // Days 7-13, weight = 0.5
        let week3 = recentWorkouts.filter { $0.date >= threeWeeksAgo && $0.date < twoWeeksAgo }  // Days 14-20, weight = 0.25

        // FREQUENCY SCORE (80% weight)
        // Count workouts per week
        let count1 = Double(week1.count)
        let count2 = Double(week2.count)
        let count3 = Double(week3.count)

        // Apply exponential weights: each week worth half the previous
        let weightedTotal = (count1 * 1.0) + (count2 * 0.5) + (count3 * 0.25)

        // Normalize by target frequency across equivalent weeks
        // Sum of weights = 1.0 + 0.5 + 0.25 = 1.75 weeks equivalent
        let equivalentWeeks = 1.75
        let frequencyRatio = weightedTotal / (Double(targetDays) * equivalentWeeks)
        let frequencyScore = min(frequencyRatio, 1.0) * 0.8

        // QUALITY SCORE (20% weight): Based on total volume (sets × reps) vs target volume
        var qualityScore: Double = 0.2  // Default to full quality if no targets set

        if let targetSets = targetSets, targetSets > 0,
           let targetRepsPerSet = targetRepsPerSet, targetRepsPerSet > 0 {

            let targetTotalReps = targetSets * targetRepsPerSet

            // Helper function: calculate quality score for a workout (0.0 to 1.0)
            let calculateWorkoutQuality: (Workout) -> Double = { workout in
                let totalReps = workout.repsCompleted

                // Volume ratio: actual total reps vs target total reps, capped at 100%
                let volumeRatio = min(Double(totalReps) / Double(targetTotalReps), 1.0)

                return volumeRatio
            }

            // Calculate weighted average quality across all weeks
            let quality1 = week1.isEmpty ? 0.0 : week1.map(calculateWorkoutQuality).reduce(0, +) / Double(week1.count)
            let quality2 = week2.isEmpty ? 0.0 : week2.map(calculateWorkoutQuality).reduce(0, +) / Double(week2.count)
            let quality3 = week3.isEmpty ? 0.0 : week3.map(calculateWorkoutQuality).reduce(0, +) / Double(week3.count)

            // Weighted average quality with exponential weights
            let weightedQuality: Double
            if weightedTotal > 0 {
                weightedQuality = (quality1 * count1 * 1.0 +
                                   quality2 * count2 * 0.5 +
                                   quality3 * count3 * 0.25) / weightedTotal
            } else {
                weightedQuality = 0
            }

            qualityScore = weightedQuality * 0.2
        }

        // Combine: 80% frequency + 20% quality
        let combinedScore = frequencyScore + qualityScore

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
    /// Uses 3-week exponential decay: recent workouts weighted more (1.0, 0.5, 0.25)
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

        let calendar = Calendar.current
        let now = Date()

        // Filter workouts to last 21 days (3 weeks)
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        let threeWeeksAgo = calendar.date(byAdding: .day, value: -21, to: now) ?? now
        let recentWorkouts = sortedWorkouts.filter { $0.date >= threeWeeksAgo }

        // Edge case: need at least 1 workout for meaningful metrics
        guard !recentWorkouts.isEmpty else { return 0 }

        // Split into 3 weeks with exponential weights: 1.0, 0.5, 0.25
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let week1 = recentWorkouts.filter { $0.date >= oneWeekAgo }      // Last 7 days, weight = 1.0
        let week2 = recentWorkouts.filter { $0.date >= twoWeeksAgo && $0.date < oneWeekAgo }  // Days 7-13, weight = 0.5
        let week3 = recentWorkouts.filter { $0.date >= threeWeeksAgo && $0.date < twoWeeksAgo }  // Days 14-20, weight = 0.25

        // Helper function: calculate exponentially-weighted average
        let calculateWeightedAvg: ([Workout], KeyPath<Workout, Int>) -> Double = { workouts, keyPath in
            let sum1 = Double(week1.map { $0[keyPath: keyPath] }.reduce(0, +)) * 1.0
            let sum2 = Double(week2.map { $0[keyPath: keyPath] }.reduce(0, +)) * 0.5
            let sum3 = Double(week3.map { $0[keyPath: keyPath] }.reduce(0, +)) * 0.25

            let count1 = Double(week1.count) * 1.0
            let count2 = Double(week2.count) * 0.5
            let count3 = Double(week3.count) * 0.25

            let totalWeight = count1 + count2 + count3
            return totalWeight > 0 ? (sum1 + sum2 + sum3) / totalWeight : 0
        }

        // FACTOR 1: Volume-based evaluation (60% weight)
        // Base score on total volume, with bonus for higher reps per set
        var setsRepsScore: Double = 0.0

        if let targetSets = targetSets, let targetRepsPerSet = targetRepsPerSet, targetSets > 0 && targetRepsPerSet > 0 {
            let targetTotalReps = targetSets * targetRepsPerSet

            // Calculate weighted average total reps
            let weightedAvgTotalReps = calculateWeightedAvg(recentWorkouts, \.repsCompleted)

            // Calculate weighted average reps per set
            let totalWeightedReps1 = week1.map { $0.repsCompleted }.reduce(0, +)
            let totalWeightedSets1 = week1.map { max($0.sets, 1) }.reduce(0, +)
            let totalWeightedReps2 = week2.map { $0.repsCompleted }.reduce(0, +)
            let totalWeightedSets2 = week2.map { max($0.sets, 1) }.reduce(0, +)
            let totalWeightedReps3 = week3.map { $0.repsCompleted }.reduce(0, +)
            let totalWeightedSets3 = week3.map { max($0.sets, 1) }.reduce(0, +)

            let weightedAvgRepsPerSet: Double = {
                let weightedRepsSum = (Double(totalWeightedReps1) * 1.0 +
                                       Double(totalWeightedReps2) * 0.5 +
                                       Double(totalWeightedReps3) * 0.25)
                let weightedSetsSum = (Double(totalWeightedSets1) * 1.0 +
                                       Double(totalWeightedSets2) * 0.5 +
                                       Double(totalWeightedSets3) * 0.25)
                return weightedSetsSum > 0 ? weightedRepsSum / weightedSetsSum : 0
            }()

            // Base volume score: 80% weight on total volume
            let volumeRatio = weightedAvgTotalReps / Double(targetTotalReps)
            let volumeComponent = min(volumeRatio, 1.0)

            // Reps per set multiplier: 20% weight
            // This scales from 0.5 (if reps/set is 50% of target) to 1.5 (if reps/set is 150% of target)
            // At exactly target reps/set: multiplier = 1.0 (neutral)
            // Below target: multiplier < 1.0 (reduces score)
            // Above target: multiplier > 1.0 (increases score)
            let repsPerSetRatio = weightedAvgRepsPerSet / Double(targetRepsPerSet)
            let repsPerSetMultiplier = min(max(repsPerSetRatio, 0.5), 1.5)

            // Combined: volume score × reps per set multiplier
            // Then apply 80% to volume base, 20% to the multiplier effect
            let baseScore = volumeComponent * 0.8
            let multiplierEffect = (repsPerSetMultiplier - 1.0) * volumeComponent * 0.2

            setsRepsScore = baseScore + volumeComponent * 0.2 + multiplierEffect
        } else {
            // Fallback: use total reps if sets info not available
            let weightedAvgReps = calculateWeightedAvg(recentWorkouts, \.repsCompleted)
            let repsRatio = weightedAvgReps / Double(targetReps)
            if repsRatio < 0.5 {
                setsRepsScore = 0.0
            } else if repsRatio >= 1.0 {
                setsRepsScore = 1.0
            } else {
                setsRepsScore = (repsRatio - 0.5) / 0.5
            }
        }

        // FACTOR 2: Difficulty rating (30% weight)
        let weightedAvgDifficulty = calculateWeightedAvg(recentWorkouts, \.difficultyRating)

        // Edge case: ensure difficulty is in valid range [1, 5]
        let clampedDifficulty = min(max(weightedAvgDifficulty, 1.0), 5.0)
        let difficultyScore = (clampedDifficulty - 1.0) / 4.0  // Normalize from 1-5 to 0-1

        // FACTOR 3: Total volume bonus (10% weight) - rewards exceeding targets
        var volumeBonus: Double = 0.0
        if let targetSets = targetSets, let targetRepsPerSet = targetRepsPerSet {
            let weightedAvgTotalReps = calculateWeightedAvg(recentWorkouts, \.repsCompleted)
            let targetTotalReps = Double(targetSets * targetRepsPerSet)
            if weightedAvgTotalReps > targetTotalReps {
                // Bonus up to 10% for exceeding target (capped at 50% above target)
                let excessRatio = min((weightedAvgTotalReps - targetTotalReps) / targetTotalReps, 0.5)
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
