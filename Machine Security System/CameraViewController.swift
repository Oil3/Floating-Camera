  //
  //  CameraViewController.swift
  //  Machine Security System
  //
  //  Created by Almahdi Morris on 04/25/24.
import SwiftUI
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
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
 override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupDetectionOverlay()
        drawCenterCircle()

    }
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    drawCenterCircle()  // Ensures the circle is drawn after everything is laid out
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
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = view.bounds
 
 DispatchQueue.main.async {
        self.view.layer.addSublayer(previewLayer)
    }

    captureSession.commitConfiguration()

    // Start the session on the background queue
    cameraQueue.async {
        self.captureSession.startRunning()
    }
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
    detectionOverlay.layoutIfNeeded()  // Forces layout update immediately
}
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let currentTime = Date()
    guard currentTime.timeIntervalSince(lastInferenceTime) >= inferenceInterval else { return }
    lastInferenceTime = currentTime
    updateDetectionOverlay()

    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let exifOrientation = orientationIOS()
      
      guard let model = try? VNCoreMLModel(for: ResNet().model) else {
        return }
      let coreMLRequest = VNCoreMLRequest(model: model) { (finishedReq, error) in
        
        guard let results = finishedReq.results as? [VNClassificationObservation]  else {
          return
        }
        
        guard let firstObservation = results.first else {
          return
        }
        
        print(firstObservation.identifier, firstObservation.confidence)
      }
        // Human and Face Detection Requests
    let humanDetectionRequest = VNDetectHumanRectanglesRequest { [weak self] request, error in
        DispatchQueue.main.async {
            self?.drawHumanBoundingBoxes(request)
            self?.detectPose(in: pixelBuffer, orientation: exifOrientation)
        }
    }

    let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
        DispatchQueue.main.async {
            self?.drawFaceBoundingBoxes(request)
        }
    }

    // Execute Vision Requests
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
    try? handler.perform([coreMLRequest, humanDetectionRequest, faceDetectionRequest])
}

  
  public func orientationIOS() -> CGImagePropertyOrientation {
    let curDeviceOrientation = UIDevice.current.orientation
    let exifOrientation: CGImagePropertyOrientation
    
    switch curDeviceOrientation {
    case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
      exifOrientation = .left
    case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
      exifOrientation = .upMirrored
    case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
      exifOrientation = .down
    case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
      exifOrientation = .up
    default:
      exifOrientation = .up
    }
    return exifOrientation
  }
func drawFaceBoundingBoxes(_ request: VNRequest) {
    guard let results = request.results as? [VNHumanObservation] else { return }
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

    // Only remove layers associated with previous human detections
    detectionOverlay.sublayers?.removeAll(where: { $0.name == "humanBox" })
    
    for observation in results {
        let boundingBox = observation.boundingBox
        let normalizedRect = VNImageRectForNormalizedRect(boundingBox, Int(bufferSize.width), Int(bufferSize.height))
        let boundingBoxLayer = CALayer()
        boundingBoxLayer.name = "humanBox"
        boundingBoxLayer.frame = normalizedRect
        boundingBoxLayer.borderColor = UIColor.red.cgColor
        boundingBoxLayer.borderWidth = 2
        detectionOverlay.addSublayer(boundingBoxLayer)
    }
    
    CATransaction.commit()
}

func drawPose(from observations: [VNHumanBodyPoseObservation]) {
    for observation in observations {
        do {
            let recognizedPoints = try observation.recognizedPoints(.all)
            for (_, point) in recognizedPoints where point.confidence > 0.5 {
                let normalizedPoint = CGPoint(x: point.location.x, y: 1 - point.location.y)  // Flip y-coordinate because Vision uses a coordinate system with origin at the bottom left
                let pointLayer = createPointLayer(at: normalizedPoint)
                DispatchQueue.main.async {
                    self.detectionOverlay.addSublayer(pointLayer)
                }
            }
        } catch {
            print("Failed to decode points from observation")
        }
    }
}


func createPointLayer(at normalizedPoint: CGPoint) -> CALayer {
    let pointSize: CGFloat = 10.0
    let pointLayer = CALayer()
    pointLayer.backgroundColor = UIColor.green.cgColor
    pointLayer.frame = CGRect(x: normalizedPoint.x * detectionOverlay.bounds.width - pointSize / 2, y: normalizedPoint.y * detectionOverlay.bounds.height - pointSize / 2, width: pointSize, height: pointSize)
    pointLayer.cornerRadius = pointSize / 2
    return pointLayer
}

func updateDetectionOverlay() {
            DispatchQueue.main.async {
    if let previewLayer = self.view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
      self.detectionOverlay.frame = previewLayer.bounds
    }
    }
}

    func drawHumanBoundingBoxes(_ request: VNRequest) {
        guard let results = request.results as? [VNHumanObservation] else { return }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        //detectionOverlay.sublayers = nil // Remove all old layers
        
        for observation in results {
            let boundingBox = observation.boundingBox
            let normalizedRect = VNImageRectForNormalizedRect(boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            let boundingBoxLayer = CALayer()
            boundingBoxLayer.frame = normalizedRect
            boundingBoxLayer.borderColor = UIColor.red.cgColor
            boundingBoxLayer.borderWidth = 2
            detectionOverlay.addSublayer(boundingBoxLayer)
        }
        
        CATransaction.commit()
    }

    func detectPose(in pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }
            DispatchQueue.main.async {
                self?.drawPose(from: observations)
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:]).perform([request])
    }


func drawCenterCircle() {
 if detectionOverlay.sublayers?.contains(where: { $0.name == "centerCircle" }) == false {
        let circleLayer = CAShapeLayer()
        circleLayer.name = "centerCircle"
        let radius: CGFloat = 50.0 // Radius of the circle
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: detectionOverlay.bounds.midX, y: detectionOverlay.bounds.midY), radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.blue.cgColor
        circleLayer.lineWidth = 5.0

        DispatchQueue.main.async {
            self.detectionOverlay.addSublayer(circleLayer)
        }
    }
}


}

