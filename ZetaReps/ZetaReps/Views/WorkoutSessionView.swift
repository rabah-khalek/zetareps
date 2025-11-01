//
//  WorkoutSessionView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import Combine

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timerManager = WorkoutTimerManager()
    @ObservedObject private var settings = AppSettings.shared

    @State private var showingCompleteWorkout = false
    @State private var pulseAnimation = false
    @State private var currentSet = 1
    @State private var completedSets: Int = 0 // Number of sets completed
    @State private var repsCompleted: Int = 0 // Total reps across all completed sets
    @State private var restTimer: TimeInterval = 0
    @State private var isResting = false
    @State private var restTimerManager: RestTimerManager?
    
    private var targetSets: Int {
        settings.effectiveTargetSets
    }
    
    private var targetRepsPerSet: Int {
        settings.effectiveTargetRepsPerSet
    }
    
    private var restTimeSeconds: Int {
        settings.effectiveRestTimeSeconds
    }
    
    private var allSetsCompleted: Bool {
        completedSets >= targetSets
    }
    
    // Color scheme helpers
    @Environment(\.colorScheme) var colorScheme
    
    private var textPrimaryColor: Color {
        if isResting {
            return colorScheme == .dark ? .white : Color(red: 0.1, green: 0.2, blue: 0.4)
        } else {
            return colorScheme == .dark ? .white : Color(red: 0.2, green: 0.05, blue: 0.1)
        }
    }
    
    private var textSecondaryColor: Color {
        if isResting {
            return colorScheme == .dark ? Color.white.opacity(0.7) : Color(red: 0.3, green: 0.4, blue: 0.5)
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.7) : Color(red: 0.4, green: 0.2, blue: 0.25)
        }
    }
    
    private var dividerColor: Color {
        if isResting {
            return colorScheme == .dark ? Color.white.opacity(0.3) : Color(red: 0.5, green: 0.6, blue: 0.7)
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.3) : Color(red: 0.7, green: 0.5, blue: 0.55)
        }
    }
    
    private var restAccentColor: Color {
        // Blue accent for rest period
        return colorScheme == .dark 
            ? Color(red: 0.4, green: 0.6, blue: 0.9)
            : Color(red: 0.2, green: 0.4, blue: 0.7)
    }
    
    // Button colors
    private var startButtonColor: Color {
        colorScheme == .dark
            ? Color(red: 0.2, green: 0.7, blue: 0.3)
            : Color(red: 0.1, green: 0.6, blue: 0.2)
    }
    
    private var completeButtonColor: Color {
        isResting
            ? (colorScheme == .dark ? Color(red: 0.3, green: 0.5, blue: 0.8) : Color(red: 0.2, green: 0.4, blue: 0.7))
            : (colorScheme == .dark ? Color(red: 0.3, green: 0.4, blue: 0.8) : Color(red: 0.2, green: 0.3, blue: 0.7))
    }
    
    private var pauseButtonColor: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.5, blue: 0.1)
            : Color(red: 0.8, green: 0.4, blue: 0.1)
    }
    
    private var skipButtonColor: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.5, blue: 0.1)
            : Color(red: 0.8, green: 0.4, blue: 0.1)
    }
    
    private var finishButtonColor: Color {
        colorScheme == .dark
            ? Color(red: 0.6, green: 0.3, blue: 0.7)
            : Color(red: 0.5, green: 0.2, blue: 0.6)
    }
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedGradientBackground(
                isRunning: timerManager.isRunning,
                isResting: isResting,
                colorScheme: colorScheme
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Minimalist header
                HStack {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 32, height: 32)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Sets and Reps Progress
                if !allSetsCompleted {
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("SET")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(textSecondaryColor)
                                Text("\(currentSet)/\(targetSets)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(textPrimaryColor)
                                    .contentTransition(.numericText())
                            }
                            
                            Divider()
                                .frame(height: 50)
                                .background(dividerColor)
                            
                            VStack(spacing: 8) {
                                Text("REPS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(textSecondaryColor)
                                Text("\(targetRepsPerSet)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(textPrimaryColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("All Sets Complete")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(textPrimaryColor)
                        
                        Text("\(completedSets) sets • \(repsCompleted) reps")
                            .font(.subheadline)
                            .foregroundStyle(textSecondaryColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer(minLength: 20)

                // Timer / Rest Display
                if isResting {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .font(.title2)
                                .foregroundStyle(restAccentColor)
                            
                            Text("Rest")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(textPrimaryColor)
                        }
                        
                        Text(formatRestTime(restTimer))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(restAccentColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        if restTimer <= 5 && restTimer > 0 {
                            Text("Almost ready!")
                                .font(.subheadline)
                                .foregroundStyle(textSecondaryColor)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    VStack(spacing: 12) {
                        Text("Workout Time")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(textSecondaryColor)

                        Text(timerManager.formattedTime)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(textPrimaryColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 20)

                // Control buttons
                VStack(spacing: 10) {
                    if !timerManager.isRunning && !isResting {
                        // Primary: Start button (large)
                        WorkoutButton(
                            title: "Start",
                            icon: "play.fill",
                            color: startButtonColor,
                            action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                timerManager.start()
                            },
                            isPrimary: true
                        )
                    } else if isResting {
                        // Start next set button (primary, appears when rest is done)
                        if restTimer <= 0 {
                            WorkoutButton(
                                title: "Start Set \(currentSet)",
                                icon: "play.fill",
                                color: startButtonColor,
                                action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    startNextSet()
                                },
                                isPrimary: true
                            )
                        }
                        
                        // Secondary: Skip rest button (smaller)
                        WorkoutButton(
                            title: "Skip Rest",
                            icon: "forward.fill",
                            color: skipButtonColor,
                            action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                skipRest()
                            },
                            isPrimary: false
                        )
                    } else {
                        // Primary: Complete Set button (large, only during active workout)
                        if !allSetsCompleted {
                            WorkoutButton(
                                title: "Complete Set \(currentSet)",
                                icon: "checkmark.circle.fill",
                                color: completeButtonColor,
                                action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    completeCurrentSet()
                                },
                                isPrimary: true
                            )
                        }
                        
                        // Secondary: Pause button (smaller)
                        WorkoutButton(
                            title: "Pause",
                            icon: "pause.fill",
                            color: pauseButtonColor,
                            action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                timerManager.pause()
                            },
                            isPrimary: false
                        )
                    }

                    // Secondary: Finish Workout button (smaller)
                    WorkoutButton(
                        title: "Finish Workout",
                        icon: "checkmark.circle.fill",
                        color: finishButtonColor,
                        action: {
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()
                            timerManager.stop()
                            showingCompleteWorkout = true
                        },
                        disabled: completedSets == 0,
                        isPrimary: false
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingCompleteWorkout) {
            CompleteWorkoutView(
                duration: timerManager.elapsedTime,
                setsCompleted: completedSets,
                totalReps: repsCompleted
            ) {
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func completeCurrentSet() {
        // Add reps for this set (using target as placeholder, user can adjust in CompleteWorkoutView)
        repsCompleted += targetRepsPerSet
        completedSets += 1
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // If more sets remaining, start rest timer
        if completedSets < targetSets {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSet += 1
            }
            // Small delay for smoother transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    startRestTimer()
                }
            }
        } else {
            // All sets done - user can finish workout
            withAnimation(.easeInOut(duration: 0.3)) {
                timerManager.pause() // Pause so they can review before finishing
            }
        }
    }
    
    private func startRestTimer() {
        isResting = true
        restTimer = TimeInterval(restTimeSeconds)
        restTimerManager = RestTimerManager(initialTime: restTimeSeconds) { [self] remainingTime in
            restTimer = remainingTime
            if remainingTime <= 0 {
                // Rest complete - smooth transition
                withAnimation(.easeInOut(duration: 0.3)) {
                    isResting = false
                }
                restTimerManager = nil
            }
        }
        restTimerManager?.start()
    }
    
    private func skipRest() {
        restTimerManager?.stop()
        withAnimation(.easeInOut(duration: 0.3)) {
            isResting = false
        }
        restTimer = 0
        restTimerManager = nil
        // Don't increment currentSet here - it's already incremented in completeCurrentSet
    }
    
    private func startNextSet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isResting = false
        }
        restTimer = 0
        restTimerManager?.stop()
        restTimerManager = nil
        
        // Small delay for smoother transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            timerManager.start() // Resume workout timer for next set
        }
    }
    
    private func formatRestTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return String(format: "%02d", seconds)
    }
}

