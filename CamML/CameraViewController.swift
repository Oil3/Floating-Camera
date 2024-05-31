//
//  CameraViewController.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//
import UIKit
import AVFoundation
import Vision
import CoreML

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var lastInferenceTime: Date = Date(timeIntervalSince1970: 0)
    private let inferenceInterval: TimeInterval = 0.3
    private var detectionOverlay: BoundingBoxView! = nil
    
    private let cameraQueue = DispatchQueue(label: "cameraQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem)
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private var selectedVNModel: VNCoreMLModel?
    private var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupDetectionOverlay()
        loadModel()
        loadSound()
    }

    func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080

        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error setting up camera input")
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        captureSession.commitConfiguration()
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    func setupDetectionOverlay() {
        detectionOverlay = BoundingBoxView(frame: view.bounds)
        detectionOverlay.backgroundColor = .clear
        view.addSubview(detectionOverlay)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = view.bounds
        }
        detectionOverlay.frame = view.bounds
    }

    func loadModel() {
        guard let modelUrl = Bundle.main.url(forResource: "yolov8x2AAA", withExtension: "mlmodelc") else {
            fatalError("Model file not found")
        }

        do {
            let model = try MLModel(contentsOf: modelUrl)
            selectedVNModel = try VNCoreMLModel(for: model)
        } catch {
            fatalError("Error loading model: \(error)")
        }
    }

    func loadSound() {
        guard let soundURL = Bundle.main.url(forResource: "detFX", withExtension: "m4a") else {
            print("Failed to find sound file.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to load sound file: \(error)")
        }
    }

    func playSound() {
        audioPlayer?.play()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }

        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastInferenceTime) >= inferenceInterval else { return }
        lastInferenceTime = currentTime

        guard let model = selectedVNModel else { return }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.processObjectObservations(results)
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        let faceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let results = request.results as? [VNFaceObservation] {
                self.processFaceObservations(results)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request, faceRequest])
        } catch {
            print("Failed to perform request: \(error)")
        }
    }

    func processObjectObservations(_ observations: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detectionOverlay.observations = observations
            if !observations.isEmpty {
                self.playSound()
            }
        }
    }

    func processFaceObservations(_ observations: [VNFaceObservation]) {
        DispatchQueue.main.async {
            self.detectionOverlay.faceObservations = observations
        }
    }
}


//ffs
import UIKit
import SwiftUI
import Vision
import AVFoundation

fileprivate class BoundingBoxView: UIView {
    private let strokeWidth: CGFloat = 2
    private var imageRect: CGRect = .zero
    
    var observations: [VNRecognizedObjectObservation]? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var faceObservations: [VNFaceObservation]? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func updateSize(for imageSize: CGSize) {
        imageRect = AVMakeRect(aspectRatio: imageSize, insideRect: self.bounds)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if let observations = observations, !observations.isEmpty {
            subviews.forEach({ $0.removeFromSuperview() })
            for (i, observation) in observations.enumerated() {
                guard ["person", "cat", "dog", "remote"].contains(observation.labels.first?.identifier ?? "") else { continue }
                
                var color = UIColor(hue: CGFloat(i) / CGFloat(observations.count), saturation: 1, brightness: 1, alpha: 1)
                if #available(iOS 12.0, *), let recognizedObjectObservation = observation as? VNRecognizedObjectObservation {
                    let firstLabelHash = recognizedObjectObservation.labels.first?.identifier.hashValue ?? 0
                    color = UIColor(hue: CGFloat(firstLabelHash % 256) / 256.0, saturation: 1, brightness: 1, alpha: 1)
                }
                
                let rect = drawBoundingBox(context: context, observation: observation, color: color)
                addLabel(on: rect, observation: observation, color: color)
            }
        }
        
        if let faceObservations = faceObservations, !faceObservations.isEmpty {
            for observation in faceObservations {
                let color = UIColor.systemBlue
                _ = drawBoundingBox(context: context, observation: observation, color: color)
            }
        }
    }
    
    func drawBoundingBox(context: CGContext, observation: VNDetectedObjectObservation, color: UIColor) -> CGRect {
        let convertedRect = VNImageRectForNormalizedRect(observation.boundingBox, Int(imageRect.width), Int(imageRect.height))
        let x = convertedRect.minX + imageRect.minX
        let y = imageRect.maxY - convertedRect.minY - convertedRect.height
        let rect = CGRect(x: x, y: y, width: convertedRect.width, height: convertedRect.height)
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(strokeWidth)
        context.stroke(rect)
        
        return rect
    }
    
     func addLabel(on rect: CGRect, observation: VNRecognizedObjectObservation, color: UIColor) {
        guard let firstLabel = observation.labels.first?.identifier else { return }
        
        let label = UILabel()
        label.text = firstLabel
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = .black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: rect.origin.x - strokeWidth / 2,
                             y: rect.origin.y - label.frame.height,
                             width: label.frame.width,
                             height: label.frame.height)
        addSubview(label)
    }
}

