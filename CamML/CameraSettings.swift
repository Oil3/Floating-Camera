//
//  CameraSettings.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//
import SwiftUI
import AVFoundation

struct CameraSettings: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Camera Settings")) {
                    Picker("Resolution", selection: $cameraController.resolution) {
                        ForEach(AVCaptureSession.Preset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .onChange(of: cameraController.resolution) { newValue in
                        cameraController.updateResolution(to: newValue)
                    }
                    
                    HStack {
                        Text("Exposure")
                        Slider(value: $cameraController.exposure, in: -100...100, step: 1)
                    }
                    
                    HStack {
                        Text("Contrast")
                        Slider(value: $cameraController.contrast, in: -10...10, step: 0.1)
                    }
                }
                
                Section(header: Text("Core ML Model")) {
                    Toggle(isOn: $cameraController.isCoreMLActivated) {
                        Text("Activate Core ML")
                    }
                    Button(action: {
                        cameraController.showCoreMLModelPicker = true
                    }) {
                        Text("Select Core ML Model")
                    }
                }
                
                Section(header: Text("Output")) {
                    Button(action: {
                        cameraController.showOutputFolderPicker = true
                    }) {
                        Text("Select Output Folder")
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .fileImporter(isPresented: $cameraController.showCoreMLModelPicker, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        cameraController.coreMLModelURL = url
                    }
                case .failure(let error):
                    print("Error picking Core ML model: \(error.localizedDescription)")
                }
            }
            .fileImporter(isPresented: $cameraController.showOutputFolderPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        cameraController.outputFolder = url
                    }
                case .failure(let error):
                    print("Error picking output folder: \(error.localizedDescription)")
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300) // Make the settings window a normal movable window
    }
}

extension AVCaptureSession.Preset {
    var displayName: String {
        switch self {
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        case .photo:
            return "Photo"
        case .inputPriority:
            return "Input Priority"
          case .hd1280x720:
            return "HD 1280x720"
        case .hd1920x1080:
            return "HD 1920x1080"
//        case .hd4K3840x2160:
//            return "4K 3840x2160"
        case .vga640x480:
            return "VGA 640x480"
        case .iFrame960x540:
            return "iFrame 960x540"
        case .iFrame1280x720:
            return "iFrame 1280x720"
        case .cif352x288:
            return "CIF 352x288"
        default:
            return "Unknown"
        }
    }
}

extension AVCaptureSession.Preset: CaseIterable {
    public static var allCases: [AVCaptureSession.Preset] {
        return [
            .high,
            .medium,
            .low,
            .photo,
            .inputPriority,
            .hd1280x720,
            .hd1920x1080,
//            .hd4K3840x2160,
            .vga640x480,
            .iFrame960x540,
            .iFrame1280x720,
            .cif352x288
        ]
    }
}
