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
                        description: "Measures how regularly you work out and complete target sets",
                        components: [
                            ("Frequency", "60%", "Days worked out vs. expected (based on your weekly target). Exceeding target = full points."),
                            ("Set Completion", "40%", "Percentage of workouts that complete both target sets and target reps per set.")
                        ],
                        formula: """
                        Score = (Frequency × 60% + Set Completion × 40%) × 10

                        Frequency:
                        • workout_days / expected_days (capped at 1.0)
                        • expected = (span_days ÷ 7) × target_days_per_week
                        • Example: 14-day span, 3 days/week → expected = 6 days

                        Set Completion:
                        • workouts meeting both targets / total workouts
                        • Needs: sets ≥ target AND reps_per_set ≥ 50% of target
                        • Example: Target 3×10 → need ≥3 sets with ≥5 reps each
                        """
                    )

                    // Intensity Metric
                    MetricExplanationCard(
                        title: "Intensity Score",
                        icon: "bolt.circle.fill",
                        iconColor: .orange,
                        score: "0-10",
                        description: "Measures how hard you're pushing yourself relative to your target sets and reps",
                        components: [
                            ("Sets & Reps", "60%", "Combined evaluation: sets completion (60%) + reps per set (40%)"),
                            ("Difficulty", "30%", "Your self-rated difficulty (1=easy, 5=hard), normalized to 0-1"),
                            ("Volume Bonus", "10%", "Bonus for exceeding total target volume (sets × reps per set)")
                        ],
                        formula: """
                        Score = (Sets & Reps × 60% + Difficulty × 30% + Volume Bonus × 10%) × 10

                        Sets & Reps (60%):
                        • Sets Component (36%): avg_sets vs target_sets
                          - <50% target = 0, ≥100% = 1.0, else linear
                        • Reps Per Set (24%): avg_reps_per_set vs target
                          - <50% target = 0, ≥100% = 1.0, else linear
                        • Combined: (Sets × 60% + Reps × 40%)

                        Difficulty (30%):
                        • (avg_difficulty - 1) ÷ 4
                        • Range: 1 (easy) to 5 (hard) → normalized 0-1

                        Volume Bonus (10%):
                        • Bonus for exceeding target volume
                        • Capped at 50% above target

                        Note: Both sets quantity and reps per set quality are evaluated separately.
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
                
                Text("Data Points Used")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Metrics are calculated using your 3-10 most recent workouts:")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("Minimum: 3 workouts required")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Maximum: 10 most recent workouts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 8)
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("Why 3-10 data points?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
                
                Text("This range ensures metrics are:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Meaningful: Less than 3 workouts isn't enough for accurate analysis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Responsive: Recent workouts have the most impact on your scores")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Stable: Up to 10 workouts prevents single outliers from skewing results")
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
                ScoreRangeRow(range: "0.0 - 3.9", label: "Needs Work", color: .red)
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
