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
    let isSupported: Bool
    let rawValue: String? // Optional String to handle cases where there is no raw value
}

class DeviceInfoViewModel: ObservableObject {
    @Published var deviceFeatures: [DeviceFeature] = []
    
    init() {
        fetchDeviceInfo()
    }
    
    func fetchDeviceInfo() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        let features = [
            DeviceFeature(name: "Has Video Media Type", isSupported: device.hasMediaType(AVMediaType.video), rawValue: nil),
            DeviceFeature(name: "Auto Focus", isSupported: device.isFocusModeSupported(.autoFocus), rawValue: nil),
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
            DeviceFeature(name: "Auto Focus System Phase Detection", isSupported: device.activeFormat.autoFocusSystem == .phaseDetection, rawValue: nil),
////ios
//            DeviceFeature(name: "Subject Area Change Monitoring Enabled", isSupported: device.isSubjectAreaChangeMonitoringEnabled, rawValue: nil),
//            DeviceFeature(name: "Low Light Boost", isSupported: device.isLowLightBoostSupported, rawValue: nil),
//            DeviceFeature(name: "Automatically Enables Low Light Boost", isSupported: device.automaticallyEnablesLowLightBoostWhenAvailable, rawValue: nil),
//            DeviceFeature(name: "Ramping Video Zoom", isSupported: device.isRampingVideoZoom, rawValue: nil),
//            DeviceFeature(name: "Video Stabilization Auto", isSupported: device.activeFormat.isVideoStabilizationModeSupported(.auto), rawValue: nil),
//            DeviceFeature(name: "Video Stabilization Cinematic", isSupported: device.activeFormat.isVideoStabilizationModeSupported(.cinematic), rawValue: nil),
//            DeviceFeature(name: "Video Stabilization Standard", isSupported: device.activeFormat.isVideoStabilizationModeSupported(.standard), rawValue: nil),
//            DeviceFeature(name: "HDR Video Supported", isSupported: device.activeFormat.videoHDRSupported, rawValue: nil),
//            DeviceFeature(name: "Smooth Auto Focus Supported", isSupported: device.isSmoothAutoFocusSupported, rawValue: nil),           
        ]
        
        self.deviceFeatures = features
    }
}
