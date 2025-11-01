//
//  SubscriptionManager.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation
import StoreKit
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

    // Published properties
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var isSubscribed: Bool = false
    @Published var purchaseInProgress = false

    // Product IDs (must match App Store Connect)
    private let monthlyProductID = "com.zetareps.premium.monthly"
    private let annualProductID = "com.zetareps.premium.annual"

    // Available products
    @Published var monthlyProduct: Product?
    @Published var annualProduct: Product?

    // UserDefaults key
    private let subscriptionKey = "userSubscriptionStatus"

    private var updateListenerTask: Task<Void, Error>?

    init() {
        // Load saved subscription status
        loadSubscriptionStatus()

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products
        Task {
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [monthlyProductID, annualProductID])

            for product in products {
                switch product.id {
                case monthlyProductID:
                    monthlyProduct = product
                case annualProductID:
                    annualProduct = product
                default:
                    break
                }
            }
        } catch {
            print("Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Check if the transaction is verified
            let transaction = try checkVerified(verification)

            // Update subscription status
            await updateSubscriptionStatus(transaction: transaction)

            // Finish the transaction
            await transaction.finish()

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        do {
            try await AppStore.sync()

            // Check for active subscriptions
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                await updateSubscriptionStatus(transaction: transaction)
            }
        } catch {
            print("Failed to restore purchases: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == monthlyProductID || transaction.productID == annualProductID {
                    hasActiveSubscription = true
                    break
                }
            }
        }

        await MainActor.run {
            self.isSubscribed = hasActiveSubscription
            self.subscriptionTier = hasActiveSubscription ? .premium : .free
            saveSubscriptionStatus()
        }
    }

    // MARK: - Listen for Transactions

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            guard let self = self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updateSubscriptionStatus(transaction: Transaction) async {
        if transaction.productID == monthlyProductID || transaction.productID == annualProductID {
            if transaction.revocationDate == nil {
                await MainActor.run {
                    self.isSubscribed = true
                    self.subscriptionTier = .premium
                    saveSubscriptionStatus()
                }
            } else {
                await MainActor.run {
                    self.isSubscribed = false
                    self.subscriptionTier = .free
                    saveSubscriptionStatus()
                }
            }
        }
    }

    private func saveSubscriptionStatus() {
        UserDefaults.standard.set(subscriptionTier.rawValue, forKey: subscriptionKey)
    }

    private func loadSubscriptionStatus() {
        if let savedStatus = UserDefaults.standard.string(forKey: subscriptionKey),
           let tier = SubscriptionTier(rawValue: savedStatus) {
            subscriptionTier = tier
            isSubscribed = tier == .premium
        }

        // Always check with StoreKit on launch
        Task {
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Product Info Helpers

    var monthlyPrice: String {
        monthlyProduct?.displayPrice ?? "$0.99"
    }

    var annualPrice: String {
        annualProduct?.displayPrice ?? "$5.99"
    }

    var monthlySavings: String {
        guard let annual = annualProduct, let monthly = monthlyProduct else {
            return "50%"
        }

        let annualMonthly = annual.price / 12
        let monthlyCost = monthly.price
        let savings = ((monthlyCost - annualMonthly) / monthlyCost) * 100

        return String(format: "%.0f%%", NSDecimalNumber(decimal: savings).doubleValue)
    }
}

// MARK: - Subscription Error

enum SubscriptionError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}

extension SubscriptionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase"
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
