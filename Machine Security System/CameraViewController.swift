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

        // Configuration block for the capture session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            captureSession.commitConfiguration()
            print("AVCaptureDevice error")
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            captureSession.commitConfiguration()
            print("AVCaptureDeviceInput error")
            return
        }
      
        captureSession.addOutput(videoDataOutput)
        videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        captureSession.commitConfiguration()

        cameraQueue.async { [self] in
        captureSession.addInput(input)
        captureSession.startRunning()
//        // Starting session in the background
//        cameraQueue.async {
//            self.
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspect
      previewLayer.frame = view.bounds
              DispatchQueue.main.async {
        self.view.layer.addSublayer(previewLayer)
    }
            detectionOverlay = CALayer() // Container for drawing bounding boxes
        detectionOverlay.bounds = view.bounds
        detectionOverlay.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        view.layer.addSublayer(detectionOverlay)

    
    
}
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
        }
    }
    

  
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
      guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return }
      
      guard let model = try? VNCoreMLModel(for: ResNet().model) else {
        return }
      let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
        
        guard let results = finishedReq.results as? [VNClassificationObservation]  else {
          return
        }
        
        guard let firstObservation = results.first else {
          return
        }
        
        print(firstObservation.identifier, firstObservation.confidence)
      }
      
      try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
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
    guard let results = request.results as? [VNFaceObservation] else { return }
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    detectionOverlay.sublayers?.removeAll(where: { $0 is CAShapeLayer })  // Remove old face layers

    for observation in results {
        let boundingBox = observation.boundingBox
        let normalizedRect = VNImageRectForNormalizedRect(boundingBox, Int(bufferSize.width), Int(bufferSize.height))
        let faceLayer = CAShapeLayer()
        faceLayer.frame = normalizedRect
        faceLayer.borderColor = UIColor.yellow.cgColor
        faceLayer.borderWidth = 2
        detectionOverlay.addSublayer(faceLayer)
    }

    CATransaction.commit()
}
func drawPose(from observations: [VNHumanBodyPoseObservation]) {
        // Additional implementation to draw keypoints for wrists, hands, head
    }
func updateDetectionOverlay() {
    if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
        detectionOverlay.frame = previewLayer.bounds
    }
}
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let currentTime = Date()
    guard currentTime.timeIntervalSince(lastInferenceTime) >= inferenceInterval else { return }
    lastInferenceTime = currentTime
    updateDetectionOverlay()

    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let exifOrientation = orientationIOS()

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
    try? handler.perform([humanDetectionRequest, faceDetectionRequest])
}






}

