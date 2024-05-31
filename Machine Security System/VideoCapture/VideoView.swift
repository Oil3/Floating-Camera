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
                //.frame(height: 400)
                .overlay(
                    VisionOverlayView(player: player, isEnabled: $isVisionEnabled),
                    alignment: .center
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
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.03, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] _ in
            self?.processCurrentFrame()
        }
    }
    
private func processCurrentFrame() {
    guard isEnabled, let currentItem = player?.currentItem else { return }

    DispatchQueue.main.async { [weak self] in
        guard let self = self,
              let overlayView = self.overlayView,
              let track = currentItem.asset.tracks(withMediaType: .video).first else { return }

        let overlayAspectRatio = overlayView.bounds.width / overlayView.bounds.height
        let videoSize = track.naturalSize
        let videoTransform = track.preferredTransform
        let transformedVideoSize = videoSize.applying(videoTransform)
        let videoWidth = abs(transformedVideoSize.width)
        let videoHeight = abs(transformedVideoSize.height)
        let aspectRatio = videoWidth / videoHeight
        var scale: CGFloat
        if aspectRatio > overlayAspectRatio { // video is wider
            scale = overlayView.bounds.height / videoHeight
        } else {
            scale = overlayView.bounds.width / videoWidth
        }
        let xOffset = (overlayView.bounds.width - videoWidth * scale) / 2
        let yOffset = (overlayView.bounds.height - videoHeight * scale) / 2

        // Continue processing with these calculations
        let imgGenerator = AVAssetImageGenerator(asset: currentItem.asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let timestamp = self.player?.currentTime() ?? CMTime.zero
        imgGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: timestamp)]) { _, image, _, _, _ in
            if let cgImage = image {
                self.runBodyAndHandPoseDetection(CGImage: cgImage, scale: scale, xOffset: xOffset, yOffset: yOffset)
            }
        }
    }
}


