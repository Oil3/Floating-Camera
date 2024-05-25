//
//  CameraController.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//
import AVFoundation
import SwiftUI

class CameraController: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var photoOutput = AVCapturePhotoOutput()
    @Published var videoOutput = AVCaptureVideoDataOutput()
    @Published var exposure: Double = 0
    @Published var contrast: Double = 0
    @Published var resolution: AVCaptureSession.Preset = .high
    @Published var outputFolder: URL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
    @Published var coreMLModelURL: URL?
    @Published var isCoreMLActivated: Bool = false
    @Published var isRecording = false
    @Published var showCoreMLModelPicker = false
    @Published var showOutputFolderPicker = false

    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.sessionPreset = resolution
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session.addInput(input)
        session.addOutput(photoOutput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(videoOutput)
        
        session.startRunning()
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func copyFrame() {
        // Implementation for copying the current frame
    }
    
    func pauseLiveFeed() {
        session.stopRunning()
    }
    
    func startRecording() {
        isRecording = true
        // Implementation for starting video recording
    }
    
    func updateResolution(to preset: AVCaptureSession.Preset) {
        session.beginConfiguration()
        session.sessionPreset = preset
        session.commitConfiguration()
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Handle saving or processing the image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Implementation for handling live feed frames
    }
}
