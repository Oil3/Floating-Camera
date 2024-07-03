//
//  DeviceInfoViewModel.swift
//  Floating Camera
//
//  Created by ZZS on 28/02/2024.
//
//  DeviceInfoViewModel.swift
//  Floating Camera
//
//  Created by ZZS on 28/02/2024.
//

import AVFoundation
import Combine

struct DeviceFeature {
  let name: String
  var isSupported: Bool
  var rawValue: String? // Optional String to handle cases where there is no raw value
}

struct CameraFormat {
  let description: String
  let format: AVCaptureDevice.Format
}

class DeviceInfoViewModel: ObservableObject {
  @Published var deviceFeatures: [DeviceFeature] = []
  @Published var cameraFormats: [CameraFormat] = [] // Changed to an array of CameraFormat
  @Published var selectedFormatIndex: Int? = nil {
    didSet {
      if let index = selectedFormatIndex, index < cameraFormats.count {
        setVideoFormat(format: cameraFormats[index].format)
      }
    }
  }
  
  init() {
    fetchDeviceFeatures()
    fetchCameraFormats()
  }
  
  private func fetchDeviceFeatures() {
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    
    var features = [
      DeviceFeature(name: "Has Video Media Type", isSupported: device.hasMediaType(.video), rawValue: nil),
      DeviceFeature(name: "Continuous Auto Focus", isSupported: device.isFocusModeSupported(.continuousAutoFocus), rawValue: nil),
      DeviceFeature(name: "Focus Locked", isSupported: device.isFocusModeSupported(.locked), rawValue: nil),
      DeviceFeature(name: "Auto Expose", isSupported: device.isExposureModeSupported(.autoExpose), rawValue: nil),
      DeviceFeature(name: "Continuous Auto Exposure", isSupported: device.isExposureModeSupported(.continuousAutoExposure), rawValue: nil),
      DeviceFeature(name: "Exposure Locked", isSupported: device.isExposureModeSupported(.locked), rawValue: nil),
      DeviceFeature(name: "Custom Exposure", isSupported: device.isExposureModeSupported(.custom), rawValue: nil),
      DeviceFeature(name: "Auto White Balance", isSupported: device.isWhiteBalanceModeSupported(.autoWhiteBalance), rawValue: nil),
      DeviceFeature(name: "Continuous Auto White Balance", isSupported: device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance), rawValue: nil),
      DeviceFeature(name: "White Balance Locked", isSupported: device.isWhiteBalanceModeSupported(.locked), rawValue: nil),
      DeviceFeature(name: "Torch Mode On", isSupported: device.isTorchModeSupported(.on), rawValue: nil),
      DeviceFeature(name: "Torch Mode Off", isSupported: device.isTorchModeSupported(.off), rawValue: nil),
      DeviceFeature(name: "Torch Mode Auto", isSupported: device.isTorchModeSupported(.auto), rawValue: nil),
      DeviceFeature(name: "Has Torch", isSupported: device.hasTorch, rawValue: nil),
      DeviceFeature(name: "Torch Active", isSupported: device.isTorchActive, rawValue: nil),
      DeviceFeature(name: "Auto Focus System Contrast Detection", isSupported: device.activeFormat.autoFocusSystem == .contrastDetection, rawValue: nil),
      DeviceFeature(name: "Auto Focus System Phase Detection", isSupported: device.activeFormat.autoFocusSystem == .phaseDetection, rawValue: nil)
    ]
    
    // List available devices
    let session = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external],
      mediaType: .video,
      position: .unspecified
    )
    
    for device in session.devices {
      // Device listing and type
      features.append(DeviceFeature(name: "Device: \(device.localizedName)", isSupported: true, rawValue: "Type: \(device.deviceType.rawValue)"))
      // Additional device-specific information
      features.append(DeviceFeature(name: "Model ID", isSupported: true, rawValue: device.modelID))
      features.append(DeviceFeature(name: "Manufacturer", isSupported: true, rawValue: device.manufacturer))
    }
    
    self.deviceFeatures = features
  }
  
  private func fetchCameraFormats() {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      return
    }
    
    for format in device.formats {
      let formatDescription = format.formatDescription
      let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
      let resolution = "\(dimensions.width)x\(dimensions.height)"
      let frameRateRange = format.videoSupportedFrameRateRanges.first
      let frameRates = "\(frameRateRange?.minFrameRate ?? 0)-\(frameRateRange?.maxFrameRate ?? 0)"
      let description = "\(resolution), \(frameRates) fps"
      cameraFormats.append(CameraFormat(description: description, format: format))
    }
  }
  
  private func setVideoFormat(format: AVCaptureDevice.Format) {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      return
    }
    
    do {
      try device.lockForConfiguration()
      device.activeFormat = format
      device.unlockForConfiguration()
      print("Active format set: \(format)")
    } catch {
      print("Error setting active format: \(error)")
    }
  }
}
