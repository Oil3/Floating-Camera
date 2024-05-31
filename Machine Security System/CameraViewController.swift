  //
  //  CameraViewController.swift
  //  Machine Security System
  //
  //  Created by Almahdi Morris on 04/25/24.
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

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform request: \(error)")
        }
    }

    func processObjectObservations(_ observations: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detectionOverlay.observations = observations
        }
    }
}
