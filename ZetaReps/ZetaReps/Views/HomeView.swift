//
//  HomeView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var showingWorkout = false
    @State private var showingPaywall = false
    @State private var paywallMilestone: Int?
    @State private var selectedWorkoutForDetail: Workout?
    @State private var selectedDateForDayView: Date?
    @AppStorage("hasShownMilestonePaywall") private var hasShownMilestonePaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                // Add visual indicator for Home tab
                Color.clear.frame(height: 0).id("home-tab")
                LazyVStack(spacing: 20) {
                    // Bento Stats Grid - Today, This Week, Streak, Next Workout
                    BentoStatsGrid(
                        todayCount: todayWorkouts.count,
                        weekTotal: weekTotal,
                        weekDaysCompleted: weekDaysCompleted,
                        targetDays: settings.effectiveTargetDays,
                        streak: currentStreak,
                        nextWorkoutTime: nextWorkoutTime,
                        workouts: workouts,
                        settings: settings
                    )
                    .id("bento-\(settings.effectiveTargetDays)-\(workouts.count)") // Refresh when targetDays or workouts change
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .transition(.scale.combined(with: .opacity))

                    // Action Buttons - Start and Share
                    HStack(spacing: 12) {
                        // Start button (left, half width)
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            
                            if !subscriptionManager.isSubscribed && totalPushups >= 100 {
                                paywallMilestone = nil
                                showingPaywall = true
                            } else {
                                showingWorkout = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Start")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .opacity(subscriptionManager.isSubscribed || totalPushups < 100 ? 1.0 : 0.6)
                        .disabled(subscriptionManager.isSubscribed ? false : totalPushups >= 100)
                        
                        // Share button (right, half width) - only show if workouts exist
                        if !workouts.isEmpty {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                
                                let shareText = ShareManager.generateShareText(from: currentMetrics)
                                let activityVC = UIActivityViewController(
                                    activityItems: [shareText],
                                    applicationActivities: nil
                                )
                                
                                // Exclude unwanted options
                                activityVC.excludedActivityTypes = [
                                    .addToReadingList,
                                    .assignToContact,
                                    .print
                                ]
                                
                                // Present share sheet
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    var topVC = rootVC
                                    while let presented = topVC.presentedViewController {
                                        topVC = presented
                                    }
                                    
                                    // For iPad
                                    if let popover = activityVC.popoverPresentationController {
                                        popover.sourceView = topVC.view
                                        popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                                        popover.permittedArrowDirections = []
                                    }
                                    
                                    topVC.present(activityVC, animated: true)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Share")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Performance Metrics Card (only show with 3+ recent workouts)
                    if hasEnoughWorkoutsForMetrics {
                        GlassmorphicMetricsCard(
                            consistency: currentMetrics.consistency,
                            intensity: currentMetrics.intensity,
                            targetDays: settings.effectiveTargetDays
                        )
                        .id("metrics-\(settings.effectiveTargetDays)-\(settings.effectiveTargetReps)-\(String(format: "%.1f", currentMetrics.consistency))-\(String(format: "%.1f", currentMetrics.intensity))-\(workouts.count)")
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                        .onChange(of: settings.effectiveTargetDays) { oldValue, newValue in
                            // Metrics will recalculate automatically via currentMetrics computed property
                        }
                        .onChange(of: settings.effectiveTargetReps) { oldValue, newValue in
                            // Metrics will recalculate automatically via currentMetrics computed property
                        }
                        .onChange(of: settings.useRecommendedStandards) { oldValue, newValue in
                            // Refresh when switching between custom and recommended
                        }
                        .onChange(of: workouts.count) { _, _ in
                            // Force refresh when workouts change (metrics depend on workout data)
                        }
                    } else {
                        // Encouragement card when not enough workouts yet
                        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
                        let recentCount = Array(sortedWorkouts.prefix(10)).count
                        MetricsPlaceholderCard(workoutsCount: recentCount)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Personal Records Card
                    PersonalRecordsCard(records: personalRecords, totalPushups: totalPushups)
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))

                    // Recent Activity - Calendar Heatmap
                    if !workouts.isEmpty {
                        WorkoutCalendarView(
                            workouts: Array(workouts.prefix(30)),
                            onDayTapped: { date in
                                selectedDateForDayView = date
                            }
                        )
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Free Limit Indicator (for non-subscribers)
                    if !subscriptionManager.isSubscribed {
                        FreeLimitIndicator(totalPushups: totalPushups, limit: 100)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        
                        // Locked button if limit reached
                        if totalPushups >= 100 {
                            LockedWorkoutButton(action: {
                                showingPaywall = true
                                paywallMilestone = nil
                            })
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingWorkout) {
                WorkoutSessionView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(milestone: paywallMilestone)
            }
            .sheet(item: $selectedWorkoutForDetail) { workout in
                WorkoutDetailView(workout: workout)
            }
            .sheet(isPresented: Binding(
                get: { selectedDateForDayView != nil },
                set: { if !$0 { selectedDateForDayView = nil } }
            )) {
                if let date = selectedDateForDayView {
                    DayWorkoutsView(
                        date: date,
                        workouts: workouts
                    )
                }
            }
            .task {
                checkMilestones()
            }
            .onChange(of: workouts.count) { _, _ in
                checkMilestones()
            }
        }
    }

    // MARK: - Computed Properties

    private var currentMetrics: WorkoutMetrics {
        MetricsCalculator.calculateMetrics(
            workouts: workouts,
            targetDays: settings.effectiveTargetDays,
            targetReps: settings.effectiveTargetReps,
            targetSets: settings.effectiveTargetSets,
            targetRepsPerSet: settings.effectiveTargetRepsPerSet,
            evaluationPeriod: 30
        )
    }
    
    // Check if we have enough recent workouts for metrics (3-10 most recent)
    private var hasEnoughWorkoutsForMetrics: Bool {
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        let recentWorkouts = Array(sortedWorkouts.prefix(10))
        return recentWorkouts.count >= 3
    }

    private var todayWorkouts: [Workout] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: today)
        }
    }

    private var weekTotal: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        return workouts
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.repsCompleted }
    }

    private var currentStreak: Int {
        MetricsCalculator.calculateCurrentStreak(workouts: workouts)
    }

    private var totalPushups: Int {
        workouts.reduce(0) { $0 + $1.repsCompleted }
    }

    private var personalRecords: PersonalRecords {
        MetricsCalculator.calculatePersonalRecords(workouts: workouts)
    }

    private var weekDaysCompleted: Int {
        let calendar = Calendar.current
        let now = Date()

        // Get the start of the current week (Sunday or Monday depending on locale)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return 0
        }

        // Count unique days with workouts in current week
        let workoutDays = Set(workouts
            .filter { $0.date >= weekStart && $0.date <= now }
            .map { calendar.startOfDay(for: $0.date) }
        )

        return workoutDays.count
    }
    
    private var nextWorkoutTime: TimeInterval? {
        Self.calculateNextWorkoutTime(workouts: workouts, settings: settings)
    }
    
    static func calculateNextWorkoutTime(workouts: [Workout], settings: AppSettings) -> TimeInterval? {
        // Always prioritize scheduled time if available
        if let scheduledTime = getNextScheduledTime(settings: settings) {
            return scheduledTime
        }

        // If reminders are disabled, don't show any next time
        guard settings.notificationsEnabled else {
            return nil
        }

        // If no schedule, use ideal next workout based on target days
        let calendar = Calendar.current
        let now = Date()

        // Get last workout date
        guard let lastWorkoutDate = workouts.map({ $0.date }).max() else {
            // No workouts yet, suggest tomorrow at a reasonable time
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
                let tomorrowMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
                return tomorrowMorning?.timeIntervalSince(now)
            }
            return nil
        }

        // Calculate ideal next workout based on target days
        let daysBetweenWorkouts = 7.0 / Double(settings.effectiveTargetDays)
        let idealNextWorkout = calendar.date(byAdding: .day, value: Int(daysBetweenWorkouts), to: calendar.startOfDay(for: lastWorkoutDate))

        guard let idealNext = idealNextWorkout else { return nil }

        // If ideal time is in the past, move to tomorrow
        if idealNext <= now {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
                let tomorrowMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
                return tomorrowMorning?.timeIntervalSince(now)
            }
        }

        // Calculate time until ideal next workout
        return idealNext.timeIntervalSince(now)
    }
    
    static func getNextScheduledTime(settings: AppSettings) -> TimeInterval? {
        guard settings.notificationsEnabled else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check schedule rule first
        if let scheduleRule = settings.currentScheduleRule, scheduleRule.isEnabled {
            return Self.getNextTimeFromRule(scheduleRule, from: now)
        }
        
        // Fallback to legacy reminder system
        switch settings.reminderFrequency {
        case .hourly:
            if let nextHour = calendar.date(bySettingHour: calendar.component(.hour, from: now) + 1, minute: 0, second: 0, of: now) {
                return nextHour.timeIntervalSince(now)
            }
        case .twiceDaily, .daily:
            // Use custom times or default times
            let times = settings.customTimes.isEmpty ? [DateComponents(hour: 9, minute: 0), DateComponents(hour: 18, minute: 0)] : settings.customTimes
            for timeComp in times {
                if let nextTime = calendar.nextDate(after: now, matching: timeComp, matchingPolicy: .nextTime) {
                    return nextTime.timeIntervalSince(now)
                }
            }
        case .custom:
            let times = settings.customTimes
            for timeComp in times {
                if let nextTime = calendar.nextDate(after: now, matching: timeComp, matchingPolicy: .nextTime) {
                    return nextTime.timeIntervalSince(now)
                }
            }
        case .disabled:
            break
        }
        
        return nil
    }
    
    static func getNextTimeFromRule(_ rule: ScheduleRule, from date: Date) -> TimeInterval? {
        let calendar = Calendar.current
        let now = date
        
        // Helper to check if a date is on an active day
        func isActiveDay(_ date: Date) -> Bool {
            let weekday = calendar.component(.weekday, from: date)
            return rule.activeDays.contains(weekday)
        }
        
        // Helper to find next active day
        func findNextActiveDay(from startDate: Date) -> Date? {
            var checkDate = calendar.startOfDay(for: startDate)
            // Check up to 14 days ahead
            for _ in 0..<14 {
                if isActiveDay(checkDate) {
                    return checkDate
                }
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
                checkDate = nextDay
            }
            return nil
        }
        
        switch rule.scheduleType {
        case .daily, .custom:
            // Find next custom time on an active day
            for timeComp in rule.customTimes {
                let components = DateComponents(hour: timeComp.hour, minute: timeComp.minute)
                
                // Check today first
                if let todayTime = calendar.date(bySettingHour: timeComp.hour, minute: timeComp.minute, second: 0, of: calendar.startOfDay(for: now)),
                   todayTime > now && isActiveDay(todayTime) {
                    return todayTime.timeIntervalSince(now)
                }
                
                // Check next matching time on active days
                var checkDate = now
                for _ in 0..<14 {
                    if let nextTime = calendar.nextDate(after: checkDate, matching: components, matchingPolicy: .nextTime) {
                        if isActiveDay(nextTime) {
                            return nextTime.timeIntervalSince(now)
                        }
                        checkDate = nextTime
                    } else {
                        break
                    }
                }
            }
        case .interval:
            // Calculate next interval time
            guard let intervalHours = rule.intervalHours, intervalHours > 0 else { break }
            
            let startHour = rule.startTime.hour
            let startMinute = rule.startTime.minute
            let endHour = rule.endTime.hour
            let endMinute = rule.endTime.minute
            
            // Check if today is an active day
            let todayIsActive = isActiveDay(now)
            
            if todayIsActive {
                // Get today's start time for the interval period
                let startOfDay = calendar.startOfDay(for: now)
                guard let todayStartTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: startOfDay) else { break }
                
                // Calculate how many minutes since the start of today's interval period
                let minutesSinceStart = calendar.dateComponents([.minute], from: todayStartTime, to: now).minute ?? 0
                
                // If we're before the start time today, next interval is at start time
                if minutesSinceStart < 0 {
                    return todayStartTime.timeIntervalSince(now)
                }
                
                // Calculate which interval period we're in
                let intervalMinutes = intervalHours * 60
                let intervalsSinceStart = minutesSinceStart / intervalMinutes
                let nextIntervalNumber = intervalsSinceStart + 1
                let minutesToNextInterval = (nextIntervalNumber * intervalMinutes) - minutesSinceStart
                
                // Calculate the next interval time
                if let nextTime = calendar.date(byAdding: .minute, value: minutesToNextInterval, to: now) {
                    let nextHour = calendar.component(.hour, from: nextTime)
                    let nextMin = calendar.component(.minute, from: nextTime)
                    
                    // Check if it's still within today's active time range
                    let nextTimeInMinutes = nextHour * 60 + nextMin
                    let endTimeInMinutes = endHour * 60 + endMinute
                    
                    if nextTimeInMinutes <= endTimeInMinutes && isActiveDay(nextTime) {
                        return nextTime.timeIntervalSince(now)
                    }
                }
            }
            
            // Need to find next active day
            if let nextActiveDay = findNextActiveDay(from: now) {
                if let nextTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: nextActiveDay) {
                    return nextTime.timeIntervalSince(now)
                }
            }
        case .hourly:
            // Find next hour in the active time range
            let todayIsActive = isActiveDay(now)
            
            if todayIsActive {
                let currentHour = calendar.component(.hour, from: now)
                if currentHour < rule.startTime.hour || currentHour >= rule.endTime.hour {
                    // Next hour is tomorrow (check if tomorrow is active)
                    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)),
                       isActiveDay(tomorrow),
                       let nextTime = calendar.date(bySettingHour: rule.startTime.hour, minute: rule.startTime.minute, second: 0, of: tomorrow) {
                        return nextTime.timeIntervalSince(now)
                    }
                } else {
                    // Next hour is today
                    if let nextHour = calendar.date(bySettingHour: currentHour + 1, minute: 0, second: 0, of: now),
                       isActiveDay(nextHour) {
                        return nextHour.timeIntervalSince(now)
                    }
                }
            }
            
            // Find next active day
            if let nextActiveDay = findNextActiveDay(from: now),
               let nextTime = calendar.date(bySettingHour: rule.startTime.hour, minute: rule.startTime.minute, second: 0, of: nextActiveDay) {
                return nextTime.timeIntervalSince(now)
            }
        case .twiceDaily:
            // Use start and end times as the two daily times
            let morningComponents = DateComponents(hour: rule.startTime.hour, minute: rule.startTime.minute)
            let eveningComponents = DateComponents(hour: rule.endTime.hour, minute: rule.endTime.minute)
            let times = [morningComponents, eveningComponents]
            
            // Check today first
            for timeComp in times {
                if let todayTime = calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: calendar.startOfDay(for: now)),
                   todayTime > now && isActiveDay(todayTime) {
                    return todayTime.timeIntervalSince(now)
                }
            }
            
            // Check next matching times on active days
            var checkDate = now
            for _ in 0..<14 {
                for timeComp in times {
                    if let nextTime = calendar.nextDate(after: checkDate, matching: timeComp, matchingPolicy: .nextTime),
                       isActiveDay(nextTime) {
                        return nextTime.timeIntervalSince(now)
                    }
                }
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) {
                    checkDate = nextDay
                } else {
                    break
                }
            }
        }
        
        return nil
    }

    // MARK: - Methods

    private func checkMilestones() {
        guard !subscriptionManager.isSubscribed else { return }
        guard !hasShownMilestonePaywall else { return }

        let total = totalPushups

        if total >= 100 {
            paywallMilestone = 100
            showingPaywall = true
            hasShownMilestonePaywall = true
        }
    }
}