// MARK: - Rest Timer Manager

class RestTimerManager: ObservableObject {
    private var timer: DispatchSourceTimer?
    private var remainingTime: TimeInterval
    private let onUpdate: (TimeInterval) -> Void
    
    init(initialTime: Int, onUpdate: @escaping (TimeInterval) -> Void) {
        self.remainingTime = TimeInterval(initialTime)
        self.onUpdate = onUpdate
    }
    
    func start() {
        let queue = DispatchQueue.global(qos: .userInteractive)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 1.0)
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1.0
                
                DispatchQueue.main.async {
                    self.onUpdate(self.remainingTime)
                    
                    if self.remainingTime <= 0 {
                        self.stop()
                    }
                }
            }
        }
        
        timer?.resume()
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
    
    deinit {
        timer?.cancel()
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    let isRunning: Bool
    let isResting: Bool
    let colorScheme: ColorScheme
    @State private var animationPhase = 0.0

    private var backgroundColor: Color {
        if isResting {
            // Rest period: Calming blue tones
            return colorScheme == .dark 
                ? Color(red: 0.1, green: 0.2, blue: 0.35) 
                : Color(red: 0.85, green: 0.9, blue: 0.95)
        } else if isRunning {
            // Active workout: Energetic red
            return colorScheme == .dark 
                ? Color(red: 0.2, green: 0.05, blue: 0.1) 
                : Color(red: 0.95, green: 0.85, blue: 0.85)
        } else {
            // Idle: Neutral gray
            return colorScheme == .dark 
                ? Color(red: 0.1, green: 0.1, blue: 0.15) 
                : Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }
    
    private var gradientColors: [Color] {
        if isResting {
            // Rest: Blue gradient
            return colorScheme == .dark
                ? [
                    Color(red: 0.15, green: 0.25, blue: 0.4),
                    Color(red: 0.1, green: 0.2, blue: 0.35)
                ]
                : [
                    Color(red: 0.9, green: 0.93, blue: 0.98),
                    Color(red: 0.85, green: 0.9, blue: 0.95)
                ]
        } else if isRunning {
            // Active: Red gradient
            return colorScheme == .dark
                ? [
                    Color(red: 0.25, green: 0.08, blue: 0.12),
                    Color(red: 0.2, green: 0.05, blue: 0.1)
                ]
                : [
                    Color(red: 0.98, green: 0.88, blue: 0.88),
                    Color(red: 0.95, green: 0.85, blue: 0.85)
                ]
        } else {
            // Idle: Neutral
            return colorScheme == .dark
                ? [
                    Color(red: 0.12, green: 0.12, blue: 0.18),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ]
                : [
                    Color(red: 0.97, green: 0.97, blue: 0.98),
                    Color(red: 0.95, green: 0.95, blue: 0.97)
                ]
        }
    }

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.5), value: isRunning)
        .animation(.easeInOut(duration: 0.5), value: isResting)
    }
}

