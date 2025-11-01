//
//  ShareButton.swift
//  ZetaReps
//
//  Created by Claude Code
//

import SwiftUI

struct ShareButton: View {
    let metrics: WorkoutMetrics
    let recentWorkouts: [Workout]

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var isGenerating = false

    var body: some View {
        Button(action: {
            generateAndShare()
        }) {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                }

                Text("Share Progress")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isGenerating)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(
                    image: image,
                    text: ShareManager.generateShareText(from: metrics),
                    shortText: ShareManager.generateShareText(from: metrics)
                )
            }
        }
    }

    @MainActor
    private func generateAndShare() {
        isGenerating = true

        Task { @MainActor in
            shareImage = ShareManager.generateShareImage(from: metrics, recentWorkouts: recentWorkouts)
            isGenerating = false
            if shareImage != nil {
                showShareSheet = true
            }
        }
    }
}

// MARK: - Compact Share Button

struct CompactShareButton: View {
    let metrics: WorkoutMetrics
    let recentWorkouts: [Workout]

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var isGenerating = false

    var body: some View {
        Button(action: {
            generateAndShare()
        }) {
            Group {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                }
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isGenerating)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(
                    image: image,
                    text: ShareManager.generateShareText(from: metrics),
                    shortText: ShareManager.generateShareText(from: metrics)
                )
            }
        }
    }

    @MainActor
    private func generateAndShare() {
        isGenerating = true
        Task { @MainActor in
            shareImage = ShareManager.generateShareImage(from: metrics, recentWorkouts: recentWorkouts)
            isGenerating = false
            if shareImage != nil {
                showShareSheet = true
            }
        }
    }
}

// MARK: - Share Sheet (UIViewControllerRepresentable)

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let text: String
    let shortText: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Use image data directly for better Files app compatibility
        let imageData = image.pngData() ?? Data()
        
        // Create multiple activity items: data for Files app, image for other apps
        var activityItems: [Any] = [imageData]
        
        // Add text for platforms that support it
        activityItems.append(text)
        
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude unwanted options
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print
        ]
        
        // Set completion handler to clean up any issues
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                print("Share error: \(error.localizedDescription)")
            }
        }

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Share Action Menu

struct ShareActionMenu: View {
    let metrics: WorkoutMetrics
    let recentWorkouts: [Workout]

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        Menu {
            Button(action: {
                shareToGeneral()
            }) {
                Label("Share...", systemImage: "square.and.arrow.up")
            }

            if ShareManager.isAppInstalled("whatsapp") {
                Button(action: {
                    shareToWhatsApp()
                }) {
                    Label("Share to WhatsApp", systemImage: "message.fill")
                }
            }

            Button(action: {
                shareToMessages()
            }) {
                Label("Share to Messages", systemImage: "message.fill")
            }

            Divider()

            Button(action: {
                copyToClipboard()
            }) {
                Label("Copy Text", systemImage: "doc.on.doc")
            }

            Button(action: {
                saveImage()
            }) {
                Label("Save Image", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(.blue)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(
                    image: image,
                    text: ShareManager.generateShareText(from: metrics),
                    shortText: ShareManager.generateShareText(from: metrics)
                )
            }
        }
    }

    @MainActor
    private func shareToGeneral() {
        Task {
            shareImage = ShareManager.generateShareImage(from: metrics, recentWorkouts: recentWorkouts)
            showShareSheet = true
        }
    }

    private func shareToWhatsApp() {
        let text = ShareManager.generateShareText(from: metrics)
        ShareManager.shareToWhatsApp(text: text)
    }

    private func shareToMessages() {
        // Open Messages app with prefilled text
        let text = ShareManager.generateShareText(from: metrics)
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "sms:&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func copyToClipboard() {
        let text = ShareManager.generateShareText(from: metrics)
        UIPasteboard.general.string = text
    }

    @MainActor
    private func saveImage() {
        Task {
            guard let image = ShareManager.generateShareImage(from: metrics, recentWorkouts: recentWorkouts) else {
                return
            }

            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}

// MARK: - Preview

#Preview("Share Button") {
    let sampleMetrics = WorkoutMetrics(
        consistency: 7.8,
        intensity: 6.5,
        totalWorkouts: 18,
        totalReps: 542,
        streakDays: 12,
        evaluationPeriod: 30
    )

    let sampleWorkouts = (1...7).map { i in
        Workout(
            date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
            duration: Double.random(in: 120...300),
            repsCompleted: Int.random(in: 20...50),
            difficultyRating: Int.random(in: 2...4),
            notes: ""
        )
    }

    return VStack(spacing: 20) {
        ShareButton(metrics: sampleMetrics, recentWorkouts: sampleWorkouts)
            .padding()

        CompactShareButton(metrics: sampleMetrics, recentWorkouts: sampleWorkouts)
            .padding()

        ShareActionMenu(metrics: sampleMetrics, recentWorkouts: sampleWorkouts)
            .padding()
    }
}
