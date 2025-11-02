//
//  PaywallView.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI
import StoreKit
import UIKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var selectedProduct: Product?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isRestoring = false

    let milestone: Int? // Optional milestone (e.g., 100 pushups)

    var body: some View {
        ZStack {
            // Animated Background gradient
            AnimatedPaywallBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal)

                    // Milestone celebration (if provided)
                    if let milestone = milestone {
                        VStack(spacing: 10) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.yellow)
                                .bounceEffect()
                                .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 0)

                            Text("Amazing! \(milestone) Pushups!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("You're building a great habit")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.top, 20)
                    }

                    // Hero section
                    VStack(spacing: 15) {
                        Text("Continue Your Progress")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                        Text("Unlimited workouts and progress tracking")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Premium features
                    VStack(spacing: 15) {
                        PremiumFeatureRow(
                            icon: "infinity",
                            title: "Unlimited Workouts",
                            description: "Track as many pushups as you want"
                        )

                        PremiumFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Full Progress Tracking",
                            description: "Complete workout history and analytics"
                        )

                        PremiumFeatureRow(
                            icon: "sparkles",
                            title: "All Features Unlocked",
                            description: "Access to everything in the app"
                        )
                    }
                    .padding(.horizontal)

                    // Pricing cards
                    VStack(spacing: 15) {
                        if let annual = subscriptionManager.annualProduct {
                            PricingCard(
                                product: annual,
                                isSelected: selectedProduct?.id == annual.id,
                                badge: "BEST VALUE - Save \(subscriptionManager.monthlySavings)",
                                monthlyEquivalent: true
                            ) {
                                selectedProduct = annual
                            }
                        }

                        if let monthly = subscriptionManager.monthlyProduct {
                            PricingCard(
                                product: monthly,
                                isSelected: selectedProduct?.id == monthly.id,
                                badge: nil,
                                monthlyEquivalent: false
                            ) {
                                selectedProduct = monthly
                            }
                        }
                        
                        // Show message if no products loaded
                        if subscriptionManager.annualProduct == nil && subscriptionManager.monthlyProduct == nil {
                            VStack(spacing: 8) {
                                Text("Loading subscription options...")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("If this persists, subscriptions may need to be configured in App Store Connect.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal)

                    // Purchase button with enhanced styling
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                        purchaseSelected()
                    }) {
                        if subscriptionManager.purchaseInProgress {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                        } else {
                            VStack(spacing: 5) {
                                Text("Subscribe Now")
                                    .font(.title3)
                                    .fontWeight(.bold)

                                Text("\(selectedProduct?.displayPrice ?? "$0.99") per \(selectedProduct?.id.contains("annual") == true ? "year" : "month")")
                                    .font(.caption)
                                    .opacity(0.9)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedProduct != nil ? Color.green : Color.gray)
                            .shadow(color: selectedProduct != nil ? .green.opacity(0.4) : .clear, radius: 15, x: 0, y: 8)
                    )
                    .disabled(selectedProduct == nil || subscriptionManager.purchaseInProgress)
                    .opacity(selectedProduct == nil ? 0.6 : 1.0)
                    .padding(.horizontal)

                    // Fine print
                    VStack(spacing: 10) {
                        Text("Subscription automatically renews. Cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 20) {
                            Button("Restore Purchases") {
                                restorePurchases()
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                            Button("Terms") {
                                if let url = URL(string: "https://zetareps.com/terms.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                            Button("Privacy") {
                                if let url = URL(string: "https://zetareps.com/privacy.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Pre-select annual subscription (best value)
            selectedProduct = subscriptionManager.annualProduct
        }
    }

    // MARK: - Actions

    private func purchaseSelected() {
        guard let product = selectedProduct else { return }

        Task {
            do {
                try await subscriptionManager.purchase(product)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true

        Task {
            do {
                try await subscriptionManager.restorePurchases()
                isRestoring = false

                if subscriptionManager.isSubscribed {
                    dismiss()
                } else {
                    errorMessage = "No previous purchases found"
                    showingError = true
                }
            } catch {
                isRestoring = false
                errorMessage = "Failed to restore purchases"
                showingError = true
            }
        }
    }
}

// MARK: - Animated Paywall Background

struct AnimatedPaywallBackground: View {
    @State private var animationPhase = 0.0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.1, blue: 0.3).opacity(0.9),
                Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.9),
                Color(red: 0.0, green: 0.15, blue: 0.35).opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(animationPhase))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                animationPhase = 30
            }
        }
    }
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.25))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.18))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let monthlyEquivalent: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Subscription Title
                Text(product.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }

                // Price
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(product.displayPrice)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("/ \(product.id.contains("annual") ? "year" : "month")")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Monthly equivalent
                if monthlyEquivalent, product.id.contains("annual") {
                    Text("Just \(String(format: "$%.2f", NSDecimalNumber(decimal: product.price / 12).doubleValue)) per month")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isSelected ? Color.white.opacity(0.28) : Color.white.opacity(0.12))
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                            .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                    }
                }
            )
            .shadow(color: isSelected ? .white.opacity(0.2) : .black.opacity(0.2), radius: isSelected ? 16 : 8, x: 0, y: isSelected ? 8 : 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Bounce Effect Extension
extension View {
    @ViewBuilder
    func bounceEffect() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce)
        } else {
            // For iOS 17, return view as-is (no effect)
            self
        }
    }
}

#Preview {
    PaywallView(milestone: 100)
}
