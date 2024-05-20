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
    private let inferenceInterval: TimeInterval = 1.0 // Run inference every 1 second
    private var detectionOverlay: CALayer! = nil
    
    private let cameraQueue = DispatchQueue(label: "cameraQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem)
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var bufferSize: CGSize = .zero
    
    private var selectedVNModel: VNCoreMLModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupDetectionOverlay()
        loadModel()
    }

    func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

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
        captureSession.startRunning()
    }

    func setupDetectionOverlay() {
        detectionOverlay = CALayer()
        detectionOverlay.frame = view.bounds
        detectionOverlay.masksToBounds = true
        view.layer.addSublayer(detectionOverlay)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = view.bounds
        }
        detectionOverlay.frame = view.bounds
        detectionOverlay.layoutIfNeeded()
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
                self.processObservations(results)
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

    func processObservations(_ observations: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detectionOverlay.sublayers?.removeAll(where: { $0.name == "objectBox" })

            for observation in observations {
                let boundingBox = observation.boundingBox
                let convertedRect = self.convertBoundingBox(boundingBox)
                let boundingBoxLayer = self.createBoundingBoxLayer(frame: convertedRect)
                self.detectionOverlay.addSublayer(boundingBoxLayer)
            }
        }
    }

    func convertBoundingBox(_ boundingBox: CGRect) -> CGRect {
        let width = boundingBox.width * view.bounds.width
        let height = boundingBox.height * view.bounds.height
        let x = boundingBox.origin.x * view.bounds.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * view.bounds.height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func createBoundingBoxLayer(frame: CGRect) -> CALayer {
        let layer = CALayer()
        layer.frame = frame
        layer.borderColor = UIColor.yellow.cgColor
        layer.borderWidth = 2.0
        layer.name = "objectBox"
        return layer
    }
}