// MARK: - Hero Metrics Section

struct PersonalRecordsCard: View {
    let records: PersonalRecords
    let totalPushups: Int

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Personal Records")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()
            }

            // Records Grid - 3 items
            HStack(spacing: 12) {
                RecordItem(
                    title: "Best Workout",
                    value: records.bestSingleWorkout,
                    icon: "flame.fill",
                    color: .orange,
                    suffix: " reps"
                )

                RecordItem(
                    title: "Longest Streak",
                    value: records.longestStreak,
                    icon: "bolt.fill",
                    color: .green,
                    suffix: records.longestStreak == 1 ? " day" : " days"
                )

                RecordItem(
                    title: "Total Pushups",
                    value: totalPushups,
                    icon: "figure.arms.open",
                    color: .blue
                )
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 24)
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
}

// MARK: - Record Item Component

struct RecordItem: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    var suffix: String = ""

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)

            Text("\(value)\(suffix)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Circular Progress Ring

struct CircularProgressRing: View {
    let progress: Double
    let total: Int
    let milestone: Int

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.blue, .purple, .pink]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)

            // Center text
            VStack(spacing: 2) {
                Text("\(total)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text("/\(milestone)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Bento Stats Grid

struct BentoStatsGrid: View {
    let todayCount: Int
    let weekTotal: Int
    let weekDaysCompleted: Int
    let targetDays: Int
    let streak: Int
    let nextWorkoutTime: TimeInterval?
    let workouts: [Workout]
    let settings: AppSettings
    
    var body: some View {
        HStack(spacing: 12) {
            GlassBentoCard(
                title: "Today",
                value: "\(todayCount)",
                icon: "calendar",
                gradient: [.orange, .red]
            )

            GlassBentoCard(
                title: "Workouts",
                value: "\(weekDaysCompleted)/\(targetDays)",
                icon: "chart.bar.fill",
                gradient: [.green, .mint]
            )

            GlassBentoCard(
                title: "Streak",
                value: "\(streak)",
                icon: "flame.fill",
                gradient: [.yellow, .orange]
            )

            if settings.notificationsEnabled {
                DowntimeCard(calculateNextTime: {
                    HomeView.calculateNextWorkoutTime(workouts: workouts, settings: settings) ?? 0
                })
                .id("downtime-\(settings.effectiveTargetDays)-\(settings.notificationsEnabled)-\(settings.reminderFrequency.rawValue)-\(settings.customTimes.map { "\($0.hour ?? 0):\($0.minute ?? 0)" }.joined(separator: ","))-\(settings.currentScheduleRule?.activeDays.sorted().map(String.init).joined(separator: ",") ?? "none")-\(workouts.count)")
            }
        }
    }
}

// MARK: - Downtime Card

struct DowntimeCard: View {
    let calculateNextTime: () -> TimeInterval?
    @State private var timeRemaining: TimeInterval?
    @State private var timer: Timer?
    @State private var refreshTrigger = UUID()
    
    init(calculateNextTime: @escaping () -> TimeInterval?) {
        self.calculateNextTime = calculateNextTime
    }
    
    private var timeUntilNext: String {
        // Always use current timeRemaining which is updated by timer and notifications
        guard let rem = timeRemaining, rem > 0 else {
            return "Now"
        }
        
        let totalSeconds = Int(rem)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours >= 24 {
            let days = hours / 24
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.body)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 2) {
                Text(timeUntilNext)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())

                Text("Next")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 85)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
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
                .onAppear {
                    updateTime()
                    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                        updateTime()
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScheduleUpdated"))) { _ in
                    refreshTrigger = UUID()
                    updateTime()
                }
                .onChange(of: refreshTrigger) { _, _ in
                    updateTime()
                }
                .id(refreshTrigger)
    }
    
    private func updateTime() {
        timeRemaining = calculateNextTime()
    }
}

