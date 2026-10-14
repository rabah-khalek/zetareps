//
//  ContentView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var selectedTab = 0
    @State private var showingWorkout = false
    @AppStorage("hasSeenFreeNotice103") private var hasSeenFreeNotice = false
    @State private var showingFreeNotice = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemeOption = .dark

    private var currentColorScheme: ColorScheme? {
        colorSchemePreference.colorScheme
    }
    
    private var currentMetrics: WorkoutMetrics {
        MetricsCalculator.calculateMetrics(
            workouts: workouts,
            targetDays: settings.targetWorkoutDays,
            targetReps: settings.defaultReps,
            evaluationPeriod: 30
        )
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                HistoryView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("History")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .preferredColorScheme(currentColorScheme)
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            WorkoutSessionView()
        }
        .alert("ZetaReps is now free", isPresented: $showingFreeNotice) {
            Button("Learn more") {
                hasSeenFreeNotice = true
                if let url = URL(string: "https://www.zetareps.com") {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK") {
                hasSeenFreeNotice = true
            }
        } message: {
            Text("The 100-pushup limit and the Premium subscription are gone: every feature is now unlocked for everyone. ZetaReps is no longer actively maintained; the source code is available at zetareps.com.")
        }
        .onAppear {
            if !hasSeenFreeNotice {
                showingFreeNotice = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Workout.self, inMemory: true)
}
