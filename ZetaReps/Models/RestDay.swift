//
//  RestDay.swift
//  ZetaReps
//

import Foundation
import SwiftData

@Model
final class RestDay {
    @Attribute(.unique) var id: UUID
    var date: Date
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.notes = notes
    }
}
