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
                        ForEach([AVCaptureSession.Preset.high, .medium, .low], id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .onChange(of: cameraController.resolution) { newValue in
                        cameraController.updateResolution(to: newValue)
                    }
                    
                    Slider(value: $cameraController.exposure, in: -10...10, step: 0.1) {
                        Text("Exposure")
                    }
                    Slider(value: $cameraController.contrast, in: -10...10, step: 0.1) {
                        Text("Contrast")
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
        default:
            return "Unknown"
        }
    }
}