private func runBodyAndHandPoseDetection(CGImage: CGImage, scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
    let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    let handPoseRequest = VNDetectHumanHandPoseRequest()
    handPoseRequest.maximumHandCount = 4

    let requests = [bodyPoseRequest, handPoseRequest]
    let handler = VNImageRequestHandler(cgImage: CGImage, options: [:])
    DispatchQueue.global(qos: .userInteractive).async {
        do {
            try handler.perform(requests)
            if let bodyObservations = bodyPoseRequest.results as? [VNHumanBodyPoseObservation] {
                self.drawBodyPoses(bodyObservations)//, scale: scale, xOffset: xOffset, yOffset: yOffset)
            }
            if let handObservations = handPoseRequest.results as? [VNHumanHandPoseObservation] {
                self.drawHandPoses(handObservations)//, scale: scale, xOffset: xOffset, yOffset: yOffset)
            }
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
    guard let overlayView = overlayView, let player = player, let videoTrack = player.currentItem?.asset.tracks(withMediaType: .video).first else { return }

    // Calculate the transform to scale points to the video layer's frame
    let videoSize = videoTrack.naturalSize
    let videoTransform = videoTrack.preferredTransform
    let transformedVideoSize = videoSize.applying(videoTransform)
    let videoWidth = abs(transformedVideoSize.width)
    let videoHeight = abs(transformedVideoSize.height)

    // Adjust for aspect fill or aspect fit
    let aspectRatio = videoWidth / videoHeight
    let overlayAspectRatio = overlayView.bounds.width / overlayView.bounds.height
    var scale: CGFloat
    if aspectRatio > overlayAspectRatio { // video is wider
        scale = overlayView.bounds.height / videoHeight
    } else {
        scale = overlayView.bounds.width / videoWidth
    }

    let xOffset = (overlayView.bounds.width - videoWidth * scale) / 2
    let yOffset = (overlayView.bounds.height - videoHeight * scale) / 2

    let points = try? observation.recognizedPoints(.all)
    points?.values.filter({ $0.confidence > 0.5 }).forEach { point in
        let x = (point.location.x * videoWidth * scale) + xOffset
        let y = ((1 - point.location.y) * videoHeight * scale) + yOffset
        DispatchQueue.main.async {
          self.drawCircle(at: CGPoint(x: x, y: y), in: overlayView, color: .blue)
        }
    }
}
private func drawHandBoxes(_ observations: [VNHumanHandPoseObservation]) {
    guard let overlayView = overlayView else { return }

    DispatchQueue.main.async { [weak self] in
        self?.clearOverlays()  // Clear previous overlays
        
        for observation in observations {
            guard let points = try? observation.recognizedPoints(.all) else { continue }
            
            for (_, point) in points where point.confidence > 0.6 {
                let x = point.location.x * overlayView.frame.size.width
                let y = (1 - point.location.y) * overlayView.frame.size.height
                self?.drawRectangle(at: CGPoint(x: x, y: y), in: overlayView, color: .green)  // Draw rectangles for hand points
            }
        }
    }
}

private func drawRectangle(at point: CGPoint, in view: UIView, color: UIColor) {
    let rectangleWidth: CGFloat = 8  // Width of the rectangle
    let rectangleHeight: CGFloat = 20  // Height of the rectangle
    let rectangleView = UIView(frame: CGRect(x: point.x - rectangleWidth / 2, y: point.y - rectangleHeight / 2, width: rectangleWidth, height: rectangleHeight))
    rectangleView.backgroundColor = color
    view.addSubview(rectangleView)
}
    private func drawHandPoses(_ observations: [VNHumanHandPoseObservation]) {
        guard let overlayView = overlayView else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.clearOverlays()  // Optionally clear previous overlays
            
            for observation in observations {
                guard let points = try? observation.recognizedPoints(.all) else { continue }
                
                for (_, point) in points where point.confidence > 0.4 {
                    let x = point.location.x * overlayView.frame.size.width
                    let y = (1 - point.location.y) * overlayView.frame.size.height
                    self?.drawCircle(at: CGPoint(x: x, y: y), in: overlayView, color: .green)  // Use green for hands
                }
            }
        }
    }
private func drawBodyPoses(_ observations: [VNHumanBodyPoseObservation]) {
    guard let overlayView = overlayView, let player = player, let videoTrack = player.currentItem?.asset.tracks(withMediaType: .video).first else { return }

    // Calculate the transform to scale points to the video layer's frame
    let videoSize = videoTrack.naturalSize
    let videoTransform = videoTrack.preferredTransform
    let transformedVideoSize = videoSize.applying(videoTransform)
    let videoWidth = abs(transformedVideoSize.width)
    let videoHeight = abs(transformedVideoSize.height)

    // Adjust for aspect fill or aspect fit
    let aspectRatio = videoWidth / videoHeight
                 DispatchQueue.main.async {
    let overlayAspectRatio = overlayView.bounds.width / overlayView.bounds.height
    var scale: CGFloat
    if aspectRatio > overlayAspectRatio { // video is wider
        scale = overlayView.bounds.height / videoHeight
    } else {
        scale = overlayView.bounds.width / videoWidth
    }

    let xOffset = (overlayView.bounds.width - videoWidth * scale) / 2
    let yOffset = (overlayView.bounds.height - videoHeight * scale) / 2

    DispatchQueue.main.async { [weak self] in
        self?.clearOverlays()  // Clear existing overlays before drawing new ones

        for observation in observations {
            do {
                let recognizedPoints = try observation.recognizedPoints(.all)  // Get all recognized points
                
                for (_, point) in recognizedPoints {
                    if point.confidence > 0.5 {  // Only draw points with high confidence
                        let x = point.location.x * videoWidth * scale + xOffset
                        let y = (1 - point.location.y) * videoHeight * scale + yOffset
                        self?.drawCircle(at: CGPoint(x: x, y: y), in: overlayView, color: .blue)  // Draw blue circles for body points
                    }
                }
            } catch {
                print("Error processing body pose points: \(error)")
            }
        }
    }
}
    }

private func drawCircle(at point: CGPoint, in view: UIView, color: UIColor) {
    let circleSize: CGFloat = 4  // Size of the circle
    let circleView = UIView(frame: CGRect(x: point.x - circleSize / 2, y: point.y - circleSize / 2, width: circleSize, height: circleSize))
    circleView.backgroundColor = color
    circleView.layer.cornerRadius = circleSize / 2
    view.addSubview(circleView)
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
