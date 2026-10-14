//
//  ZetaRepsApp.swift
//  ZetaReps
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ZetaRepsApp: App {
    init() {
        // Set notification delegate first
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Request notification permission on app launch (will only prompt if not determined)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Error requesting notification permission: \(error.localizedDescription)")
                    } else if granted {
                        print("Notification permission granted")
                        DispatchQueue.main.async {
                            NotificationManager.shared.scheduleReminders()
                        }
                    } else {
                        print("Notification permission denied")
                    }
                }
            } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                // Already authorized, schedule reminders
                print("Notifications already authorized, scheduling reminders...")
                DispatchQueue.main.async {
                    NotificationManager.shared.scheduleReminders()
                }
            } else {
                print("Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Workout.self, RestDay.self])
    }
}
