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
    }



    private func setupCameraPreview() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
      
//        cameraSession.sessionPreset = .high //ZZ it's the default anyway
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
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .denied, .restricted:
            completion(false)

        default:
            completion(false)
        }
    }

//    @objc private func c(notification: Notification) {
//        if let size = notification.userInfo?["size"] as? CGFloat {
//            self.previewLayer?.frame = CGRect (x: 0, y: 0, width: size, height: size)
//            self.view.layer?.cornerRadius = 0
//        }
//    }
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

