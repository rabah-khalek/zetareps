//
//  TabHelpers.swift
//  ZetaReps
//

import SwiftUI

struct StartTabView: View {
    @Binding var showingWorkout: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        Color.clear
            .onAppear {
                // Action is handled in ContentView onChange
            }
    }
}

struct ShareTabView: View {
    let metrics: WorkoutMetrics
    let recentWorkouts: [Workout]
    @Binding var selectedTab: Int
    
    var body: some View {
        Color.clear
            .onAppear {
                // Trigger share action
                Task { @MainActor in
                    if let shareImage = ShareManager.generateShareImage(
                        from: metrics,
                        recentWorkouts: recentWorkouts
                    ) {
                        ShareManager.presentShareSheet(
                            image: shareImage,
                            text: ShareManager.generateShareText(from: metrics),
                            shortText: ShareManager.generateShareText(from: metrics)
                        )
                    }
                }
            }
    }
}

