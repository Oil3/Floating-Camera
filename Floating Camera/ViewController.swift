import AVFoundation
import Cocoa

class ViewController: NSViewController {
  private weak var runtimeData: RuntimeData!
  private let cameraSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var videoDeviceInput: AVCaptureDeviceInput!
  var photoOutput: AVCapturePhotoOutput!
  var videoOutput: AVCaptureMovieFileOutput!
  var videoDataOutput: AVCaptureVideoDataOutput!
  var currentFrame: NSImage?
  
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
    
    setupContextMenu()
  }
  
  private func setupCameraPreview() {
    guard let device = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device) else { return }
    
    if !cameraSession.inputs.contains(where: { $0 == input }) {
      cameraSession.addInput(input)
    }
    
    photoOutput = AVCapturePhotoOutput()
    if cameraSession.canAddOutput(photoOutput) {
      cameraSession.addOutput(photoOutput)
    }
    
    videoOutput = AVCaptureMovieFileOutput()
    if cameraSession.canAddOutput(videoOutput) {
      cameraSession.addOutput(videoOutput)
    }
    
    videoDataOutput = AVCaptureVideoDataOutput()
    videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    if cameraSession.canAddOutput(videoDataOutput) {
      cameraSession.addOutput(videoDataOutput)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
    videoDeviceInput = input // Make sure to assign the input to the property
    
    if let preview = previewLayer {
      view.layer?.addSublayer(preview)
      preview.videoGravity = .resizeAspect // Maintain aspect ratio
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
    defer { cameraSession.commitConfiguration() } // Ensure configuration is committed
    
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      print("Front camera not available")
      return
    }
    
    for format in device.formats {
      let formatDescription = format.formatDescription
      let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
      let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
      
      if mediaSubType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
        do {
          try device.lockForConfiguration()
          device.activeFormat = format
          print("Video range format set: \(format)")
          
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
    guard let view = gestureRecognizer.view, let previewLayer = self.previewLayer, let device = AVCaptureDevice.default(for: .video) else { return }
    let clickLocation = gestureRecognizer.location(in: view)
    let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: clickLocation)
    print("Calculated device point: \(devicePoint)")
    
    do {
      try device.lockForConfiguration()
      if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.locked) {
        device.focusPointOfInterest = devicePoint
        device.focusMode = .locked  // Or .autoFocus based on needs
        device.unlockForConfiguration()
        
        // Optional: Include exposure settings
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
  
  private func setupContextMenu() {
    let menu = NSMenu()
    
    menu.addItem(NSMenuItem(title: "Take Photo", action: #selector(takePhoto), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Copy Frame", action: #selector(copyFrame), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Record", action: #selector(record), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Stop Record", action: #selector(stopRecord), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    menu.addItem(NSMenuItem(title: "Hide", action: #selector(hide), keyEquivalent: "h"))
    
    view.menu = menu
  }
  
  @objc private func takePhoto() {
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
    print("Take Photo selected")
  }
  
  @objc private func copyFrame() {
    guard let currentFrame = currentFrame else { return }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([currentFrame])
    print("Copy Frame selected")
  }
  
  @objc private func record() {
    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.mov")
    videoOutput.startRecording(to: outputURL, recordingDelegate: self)
    print("Record selected")
  }
  
  @objc private func stopRecord() {
    if videoOutput.isRecording {
      videoOutput.stopRecording()
      print("Stop Record selected")
    }
  }
  
  @objc private func quit() {
    NSApplication.shared.terminate(self)
  }
  
  @objc private func hide() {
    NSApplication.shared.hide(self)
  }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = NSImage(data: imageData) else { return }
    
    let savePanel = NSSavePanel()
    savePanel.allowedFileTypes = ["jpg"]
    savePanel.begin { (result) in
      if result == .OK {
        guard let url = savePanel.url else { return }
        try? imageData.write(to: url)
      }
    }
  }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    let savePanel = NSSavePanel()
    savePanel.allowedFileTypes = ["mov"]
    savePanel.begin { (result) in
      if result == .OK {
        guard let url = savePanel.url else { return }
        try? FileManager.default.moveItem(at: outputFileURL, to: url)
      }
    }
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let bitmapRep = NSBitmapImageRep(ciImage: ciImage)
    let image = NSImage()
    image.addRepresentation(bitmapRep)
    self.currentFrame = image
  }
}
