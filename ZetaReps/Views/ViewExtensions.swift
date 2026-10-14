//
//  ViewExtensions.swift
//  ZetaReps
//
//  Shared view modifiers (moved out of the removed PaywallView).
//

import SwiftUI

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

