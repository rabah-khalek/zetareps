//
//  ActionButtonsToolbar.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI

struct ActionButtonsToolbar: View {
    @Binding var showingWorkout: Bool
    @Binding var showingPaywall: Bool
    let workouts: [Workout]
    let settings: AppSettings
    let subscriptionManager: SubscriptionManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Share button (only show if workouts exist)
            if !workouts.isEmpty {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    
                    Task { @MainActor in
                    let metrics = MetricsCalculator.calculateMetrics(
                        workouts: workouts,
                        targetDays: settings.effectiveTargetDays,
                        targetReps: settings.effectiveTargetReps,
                        targetSets: settings.effectiveTargetSets,
                        targetRepsPerSet: settings.effectiveTargetRepsPerSet,
                        evaluationPeriod: 30
                    )
                        if let shareImage = ShareManager.generateShareImage(
                            from: metrics,
                            recentWorkouts: Array(workouts.prefix(7))
                        ) {
                            ShareManager.presentShareSheet(
                                image: shareImage,
                                text: ShareManager.generateShareText(from: metrics),
                                shortText: ShareManager.generateShareText(from: metrics)
                            )
                        }
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
            }
            
            // Start button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                let totalPushups = workouts.reduce(0) { $0 + $1.repsCompleted }
                if !subscriptionManager.isSubscribed && totalPushups >= 100 {
                    showingPaywall = true
                } else {
                    showingWorkout = true
                }
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }
            .opacity(subscriptionManager.isSubscribed || workouts.reduce(0) { $0 + $1.repsCompleted } < 100 ? 1.0 : 0.6)
        }
    }
}