// MARK: - Glass Bento Card

struct GlassBentoCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    var isLarge: Bool = false

    var body: some View {
        Group {
            if isLarge {
                // Large card layout (horizontal)
                HStack(spacing: 16) {
                    // Icon with gradient
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Spacer()

                    // Text content
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(value)
                            .font(.system(size: 48, weight: .bold, design: .rounded))

                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                // Small card layout (vertical)
                VStack(spacing: 8) {
                    // Icon with gradient
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Text content
                    VStack(spacing: 2) {
                        Text(value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 85)
                .padding(.vertical, 12)
                .padding(.horizontal, 6)
            }
        }
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
}

// MARK: - Start Workout Button

struct StartWorkoutButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .symbolEffect(.bounce, value: isPressed)

                Text("Start Workout")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .green.opacity(0.5), radius: isPressed ? 10 : 20, x: 0, y: isPressed ? 5 : 10)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Free Limit Indicator

struct FreeLimitIndicator: View {
    let totalPushups: Int
    let limit: Int

    private var remaining: Int {
        max(0, limit - totalPushups)
    }

    private var progress: Double {
        min(Double(totalPushups) / Double(limit), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Version")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if remaining > 0 {
                        Text("\(remaining) pushups remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Limit reached - Subscribe to continue")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Text("\(totalPushups)/\(limit)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: progress < 0.9 ? [.blue, .cyan] : [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
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
}

// MARK: - Locked Button (shown in content area if limit reached)

struct LockedWorkoutButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Free limit reached")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.4), .red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: .orange.opacity(0.2), radius: 12, x: 0, y: 6)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Metrics Placeholder Card

struct MetricsPlaceholderCard: View {
    let workoutsCount: Int
    @State private var showingInfo = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Performance Metrics")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    showingInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.bottom, 4)

            // Message
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.opacity(0.5))
                
                Text("Complete \(3 - workoutsCount) more workout\(3 - workoutsCount == 1 ? "" : "s") to see your performance metrics")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Metrics use your 3-10 most recent workouts for accurate analysis")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.1),
                                Color.primary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .sheet(isPresented: $showingInfo) {
            MetricsInfoView()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Workout.self, inMemory: true)
}
