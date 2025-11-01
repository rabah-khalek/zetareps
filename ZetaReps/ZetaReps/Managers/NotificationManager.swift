//
//  NotificationManager.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation
import UserNotifications
import Combine
import SwiftData
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkPermissionStatus()
    }

    // MARK: - Permission Handling

    func checkPermissionStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionStatus = settings.authorizationStatus
            }
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.checkPermissionStatus()
                completion(granted)
            }

            if granted {
                self?.scheduleReminders()
            }
        }
    }

    // MARK: - Scheduling Reminders

    func scheduleReminders() {
        // Check permission first
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                print("⚠️ Notification permission not granted. Status: \(settings.authorizationStatus.rawValue)")
                return
            }
            
            // Check if free user has reached the 100 pushup limit
            if self.shouldStopRemindersDueToLimit() {
                print("⛔ Free user limit reached (100 pushups). Stopping all reminders.")
                self.notificationCenter.removeAllPendingNotificationRequests()
                return
            }
            
            // Remove all pending notifications first
            self.notificationCenter.removeAllPendingNotificationRequests()

            // Get app settings
            let appSettings = AppSettings.shared

            guard appSettings.notificationsEnabled else {
                print("⚠️ Notifications are disabled in settings")
                return
            }

            // Priority: Custom times (if explicitly selected) > Schedule rule > Legacy frequency
            if appSettings.reminderFrequency == .custom && !appSettings.customTimes.isEmpty {
                // User explicitly selected custom times - use them
                print("📅 Using custom reminder times")
                self.scheduleCustomReminders(times: appSettings.customTimes, excludeWeekends: appSettings.excludeWeekends)
            } else if let scheduleRule = appSettings.currentScheduleRule, scheduleRule.isEnabled {
                // Schedule rule takes priority over legacy frequency settings
                print("📅 Using schedule rule system")
                self.scheduleFromRule(scheduleRule)
            } else {
                // Fallback to legacy frequency system
                switch appSettings.reminderFrequency {
                case .hourly:
                    self.scheduleHourlyReminders(excludeWeekends: appSettings.excludeWeekends)
                case .twiceDaily:
                    self.scheduleTwiceDailyReminders(excludeWeekends: appSettings.excludeWeekends)
                case .daily:
                    self.scheduleDailyReminders(excludeWeekends: appSettings.excludeWeekends)
                case .custom:
                    // Custom times selected but empty - schedule with defaults or skip
                    if appSettings.customTimes.isEmpty {
                        print("⚠️ Custom times selected but no times configured")
                    } else {
                        self.scheduleCustomReminders(times: appSettings.customTimes, excludeWeekends: appSettings.excludeWeekends)
                    }
                case .disabled:
                    print("⚠️ Notification frequency is disabled")
                    break
                }
            }
        }
    }

    // MARK: - Schedule from Rule

    /// Schedule notifications based on a ScheduleRule
    func scheduleFromRule(_ rule: ScheduleRule) {
        let content = createNotificationContent()
        let timeSlots = rule.generateTimeSlots()

        print("📅 Scheduling notifications from rule: \(rule.name)")
        print("   Schedule type: \(rule.scheduleType)")
        print("   Active days: \(rule.activeDays.sorted())")
        print("   Time slots: \(timeSlots.count)")

        var notificationCount = 0

        for (hour, minute) in timeSlots {
            for weekday in rule.activeDays {
                // Check 64 notification limit
                guard notificationCount < 64 else {
                    print("⚠️ Warning: Reached iOS 64 notification limit. \(timeSlots.count * rule.activeDays.count - notificationCount) notifications were not scheduled.")
                    return
                }

                var components = DateComponents()
                components.weekday = weekday
                components.hour = hour
                components.minute = minute

                let identifier = "rule-\(rule.id.uuidString)-\(weekday)-\(hour)-\(minute)"

                scheduleNotification(
                    content: content,
                    dateComponents: components,
                    identifier: identifier
                )

                notificationCount += 1
            }
        }

        print("✅ Scheduled \(notificationCount) notifications from rule: \(rule.name)")
        
        // Verify scheduled notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.getPendingNotificationCount { count in
                print("📊 Total pending notifications: \(count)")
            }
            self.listPendingNotifications()
        }
    }

    private func scheduleHourlyReminders(excludeWeekends: Bool) {
        // Schedule hourly reminders from 8 AM to 8 PM
        for hour in 8...20 {
            let content = createNotificationContent()

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            if excludeWeekends {
                // Schedule for each weekday
                for weekday in 2...6 { // Monday = 2, Friday = 6
                    var components = dateComponents
                    components.weekday = weekday
                    scheduleNotification(content: content, dateComponents: components, identifier: "hourly-\(weekday)-\(hour)")
                }
            } else {
                // Schedule for every day
                scheduleNotification(content: content, dateComponents: dateComponents, identifier: "hourly-\(hour)")
            }
        }
    }

    private func scheduleTwiceDailyReminders(excludeWeekends: Bool) {
        let times = [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 18, minute: 0)
        ]
        scheduleCustomReminders(times: times, excludeWeekends: excludeWeekends)
    }

    private func scheduleDailyReminders(excludeWeekends: Bool) {
        let content = createNotificationContent()

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        if excludeWeekends {
            // Schedule for each weekday
            for weekday in 2...6 { // Monday = 2, Friday = 6
                var components = dateComponents
                components.weekday = weekday
                scheduleNotification(content: content, dateComponents: components, identifier: "daily-\(weekday)")
            }
        } else {
            // Schedule for every day
            scheduleNotification(content: content, dateComponents: dateComponents, identifier: "daily")
        }
    }

    private func scheduleCustomReminders(times: [DateComponents], excludeWeekends: Bool) {
        let content = createNotificationContent()
        
        print("📅 Scheduling \(times.count) custom reminder time(s), excludeWeekends: \(excludeWeekends)")

        for (index, time) in times.enumerated() {
            // Ensure hour and minute are set
            guard let hour = time.hour, let minute = time.minute else {
                print("⚠️ Warning: Custom time at index \(index) is missing hour or minute. Skipping.")
                continue
            }
            
            print("   Custom time \(index + 1): \(hour):\(String(format: "%02d", minute))")
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            if excludeWeekends {
                // Schedule for each weekday
                for weekday in 2...6 { // Monday = 2, Friday = 6
                    var components = dateComponents
                    components.weekday = weekday
                    let identifier = "custom-\(index)-\(weekday)"
                    print("   Scheduling for weekday \(weekday) with identifier: \(identifier)")
                    scheduleNotification(
                        content: content,
                        dateComponents: components,
                        identifier: identifier
                    )
                }
            } else {
                // Schedule for every day
                let identifier = "custom-\(index)"
                print("   Scheduling for every day with identifier: \(identifier)")
                scheduleNotification(
                    content: content,
                    dateComponents: dateComponents,
                    identifier: identifier
                )
            }
        }
        
        // Verify scheduled notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.getPendingNotificationCount { count in
                print("📊 Total pending notifications after scheduling custom times: \(count)")
            }
        }
    }

    private func scheduleNotification(content: UNNotificationContent, dateComponents: DateComponents, identifier: String) {
        // UNCalendarNotificationTrigger with repeats: true will fire at the next matching date/time
        // If the time has passed today, it will fire on the next occurrence
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification \(identifier): \(error.localizedDescription)")
            } else {
                // Calculate when this will fire next
                if let nextDate = Calendar.current.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    print("✅ Scheduled notification: \(identifier)")
                    print("   Next fire: \(formatter.string(from: nextDate))")
                } else {
                    print("✅ Scheduled notification: \(identifier) - \(dateComponents)")
                }
            }
        }
    }

    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // Try to get smart notification based on user data
        if let smartMessage = getSmartNotificationMessage() {
            content.title = smartMessage.title
            content.body = smartMessage.body
        } else {
            // Fallback to simple motivational message
            content.title = "Workout Reminder"
            content.body = "No Pain No Gain!"
        }

        content.sound = .default
        // Badge count managed via UNUserNotificationCenter.setBadgeCount (iOS 17+)
        content.categoryIdentifier = "PUSHUP_REMINDER"
        
        // Ensure notification shows as alert (banner) even when app is in foreground
        // This is handled by the delegate's willPresent method

        return content
    }

    // MARK: - Smart Notifications

    /// Generate context-aware notification message based on user's workout history
    private func getSmartNotificationMessage() -> (title: String, body: String)? {
        // This will be called at notification schedule time, not delivery time
        // So we cache the user's current state
        let (title, body) = determineSmartMessage()
        return (title, body)
    }

    /// Determine smart notification message based on current workout data
    private func determineSmartMessage() -> (title: String, body: String) {
        // Get workout data from SwiftData
        guard let container = try? ModelContainer(for: Workout.self, RestDay.self),
              let workouts = try? container.mainContext.fetch(FetchDescriptor<Workout>()),
              let restDays = try? container.mainContext.fetch(FetchDescriptor<RestDay>()) else {
            return ("Workout Reminder", "No Pain No Gain!")
        }

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Check if user worked out today
        let todayWorkouts = workouts.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let hasWorkedOutToday = !todayWorkouts.isEmpty

        // Get last workout date
        let lastWorkout = workouts.max(by: { $0.date < $1.date })
        let daysSinceLastWorkout = lastWorkout.map {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.date), to: today).day ?? 0
        } ?? 999

        // Check if today is a rest day
        let isRestDay = restDays.contains { calendar.isDate($0.date, inSameDayAs: today) }

        // Don't send notifications on rest days
        if isRestDay {
            return ("", "") // Empty notification will be skipped
        }

        // Don't spam if they already worked out today
        if hasWorkedOutToday {
            // Only send encouraging message if it's been less than 4 hours since last workout
            if let lastTodayWorkout = todayWorkouts.max(by: { $0.date < $1.date }),
               now.timeIntervalSince(lastTodayWorkout.date) < 4 * 3600 {
                return ("", "") // Skip notification
            }
        }

        // Smart messages based on context - always use "No Pain No Gain!" as main message
        if daysSinceLastWorkout >= 3 {
            // Coming back after break
            return ("Workout Reminder", "No Pain No Gain! Ready to start fresh?")
        } else {
            // Normal reminder
            let hour = calendar.component(.hour, from: now)
            if hour < 12 {
                return ("Workout Reminder", "No Pain No Gain!")
            } else if hour < 17 {
                return ("Workout Reminder", "No Pain No Gain!")
            } else {
                return ("Workout Reminder", "No Pain No Gain!")
            }
        }
    }

    // MARK: - Free Limit Check
    
    /// Check if reminders should be stopped due to free user limit
    private func shouldStopRemindersDueToLimit() -> Bool {
        // Check subscription status
        guard !SubscriptionManager.shared.isSubscribed else {
            return false // Premium users don't have limits
        }
        
        // Get workout data and calculate total pushups
        guard let container = try? ModelContainer(for: Workout.self, RestDay.self),
              let workouts = try? container.mainContext.fetch(FetchDescriptor<Workout>()) else {
            return false // Can't determine limit, allow notifications
        }
        
        let totalPushups = workouts.reduce(0) { $0 + $1.repsCompleted }
        
        // Stop reminders if limit reached
        return totalPushups >= 100
    }
    
    // MARK: - Debug Helper

    func getPendingNotificationCount(completion: @escaping (Int) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.count)
            }
        }
    }
    
    /// Schedule a test notification with specified interval (for simulator testing)
    func scheduleTestNotification(interval: TimeInterval = 5) {
        // Check permission first
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                print("⚠️ Cannot schedule test notification - permission not granted. Status: \(settings.authorizationStatus.rawValue)")
                return
            }
            
            // Use the actual notification content generator to show real reminder message
            let content = self.createNotificationContent()
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: "test-notification-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
            
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling test notification: \(error.localizedDescription)")
                } else {
                    print("✅ Test notification scheduled for \(Int(interval)) seconds from now")
                    print("   💡 Tip: Put the app in background or lock the simulator to see the banner!")
                }
            }
        }
    }
    
    /// Schedule a notification for the next minute (for immediate testing)
    func scheduleImmediateTestNotification() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                print("⚠️ Cannot schedule immediate test - permission not granted")
                return
            }
            
            // Use the actual notification content generator to show real reminder message
            let content = self.createNotificationContent()
            
            // Schedule for 10 seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: "immediate-test-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
            
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Error: \(error.localizedDescription)")
                } else {
                    print("✅ Immediate test notification scheduled for 10 seconds from now")
                    print("   💡 Tip: Put the app in background or lock the simulator to see it!")
                }
            }
        }
    }
    
    /// List all pending notifications (for debugging)
    func listPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("\n📋 Pending Notifications (\(requests.count)):")
            for request in requests.prefix(10) {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  - \(request.identifier)")
                    print("    Components: \(trigger.dateComponents)")
                }
            }
            if requests.count > 10 {
                print("  ... and \(requests.count - 10) more")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound when app is in foreground
        // .list ensures it appears in notification center even if banner is dismissed
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Can handle notification actions here in the future
        completionHandler()
    }
}
