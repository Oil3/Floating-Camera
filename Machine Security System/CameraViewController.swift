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
  
  private let cameraQueue = DispatchQueue(label: "cameraQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem)
  private let captureSession = AVCaptureSession()
private let videoDataOutput = AVCaptureVideoDataOutput()
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
      override func viewDidLoad() {
        super.viewDidLoad()

        // Configuration block for the capture session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080
                captureSession.commitConfiguration()

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
        cameraQueue.async {
          self.captureSession.addInput(input)
          self.captureSession.startRunning()
//        // Starting session in the background
//        cameraQueue.async {
//            self.
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(previewLayer)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: cameraQueue)  // Consistent queue usage
        captureSession.addOutput(dataOutput)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = view.bounds
        }
    }
    

  
    // The captureOutput method remains unchanged
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
      guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return }
      
      guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
        return }
      let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
        
        guard let results = finishedReq.results as? [VNClassificationObservation] else {
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
}