// MARK: - Workout Button

struct WorkoutButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var disabled: Bool = false
    var isPrimary: Bool = false

    @State private var isPressed = false
    
    private var fontSize: CGFloat {
        isPrimary ? 32 : 20
    }
    
    private var verticalPadding: CGFloat {
        isPrimary ? 26 : 16
    }
    
    private var shadowRadius: CGFloat {
        isPrimary ? 24 : 12
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isPrimary ? 14 : 10) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 22 : 18))
                    .symbolEffect(.bounce, value: isPressed)

                Text(title)
                    .fontWeight(isPrimary ? .bold : .semibold)
            }
            .font(.system(size: fontSize, weight: isPrimary ? .bold : .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(disabled ? Color.gray.opacity(0.5) : color)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(disabled ? 0.6 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !disabled {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
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

// MARK: - Workout Timer Manager

class WorkoutTimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false

    private var timer: DispatchSourceTimer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0

    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        startTime = Date()

        let queue = DispatchQueue.global(qos: .userInteractive)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 0.1)

        timer?.setEventHandler { [weak self] in
            guard let self = self, let startTime = self.startTime else { return }

            let elapsed = Date().timeIntervalSince(startTime) + self.pausedTime

            DispatchQueue.main.async {
                self.elapsedTime = elapsed
            }
        }

        timer?.resume()
    }

    func pause() {
        guard isRunning else { return }

        isRunning = false
        timer?.cancel()
        timer = nil

        pausedTime = elapsedTime
        startTime = nil
    }

    func stop() {
        pause()
        // Don't reset elapsedTime - we need it for the completion form
    }

    func reset() {
        pause()
        elapsedTime = 0
        pausedTime = 0
        startTime = nil
    }

    deinit {
        timer?.cancel()
    }
}

#Preview {
    WorkoutSessionView()
}
