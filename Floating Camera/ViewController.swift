import AVFoundation
import Cocoa
import CoreImage
import CoreML

class ViewController: NSViewController {
  private let cameraSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var videoDeviceInput: AVCaptureDeviceInput!
  var photoOutput: AVCapturePhotoOutput!
  var videoOutput: AVCaptureMovieFileOutput!
  var videoDataOutput: AVCaptureVideoDataOutput!
  var currentFrame: NSImage?
  var isContinuousRecording = false
  var isPersistingRecordings = false
  let maxRecordingDuration: CMTime = CMTimeMake(value: 1200, timescale: 1) // 20minutes segments, can grow to 3GB each, movdata is saved at start for failsafe saving,r for now saved ~/Library/Containers/Floating-Camera/Data/tmp
  var currentRecordingFileURL: URL?
  var previousRecordingFileURL: URL?
  var recordingStartTime: Date?
  var fileCounter = 0
  var fileURLs: [URL] = []
  private var recordingMonitorTimer: Timer?

  // Properties for Core Image and Core ML
  var ciContext = CIContext()
  var selectedFilter: CIFilter?
  var mlModel: MLModel?
  var applyFilter = false
  var applyMLModel = false
  var brightness: CGFloat = 0.0
  var contrast: CGFloat = 1.0
  var saturation: CGFloat = 1.0
  var inputEV: CGFloat = 0.0
  var gamma: CGFloat = 1.0
  var hue: CGFloat = 0.0
  var highlightAmount: CGFloat = 1.0
  var shadowAmount: CGFloat = 0.0
  var temperature: CGFloat = 6500.0
  var tint: CGFloat = 0.0
  var whitePoint: CGFloat = 1.0
  var invert = false
  var posterize = false
  var sharpenLuminance = false
  var unsharpMask = false
  var edges = false
  var gaborGradients = false
  
