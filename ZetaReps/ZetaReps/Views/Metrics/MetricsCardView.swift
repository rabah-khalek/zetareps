//
//  MetricsCardView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import Charts

struct MetricsCardView: View {
    let consistency: Double
    let intensity: Double

    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 16) {
            // Header with info button
            HStack {
                Text("Performance Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    showingInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }

            // Dual Gauges
            HStack(spacing: 40) {
                // Consistency Gauge
                CircularMetricGauge(
                    score: consistency,
                    title: "Consistency",
                    icon: "calendar.badge.clock",
                    gradient: consistencyGradient
                )

                // Intensity Gauge
                CircularMetricGauge(
                    score: intensity,
                    title: "Intensity",
                    icon: "bolt.fill",
                    gradient: intensityGradient
                )
            }

            // Score Legend
            ScoreLegend()
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .sheet(isPresented: $showingInfo) {
            MetricsInfoView()
        }
    }

    private var consistencyGradient: [Color] {
        [.red, .orange, .yellow, .green]
    }

    private var intensityGradient: [Color] {
        [.blue, .purple, .pink, .orange]
    }
}

// MARK: - Circular Metric Gauge

struct CircularMetricGauge: View {
    let score: Double
    let title: String
    let icon: String
    let gradient: [Color]

    @State private var animatedScore: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 14)
                    .frame(width: 120, height: 120)

                // Progress ring with score-based color
                Circle()
                    .trim(from: 0, to: animatedScore / 10)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animatedScore)

                // Score display
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(scoreColor)

                    Text(String(format: "%.1f", score))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)

                    Text("/ 10")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .onAppear {
            animatedScore = score
        }
        .onChange(of: score) {
            animatedScore = score
        }
    }

    private var scoreColor: Color {
        switch score {
        case 8...10: return .green
        case 6..<8: return .blue
        case 4..<6: return .orange
        default: return .red
        }
    }
}

// MARK: - Score Legend

struct ScoreLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(color: .green, range: "8-10", label: "Excellent")
            LegendItem(color: .blue, range: "6-8", label: "Good")
            LegendItem(color: .orange, range: "4-6", label: "Fair")
            LegendItem(color: .red, range: "0-4", label: "Needs Work")
        }
        .font(.caption2)
    }
}

struct LegendItem: View {
    let color: Color
    let range: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Performance Tip View

struct PerformanceTipView: View {
    let tip: PerformanceTip
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: tip.icon)
                    .font(.subheadline)
                    .foregroundStyle(tip.color)
                
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(tip.message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tip.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tip.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Glassmorphism Variant

struct GlassmorphicMetricsCard: View {
    let consistency: Double
    let intensity: Double
    let targetDays: Int
    
    @State private var showingInfo = false
    
    init(consistency: Double, intensity: Double, targetDays: Int = 5) {
        self.consistency = consistency
        self.intensity = intensity
        self.targetDays = targetDays
    }
    
    private var performanceTip: PerformanceTip? {
        MetricsCalculator.analyzePerformanceOptimization(
            consistency: consistency,
            intensity: intensity,
            targetDays: targetDays
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Performance Metrics")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    showingInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.bottom, 4)

            // Dual Gauges
            HStack(spacing: 40) {
                CircularMetricGauge(
                    score: consistency,
                    title: "Consistency",
                    icon: "calendar.badge.clock",
                    gradient: [.red, .orange, .yellow, .green]
                )

                CircularMetricGauge(
                    score: intensity,
                    title: "Intensity",
                    icon: "bolt.fill",
                    gradient: [.blue, .purple, .pink, .orange]
                )
            }

            // Score Legend
            ScoreLegend()
                .padding(.top, 4)
            
            // Performance Tip (if available) - inline, full width
            if let tip = performanceTip {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: tip.icon)
                            .font(.subheadline)
                            .foregroundStyle(tip.color)
                        
                        Text(tip.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(tip.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 24)
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
        .sheet(isPresented: $showingInfo) {
            MetricsInfoView()
        }
    }
}

// MARK: - Compact Horizontal Variant

struct CompactMetricsView: View {
    let consistency: Double
    let intensity: Double

    var body: some View {
        HStack(spacing: 20) {
            CompactMetricItem(
                score: consistency,
                title: "Consistency",
                icon: "calendar.badge.clock",
                color: .green
            )

            Divider()
                .frame(height: 60)

            CompactMetricItem(
                score: intensity,
                title: "Intensity",
                icon: "bolt.fill",
                color: .orange
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct CompactMetricItem: View {
    let score: Double
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(String(format: "%.1f", score))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text("/ 10")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Standard") {
    VStack(spacing: 20) {
        MetricsCardView(consistency: 7.8, intensity: 6.5)
            .padding()

        MetricsCardView(consistency: 4.2, intensity: 8.9)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Glassmorphic") {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassmorphicMetricsCard(consistency: 8.5, intensity: 7.2)
            .padding()
    }
}

#Preview("Compact") {
    CompactMetricsView(consistency: 6.7, intensity: 5.4)
        .padding()
        .background(Color(.systemGroupedBackground))
}
