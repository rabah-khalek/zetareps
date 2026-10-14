//
//  DayWorkoutsView.swift
//  ZetaReps
//

import SwiftUI
import SwiftData

struct DayWorkoutsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    let workouts: [Workout]
    
    @State private var selectedWorkout: Workout?
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?
    
    private var calendar: Calendar { Calendar.current }
    
    private var dayWorkouts: [Workout] {
        workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(dayWorkouts.count) workout\(dayWorkouts.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    if dayWorkouts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("No workouts found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Instruction text
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("Tap any workout to edit or delete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        
                        // Workout cards
                        ForEach(dayWorkouts) { workout in
                            WorkoutRowCard(workout: workout) {
                                selectedWorkout = workout
                            } onDelete: {
                                workoutToDelete = workout
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
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
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
            .alert("Delete Workout", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    workoutToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete {
                        deleteWorkout(workout)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error.localizedDescription)")
        }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Workout Row Card

struct WorkoutRowCard: View {
    let workout: Workout
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.date.formatted(.dateTime.hour().minute()))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 70, alignment: .leading)
                
                // Sets, Reps, and Difficulty
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                        Text("\(workout.sets)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.arms.open")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(workout.repsCompleted)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .font(.caption2)
                            .foregroundStyle(difficultyColor)
                        Text(difficultyLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit/Delete indicators
                HStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue.opacity(0.6))
                    
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onDelete()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 16)
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
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
    
    private var difficultyColor: Color {
        switch workout.difficultyRating {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
    
    private var difficultyLabel: String {
        switch workout.difficultyRating {
        case 1: return "Easy"
        case 2: return "Light"
        case 3: return "Medium"
        case 4: return "Hard"
        case 5: return "Brutal"
        default: return ""
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    
    let calendar = Calendar.current
    let today = Date()
    
    let workouts = [
        Workout(
            date: calendar.date(byAdding: .hour, value: -2, to: today)!,
            duration: 120,
            repsCompleted: 50,
            difficultyRating: 3,
            notes: "Morning workout"
        ),
        Workout(
            date: today,
            duration: 180,
            repsCompleted: 75,
            difficultyRating: 4,
            notes: "Evening session"
        )
    ]
    
    for workout in workouts {
        container.mainContext.insert(workout)
    }
    
    return DayWorkoutsView(date: today, workouts: workouts)
        .modelContainer(container)
}

