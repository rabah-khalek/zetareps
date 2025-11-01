//
//  SettingsView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import UserNotifications

enum ColorSchemeOption: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemeOption = .dark
    @State private var showingPermissionAlert = false
    @State private var pendingNotificationCount = 0
    @State private var showingCustomTimePicker = false
    @State private var newCustomTime = DateComponents(hour: 12, minute: 0)
    @State private var showingPaywall = false
    @State private var showingWorkout = false
    @State private var isRestoring = false
    @State private var showingScheduleBuilder = false
    @State private var showingRecommendedStandardsInfo = false
    
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    private var currentColorScheme: ColorScheme? {
        colorSchemePreference.colorScheme
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                            Text("Appearance")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.bottom, 4)
                        
                        HStack(spacing: 8) {
                            ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                                AppearanceOptionButton(
                                    option: option,
                                    isSelected: colorSchemePreference == option,
                                    iconName: iconName(for: option)
                                ) {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        colorSchemePreference = option
                                    }
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
                                        colors: [.purple.opacity(0.3), .purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .purple.opacity(0.15), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Workout Targets Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text("Workout Targets")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Info button for recommended standards (always visible)
                            Button(action: {
                                showingRecommendedStandardsInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.bottom, 4)
                        
                        // Toggle: Use Recommended Standards
                        Toggle("Use Recommended Standards", isOn: $settings.useRecommendedStandards)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if settings.useRecommendedStandards {
                            // Recommended Standards Mode
                            VStack(spacing: 16) {
                                // Fitness Level Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fitness Level")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Picker("Fitness Level", selection: $settings.fitnessLevel) {
                                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                                            Text(level.displayName).tag(level)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                    
                                    // Show description of selected level
                                    Text(settings.fitnessLevel.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Display current recommended targets
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Per Workout:")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("\(settings.effectiveTargetSets) sets × \(settings.effectiveTargetRepsPerSet) reps")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                        }
                                        
                                        HStack {
                                            Text("Rest Time:")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("\(settings.effectiveRestTimeSeconds)s between sets")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                        }
                                        
                                        HStack {
                                            Text("Weekly Schedule:")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("\(settings.effectiveTargetDays) days/week")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                    .padding(.top, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Optional: Age selector (can be added later if needed)
                                // For now, keeping it simple as requested
                            }
                            .padding(.vertical, 8)
                        } else {
                            // Custom Targets Mode
                            VStack(spacing: 16) {
                                Stepper("Target Sets: \(settings.targetSets)", value: $settings.targetSets, in: 1...20, step: 1)
                                
                                Stepper("Reps Per Set: \(settings.targetRepsPerSet)", value: $settings.targetRepsPerSet, in: 1...100, step: 1)
                                
                                Stepper("Rest Time: \(settings.restTimeSeconds)s", value: $settings.restTimeSeconds, in: 30...300, step: 10)
                                
                                Stepper("Weekly Schedule: \(settings.targetWorkoutDays) days/week", value: $settings.targetWorkoutDays, in: 1...7)
                                
                                Text("Total: \(settings.targetSets * settings.targetRepsPerSet) reps per workout")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                                        colors: [.green.opacity(0.3), .green.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)

                    // Notifications Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Text("Workout Reminders")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.bottom, 4)
                        
                        VStack(spacing: 12) {
                            Toggle("Enable Workout Reminders", isOn: $settings.notificationsEnabled)
                                .onChange(of: settings.notificationsEnabled) { _, newValue in
                                    if newValue && notificationManager.permissionStatus != .authorized {
                                        requestNotificationPermission()
                                    }
                                }

                            if settings.notificationsEnabled {
                                if notificationManager.permissionStatus == .denied {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                            .symbolEffect(.pulse)
                                        Text("Notifications disabled in Settings")
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.orange.opacity(0.1))
                                    )
                                }

                                // Schedule Settings - Single source of truth
                                Button(action: {
                                    showingScheduleBuilder = true
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Schedule Settings")
                                                .foregroundColor(.primary)
                                                .fontWeight(.medium)

                                            if let rule = settings.currentScheduleRule {
                                                Text(rule.scheduleDescription)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("Configure your workout reminder schedule")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Text("You have \(pendingNotificationCount) scheduled reminder(s)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 4)
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
                                        colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)

                    // Subscription Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Subscription")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.bottom, 4)
                        
                        VStack(spacing: 16) {
                            if subscriptionManager.isSubscribed {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.green.opacity(0.15), .green.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title2)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Premium Active")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text("All features unlocked")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )

                                HStack(spacing: 12) {
                                    Button(action: {
                                        openSubscriptionManagement()
                                    }) {
                                        Text("Manage Subscription")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemGray6))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        restorePurchases()
                                    }) {
                                        Text("Restore Purchases")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemGray6))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isRestoring)
                                }
                            } else {
                                Button(action: {
                                    showingPaywall = true
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.yellow.opacity(0.2), .orange.opacity(0.15)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 48, height: 48)
                                            
                                            Image(systemName: "sparkles")
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.yellow, .orange],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .font(.title3)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Upgrade to Premium")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                            Text("Unlock unlimited history & advanced features")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    restorePurchases()
                                }) {
                                    Text("Restore Purchases")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(isRestoring)
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
                                        colors: [.yellow.opacity(0.3), .orange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)

                    // Debug Section
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text("Debug & Demo")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.bottom, 4)
                        
                        VStack(spacing: 16) {
                            Picker("Demo Data", selection: Binding(
                                get: { DemoDataManager.currentDemoPreset },
                                set: { newPreset in
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()

                                    DemoDataManager.setDemoPreset(newPreset)
                                    DemoDataManager.generateDemoData(context: modelContext)
                                }
                            )) {
                                ForEach(DemoDataManager.DemoPreset.allCases, id: \.self) { preset in
                                    Text(preset.displayName).tag(preset)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select demo data to test different scenarios:")
                                Text("• Beginner: 2-3 sets × 5-10 reps, 3-4 days/week")
                                Text("• Intermediate: 3-4 sets × 10-20 reps, 4-5 days/week")
                                Text("• Advanced: 4-5 sets × 20-40 reps, 5-6 days/week")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                            Divider()
                            
                            VStack(spacing: 12) {
                                Button("Test Reminder (5s)") {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    NotificationManager.shared.scheduleTestNotification(interval: 5)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                
                                Button("Test Reminder (10s)") {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    NotificationManager.shared.scheduleTestNotification(interval: 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                
                                Text("💡 Put app in background or lock simulator to see banner")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
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
                                        colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)
                    #endif
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .preferredColorScheme(currentColorScheme)
            .task {
                updateNotificationCount()
            }
            .sheet(isPresented: $showingCustomTimePicker) {
                CustomTimePickerView(
                    timeComponents: $newCustomTime,
                    onSave: {
                        settings.customTimes.append(newCustomTime)
                        showingCustomTimePicker = false
                    },
                    onCancel: {
                        showingCustomTimePicker = false
                    }
                )
            }
            .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
                Button("Open Settings", action: openAppSettings)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive pushup reminders.")
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(milestone: nil)
            }
            .sheet(isPresented: $showingScheduleBuilder) {
                ScheduleBuilderView(settings: settings)
                    .onDisappear {
                        updateNotificationCount()
                    }
            }
            .sheet(isPresented: $showingRecommendedStandardsInfo) {
                RecommendedStandardsInfoView()
            }
        }
    }

    private func requestNotificationPermission() {
        notificationManager.requestPermission { granted in
            if !granted {
                showingPermissionAlert = true
                settings.notificationsEnabled = false
            } else {
                updateNotificationCount()
            }
        }
    }

    private func updateNotificationCount() {
        notificationManager.getPendingNotificationCount { count in
            pendingNotificationCount = count
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func timeString(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }

    private func restorePurchases() {
        isRestoring = true

        Task {
            do {
                try await subscriptionManager.restorePurchases()
                isRestoring = false
            } catch {
                isRestoring = false
                print("Failed to restore purchases: \(error.localizedDescription)")
            }
        }
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func iconName(for option: ColorSchemeOption) -> String {
        switch option {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Appearance Option Button

struct AppearanceOptionButton: View {
    let option: ColorSchemeOption
    let isSelected: Bool
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                Text(option.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    } else {
                        // Better dark mode alternative: subtle purple-tinted background
                        ZStack {
                            // Base adaptive background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                            
                            // Subtle purple tint that adds depth in dark mode
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .purple.opacity(0.08),
                                            .purple.opacity(0.03)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.clear : (
                            // Subtle border that adapts to light/dark mode
                            Color(.systemGray5).opacity(0.5)
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Time Picker View

struct CustomTimePickerView: View {
    @Binding var timeComponents: DateComponents
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: $selectedDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()

                Spacer()
            }
            .navigationTitle("Add Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
                        timeComponents = components
                        onSave()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
