//
//  HistoryView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?
    @State private var showingWorkout = false
    @State private var selectedWorkoutForDetail: Workout?

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Statistics summary
                    StatisticsSummaryView(workouts: filteredWorkouts)
                        .padding(.horizontal)

                    // Metrics Progress Chart (Consistency & Intensity)
                    if !filteredWorkouts.isEmpty {
                        MetricsProgressChartView(
                            workouts: filteredWorkouts,
                            targetWorkoutDays: settings.effectiveTargetDays,
                            targetReps: settings.effectiveTargetReps,
                            timeRange: selectedTimeRange
                        )
                        .padding(.horizontal)
                    }

                    // Reps Progress chart
                    if !filteredWorkouts.isEmpty {
                        WorkoutChartView(
                            workouts: filteredWorkouts,
                            timeRange: selectedTimeRange
                        )
                        .padding(.horizontal)
                    } else {
                        EmptyStateView()
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .alert("Delete Workout", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete {
                        deleteWorkout(workout)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this workout?")
            }
            .sheet(item: $selectedWorkoutForDetail) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()

        // No 90-day limit - all users get full history access
        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return workouts.filter { $0.date >= weekAgo }

        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return workouts.filter { $0.date >= monthAgo }

        case .all:
            return workouts
        }
    }

    // MARK: - Methods

    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        do {
            try modelContext.save()
        } catch {
            print("❌ Error deleting workout: \(error.localizedDescription)")
        }
    }
}

// MARK: - Statistics Summary View

struct StatisticsSummaryView: View {
    let workouts: [Workout]

    var body: some View {
        HStack(spacing: 12) {
            StatBox(
                title: "Reps",
                value: "\(totalReps)",
                icon: "number",
                color: .blue
            )

            StatBox(
                title: "Workouts",
                value: "\(workouts.count)",
                icon: "calendar",
                color: .green
            )

            StatBox(
                title: "Avg.",
                value: "\(averageReps)",
                icon: "chart.bar",
                color: .orange
            )

            StatBox(
                title: "Time",
                value: formattedTotalTime,
                icon: "clock",
                color: .purple
            )
        }
    }

    private var totalReps: Int {
        workouts.reduce(0) { $0 + $1.repsCompleted }
    }

    private var averageReps: Int {
        guard !workouts.isEmpty else { return 0 }
        return totalReps / workouts.count
    }

    private var totalTime: TimeInterval {
        workouts.reduce(0) { $0 + $1.duration }
    }

    private var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Box Component

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @State private var animateValue = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, value: animateValue)
            }

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: color.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            animateValue = true
        }
    }
}

// MARK: - Metrics Progress Chart View

struct MetricsProgressChartView: View {
    let workouts: [Workout]
    let targetWorkoutDays: Int
    let targetReps: Int
    var timeRange: HistoryView.TimeRange = .week

    @State private var showingInfo = false
    
    private var calendar: Calendar { Calendar.current }

