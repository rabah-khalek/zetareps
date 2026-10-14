//
//  MetricsSimulatorView.swift
//  ZetaReps
//

import SwiftUI
import SwiftData

struct MetricsSimulatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var workouts: [Workout]
    @ObservedObject var settings = AppSettings.shared

    // Workout counts per week
    @State private var week1Count: Int = 5
    @State private var week2Count: Int = 3
    @State private var week3Count: Int = 1

    // Workout quality (sets and reps)
    @State private var setsPerWorkout: Int = 3
    @State private var repsPerSet: Int = 10
    @State private var difficulty: Int = 3

    // Targets
    @State private var targetDaysPerWeek: Int = 5
    @State private var targetSets: Int = 3
    @State private var targetRepsPerSet: Int = 10

    // Computed metrics
    private var simulatedMetrics: (consistency: Double, intensity: Double) {
        let metrics = MetricsCalculator.calculateMetrics(
            workouts: workouts,
            targetDays: targetDaysPerWeek,
            targetSets: targetSets,
            targetRepsPerSet: targetRepsPerSet
        )
        return (metrics.consistency, metrics.intensity)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Metrics Preview at Top
                HStack(spacing: 16) {
                    MetricBadge(
                        label: "Consistency",
                        value: simulatedMetrics.consistency,
                        color: colorForScore(simulatedMetrics.consistency)
                    )
                    MetricBadge(
                        label: "Intensity",
                        value: simulatedMetrics.intensity,
                        color: colorForScore(simulatedMetrics.intensity)
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                ScrollView {
                    VStack(spacing: 20) {
                        // Workouts Per Week (Compact)
                        CompactSectionCard(title: "Workouts Per Week", icon: "calendar", iconColor: .green) {
                            VStack(spacing: 12) {
                                CompactSlider(label: "Week 1", value: $week1Count, range: 0...7, color: .green)
                                CompactSlider(label: "Week 2", value: $week2Count, range: 0...7, color: .blue)
                                CompactSlider(label: "Week 3", value: $week3Count, range: 0...7, color: .purple)
                            }
                        }

                        // Workout Quality (Compact)
                        CompactSectionCard(title: "Workout Quality", icon: "figure.mixed.cardio", iconColor: .orange) {
                            VStack(spacing: 12) {
                                CompactSlider(label: "Sets", value: $setsPerWorkout, range: 1...10, color: .orange)
                                CompactSlider(label: "Reps/Set", value: $repsPerSet, range: 5...50, step: 5, color: .orange)
                                CompactSlider(label: "Difficulty", value: $difficulty, range: 1...5, color: .orange)
                            }
                        }

                        // Targets (Compact)
                        CompactSectionCard(title: "Targets", icon: "target", iconColor: .blue) {
                            VStack(spacing: 12) {
                                CompactSlider(label: "Days/Week", value: $targetDaysPerWeek, range: 1...7, color: .blue)
                                CompactSlider(label: "Target Sets", value: $targetSets, range: 1...10, color: .blue)
                                CompactSlider(label: "Target Reps", value: $targetRepsPerSet, range: 5...50, step: 5, color: .blue)
                            }
                        }

                        // Apply Button
                        Button(action: applySimulation) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Apply Simulation")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Metrics Simulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0..<4: return .red
        case 4..<6: return .orange
        case 6..<8: return .blue
        default: return .green
        }
    }

    private func applySimulation() {
        let calendar = Calendar.current
        let now = Date()

        // Clear existing data
        try? modelContext.delete(model: Workout.self)

        // Generate Week 1 workouts (days 0-6)
        generateWorkouts(count: week1Count, startDay: 0, endDay: 6, calendar: calendar, now: now)

        // Generate Week 2 workouts (days 7-13)
        generateWorkouts(count: week2Count, startDay: 7, endDay: 13, calendar: calendar, now: now)

        // Generate Week 3 workouts (days 14-20)
        generateWorkouts(count: week3Count, startDay: 14, endDay: 20, calendar: calendar, now: now)

        try? modelContext.save()

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func generateWorkouts(count: Int, startDay: Int, endDay: Int, calendar: Calendar, now: Date) {
        guard count > 0 else { return }

        let daysInRange = endDay - startDay + 1
        let spacing = daysInRange / count

        for i in 0..<count {
            let daysAgo = startDay + (i * spacing)
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

            let totalReps = setsPerWorkout * repsPerSet
            let duration = TimeInterval(totalReps * 2 + setsPerWorkout * 60) // 2s per rep + 60s rest per set

            let workout = Workout(
                date: date,
                duration: duration,
                sets: setsPerWorkout,
                repsCompleted: totalReps,
                difficultyRating: difficulty,
                notes: "Simulated - Week \((startDay / 7) + 1)"
            )
            modelContext.insert(workout)
        }
    }
}

// MARK: - Metric Badge (Compact)

struct MetricBadge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f", value))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text("/ 10")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Compact Section Card

struct CompactSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Compact Slider

struct CompactSlider: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step))
            .tint(color)

            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    MetricsSimulatorView()
        .modelContainer(for: Workout.self, inMemory: true)
}
