//
//  WorkoutDetailView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    @State private var isEditing = false
    @State private var editedSets: Int
    @State private var editedReps: Int
    @State private var editedDuration: TimeInterval
    @State private var editedDifficulty: Int
    @State private var editedDate: Date

    @State private var showingDeleteAlert = false
    @State private var durationMinutes: Int
    @State private var durationSeconds: Int

    init(workout: Workout) {
        self.workout = workout
        _editedSets = State(initialValue: workout.sets)
        _editedReps = State(initialValue: workout.repsCompleted)
        _editedDuration = State(initialValue: workout.duration)
        _editedDifficulty = State(initialValue: workout.difficultyRating)
        _editedDate = State(initialValue: workout.date)
        _isEditing = State(initialValue: true) // Start in edit mode directly

        let mins = Int(workout.duration) / 60
        let secs = Int(workout.duration) % 60
        _durationMinutes = State(initialValue: mins)
        _durationSeconds = State(initialValue: secs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Show editing form directly
                    editingForm
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }
            }
            .alert("Delete Workout", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteWorkout()
                }
            } message: {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
        }
    }

    // MARK: - Header Card (Display Mode)

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Large rep count
            VStack(spacing: 8) {
                Text("\(workout.repsCompleted)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("pushups")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text("\(workout.sets) sets × \(Int(workout.averageRepsPerSet)) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.8))
            }
            .padding(.top)

            // Date and time
            VStack(spacing: 4) {
                Text(workout.date.formatted(.dateTime.month(.wide).day().year()))
                    .font(.headline)

                Text(workout.date.formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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

    // MARK: - Details Card (Display Mode)

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sets
            DetailRow(
                icon: "repeat",
                iconColor: .indigo,
                title: "Sets",
                value: "\(workout.sets) sets"
            )

            Divider()
            
            // Average reps per set
            DetailRow(
                icon: "figure.arms.open",
                iconColor: .blue,
                title: "Avg Reps per Set",
                value: String(format: "%.1f", workout.averageRepsPerSet)
            )

            Divider()

            // Duration
            DetailRow(
                icon: "clock.fill",
                iconColor: .blue,
                title: "Duration",
                value: workout.formattedDuration
            )

            Divider()

            // Difficulty
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                    Text("Difficulty")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= workout.difficultyRating ? "star.fill" : "star")
                            .foregroundStyle(index <= workout.difficultyRating ? .orange : .gray.opacity(0.3))
                            .font(.title3)
                    }
                }
            }

        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Editing Form

    private var editingForm: some View {
        VStack(spacing: 20) {
            // Date picker
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("Date & Time")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 4)

                DatePicker("", selection: $editedDate)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.blue)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )

            // Sets stepper
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "repeat")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                    Text("Sets")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 4)

                HStack(spacing: 20) {
                    Button(action: {
                        if editedSets > 1 {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                editedSets -= 1
                            }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(editedSets > 1 ? .red : .gray.opacity(0.3))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(editedSets <= 1)

                    Text("\(editedSets)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(minWidth: 100)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Button(action: {
                        if editedSets < 20 {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                editedSets += 1
                            }
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(editedSets < 20 ? .green : .gray.opacity(0.3))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(editedSets >= 20)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.indigo.opacity(0.3), Color.indigo.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )

            // Reps stepper
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.arms.open")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text("Total Reps")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 4)

                HStack(spacing: 20) {
                    Button(action: {
                        if editedReps > 1 {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                editedReps -= 1
                            }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(editedReps > 1 ? .red : .gray.opacity(0.3))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(editedReps <= 1)

                    Text("\(editedReps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(minWidth: 100)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Button(action: {
                        if editedReps < 1000 {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                editedReps += 1
                            }
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(editedReps < 1000 ? .green : .gray.opacity(0.3))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(editedReps >= 1000)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )

            // Duration pickers
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    Text("Duration")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 4)

                HStack(spacing: 20) {
                    // Minutes
                    VStack(spacing: 8) {
                        Text("Minutes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)

                    Text(":")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)

                    // Seconds
                    VStack(spacing: 8) {
                        Text("Seconds")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Picker("Seconds", selection: $durationSeconds) {
                            ForEach(0..<60) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: durationMinutes) { _, _ in
                    editedDuration = TimeInterval(durationMinutes * 60 + durationSeconds)
                }
                .onChange(of: durationSeconds) { _, _ in
                    editedDuration = TimeInterval(durationMinutes * 60 + durationSeconds)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )

            // Difficulty picker - using modern selector (matching CompleteWorkoutView style)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    Text("How difficult was it?")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                ModernDifficultySelector(selectedRating: $editedDifficulty)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
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

    // MARK: - Helper Methods

    private func saveChanges() {
        // Update duration from minutes and seconds
        editedDuration = TimeInterval(durationMinutes * 60 + durationSeconds)

        // Update workout properties
        workout.date = editedDate
        workout.sets = editedSets
        workout.repsCompleted = editedReps
        workout.duration = editedDuration
        workout.difficultyRating = editedDifficulty

        // Save to context
        do {
            try modelContext.save()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Dismiss the view after successful save
            dismiss()
        } catch {
            // Handle save error (could show an alert here if needed)
            print("Error saving workout: \(error.localizedDescription)")
        }
    }

    private func deleteWorkout() {
        modelContext.delete(workout)
        do {
            try modelContext.save()
        } catch {
            print("❌ Error deleting workout: \(error.localizedDescription)")
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        dismiss()
    }

    private func difficultyLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "Easy"
        case 2: return "Light"
        case 3: return "Medium"
        case 4: return "Hard"
        case 5: return "Brutal"
        default: return ""
        }
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Workout.self, configurations: config) else {
        return Text("Preview unavailable")
            .padding()
    }

    let workout = Workout(
        date: Date(),
        duration: 120,
        repsCompleted: 50,
        difficultyRating: 3,
        notes: "Great workout! Felt strong today."
    )
    container.mainContext.insert(workout)

    return WorkoutDetailView(workout: workout)
        .modelContainer(container)
}