  // Additional properties for camera controls
//  var iso: Float = AVCaptureDevice.currentISO
//  var exposureDuration: CMTime = AVCaptureDevice.currentExposureDuration
  var zoomFactor: CGFloat = 1.0 {
    didSet {
//      guard let device = videoDeviceInput.device else { return }
      do {
//        try device.lockForConfiguration()
//        device.zoom = zoomFactor
//        device.unlockForConfiguration()
      } catch {
        print("Failed to set zoom factor: \(error)")
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.black.cgColor
    
    requestPermission { [weak self] granted in
      if granted {
        self?.setupCameraPreview()
        self?.setVideoRangeFormat()
      }
    }
    
    setupContextMenu()
    setupGestureRecognizers()
  }
  override func viewDidAppear() {
    super.viewDidAppear()
    cameraSession.startRunning()
    startRecordingMonitoring()
  }
//  override func viewWillDisappear() {
//    super.viewWillDisappear()
//    cameraSession.stopRunning()
//    stopRecordingMonitoring()
//  }

  private func startRecordingMonitoring() {
    recordingMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      self?.checkRecordingDuration()
    }
  }
  
  private func stopRecordingMonitoring() {
    recordingMonitorTimer?.invalidate()
    recordingMonitorTimer = nil
  }
  
  private func checkRecordingDuration() {
    guard isContinuousRecording, let startTime = recordingStartTime else { return }
    let elapsedTime = Date().timeIntervalSince(startTime)
    if elapsedTime >= maxRecordingDuration.seconds {
      videoOutput.stopRecording()
    }
  }


  
  @objc private func switchRecordingFile() {
    if isContinuousRecording {
      videoOutput.stopRecording()
      startNewRecording()
      print("Switched to new recording file")
    }


//  override func viewWillDisappear() {
//    super.viewWillDisappear()
//    cameraSession.stopRunning()
//    stopRecordingMonitoring()
//  }
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
      videoOutput.movieFragmentInterval = CMTime(value: 20, timescale: 1) //20 seeconds seems a lot , might make sense to have this editable, might make sense to lower or the opposit, technically highest security would want 1 or 2 seconds. I thought we could put these data at the beggining though -like if streaming, need to investigate this as photobooth-style unviewable gray video would be unnacceptable.
      cameraSession.addOutput(videoOutput)
    }
    
    videoDataOutput = AVCaptureVideoDataOutput()
    videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    if cameraSession.canAddOutput(videoDataOutput) {
      cameraSession.addOutput(videoDataOutput)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
    videoDeviceInput = input
    
    if let preview = previewLayer {
      view.layer?.addSublayer(preview)
      preview.videoGravity = .resizeAspect
      preview.frame = view.bounds
    }
  
 }

  
  override func viewDidLayout() {
    super.viewDidLayout()
    previewLayer?.frame = view.bounds
  }
  
  func setVideoRangeFormat() {
    cameraSession.beginConfiguration()
    defer { cameraSession.commitConfiguration() }
    
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      print("default builtinwideanglecamera needs to be changed to disccovery thing")
      return
    }
    
    for format in device.formats {
      let formatDescription = format.formatDescription
      let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
      
      if mediaSubType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
        do {
          try device.lockForConfiguration()
          device.activeFormat = format
          print("Video range format set: \(format)")
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
        device.focusMode = .locked
        device.unlockForConfiguration()
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
    menu.addItem(NSMenuItem(title: isContinuousRecording ? "Stop continuous recording" : "Continuous recroding", action: #selector(toggleRecording), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: isPersistingRecordings ? "Stop keeping every recordings " : "Keep every recordings", action: #selector(togglePersistence), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Extract Last Recording", action: #selector(savePreviousRecording), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Extract Last Minute", action: #selector(saveLastMinute), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    menu.addItem(NSMenuItem(title: "Hide", action: #selector(hide), keyEquivalent: "h"))
    
    view.menu = menu
  }
  @objc private func stopRecord() {
    if videoOutput.isRecording {
      videoOutput.stopRecording()
    }
  }
  
  @objc private func takePhoto() {
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
  }
  
  @objc private func copyFrame() {
    guard let currentFrame = currentFrame else { return }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([currentFrame])
  }
  
  @objc private func record() {
    if isContinuousRecording {
      stopContinuousRecording()
    } else {
      startContinuousRecording()
    }
  }
  
  private func startContinuousRecording() {
    isContinuousRecording = true
    startNewRecording()
  }
  
  func stopContinuousRecording() {
    isContinuousRecording = false
    videoOutput.stopRecording()
  }
  
  private func startNewRecording() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    let timestamp = dateFormatter.string(from: Date())
    
    let fileName = "FLC_\(fileCounter)_\(timestamp).mov"
    let newFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    
    if fileURLs.count < 3 {
      fileURLs.append(newFileURL)
    } else {
      // Delete the oldest file if we are not persisting recordings
      if !isPersistingRecordings {
        let oldestFileURL = fileURLs[fileCounter]
        if FileManager.default.fileExists(atPath: oldestFileURL.path) {
          try? FileManager.default.removeItem(at: oldestFileURL)
        }
      }
      fileURLs[fileCounter] = newFileURL
    }
    
    currentRecordingFileURL = newFileURL
    recordingStartTime = Date()
    videoOutput.startRecording(to: newFileURL, recordingDelegate: self)
    fileCounter = (fileCounter + 1) % 3
    print("Started recording to \(newFileURL)")
  }


  @objc private func quit() {
    NSApplication.shared.terminate(self)
  }
  
  @objc private func hide() {
    NSApplication.shared.hide(self)
  }
  
  private func setupGestureRecognizers() {
    let pinchRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    view.addGestureRecognizer(pinchRecognizer)
  }
  
  @objc private func handlePinch(_ recognizer: NSMagnificationGestureRecognizer) {
    zoomFactor *= recognizer.magnification + 1
    zoomFactor = min(max(zoomFactor, 1.0), 5.0)
    recognizer.magnification = 0
  }
  @objc private func savePreviousRecording() {
    guard let url = previousRecordingFileURL else { return }
    
    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.quickTimeMovie]
    savePanel.begin { (result) in
      if result == .OK {
        guard let destinationURL = savePanel.url else { return }
        try? FileManager.default.copyItem(at: url, to: destinationURL)
        print("Previous recording saved to \(destinationURL)")
      }
    }
  }
  
  func updateCameraSettings() {
//    guard let device = videoDeviceInput.device else { return }
    do {
//      try device.lockForConfiguration()
//      device.wh (duration: exposureDuration, iso: iso, completionHandler: nil)
//      device.unlockForConfiguration()
    } catch {
      print("Failed to update camera settings: \(error)")
    }
  }
  @objc private func toggleRecording() {
    if isContinuousRecording {
      stopContinuousRecording()
    } else {
      startContinuousRecording()
    }
    setupContextMenu()
  }
  
  @objc private func togglePersistence() {
    isPersistingRecordings.toggle()
    setupContextMenu()
  }
  
  @objc private func saveLastMinute() {
    guard let url = currentRecordingFileURL else { return }
    
    // Get the duration of the current recording
    let asset = AVAsset(url: url)
    let endTime = 120.0 //segments are of 2min , else can use usingCMTimeGetSeconds(asset.duration)
    let startTime = max(endTime - 60, 0) // Last 60 seconds
    
    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("lastMinute_\(UUID().uuidString).mov")
    exportSession?.outputURL = outputURL
    exportSession?.outputFileType = .mov
    exportSession?.timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 1), duration: CMTime(seconds: 60, preferredTimescale: 1))
    
    exportSession?.exportAsynchronously {
      if exportSession?.status == .completed {
        DispatchQueue.main.async {
          let savePanel = NSSavePanel()
          savePanel.allowedContentTypes = [.quickTimeMovie]
          savePanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
          savePanel.begin { result in
            if result == .OK, let destinationURL = savePanel.url {
              try? FileManager.default.moveItem(at: outputURL, to: destinationURL)
              print("Last minute recording saved to \(destinationURL)")
            }
          }
        }
      } else if let error = exportSession?.error {
        print("Failed to export last minute: \(error)")
      }
    }
  }

  
  
}

