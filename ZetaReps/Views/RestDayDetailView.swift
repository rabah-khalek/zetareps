//
//  RestDayDetailView.swift
//  ZetaReps
//

import SwiftUI
import SwiftData

struct RestDayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let restDay: RestDay

    @State private var isEditing = false
    @State private var editedNotes: String
    @State private var editedDate: Date

    @State private var showingDeleteAlert = false

    init(restDay: RestDay) {
        self.restDay = restDay
        _editedNotes = State(initialValue: restDay.notes)
        _editedDate = State(initialValue: restDay.date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    if !isEditing {
                        headerCard
                    }

                    // Editable Fields
                    if isEditing {
                        editingForm
                    } else {
                        detailsCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Rest Day" : "Rest Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    if !isEditing {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .alert("Remove Rest Day", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    deleteRestDay()
                }
            } message: {
                Text("Are you sure you want to remove this rest day?")
            }
        }
    }

    // MARK: - Header Card (Display Mode)

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top)

            Text("Rest Day")
                .font(.title2)
                .fontWeight(.semibold)

            // Date
            VStack(spacing: 4) {
                Text(restDay.date.formatted(.dateTime.month(.wide).day().year()))
                    .font(.headline)

                Text(restDay.date.formatted(.dateTime.weekday(.wide)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.indigo.opacity(0.4), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
    }

    // MARK: - Details Card (Display Mode)

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !restDay.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(.purple)
                        Text("Notes")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    Text(restDay.notes)
                        .font(.body)
                }
            } else {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("Recovery day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Rest days are important for muscle recovery and preventing burnout.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
    }

    // MARK: - Editing Form

    private var editingForm: some View {
        VStack(spacing: 20) {
            // Date picker
            VStack(alignment: .leading, spacing: 8) {
                Label("Date", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                DatePicker("", selection: $editedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )

            // Notes field
            VStack(alignment: .leading, spacing: 8) {
                Label("Notes", systemImage: "note.text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Add notes about this rest day...", text: $editedNotes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Helper Methods

    private func saveChanges() {
        // Update rest day properties
        restDay.date = editedDate
        restDay.notes = editedNotes

        // Save to context
        do {
            try modelContext.save()
        } catch {
            print("Error saving rest day: \(error.localizedDescription)")
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        isEditing = false
    }

    private func deleteRestDay() {
        modelContext.delete(restDay)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting rest day: \(error.localizedDescription)")
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RestDay.self, configurations: config)

    let restDay = RestDay(
        date: Date(),
        notes: "Feeling a bit sore from yesterday's workout"
    )
    container.mainContext.insert(restDay)

    return RestDayDetailView(restDay: restDay)
        .modelContainer(container)
}
