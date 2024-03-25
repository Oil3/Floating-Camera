    //
    //  ViewController.swift
    //  Floating Camera
    //  Created by ZZS on 14/02/2024.

import AVFoundation
import Cocoa


class ViewController: NSViewController {
    private weak var runtimeData: RuntimeData!
    private let cameraSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoDeviceInput: AVCaptureDeviceInput!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runtimeData = (NSApplication.shared.delegate as? AppDelegate)?.runtimeData
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        requestPermission { [weak self] granted in
            if granted {
                self?.setupCameraPreview()
                self?.setVideoRangeFormat() // Sets the video range format
                
            }
        }
            //        NotificationCenter.default.addObserver(self, selector: #selector(setupCameraAutoFocusAndExposure), name: .setupCamera, object: nil)
    }
    
    
    private func setupCameraPreview() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        
            //        cameraSession.sessionPreset = .hd1280x720
        if !cameraSession.inputs.contains(where: { $0 == input }) {
            cameraSession.addInput(input)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        videoDeviceInput = input // Make sure to assign the input to the property
        
        if let preview = previewLayer {
            view.layer?.addSublayer(preview)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        cameraSession.startRunning()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        cameraSession.stopRunning()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        previewLayer?.frame = view.bounds
    }
    func setVideoRangeFormat() {
    cameraSession.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Front camera not available")
            return
        }
        
        for format in device.formats {
            let formatDescription = format.formatDescription
            let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            
            if mediaSubType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && dimensions.width == 1552 && dimensions.height == 1552 {
                do {
                    try device.lockForConfiguration()
                    device.activeFormat = format
    
                    print("Video range format set: \(format)")
//                    device.activeVideoMinFrameDuration = 24
//                    device.activeVideoMaxFrameDuration = 30
                    
                        // Print the active format after setting the new format
                    let activeFormat = device.activeFormat
                    let activeFormatDescription = activeFormat.formatDescription
                    let activeDimensions = CMVideoFormatDescriptionGetDimensions(activeFormatDescription)
                    let activeMediaType = CMFormatDescriptionGetMediaType(activeFormatDescription)
                    print("Active format: Resolution: \(activeDimensions.width)x\(activeDimensions.height), Media Type: \(activeMediaType)")
                    device.unlockForConfiguration()

                    return
                } catch {
                    print("Error setting video range format: \(error)")
                }
                                cameraSession.commitConfiguration()
        }
        }
    print("Video range format not found")
    }


private func requestPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    default:
        completion(false)
    }
}

@IBAction func unlockConfiguration(_ sender: NSMenuItem) {
    let device = AVCaptureDevice.default(for: .video) 
    device?.unlockForConfiguration()
}



@IBAction private func focusAndExpose(_ gestureRecognizer: NSClickGestureRecognizer) {
    guard let view = gestureRecognizer.view, let previewLayer = self.previewLayer, let device = AVCaptureDevice.default(for: .video) else { return } //self.videoDeviceInput?.device else { return }
    let clickLocation = gestureRecognizer.location(in: view)
    let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: clickLocation)
    print("Calculated device point: \(devicePoint)")
    
    do {    
        try device.lockForConfiguration()
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.locked) {
            device.focusPointOfInterest = devicePoint
            device.focusMode = .locked  // Or .autoFocus based on needs
            device.unlockForConfiguration()
            
                //  to include exposure settings:
                // if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                //     device.exposurePointOfInterest = devicePoint
                //     device.exposureMode = .autoExpose
                // }
        }
    } catch {
        print("Could not lock device for configuration: \(error)")
    }
}


override func mouseDown(with event: NSEvent) {
    guard let window = view.window, let _ = self.previewLayer else { return }
    let startingPoint = event.locationInWindow
        //        // Convert the starting point to the view's coordinate system
        //        let pointInView = view.convert(startingPoint, from: nil)
        //        // Convert the point from the view's coordinate system to the AVCaptureDevice's coordinate system
    
    
    window.trackEvents(matching: [.leftMouseDragged, .leftMouseUp], timeout: .infinity, mode: .default) { event, stop in
        guard let event = event else { return }
        switch event.type {
        case .leftMouseUp:
            NSApp.postEvent(event, atStart: false)
            stop.pointee = true
            
        case .leftMouseDragged:
            let currentPoint = event.locationInWindow
            if abs(currentPoint.x - startingPoint.x) >= 5 || abs(currentPoint.y - startingPoint.y) >= 5 {
                stop.pointee = true
                window.performDrag(with: event)
            }
            
        default:
            break
        }
    }
}
}
