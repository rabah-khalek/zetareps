//
//  MetricsInfoView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI

struct MetricsInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Data Points Explanation (New)
                    DataPointsCard()
                    
                    // Consistency Metric
                    MetricExplanationCard(
                        title: "Consistency Score",
                        icon: "calendar.circle.fill",
                        iconColor: .green,
                        score: "0-10",
                        description: "Measures how regularly you work out and meet volume targets over the last 3 weeks",
                        components: [
                            ("Frequency", "80%", "Workouts per week vs. target, with exponential time decay (recent weeks count more)"),
                            ("Quality", "20%", "Percentage of total volume (sets × reps) completed vs. target")
                        ],
                        formula: """
                        Score = (Frequency × 80% + Quality × 20%) × 10

                        Time Weighting (3 weeks):
                        • Week 1 (days 0-6): 100% weight (1.0)
                        • Week 2 (days 7-13): 50% weight (0.5)
                        • Week 3 (days 14-20): 25% weight (0.25)
                        • Equivalent weeks = 1.75 (sum of weights)

                        Frequency (80%):
                        • weighted_total = (count₁×1.0 + count₂×0.5 + count₃×0.25)
                        • frequency_ratio = weighted_total / (target_days × 1.75)
                        • Capped at 1.0 (exceeding target = full points)

                        Quality (20%):
                        • Per workout: quality = min(total_reps / target_total_reps, 1.0)
                        • Examples (target: 3 sets × 10 reps = 30 total):
                          - 15 reps → 15/30 = 0.5 (50% quality)
                          - 30 reps → 30/30 = 1.0 (100% quality)
                          - 45 reps → 45/30 = 1.5, capped at 1.0 (100% quality)
                        • quality_avg_week = average quality across workouts that week
                        • weighted_avg = (q₁×c₁×1.0 + q₂×c₂×0.5 + q₃×c₃×0.25) / weighted_total

                        Note: Quality is based purely on total volume, regardless of how you split sets/reps.
                        """
                    )

                    // Intensity Metric
                    MetricExplanationCard(
                        title: "Intensity Score",
                        icon: "bolt.circle.fill",
                        iconColor: .orange,
                        score: "0-10",
                        description: "Measures how hard you're pushing yourself relative to targets over the last 3 weeks",
                        components: [
                            ("Volume", "60%", "Total volume (sets × reps) with bonus for higher reps per set"),
                            ("Difficulty", "30%", "Your self-rated difficulty (1=easy, 5=hard), time-weighted average"),
                            ("Volume Bonus", "10%", "Bonus for exceeding total target volume (capped at 50% above)")
                        ],
                        formula: """
                        Score = (Volume × 60% + Difficulty × 30% + Volume Bonus × 10%) × 10

                        Time Weighting (same as Consistency):
                        • Week 1: 100% (1.0), Week 2: 50% (0.5), Week 3: 25% (0.25)
                        • All averages are exponentially-weighted across 3 weeks

                        Volume (60%):
                        • weighted_avg_total_reps = Σ(reps × weight) / Σ(weight)
                        • weighted_avg_reps_per_set = Σ(reps × weight) / Σ(sets × weight)
                        • volume_ratio = weighted_avg_total_reps / target_total_reps
                        • volume_component = min(volume_ratio, 1.0)
                        • reps_per_set_multiplier = min(max(avg_reps_per_set / target_reps_per_set, 0.5), 1.5)
                        • base_score = volume_component × 80%
                        • multiplier_effect = (reps_per_set_multiplier - 1.0) × volume_component × 20%
                        • final = base_score + volume_component × 20% + multiplier_effect

                        Examples (target: 3 sets × 10 reps = 30 total):
                        • 3 sets × 10 reps = 30 → volume=1.0, rps_mult=1.0 → score=1.0
                        • 2 sets × 15 reps = 30 → volume=1.0, rps_mult=1.5 → score=1.1
                        • 1 set × 30 reps = 30 → volume=1.0, rps_mult=1.5 → score=1.1

                        Difficulty (30%):
                        • weighted_avg_difficulty = Σ(difficulty × weight) / Σ(weight)
                        • Normalized: (avg - 1) ÷ 4 (converts 1-5 to 0-1)

                        Volume Bonus (10%):
                        • If weighted_avg_total_reps > target_total_reps
                        • excess_ratio = (achieved - target) / target (max 0.5)
                        • bonus = excess_ratio × 0.2 (scales to 0-0.1 range)

                        Note: Higher reps per set (at same volume) gives slightly better intensity score.
                        """
                    )

                    // Scoring Guide
                    ScoringGuideCard()
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Data Points Card

