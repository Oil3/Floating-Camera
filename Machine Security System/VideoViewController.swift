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
import MobileCoreServices  // This import is necessary for file types

class VideoViewController: UIViewController, UIDocumentPickerDelegate {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoOutput: AVPlayerItemVideoOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        showFilePicker()  // Call the file picker
    }

    func showFilePicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [UTType.movie.identifier], in: .open)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    // Implement the document picker delegate method
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
        
        let outputSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
        item.add(videoOutput!)
        
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer!)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: item)
        player?.play()
    }

    @objc func processVideoFrame(displayLink: CADisplayLink) {
        guard let videoOutput = videoOutput else { return }
        
        let nextVSync = displayLink.timestamp + displayLink.duration
        let itemTime = videoOutput.itemTime(forHostTime: nextVSync)
        
        if videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
           let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) {
            // Process the pixel buffer with Vision and CoreML
        }
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }
}





