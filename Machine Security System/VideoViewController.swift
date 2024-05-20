//
//  VideoViewController.swift
//  Machine Security System
//
//  Created by Almahdi Morris on 05/05/24.
//
import UIKit
import AVFoundation
import Vision
import CoreML
import MobileCoreServices

class VideoViewController: UIViewController, UIDocumentPickerDelegate {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var boundingBoxView: BoundingBoxView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boundingBoxView = BoundingBoxView(frame: view.bounds)
        boundingBoxView.backgroundColor = .clear
        view.addSubview(boundingBoxView)
        
        addPlaybackControls()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showFilePicker()
    }
    
    func showFilePicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [UTType.movie.identifier], in: .open)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("No file selected.")
            return
        }
        setupVideoPlayer(from: url)
    }
    
    func setupVideoPlayer(from url: URL) {
        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        let outputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
        item.add(videoOutput!)
        
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        view.layer.insertSublayer(playerLayer!, below: boundingBoxView.layer)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: item)
        
        player?.play()
        setupDisplayLink()
    }
    
    @objc func processVideoFrame(displayLink: CADisplayLink) {
        guard let videoOutput = videoOutput else { return }
        
        let nextVSync = displayLink.timestamp + displayLink.duration
        let itemTime = videoOutput.itemTime(forHostTime: nextVSync)
        
        if videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
           let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) {
            // Process the pixel buffer with Vision and CoreML
            performVisionRequest(on: pixelBuffer)
        }
    }
    
    func performVisionRequest(on pixelBuffer: CVPixelBuffer) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: yolov8x2AAA().model)) { request, error in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                DispatchQueue.main.async {
                    self.boundingBoxView.observations = results
                }
            }
        }
        try? requestHandler.perform([request])
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }
    
    func addPlaybackControls() {
        let playButton = UIButton(frame: CGRect(x: 20, y: 50, width: 100, height: 50))
        playButton.backgroundColor = .blue
        playButton.setTitle("Toggle Play", for: .normal)
        playButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        view.addSubview(playButton)
    }
    
    @objc func togglePlayPause() {
        if player?.timeControlStatus == .playing {
            player?.pause()
        } else {
            player?.play()
        }
    }
    
    func setupDisplayLink() {
        let displayLink = CADisplayLink(target: self, selector: #selector(processVideoFrame))
        displayLink.add(to: .current, forMode: .common)
    }
}