struct DataPointsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Time-Based Calculation")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Metrics are based on the last 3 weeks of workouts with exponential decay:")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "1.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("This week (days 0-6): 100% weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "2.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Last week (days 7-13): 50% weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "3.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        Text("2 weeks ago (days 14-20): 25% weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 8)

                Divider()
                    .padding(.vertical, 4)

                Text("Why exponential decay?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 4)

                Text("This approach ensures your scores:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Reflect your current fitness level, not past performance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Gradually decrease if you stop training (no sudden drops)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Align with your weekly workout targets and training cycles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Match how fitness actually works (gradual deconditioning)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 8)
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
}

// MARK: - Metric Explanation Card

struct MetricExplanationCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let score: String
    let description: String
    let components: [(name: String, weight: String, description: String)]
    let formula: String

    @State private var showFormula = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(score)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 4)

            // Components
            VStack(alignment: .leading, spacing: 12) {
                Text("Components:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(components, id: \.name) { component in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(component.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text(component.weight)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }

                        Text(component.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Formula Toggle
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showFormula.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showFormula ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Text(showFormula ? "Hide Formula" : "Show Formula")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.blue)
            }
            .padding(.top, 4)

            if showFormula {
                VStack(alignment: .leading, spacing: 12) {
                    // Render formula with clean formatting
                    FormulaView(formula: formula)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5).opacity(0.5), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
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
}

// MARK: - Scoring Guide Card

struct ScoringGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Scoring Guide")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            VStack(spacing: 12) {
                ScoreRangeRow(range: "8.0 - 10.0", label: "Excellent", color: .green)
                ScoreRangeRow(range: "6.0 - 7.9", label: "Good", color: .blue)
                ScoreRangeRow(range: "4.0 - 5.9", label: "Fair", color: .orange)
                ScoreRangeRow(range: "0.0 - 3.9", label: "Poor", color: .red)
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
}

struct ScoreRangeRow: View {
    let range: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(range)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 90, alignment: .leading)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Formula Rendering Components

struct FormulaView: View {
    let formula: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let lines = formula.components(separatedBy: "\n")
            
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                if trimmed.isEmpty {
                    EmptyView()
                } else if trimmed.hasPrefix("Note:") {
                    // Note section
                    Text(trimmed)
                        .font(.system(.caption, design: .rounded))
                        .italic()
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                } else if trimmed.contains(":") && !trimmed.hasPrefix("•") && !trimmed.hasPrefix("-") {
                    // Section header (like "Frequency:" or "Sets & Reps (60%):")
                    Text(trimmed)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.top, index > 0 ? 8 : 0)
                } else if trimmed.hasPrefix("•") {
                    // Main bullet point
                    let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                    FormulaLine(text: String(content), isMain: true)
                } else if trimmed.hasPrefix("-") && index > 0 {
                    // Sub-bullet (indented)
                    let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                    FormulaLine(text: String(content), isMain: false, indent: true)
                } else {
                    // Main equation line
                    FormulaLine(text: trimmed, isMain: false, isEquation: true)
                }
            }
        }
    }
}

struct FormulaLine: View {
    let text: String
    var isMain: Bool = false
    var indent: Bool = false
    var isEquation: Bool = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if indent {
                Text("  ")
                    .font(.system(.caption, design: .monospaced))
            }
            
            if isMain {
                Circle()
                    .fill(.blue.opacity(0.6))
                    .frame(width: 3, height: 3)
                    .padding(.trailing, 4)
            }
            
            // Format the line with mathematical notation
            formattedText(text, isEquation: isEquation)
        }
        .padding(.vertical, 1)
    }
    
    @ViewBuilder
    private func formattedText(_ text: String, isEquation: Bool) -> some View {
        if isEquation {
            // Main equation - use monospaced and slightly larger
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        } else {
            // Regular text - use rounded for better readability
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    MetricsInfoView()
}