extension ViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = NSImage(data: imageData) else { return }
    
    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.image]
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
    if let error = error {
      print("Recording error: \(error)")
    }
    
    if isContinuousRecording {
      startNewRecording()
    }
  }
}




extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    
    // Apply filters and models to the ciImage
    if applyFilter {
      ciImage = applyCurrentFilters(to: ciImage)
    }
    
    let bitmapRep = NSBitmapImageRep(ciImage: ciImage)
    let image = NSImage()
    image.addRepresentation(bitmapRep)
    self.currentFrame = image
  }
  
  func applyCurrentFilters(to ciImage: CIImage) -> CIImage {
    var ciImage = ciImage
    
    if let selectedFilter = selectedFilter {
      selectedFilter.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = selectedFilter.outputImage ?? ciImage
    }
    
    if invert {
      let filter = CIFilter(name: "CIColorInvert")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if posterize {
      let filter = CIFilter(name: "CIColorPosterize")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if sharpenLuminance {
      let filter = CIFilter(name: "CISharpenLuminance")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if unsharpMask {
      let filter = CIFilter(name: "CIUnsharpMask")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if edges {
      let filter = CIFilter(name: "CIEdges")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if gaborGradients {
      let filter = CIFilter(name: "CIGaborGradients")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    let colorControlsFilter = CIFilter(name: "CIColorControls")
    colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    colorControlsFilter?.setValue(brightness, forKey: kCIInputBrightnessKey)
    colorControlsFilter?.setValue(contrast, forKey: kCIInputContrastKey)
    colorControlsFilter?.setValue(saturation, forKey: kCIInputSaturationKey)
    ciImage = colorControlsFilter?.outputImage ?? ciImage
    
    let gammaFilter = CIFilter(name: "CIGammaAdjust")
    gammaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    gammaFilter?.setValue(gamma, forKey: "inputPower")
    ciImage = gammaFilter?.outputImage ?? ciImage
    
    let hueFilter = CIFilter(name: "CIHueAdjust")
    hueFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    hueFilter?.setValue(hue, forKey: kCIInputAngleKey)
    ciImage = hueFilter?.outputImage ?? ciImage
    
    let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
    highlightShadowFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    highlightShadowFilter?.setValue(highlightAmount, forKey: "inputHighlightAmount")
    highlightShadowFilter?.setValue(shadowAmount, forKey: "inputShadowAmount")
    ciImage = highlightShadowFilter?.outputImage ?? ciImage
    
    let temperatureAndTintFilter = CIFilter(name: "CITemperatureAndTint")
    temperatureAndTintFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    temperatureAndTintFilter?.setValue(CIVector(x: temperature, y: tint), forKey: "inputNeutral")
    ciImage = temperatureAndTintFilter?.outputImage ?? ciImage
    
    let whitePointAdjustFilter = CIFilter(name: "CIWhitePointAdjust")
    whitePointAdjustFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    whitePointAdjustFilter?.setValue(CIColor(red: CGFloat(Float(whitePoint)), green: CGFloat(Float(whitePoint)), blue: CGFloat(Float(whitePoint))), forKey: kCIInputColorKey)
    ciImage = whitePointAdjustFilter?.outputImage ?? ciImage
    
    if let mlModel = mlModel, applyMLModel {
      let mlFilter = CIFilter(name: "CICoreMLModelFilter")!
      mlFilter.setValue(mlModel, forKey: "inputModel")
      mlFilter.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = mlFilter.outputImage ?? ciImage
    }
    
    return ciImage
  }
}
