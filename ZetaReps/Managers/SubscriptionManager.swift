//
//  SubscriptionManager.swift
//  ZetaReps
//
//  Since version 1.0.4 ZetaReps is completely free: the Premium subscription
//  and the 100-pushup limit were removed and every feature is unlocked.
//

import Foundation
import Combine

// MARK: - Subscription Status

enum SubscriptionTier: String {
    case free = "free"
    case premium = "premium"
}

// MARK: - Subscription Manager

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    /// Always premium: every feature is unlocked for everyone.
    @Published var subscriptionTier: SubscriptionTier = .premium
    @Published var isSubscribed: Bool = true

    init() {}
}
