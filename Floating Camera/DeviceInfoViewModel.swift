//
//  DeviceInfoViewModel.swift
//  Floating Camera
//
//  Created by ZZS on 28/02/2024.
//
import AVFoundation
import Combine

class DeviceInfoViewModel: ObservableObject {
    @Published var deviceInfo: [String] = []
    
    init() {
        fetchDeviceInfo()
    }
    
    func fetchDeviceInfo() {
        // Example: Fetching supported exposure modes dynamically
        var info: [String] = ["Supported Exposure Modes:"]
        
        // Assuming the usage of AVCaptureDevice.default(for: .video) to get the default video capture device
        // This needs to be adjusted based on actual device selection logic in your app
        if let device = AVCaptureDevice.default(for: .video) {
            if device.isExposureModeSupported(.autoExpose) {
                info.append("Auto Expose")
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                info.append("Continuous Auto Exposure")
            }
            if device.isExposureModeSupported(.locked) {
                info.append("Locked")
            }
            if device.isExposureModeSupported(.custom) {
                info.append("Custom")
            }
            
            // Add more device-specific information querying here
            // For instance, querying focus modes, white balance modes, etc.
        }
        
        self.deviceInfo = info
    }
}
