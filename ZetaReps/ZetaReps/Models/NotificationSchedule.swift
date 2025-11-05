//
//  NotificationSchedule.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation

// MARK: - Schedule Types

enum ScheduleType: String, Codable, CaseIterable {
    case hourly = "Hourly"
    case daily = "Daily"
    case interval = "Every X Hours"
    case twiceDaily = "Twice Daily"
    case custom = "Custom Times"

    var description: String {
        rawValue
    }
}

// MARK: - Time Components

struct TimeComponents: Codable, Hashable {
    var hour: Int
    var minute: Int

    var formatted: String {
        String(format: "%d:%02d %@",
               hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour),
               minute,
               hour >= 12 ? "PM" : "AM")
    }

    static func from(date: Date) -> TimeComponents {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return TimeComponents(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
}

// MARK: - Weekday Enum

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - Schedule Rule

struct ScheduleRule: Codable, Identifiable {
    let id: UUID
    var name: String
    var isEnabled: Bool

    // Schedule type
    var scheduleType: ScheduleType

    // Time range (for interval-based schedules)
    var startTime: TimeComponents
    var endTime: TimeComponents

    // Day selection
    var activeDays: Set<Int> // Weekday raw values (1=Sunday, 2=Monday, etc.)

    // Interval settings (for "every X hours")
    var intervalHours: Int?

    // Custom times (for specific times)
    var customTimes: [TimeComponents]

    // Date range (optional)
    var startDate: Date?
    var endDate: Date?

    init(id: UUID = UUID(),
         name: String = "My Schedule",
         isEnabled: Bool = true,
         scheduleType: ScheduleType = .daily,
         startTime: TimeComponents = TimeComponents(hour: 8, minute: 0),
         endTime: TimeComponents = TimeComponents(hour: 22, minute: 0),
         activeDays: Set<Int> = [2, 3, 4, 5, 6], // Mon-Fri
         intervalHours: Int? = nil,
         customTimes: [TimeComponents] = [],
         startDate: Date? = nil,
         endDate: Date? = nil) {

        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.scheduleType = scheduleType
        self.startTime = startTime
        self.endTime = endTime
        self.activeDays = activeDays
        self.intervalHours = intervalHours
        self.customTimes = customTimes
        self.startDate = startDate
        self.endDate = endDate
    }

    // MARK: - Computed Properties

    var estimatedNotificationCount: Int {
        switch scheduleType {
        case .daily:
            return activeDays.count

        case .hourly:
            let hoursInRange = max(endTime.hour - startTime.hour, 1)
            let slotsPerDay = hoursInRange + 1 // +1 to include end hour
            return slotsPerDay * activeDays.count

        case .twiceDaily:
            return 2 * activeDays.count

        case .interval:
            guard let interval = intervalHours, interval > 0 else { return 0 }
            let hoursInRange = endTime.hour - startTime.hour
            let slotsPerDay = max(hoursInRange / interval, 1)
            return slotsPerDay * activeDays.count

        case .custom:
            return customTimes.count * activeDays.count
        }
    }

    var activeDaysDescription: String {
        let sortedDays = activeDays.sorted()

        if sortedDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else if sortedDays == [1, 7] {
            return "Weekends"
        } else if sortedDays.count == 7 {
            return "Every day"
        } else {
            return sortedDays
                .compactMap { Weekday(rawValue: $0) }
                .map { $0.shortName }
                .joined(separator: ", ")
        }
    }

    var scheduleDescription: String {
        switch scheduleType {
        case .daily:
            return "Daily at \(customTimes.first?.formatted ?? "9:00 AM")"

        case .hourly:
            return "Every hour, \(startTime.formatted) - \(endTime.formatted)"

        case .twiceDaily:
            if customTimes.count >= 2 {
                return "Twice daily (\(customTimes[0].formatted), \(customTimes[1].formatted))"
            } else {
                return "Twice daily (9:00 AM, 6:00 PM)"
            }

        case .interval:
            guard let hours = intervalHours else { return "Interval" }
            return "Every \(hours) hour\(hours > 1 ? "s" : ""), \(startTime.formatted) - \(endTime.formatted)"

        case .custom:
            if customTimes.isEmpty {
                return "Custom times"
            } else if customTimes.count == 1 {
                return "Daily at \(customTimes[0].formatted)"
            } else {
                return "\(customTimes.count) times per day"
            }
        }
    }

    // MARK: - Helper Methods

    func isActive(on date: Date) -> Bool {
        guard isEnabled else { return false }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // Check if day is active
        guard activeDays.contains(weekday) else { return false }

        // Check date range if specified
        if let start = startDate, date < start {
            return false
        }

        if let end = endDate, date > end {
            return false
        }

        return true
    }

    func generateTimeSlots() -> [(hour: Int, minute: Int)] {
        var slots: [(Int, Int)] = []

        switch scheduleType {
        case .daily:
            if let time = customTimes.first {
                slots.append((time.hour, time.minute))
            } else {
                slots.append((9, 0)) // Default 9 AM
            }

        case .hourly:
            // Generate hourly slots between startTime and endTime
            var currentHour = startTime.hour
            while currentHour <= endTime.hour {
                slots.append((currentHour, startTime.minute))
                currentHour += 1
            }

        case .twiceDaily:
            // Use customTimes if available, otherwise default to 9 AM and 6 PM
            if customTimes.count >= 2 {
                slots.append((customTimes[0].hour, customTimes[0].minute))
                slots.append((customTimes[1].hour, customTimes[1].minute))
            } else {
                slots.append((9, 0))  // 9 AM
                slots.append((18, 0)) // 6 PM
            }

        case .interval:
            guard let interval = intervalHours, interval > 0 else { break }
            var currentHour = startTime.hour

            while currentHour < endTime.hour {
                slots.append((currentHour, startTime.minute))
                currentHour += interval
            }

        case .custom:
            slots = customTimes.map { ($0.hour, $0.minute) }
        }

        return slots
    }
}

// MARK: - Predefined Schedules

extension ScheduleRule {
    static let presets: [ScheduleRule] = [
        ScheduleRule(
            name: "Workday Hourly",
            scheduleType: .hourly,
            activeDays: [2, 3, 4, 5, 6] // Mon-Fri
        ),
        ScheduleRule(
            name: "Every 2 Hours",
            scheduleType: .interval,
            startTime: TimeComponents(hour: 8, minute: 0),
            endTime: TimeComponents(hour: 22, minute: 0),
            activeDays: [2, 3, 4, 5, 6],
            intervalHours: 2
        ),
        ScheduleRule(
            name: "Morning & Evening",
            scheduleType: .twiceDaily,
            activeDays: [1, 2, 3, 4, 5, 6, 7]
        ),
        ScheduleRule(
            name: "Daily Reminder",
            scheduleType: .daily,
            activeDays: [1, 2, 3, 4, 5, 6, 7],
            customTimes: [TimeComponents(hour: 9, minute: 0)]
        )
    ]
}
