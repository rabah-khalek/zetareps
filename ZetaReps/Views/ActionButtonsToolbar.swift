//
//  ActionButtonsToolbar.swift
//  ZetaReps
//

import SwiftUI

struct ActionButtonsToolbar: View {
    @Binding var showingWorkout: Bool
    let workouts: [Workout]
    let settings: AppSettings
    
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
                
                showingWorkout = true
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
        }
    }
}

