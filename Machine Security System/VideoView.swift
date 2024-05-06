//
//  VideoView.swift
//  Machine Security System
//
//  Created by Almahdi Morris on 05/05/24.
//
import SwiftUI
import AVKit
import Vision

struct VideoView: View {
    @State private var player = AVPlayer()
    @State private var showPicker = false
    @State private var isVisionEnabled = false
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .frame(height: 400)
                .overlay(
                    VisionOverlayView(player: player, isEnabled: $isVisionEnabled),
                    alignment: .topLeading
                )
            
            HStack {
                Button(action: {
                    self.player.pause()
                }) {
                    Text("Pause")
                }
                
                Button(action: {
                    self.player.play()
                }) {
                    Text("Play")
                }
                
                Button(action: {
                    self.showPicker = true
                }) {
                    Text("Load Video")
                }
                .sheet(isPresented: $showPicker) {
                    DocumentPicker { url in
                        self.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    }
                }
                
                Toggle("Enable Vision", isOn: $isVisionEnabled)
                    .padding()
            }
            .padding()
        }
    }
}

struct VisionOverlayView: UIViewRepresentable {
    let player: AVPlayer
    @Binding var isEnabled: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Vision processing setup
        let visionProcessor = VisionProcessor()
        visionProcessor.setupVision(player: player, view: view)
        
        // Binding to enable/disable vision processing
        DispatchQueue.main.async {
            context.coordinator.visionProcessor = visionProcessor
            context.coordinator.isEnabled = self.isEnabled
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isEnabled = isEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var visionProcessor: VisionProcessor?
        var isEnabled: Bool = false {
            didSet {
                visionProcessor?.isEnabled = isEnabled
            }
        }
    }
}

class VisionProcessor {
    var player: AVPlayer?
    var overlayView: UIView?
    var isEnabled: Bool = false {
        didSet {
            if !isEnabled {
                clearOverlays()
            }
        }
    }
    
    func setupVision(player: AVPlayer, view: UIView) {
        self.player = player
        self.overlayView = view
        
        // Setup periodic time observer to update vision processing
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.02, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] _ in
            self?.processCurrentFrame()
        }
    }
    
    private func processCurrentFrame() {
        guard isEnabled, let currentItem = player?.currentItem else { return }
        
        // Get current frame from the video
        let asset = currentItem.asset
        guard let track = asset.tracks(withMediaType: .video).first else { return }
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let timestamp = player?.currentTime() ?? CMTime.zero
    imgGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: timestamp)]) { [weak self] _, image, _, _, _ in
        if let cgImage = image {
            self?.runVisionOnImage(CGImage: cgImage)
        }
    }
}

private func runVisionOnImage(CGImage: CGImage) {
    let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
        guard error == nil else {
            print("Vision request failed with error: \(error!.localizedDescription)")
            return
        }
        self?.drawVisionResults(request)
    }
    
    let handler = VNImageRequestHandler(cgImage: CGImage, options: [:])
    DispatchQueue.global(qos: .userInteractive).async {
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error)")
        }
    }
}

private func drawVisionResults(_ request: VNRequest) {
    guard let results = request.results as? [VNHumanBodyPoseObservation] else { return }
    DispatchQueue.main.async { [weak self] in
        self?.clearOverlays()
        results.forEach { observation in
            self?.drawPose(observation)
        }
    }
}

private func drawPose(_ observation: VNHumanBodyPoseObservation) {
    guard let overlayView = overlayView else { return }
    let points = try? observation.recognizedPoints(.all)
    
    points?.values.filter({ $0.confidence > 0.6 }).forEach { point in
        let x = point.location.x * overlayView.frame.size.width
        let y = (1 - point.location.y) * overlayView.frame.size.height  // Convert y coordinate
        let circleView = UIView(frame: CGRect(x: x - 10, y: y - 10, width: 5, height: 5))
        circleView.backgroundColor = .systemBlue
        circleView.layer.cornerRadius = 1
        overlayView.addSubview(circleView)
    }
}

private func clearOverlays() {
    overlayView?.subviews.forEach { $0.removeFromSuperview() }
}
}

struct DocumentPicker: UIViewControllerRepresentable {
var completion: (URL) -> Void

func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.movie])
    picker.delegate = context.coordinator
    return picker
}

func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

func makeCoordinator() -> Coordinator {
    Coordinator(self)
}

class Coordinator: NSObject, UIDocumentPickerDelegate {
    var parent: DocumentPicker
    
    init(_ parent: DocumentPicker) {
        self.parent = parent
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        parent.completion(url)
    }
}

}

//### Explanation:
//
//- **`VideoView`**: SwiftUI view that shows a button to open a video picker and displays the video with an overlay for detected human poses.
//- **`DocumentPicker`**: Wrapper around `UIDocumentPickerViewController` to handle video file selection.
//- **`VisionOverlayView`**: A UIView that handles drawing overlays on top of the video based on Vision framework outputs.
//- **`VisionProcessor`**: A class that manages the Vision requests and updates the overlay based on detected body poses.
//- **`Process Video Frame`**: Scheduled with `CADisplayLink` to frequently update and process frames from the video.
//- **`Clear and Draw Overlays`**: Methods to manage and update the overlay views based on Vision detection results.
//
//This structure integrates video playing and processing directly into a SwiftUI application, using Vision to analyze and overlay human body poses in real time. Adjust paths and configurations as necessary to fit the specifics of your project environment and requirements.
