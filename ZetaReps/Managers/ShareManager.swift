//
//  ShareManager.swift
//  ZetaReps
//

import SwiftUI
import UIKit

// MARK: - Share Manager

@MainActor
class ShareManager {

    // MARK: - Shareable Content Generation

    /// Generate a shareable image from workout metrics
    /// - Parameter metrics: Workout metrics to display
    /// - Returns: UIImage ready for sharing
    static func generateShareImage(from metrics: WorkoutMetrics,
                                   recentWorkouts: [Workout]) -> UIImage? {
        // Ensure we're on the main actor for UI rendering
        assert(Thread.isMainThread, "Must be called on main thread")
        
        let cardView = ShareableCardView(metrics: metrics, recentWorkouts: recentWorkouts)
        
        // Create renderer with explicit size
        let renderer = ImageRenderer(content: cardView)
        
        // Set explicit proposed size to avoid rendering issues
        renderer.proposedSize = .init(width: 400, height: 600)
        
        // Use a standard scale (2x is safer and works well)
        renderer.scale = 2.0
        
        // Configure for transparency support
        renderer.isOpaque = false
        
        // Render the image
        let image = renderer.uiImage
        
        // Ensure image is valid and properly formatted
        guard let image = image else { return nil }
        
        // Convert to PNG data and back to ensure proper format for sharing
        guard let pngData = image.pngData() else { return image }
        return UIImage(data: pngData)
    }

    /// Generate shareable text
    /// - Parameter metrics: Workout metrics to include
    /// - Returns: Formatted text string
    static func generateShareText(from metrics: WorkoutMetrics) -> String {
        return """
        ZetaReps - \(metrics.evaluationPeriod) Day Progress
        
        Workouts: \(metrics.totalWorkouts)
        Total Reps: \(metrics.totalReps)
        Streak: \(metrics.streakDays) days
        
        Consistency: \(String(format: "%.1f", metrics.consistency))/10
        Intensity: \(String(format: "%.1f", metrics.intensity))/10
        """
    }

    // MARK: - Platform Detection

    enum SharePlatform {
        case whatsapp
        case instagram
        case twitter
        case messages
        case other
    }

    static func detectPlatform(from activityType: UIActivity.ActivityType?) -> SharePlatform {
        guard let type = activityType else { return .other }

        let typeString = type.rawValue.lowercased()

        if typeString.contains("whatsapp") {
            return .whatsapp
        } else if typeString.contains("instagram") {
            return .instagram
        } else if typeString.contains("twitter") {
            return .twitter
        } else if typeString.contains("messages") || typeString.contains("sms") {
            return .messages
        }

        return .other
    }

    // MARK: - Activity Item Source

    /// Custom activity item source for platform-specific sharing
    class CustomActivityItemSource: NSObject, UIActivityItemSource {
        let image: UIImage
        let imageData: Data?
        let text: String
        let shortText: String

        init(image: UIImage, text: String, shortText: String) {
            self.image = image
            self.imageData = image.pngData()
            self.text = text
            self.shortText = shortText
        }

        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            // Return data for better Files app compatibility
            return imageData ?? image
        }

        func activityViewController(_ activityViewController: UIActivityViewController,
                                   itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            // For Files app and file services, use PNG data directly
            // This avoids IOSurface and assertion errors
            if let data = imageData {
                return data
            }
            return image
        }

        func activityViewController(_ activityViewController: UIActivityViewController,
                                   subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
            return "ZetaReps Progress"
        }

        func activityViewController(_ activityViewController: UIActivityViewController,
                                   dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
            return "public.png"
        }
    }

    // MARK: - Share Sheet Presentation

    /// Present share sheet with image and text
    static func presentShareSheet(image: UIImage,
                                 text: String,
                                 shortText: String,
                                 from viewController: UIViewController? = nil) {

        let activityItem = CustomActivityItemSource(image: image,
                                                    text: text,
                                                    shortText: shortText)

        let activityVC = UIActivityViewController(
            activityItems: [activityItem],
            applicationActivities: nil
        )

        // Exclude unwanted options
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print,
            .saveToCameraRoll // Since we're not actually saving to photos
        ]

        // Present
        guard let viewController = viewController ?? getRootViewController() else {
            print("Could not find view controller to present share sheet")
            return
        }

        // For iPad, set popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                       y: viewController.view.bounds.midY,
                                       width: 0,
                                       height: 0)
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    /// Get root view controller from active window scene
    private static func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }

        // Get the topmost presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        return topVC
    }

    // MARK: - Social Media Helpers

    /// Check if specific app is installed
    static func isAppInstalled(_ app: String) -> Bool {
        guard let url = URL(string: "\(app)://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Deep link to share directly on specific platform
    static func shareToWhatsApp(text: String) {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "whatsapp://send?text=\(encoded)") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
