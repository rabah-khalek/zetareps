//
//  CompleteWorkoutView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct CompleteWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    let duration: TimeInterval
    let setsCompleted: Int
    let totalReps: Int
    let onComplete: () -> Void

    @ObservedObject private var settings = AppSettings.shared

    @State private var sets: Int
    @State private var repsCompleted: Int
    @State private var difficultyRating = 3
    @State private var showingShareSheet = false
    @State private var shareText = ""
    @State private var repsPerSet: [Int] = []

    init(duration: TimeInterval, setsCompleted: Int, totalReps: Int, onComplete: @escaping () -> Void) {
        self.duration = duration
        self.setsCompleted = setsCompleted
        self.totalReps = totalReps
        self.onComplete = onComplete

        _sets = State(initialValue: max(setsCompleted, 1))
        _repsCompleted = State(initialValue: totalReps)
        
        // Initialize reps per set array
        if setsCompleted > 0 {
            let averageReps = totalReps / setsCompleted
            _repsPerSet = State(initialValue: Array(repeating: averageReps, count: setsCompleted))
        } else {
            _repsPerSet = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.08),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Success icon with animation
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.2), .green.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .bounceEffect()
                        }
                        .padding(.top, 20)

                        VStack(spacing: 8) {
                            Text("Great Job!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))

                            Text("Duration: \(formattedDuration)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Form fields
                        VStack(spacing: 20) {
                            // Sets completed
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "repeat")
                                        .font(.title3)
                                        .foregroundStyle(.indigo)
                                    Text("How many sets did you complete?")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }

                                HStack {
                                    Button(action: {
                                        if sets > 1 {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                            sets -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.red)
                                            .symbolEffect(.bounce, value: sets)
                                    }

                                    Text("\(sets)")
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .frame(minWidth: 80)
                                        .monospacedDigit()
                                        .contentTransition(.numericText())

                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        sets += 1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.green)
                                            .symbolEffect(.bounce, value: sets)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color(.systemBackground))
                                        
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.indigo.opacity(0.3), .indigo.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(color: .indigo.opacity(0.15), radius: 12, x: 0, y: 6)
                                )
                            }

                            // Reps completed
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "figure.arms.open")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                    Text("Total reps across all sets?")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }

                                HStack {
                                    Button(action: {
                                        if repsCompleted > 0 {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                            repsCompleted -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.red)
                                            .symbolEffect(.bounce, value: repsCompleted)
                                    }

                                    Text("\(repsCompleted)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .frame(minWidth: 100)
                                        .monospacedDigit()
                                        .contentTransition(.numericText())

                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        repsCompleted += 1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.green)
                                            .symbolEffect(.bounce, value: repsCompleted)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(20)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color(.systemBackground))
                                        
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(color: .blue.opacity(0.15), radius: 12, x: 0, y: 6)
                                )
                            }

                            // Difficulty rating
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "gauge.with.dots.needle.33percent")
                                        .font(.title3)
                                        .foregroundStyle(.orange)
                                    Text("How difficult was it?")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }

                                ModernDifficultySelector(
                                    selectedRating: $difficultyRating
                                )
                            }
                            .padding(20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemBackground))
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                            )

                        }
                        .padding(.horizontal, 20)

                        // Save buttons
                        HStack(spacing: 12) {
                            // Save button
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                saveWorkout(shouldShare: false)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Save")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                            
                            // Save & Share button
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                saveWorkout(shouldShare: true)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.title3)
                                    Text("Save & Share")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // Discard button
                        Button(action: {
                            onComplete()
                        }) {
                            Text("Discard")
                                .foregroundColor(.red)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Complete Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                SimpleShareSheet(activityItems: [shareText]) {
                    // Dismiss after sharing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

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

    private func saveWorkout(shouldShare: Bool) {
        let workout = Workout(
            date: Date(),
            duration: duration,
            sets: sets,
            repsCompleted: repsCompleted,
            difficultyRating: difficultyRating,
            notes: ""
        )

        modelContext.insert(workout)

        do {
            try modelContext.save()
            
            if shouldShare {
                // Generate share text and show share sheet
                let allWorkouts = workouts + [workout]
                let metrics = MetricsCalculator.calculateMetrics(
                    workouts: allWorkouts,
                    targetDays: settings.effectiveTargetDays,
                    targetReps: settings.effectiveTargetReps,
                    targetSets: settings.effectiveTargetSets,
                    targetRepsPerSet: settings.effectiveTargetRepsPerSet,
                    evaluationPeriod: 30
                )
                shareText = ShareManager.generateShareText(from: metrics)
                showingShareSheet = true
            } else {
                // Just dismiss after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        } catch {
            print("Error saving workout: \(error.localizedDescription)")
        }
    }

    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Simple Share Sheet

struct SimpleShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onComplete: (() -> Void)?
    
    init(activityItems: [Any], onComplete: (() -> Void)? = nil) {
        self.activityItems = activityItems
        self.onComplete = onComplete
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print
        ]
        
        activityVC.completionWithItemsHandler = { _, completed, _, error in
            if completed {
                onComplete?()
            }
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Modern Difficulty Selector

struct ModernDifficultySelector: View {
    @Binding var selectedRating: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    DifficultyButton(
                        rating: rating,
                        isSelected: selectedRating == rating,
                        difficultyColor: difficultyColor(for: rating),
                        difficultyGradient: difficultyGradient(for: rating)
                    ) {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRating = rating
                        }
                    }
                }
            }
            
            // Selected difficulty info
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text(difficultyLabel(for: selectedRating))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(difficultyColor(for: selectedRating))
                    
                    Text(difficultyDescription(for: selectedRating))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    private func difficultyColor(for rating: Int) -> Color {
        switch rating {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    private func difficultyGradient(for rating: Int) -> [Color] {
        switch rating {
        case 1: return [.green, .mint]
        case 2: return [.mint, .cyan]
        case 3: return [.yellow, .orange]
        case 4: return [.orange, .red]
        case 5: return [.red, .pink]
        default: return [.gray, .gray]
        }
    }
    
    private func difficultyLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Easy"
        case 2: return "Light"
        case 3: return "Moderate"
        case 4: return "Hard"
        case 5: return "Very Hard"
        default: return "Moderate"
        }
    }
    
    private func difficultyDescription(for rating: Int) -> String {
        switch rating {
        case 1: return "Breezed through it"
        case 2: return "Comfortable pace"
        case 3: return "Good challenge"
        case 4: return "Pushed myself"
        case 5: return "Maximum effort"
        default: return ""
        }
    }
}

// MARK: - Difficulty Button

struct DifficultyButton: View {
    let rating: Int
    let isSelected: Bool
    let difficultyColor: Color
    let difficultyGradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Visual intensity indicator
                ZStack {
                    // Background bars
                    VStack(spacing: 3) {
                        ForEach(0..<rating, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: difficultyGradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: isSelected ? 28 : 24, height: 4)
                                .opacity(isSelected ? 1.0 : 0.6)
                        }
                    }
                    
                    // Selected indicator ring
                    if isSelected {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: difficultyGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 48, height: 48)
                            .scaleEffect(1.1)
                    }
                }
                .frame(height: 50)
                
                // Rating number
                Text("\(rating)")
                    .font(.system(size: isSelected ? 18 : 16, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        isSelected ?
                            LinearGradient(
                                colors: difficultyGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                                difficultyColor.opacity(0.15) :
                                Color(.systemBackground)
                        )
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: difficultyGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    }
                }
            )
            .shadow(
                color: isSelected ? difficultyColor.opacity(0.4) : .black.opacity(0.05),
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    CompleteWorkoutView(duration: 125, setsCompleted: 3, totalReps: 30) {}
        .modelContainer(for: Workout.self, inMemory: true)
}