    private struct MetricDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let consistency: Double
        let intensity: Double
    }

    private var dataPoints: [MetricDataPoint] {
        guard !workouts.isEmpty else { return [] }

        let calendar = Calendar.current
        let sortedWorkouts = workouts.sorted { $0.date < $1.date }

        guard let firstDate = sortedWorkouts.first?.date,
              let lastDate = sortedWorkouts.last?.date else {
            return []
        }

        // Create data points for each day with workouts
        var points: [MetricDataPoint] = []
        var currentDate = calendar.startOfDay(for: firstDate)
        let endDate = calendar.startOfDay(for: lastDate)

        while currentDate <= endDate {
            // Get workouts up to and including this date for cumulative metrics
            let workoutsUpToDate = sortedWorkouts.filter { $0.date <= currentDate }

            // Only include days where we have at least some workout data
            if !workoutsUpToDate.isEmpty {
                let settings = AppSettings.shared
                let metrics = MetricsCalculator.calculateMetrics(
                    workouts: workoutsUpToDate,
                    targetDays: targetWorkoutDays,
                    targetReps: targetReps,
                    targetSets: settings.effectiveTargetSets,
                    targetRepsPerSet: settings.effectiveTargetRepsPerSet,
                    evaluationPeriod: 30
                )

                points.append(MetricDataPoint(
                    date: currentDate,
                    consistency: metrics.consistency,
                    intensity: metrics.intensity
                ))
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return points
    }


    private var maxMetricValue: Double {
        let maxConsistency = dataPoints.map { $0.consistency }.max() ?? 10
        let maxIntensity = dataPoints.map { $0.intensity }.max() ?? 10
        return max(maxConsistency, maxIntensity, 10)
    }

    private var visibleDomainLength: TimeInterval {
        // Always show 7 days in the visible domain
        return 7 * 24 * 60 * 60
    }
    
    private var axisStride: Calendar.Component {
        switch timeRange {
        case .week:
            return .day
        case .month:
            return .day
        case .all:
            return .day
        }
    }
    
    private var axisStrideCount: Int {
        // Always show at least 7 labels (one per day) in the visible domain
        // Since visibleDomainLength is always 7 days, we should show every day
        return 1
    }
    
    private var axisLabelCount: Int {
        guard !dataPoints.isEmpty else { return 5 }
        
        let visibleLength = visibleDomainLength
        let daysInRange = visibleLength / (24 * 60 * 60)
        
        // Calculate optimal label count based on visible range
        // With rotated labels, we can fit more labels without overlap
        // Typical chart width ~350pt, rotated label takes ~30pt width
        let optimalCount: Int
        if daysInRange <= 2 {
            optimalCount = min(6, max(2, dataPoints.count / 2))
        } else if daysInRange <= 5 {
            optimalCount = min(8, max(3, dataPoints.count / 3))
        } else if daysInRange <= 10 {
            optimalCount = min(10, max(5, dataPoints.count / 4))
        } else {
            optimalCount = min(12, max(6, dataPoints.count / 5))
        }
        
        return optimalCount
    }
    
    private func formatDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        
        if daysDiff == 0 {
            return "Today"
        } else if daysDiff == 1 {
            return "Yesterday"
        } else if daysDiff < 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Performance Trends")
                            .font(.headline)

                        Button(action: {
                            showingInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }

                }

                Spacer()

                // Legend
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Consistency")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text("Intensity")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Chart
            Chart {
                // Range indicator lines (horizontal rules)
                // Poor (0-4) - Red
                RuleMark(y: .value("Threshold", 4))
                    .foregroundStyle(.red.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Poor")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                
                // Fair (4-6) - Orange/Yellow
                RuleMark(y: .value("Threshold", 6))
                    .foregroundStyle(.orange.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Fair")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                
                // Good (6-8) - Blue
                RuleMark(y: .value("Threshold", 8))
                    .foregroundStyle(.blue.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Good")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                
                // Excellent (8-10) - Green
                RuleMark(y: .value("Threshold", 10))
                    .foregroundStyle(.green.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Excellent")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                
                // Consistency line with series
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", calendar.startOfDay(for: point.date), unit: .day),
                        y: .value("Score", point.consistency),
                        series: .value("Metric", "Consistency")
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Intensity line with series
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", calendar.startOfDay(for: point.date), unit: .day),
                        y: .value("Score", point.intensity),
                        series: .value("Metric", "Intensity")
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Data points
                ForEach(dataPoints) { point in
                    PointMark(
                        x: .value("Date", calendar.startOfDay(for: point.date), unit: .day),
                        y: .value("Score", point.consistency)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(30)

                    PointMark(
                        x: .value("Date", calendar.startOfDay(for: point.date), unit: .day),
                        y: .value("Score", point.intensity)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.primary.opacity(0.1))
                    
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...11.5) // Consistent domain across all views to ensure "Excellent" label is fully visible
            .chartScrollableAxes(timeRange == .week ? [] : .horizontal)
            .chartXVisibleDomain(length: visibleDomainLength)
            .frame(height: 200)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        .sheet(isPresented: $showingInfo) {
            MetricsInfoView()
        }
    }
}

// MARK: - Workout Chart View

struct WorkoutChartView: View {
    let workouts: [Workout]
    var timeRange: HistoryView.TimeRange = .week
    
    private var calendar: Calendar { Calendar.current }

    private struct DailySum: Identifiable {
        let id = UUID()
        let date: Date
        let totalReps: Int
        let averageDifficulty: Int
    }


    private var maxReps: Int {
        dailySums.map { $0.totalReps }.max() ?? 100
    }

    private var averageReps: Double {
        guard !dailySums.isEmpty else { return 0 }
        return Double(dailySums.reduce(0) { $0 + $1.totalReps }) / Double(dailySums.count)
    }

    private var dailySums: [DailySum] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.startOfDay(for: workout.date)
        }

        return grouped.map { date, workouts in
            let totalReps = workouts.reduce(0) { $0 + $1.repsCompleted }
            let avgDifficulty = Int(round(Double(workouts.reduce(0) { $0 + $1.difficultyRating }) / Double(workouts.count)))
            // Use start of day to ensure alignment with axis marks
            return DailySum(date: calendar.startOfDay(for: date), totalReps: totalReps, averageDifficulty: avgDifficulty)
        }.sorted { $0.date < $1.date }
    }

    private var visibleDomainLength: TimeInterval {
        // Always show 7 days in the visible domain
        return 7 * 24 * 60 * 60
    }
    
    private var axisStride: Calendar.Component {
        switch timeRange {
        case .week:
            return .day
        case .month:
            return .day
        case .all:
            return .day
        }
    }
    
    private var axisStrideCount: Int {
        // Always show at least 7 labels (one per day) in the visible domain
        // Since visibleDomainLength is always 7 days, we should show every day
        return 1
    }
    
    private var axisLabelCount: Int {
        guard !dailySums.isEmpty else { return 5 }
        
        let visibleLength = visibleDomainLength
        let daysInRange = visibleLength / (24 * 60 * 60)
        
        // Calculate optimal label count based on visible range
        // With rotated labels, we can fit more labels without overlap
        // Typical chart width ~350pt, rotated label takes ~30pt width
        let optimalCount: Int
        if daysInRange <= 2 {
            optimalCount = min(6, max(2, dailySums.count / 2))
        } else if daysInRange <= 5 {
            optimalCount = min(8, max(3, dailySums.count / 3))
        } else if daysInRange <= 10 {
            optimalCount = min(10, max(5, dailySums.count / 4))
        } else {
            optimalCount = min(12, max(6, dailySums.count / 5))
        }
        
        return optimalCount
    }
    
    private func formatDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        
        if daysDiff == 0 {
            return "Today"
        } else if daysDiff == 1 {
            return "Yesterday"
        } else if daysDiff < 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    private var chartHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progress Chart")
                .font(.headline)
        }
    }

    private var bestWorkoutIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("\(maxReps)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Text("Best")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                chartHeader
                Spacer()
                bestWorkoutIndicator
            }

            progressChart

            chartLegend
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
    }

    @ChartContentBuilder
    private var chartContent: some ChartContent {
        // Average line
        RuleMark(y: .value("Average", averageReps))
            .foregroundStyle(Color.orange.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .annotation(position: .top, alignment: .leading) {
                Text("Avg")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }

        // Daily sum bars with gradient colors based on difficulty
        ForEach(dailySums) { sum in
            BarMark(
                x: .value("Date", sum.date, unit: .day),
                y: .value("Reps", sum.totalReps),
                width: .ratio(0.8)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [difficultyColor(sum.averageDifficulty).opacity(0.6), difficultyColor(sum.averageDifficulty)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(6)
            .opacity(0.85)
        }
    }

    private var progressChart: some View {
        Chart {
            chartContent
        }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.primary.opacity(0.1))
                    
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                        }
                    }
                }
            }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYScale(domain: 0...(maxReps + max(Int(Double(maxReps) * 0.15), 10)))
        .chartScrollableAxes(timeRange == .week ? [] : .horizontal)
        .chartXVisibleDomain(length: visibleDomainLength)
        .frame(height: 220)
    }

    private var chartLegend: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 8) {
                Text("Easy")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { rating in
                        Circle()
                            .fill(difficultyColor(rating))
                            .frame(width: 8, height: 8)
                    }
                }

                Text("Hard")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }

    private func getBarColor(isSelected: Bool, isAboveAverage: Bool) -> AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.blue.gradient)
        } else if isAboveAverage {
            return AnyShapeStyle(Color.green.gradient)
        } else {
            return AnyShapeStyle(Color.blue.opacity(0.6).gradient)
        }
    }

    private func difficultyColor(_ rating: Int) -> Color {
        switch rating {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
}

// MARK: - Chart Legend Item

struct ChartLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workout Row View

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 15) {
            // Date badge
            VStack(spacing: 2) {
                Text(workout.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(workout.date.formatted(.dateTime.day()))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(width: 50)

            // Workout details
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(workout.repsCompleted) pushups")
                        .font(.headline)

                    Spacer()

                    Text(workout.formattedDuration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    // Difficulty indicator
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= workout.difficultyRating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(index <= workout.difficultyRating ? .orange : .gray)
                        }
                    }


                    Spacer()

                    Text(workout.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Compact Workout Card

struct CompactWorkoutCard: View {
    let workout: Workout
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor)
            }

            // Workout info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(workout.repsCompleted)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Text("pushups")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Difficulty emoji
                    Text(difficultyEmoji)
                        .font(.caption)
                }

                HStack(spacing: 8) {
                    Text(workout.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(workout.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !workout.notes.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(workout.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }

    private var difficultyEmoji: String {
        switch workout.difficultyRating {
        case 1: return "😊"
        case 2: return "🙂"
        case 3: return "😐"
        case 4: return "😓"
        case 5: return "😰"
        default: return "😐"
        }
    }
}

// MARK: - Workout Calendar View

struct WorkoutCalendarView: View {
    let workouts: [Workout]
    var onDayTapped: ((Date) -> Void)? = nil

    private var calendar: Calendar { Calendar.current }

    private var dateRange: ClosedRange<Date> {
        let sortedWorkouts = workouts.sorted { $0.date < $1.date }
        let start = sortedWorkouts.first?.date ?? Date()
        let end = sortedWorkouts.last?.date ?? Date()
        return start...end
    }

    private func intensity(for date: Date) -> Double {
        let dayWorkouts = workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let totalReps = dayWorkouts.reduce(0) { $0 + $1.repsCompleted }
        return min(Double(totalReps) / 100.0, 1.0) // Normalize to 0-1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 Days")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let date = calendar.date(byAdding: .day, value: -6 + index, to: Date()) ?? Date()
                    let intensity = intensity(for: date)

                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(dayColor(intensity: intensity))
                                .frame(width: 32, height: 32)

                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(intensity > 0.3 ? .white : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if intensity > 0 {
                            onDayTapped?(date)
                        }
                    }
                }
            }

            // Legend - centered
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Spacer()

                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(intensityColor(level))
                            .frame(width: 10, height: 10)
                    }

                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.top, 4)
            }

            // Settings hint
            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Tap any day to view and edit workouts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.15),
                                Color.primary.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    private func dayColor(intensity: Double) -> Color {
        if intensity == 0 {
            return Color(.systemGray5)
        } else if intensity < 0.25 {
            return .green.opacity(0.3)
        } else if intensity < 0.5 {
            return .green.opacity(0.5)
        } else if intensity < 0.75 {
            return .green.opacity(0.7)
        } else {
            return .green
        }
    }

    private func intensityColor(_ intensity: Double) -> Color {
        if intensity == 0 {
            return Color(.systemGray5)
        } else if intensity < 0.25 {
            return .green.opacity(0.3)
        } else if intensity < 0.5 {
            return .green.opacity(0.5)
        } else if intensity < 0.75 {
            return .green.opacity(0.7)
        } else {
            return .green
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete your first workout to see your progress here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Workout.self, inMemory: true)
}
