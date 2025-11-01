//
//  RecommendedStandardsInfoView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI

struct RecommendedStandardsInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    let standardsTuple: (frequency: String, setsReps: String, sources: [(name: String, url: String, description: String)]) = RecommendedStandards.getStandardsDescription()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Fitness Standards")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    // Sets & Reps Standards Card
                    SetsRepsCard(
                        title: "Sets & Reps Per Workout",
                        icon: "repeat.circle.fill",
                        iconColor: .blue,
                        description: "These targets are per workout session. Sets × Reps structure allows for better tracking and progression."
                    )
                    
                    // Sources Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "book.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                            Text("Sources & References")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(standardsTuple.sources.enumerated()), id: \.offset) { index, source in
                                if index > 0 {
                                    Divider()
                                        .padding(.vertical, 2)
                                }
                                
                                Link(destination: URL(string: source.url)!) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "link.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        Text(source.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.blue)
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

struct StandardsCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct SetsRepsCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            // Table format
            VStack(spacing: 0) {
                // Table Header
                HStack(spacing: 0) {
                    Text("Level")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Sets × Reps")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Frequency")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                
                Divider()
                
                // Table Rows
                TableRow(level: "Beginner", sets: "2-3", reps: "5-10", frequency: "3-4 days")
                
                Divider()
                
                TableRow(level: "Intermediate", sets: "3-4", reps: "10-20", frequency: "4-5 days")
                
                Divider()
                
                TableRow(level: "Advanced", sets: "4-5", reps: "20-40", frequency: "5-6 days")
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5).opacity(0.5), lineWidth: 1)
                    )
            )
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct TableRow: View {
    let level: String
    let sets: String
    let reps: String
    let frequency: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(level)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(sets) × \(reps)")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(frequency)
                .font(.caption)
                .foregroundStyle(.indigo)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}

#Preview {
    RecommendedStandardsInfoView()
}

