//
//  ShareableCardView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import Charts

struct ShareableCardView: View {
    let metrics: WorkoutMetrics
    let recentWorkouts: [Workout]

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("ZetaReps")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(metrics.evaluationPeriod) Day Progress")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Stats Grid
            HStack(spacing: 20) {
                ShareStatPill(
                    value: "\(metrics.totalWorkouts)",
                    label: "Workouts",
                    icon: "flame.fill",
                    color: .orange
                )

                ShareStatPill(
                    value: "\(metrics.totalReps)",
                    label: "Pushups",
                    icon: "figure.arms.open",
                    color: .blue
                )

                ShareStatPill(
                    value: "\(metrics.streakDays)",
                    label: "Day Streak",
                    icon: "calendar",
                    color: .green
                )
            }

            // Metrics Gauges
            HStack(spacing: 40) {
                ShareMetricBadge(
                    score: metrics.consistency,
                    label: "Consistency",
                    color: .green
                )

                ShareMetricBadge(
                    score: metrics.intensity,
                    label: "Intensity",
                    color: .orange
                )
            }

            // Mini Chart
            if !recentWorkouts.isEmpty {
                MiniProgressChart(workouts: recentWorkouts)
                    .frame(height: 100)
                    .padding(.horizontal, 16)
            }

            // Footer
            VStack(spacing: 8) {
                Text("Keep pushing! 💪")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .frame(width: 400, height: 600)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height

                        // Draw diagonal lines for texture
                        for i in stride(from: -height, to: width + height, by: 40) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + height, y: height))
                        }
                    }
                    .stroke(Color.gray.opacity(0.05), lineWidth: 1)
                }
            }
        )
    }
}

// MARK: - Share Stat Pill

struct ShareStatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Share Metric Badge

struct ShareMetricBadge: View {
    let score: Double
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                // Progress ring
                Circle()
                    .trim(from: 0, to: score / 10)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(color)

                    Text("/ 10")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Mini Progress Chart

struct MiniProgressChart: View {
    let workouts: [Workout]

    private var chartData: [ChartDataPoint] {
        workouts
            .suffix(7) // Last 7 workouts
            .map { ChartDataPoint(date: $0.date, reps: $0.repsCompleted) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Progress")
                .font(.caption)
                .foregroundColor(.secondary)

            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Reps", dataPoint.reps)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let reps: Int
}

// MARK: - Instagram Stories Variant

struct InstagramStoriesCard: View {
    let metrics: WorkoutMetrics
    let recentWorkouts: [Workout]

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.purple,
                    Color.blue,
                    Color.pink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 30) {
                Spacer()

                // Main stat
                VStack(spacing: 16) {
                    Text("\(metrics.totalReps)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("PUSHUPS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))

                    Text("in \(metrics.evaluationPeriod) days")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Metrics
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", metrics.consistency))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Consistency")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", metrics.intensity))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Intensity")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    Text("💪")
                        .font(.system(size: 40))

                    Text("ZetaReps")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(40)
        }
        .frame(width: 1080, height: 1920) // Instagram Stories dimensions
    }
}

// MARK: - Preview

#Preview("Standard Card") {
    let sampleMetrics = WorkoutMetrics(
        consistency: 7.8,
        intensity: 6.5,
        totalWorkouts: 18,
        totalReps: 542,
        streakDays: 12,
        evaluationPeriod: 30
    )

    let sampleWorkouts = (1...7).map { i in
        Workout(
            date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
            duration: Double.random(in: 120...300),
            repsCompleted: Int.random(in: 20...50),
            difficultyRating: Int.random(in: 2...4),
            notes: ""
        )
    }

    return ShareableCardView(metrics: sampleMetrics, recentWorkouts: sampleWorkouts)
}

#Preview("Instagram Stories") {
    let sampleMetrics = WorkoutMetrics(
        consistency: 8.5,
        intensity: 7.2,
        totalWorkouts: 25,
        totalReps: 750,
        streakDays: 20,
        evaluationPeriod: 30
    )

    return InstagramStoriesCard(metrics: sampleMetrics, recentWorkouts: [])
        .scaleEffect(0.3) // Scale down to fit preview
}
