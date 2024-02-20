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
//        @IBOutlet private weak var previewLayer : previewLayer!

  
    private var videoDeviceInput: AVCaptureDeviceInput!

    override func viewDidLoad() {
        super.viewDidLoad()

        runtimeData = (NSApplication.shared.delegate as? AppDelegate)?.runtimeData

        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor //resizing more responsive with an opaque bg
        requestPermission { [weak self] granted in
            if granted {
                self?.setupCameraPreview()
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(setupCameraAutoFocusAndExposure), name: .setupCamera, object: nil)
    }


    private func setupCameraPreview() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
      
//        cameraSession.sessionPreset = .high //ZZ haven't see much difference
        cameraSession.sessionPreset = .hd1280x720
        cameraSession.addInput(input)
        

        previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        if let preview = previewLayer {
            view.layer?.addSublayer(preview)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds //bounds
        }
    }

    override func viewDidAppear() {
        cameraSession.startRunning()
    }

    override func viewWillDisappear() {
        cameraSession.stopRunning()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        previewLayer?.frame = view.bounds
}
   
    private func requestPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { //ZZ works good.
                    completion(granted)
                }
            }

        case .denied, .restricted:
            completion(false)

        default:
            completion(false)
        }
    }
    
    @objc func setupCameraAutoFocusAndExposure() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
            }
    }
       
//    @objc func setautomaticallyEnablesLowLightBoostWhenAvailable() {
//        guard let device = AVCaptureDevice.default(for: .video) else { return }
//        do {
//            try device.lockForConfiguration()
//            if device.isLowLightBoostSupported {// oops its just for IOS, keeping
//     }

//     @objc
//        func subjectAreaDidChange(notification: NSNotification) {
//            let devicePoint = CGPoint(x: 0.5, y: 0.5)
//            focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
//        }

    @objc private func updateWindowSize(notification: Notification) {
        if let sizeValue = notification.userInfo?["size"] as? CGSize {
            self.previewLayer?.frame = CGRect(origin: .zero, size: sizeValue)
        }
    }


    
    override func mouseDown(with event: NSEvent) {
        guard let window = view.window else { return }

        let startingPoint = event.locationInWindow

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

