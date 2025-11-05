//
//  ScheduleBuilderView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI

struct ScheduleBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: AppSettings

    @State private var scheduleType: ScheduleType = .interval
    @State private var intervalHours: Int = 2
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var morningTime = Date()
    @State private var eveningTime = Date()
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri
    @State private var customTimes: [Date] = []
    @State private var showingAddTime = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Schedule Type Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.badge")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Reminder Pattern")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        Picker("Schedule Type", selection: $scheduleType) {
                            ForEach(ScheduleType.allCases, id: \.self) { type in
                                Text(type.description).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text(scheduleTypeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

                    // Time Range Card (for hourly)
                    if scheduleType == .hourly {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Active Hours")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()
                            }

                            DatePicker("Start Time",
                                     selection: $startTime,
                                     displayedComponents: .hourAndMinute)

                            DatePicker("End Time",
                                     selection: $endTime,
                                     displayedComponents: .hourAndMinute)

                            Text("Reminders will be sent every hour within this time range")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

                    // Time Range Card (for interval-based)
                    if scheduleType == .interval {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Active Hours")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()
                            }

                            DatePicker("Start Time",
                                     selection: $startTime,
                                     displayedComponents: .hourAndMinute)

                            DatePicker("End Time",
                                     selection: $endTime,
                                     displayedComponents: .hourAndMinute)

                            Stepper("Every \(intervalHours) hour\(intervalHours > 1 ? "s" : "")",
                                   value: $intervalHours,
                                   in: 1...12)
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

                    // Custom Times Card
                    if scheduleType == .custom {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Reminder Times")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            
                            ForEach(customTimes.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)

                                    Text(customTimes[index].formatted(date: .omitted, time: .shortened))
                                        .font(.body)

                                    Spacer()

                                    Button(role: .destructive) {
                                        customTimes.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }

                            Button(action: { showingAddTime = true }) {
                                Label("Add Time", systemImage: "plus.circle.fill")
                            }
                            
                            Text("Tap to add specific times for reminders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

                    // Daily Time Picker Card
                    if scheduleType == .daily {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "alarm")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Daily Time")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()
                            }

                            DatePicker("Reminder Time",
                                     selection: $startTime,
                                     displayedComponents: .hourAndMinute)

                            Text("Set the time for your daily reminder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

                    // Twice Daily Time Pickers Card
                    if scheduleType == .twiceDaily {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sunrise.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .yellow],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Reminder Times")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()
                            }

                            DatePicker("Morning Time",
                                     selection: $morningTime,
                                     displayedComponents: .hourAndMinute)

                            DatePicker("Evening Time",
                                     selection: $eveningTime,
                                     displayedComponents: .hourAndMinute)

                            Text("Set morning and evening reminder times")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

                    // Day Selection Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Active Days")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        ForEach(Weekday.allCases) { day in
                            Toggle(isOn: binding(for: day)) {
                                HStack {
                                    Text(day.name)
                                    Spacer()
                                    Text(day.shortName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
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

                    // Preview Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "eye.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Preview")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.orange)
                                Text("Estimated Notifications")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(estimatedCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }

                            if estimatedCount > 64 {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                        .symbolEffect(.pulse)

                                    Text("iOS limits apps to 64 pending notifications. Your schedule exceeds this limit. Consider reducing the frequency or active days.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 4)
                            }

                            Text(schedulePreview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
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

                    // Quick Presets Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Quick Presets")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        ForEach(ScheduleRule.presets) { preset in
                            Button(action: {
                                applyPreset(preset)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preset.name)
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        Text(preset.scheduleDescription)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
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
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schedule Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        saveSchedule()
                    }
                    .disabled(estimatedCount > 64 || selectedDays.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddTime) {
                TimePickerSheet(customTimes: $customTimes)
            }
            .task {
                loadCurrentSchedule()
            }
        }
    }

    // MARK: - Computed Properties

    private var estimatedCount: Int {
        let timeSlots: Int
        let calendar = Calendar.current

        switch scheduleType {
        case .daily:
            timeSlots = 1
        case .hourly:
            let startHour = calendar.component(.hour, from: startTime)
            let endHour = calendar.component(.hour, from: endTime)
            let hoursInRange = max(endHour - startHour, 1)
            timeSlots = hoursInRange + 1 // +1 to include the end hour
        case .twiceDaily:
            timeSlots = 2
        case .interval:
            let startHour = calendar.component(.hour, from: startTime)
            let endHour = calendar.component(.hour, from: endTime)
            let hoursInRange = max(endHour - startHour, 1)
            timeSlots = max(hoursInRange / intervalHours, 1)
        case .custom:
            timeSlots = customTimes.count
        }

        return timeSlots * selectedDays.count
    }

    private var scheduleTypeDescription: String {
        switch scheduleType {
        case .daily:
            return "One reminder per day at a specific time"
        case .hourly:
            return "Reminders every hour during your active hours"
        case .twiceDaily:
            return "Two reminders per day (morning and evening)"
        case .interval:
            return "Reminders at regular intervals during active hours"
        case .custom:
            return "Reminders at specific times you choose"
        }
    }

    private var schedulePreview: String {
        let daysText = activeDaysText
        let timesText: String

        switch scheduleType {
        case .daily:
            let time = startTime.formatted(date: .omitted, time: .shortened)
            timesText = "once daily at \(time)"
        case .hourly:
            let start = startTime.formatted(date: .omitted, time: .shortened)
            let end = endTime.formatted(date: .omitted, time: .shortened)
            timesText = "every hour, \(start) - \(end)"
        case .twiceDaily:
            let morning = morningTime.formatted(date: .omitted, time: .shortened)
            let evening = eveningTime.formatted(date: .omitted, time: .shortened)
            timesText = "at \(morning) and \(evening)"
        case .interval:
            let start = startTime.formatted(date: .omitted, time: .shortened)
            let end = endTime.formatted(date: .omitted, time: .shortened)
            timesText = "every \(intervalHours)h, \(start) - \(end)"
        case .custom:
            timesText = customTimes.isEmpty ? "no times set" :
                customTimes.map { $0.formatted(date: .omitted, time: .shortened) }.joined(separator: ", ")
        }

        return "Reminders \(timesText) on \(daysText)"
    }

    private var activeDaysText: String {
        let sortedDays = selectedDays.sorted()

        if sortedDays == [2, 3, 4, 5, 6] {
            return "weekdays"
        } else if sortedDays == [1, 7] {
            return "weekends"
        } else if sortedDays.count == 7 {
            return "every day"
        } else {
            return sortedDays
                .compactMap { Weekday(rawValue: $0) }
                .map { $0.shortName }
                .joined(separator: ", ")
        }
    }

    // MARK: - Helper Methods

    private func binding(for day: Weekday) -> Binding<Bool> {
        Binding(
            get: { selectedDays.contains(day.rawValue) },
            set: { isSelected in
                if isSelected {
                    selectedDays.insert(day.rawValue)
                } else {
                    selectedDays.remove(day.rawValue)
                }
            }
        )
    }

    private func loadCurrentSchedule() {
        let calendar = Calendar.current

        if let rule = settings.currentScheduleRule {
            scheduleType = rule.scheduleType
            selectedDays = rule.activeDays

            if let interval = rule.intervalHours {
                intervalHours = interval
            }

            // Convert TimeComponents to Date for pickers
            startTime = calendar.date(from: DateComponents(hour: rule.startTime.hour, minute: rule.startTime.minute)) ?? Date()
            endTime = calendar.date(from: DateComponents(hour: rule.endTime.hour, minute: rule.endTime.minute)) ?? Date()

            // Convert custom times
            customTimes = rule.customTimes.compactMap {
                calendar.date(from: DateComponents(hour: $0.hour, minute: $0.minute))
            }

            // Load specific times based on schedule type
            switch rule.scheduleType {
            case .daily:
                // For daily, use the first custom time or default to 9 AM
                if let firstTime = rule.customTimes.first {
                    startTime = calendar.date(from: DateComponents(hour: firstTime.hour, minute: firstTime.minute)) ?? Date()
                } else {
                    startTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
                }

            case .twiceDaily:
                // For twice daily, use first two custom times or default to 9 AM and 6 PM
                if rule.customTimes.count >= 2 {
                    morningTime = calendar.date(from: DateComponents(hour: rule.customTimes[0].hour, minute: rule.customTimes[0].minute)) ?? Date()
                    eveningTime = calendar.date(from: DateComponents(hour: rule.customTimes[1].hour, minute: rule.customTimes[1].minute)) ?? Date()
                } else {
                    morningTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
                    eveningTime = calendar.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
                }

            default:
                break
            }
        } else {
            // Set defaults
            startTime = calendar.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
            endTime = calendar.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
            morningTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
            eveningTime = calendar.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        }
    }

    private func saveSchedule() {
        let startComponents = TimeComponents.from(date: startTime)
        let endComponents = TimeComponents.from(date: endTime)

        var customTimeComponents: [TimeComponents]

        // Handle custom times based on schedule type
        switch scheduleType {
        case .daily:
            // For daily, save the single time in customTimes
            customTimeComponents = [TimeComponents.from(date: startTime)]

        case .twiceDaily:
            // For twice daily, save morning and evening times
            customTimeComponents = [
                TimeComponents.from(date: morningTime),
                TimeComponents.from(date: eveningTime)
            ].sorted { time1, time2 in
                // Sort by hour, then minute
                if time1.hour != time2.hour {
                    return time1.hour < time2.hour
                }
                return time1.minute < time2.minute
            }

        case .custom:
            // For custom, use the customTimes array
            customTimeComponents = customTimes.map { TimeComponents.from(date: $0) }

        default:
            // For interval and hourly, use empty array
            customTimeComponents = []
        }

        let rule = ScheduleRule(
            name: "My Schedule",
            isEnabled: true,
            scheduleType: scheduleType,
            startTime: startComponents,
            endTime: endComponents,
            activeDays: selectedDays,
            intervalHours: scheduleType == .interval ? intervalHours : nil,
            customTimes: customTimeComponents
        )

        settings.currentScheduleRule = rule
        settings.notificationsEnabled = true

        // Request permission if not already granted, then schedule
        NotificationManager.shared.requestPermission { granted in
            if granted {
                NotificationManager.shared.scheduleReminders()
            } else {
                print("⚠️ Notification permission denied")
            }
        }

        // Post notification to refresh countdown timer
        NotificationCenter.default.post(name: NSNotification.Name("ScheduleUpdated"), object: nil)

        dismiss()
    }

    private func applyPreset(_ preset: ScheduleRule) {
        scheduleType = preset.scheduleType
        selectedDays = preset.activeDays

        if let interval = preset.intervalHours {
            intervalHours = interval
        }

        let calendar = Calendar.current
        startTime = calendar.date(from: DateComponents(hour: preset.startTime.hour, minute: preset.startTime.minute)) ?? Date()
        endTime = calendar.date(from: DateComponents(hour: preset.endTime.hour, minute: preset.endTime.minute)) ?? Date()

        customTimes = preset.customTimes.compactMap {
            calendar.date(from: DateComponents(hour: $0.hour, minute: $0.minute))
        }

        // Load specific times based on schedule type
        switch preset.scheduleType {
        case .daily:
            if let firstTime = preset.customTimes.first {
                startTime = calendar.date(from: DateComponents(hour: firstTime.hour, minute: firstTime.minute)) ?? Date()
            }

        case .twiceDaily:
            if preset.customTimes.count >= 2 {
                morningTime = calendar.date(from: DateComponents(hour: preset.customTimes[0].hour, minute: preset.customTimes[0].minute)) ?? Date()
                eveningTime = calendar.date(from: DateComponents(hour: preset.customTimes[1].hour, minute: preset.customTimes[1].minute)) ?? Date()
            }

        default:
            break
        }
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var customTimes: [Date]
    @State private var selectedTime = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Select Time",
                         selection: $selectedTime,
                         displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    customTimes.append(selectedTime)
                    customTimes.sort()
                    dismiss()
                }) {
                    Text("Add Time")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Add Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
            ScheduleBuilderView(settings: AppSettings.shared)
}
