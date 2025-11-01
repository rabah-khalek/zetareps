//
//  Workout.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var date: Date
    var duration: TimeInterval // in seconds
    var sets: Int = 1 // number of sets completed (default 1 for backward compatibility)
    var repsCompleted: Int // total reps across all sets
    var difficultyRating: Int // 1-5 scale
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval = 0,
        sets: Int = 1,
        repsCompleted: Int = 0,
        difficultyRating: Int = 3,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.sets = sets
        self.repsCompleted = repsCompleted
        self.difficultyRating = difficultyRating
        self.notes = notes
    }
    
    // Computed property for average reps per set
    var averageRepsPerSet: Double {
        guard sets > 0 else { return 0 }
        return Double(repsCompleted) / Double(sets)
    }

    // Computed property for formatted duration
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
