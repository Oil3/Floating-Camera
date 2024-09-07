import SwiftUI

struct DeviceInfoView: View {
  @ObservedObject private var viewModel = DeviceInfoViewModel()
  @ObservedObject var viewController = ViewController()
  
  var body: some View {
    TabView {
      FiltersView()
        .tabItem {
          Label("Filters", systemImage: "slider.horizontal.3")
        }
      
      AdjustmentsView()
        .tabItem {
          Label("Adjustments", systemImage: "wand.and.rays")
        }
      CoreMLSettingsView(viewController: viewController)
        .tabItem {
          Label("CoreML", systemImage: "wand.and.rays")
        }
      DeviceSettingsView(viewModel: viewModel)
        .tabItem {
          Label("Device", systemImage: "video")
        }
    }
    .navigationTitle("Settings")
    .textSelection(.enabled)
  }
}


import Vision
import CoreML

var detectionModel: VNCoreMLModel?

struct CoreMLSettingsView: View {
  @ObservedObject var viewController: ViewController
  var body: some View {
    Toggle("Enable Object Detection", isOn: $viewController.isDetectionEnabled)
      .onChange(of: viewController.isDetectionEnabled) { value in
        if value {
          loadCoreMLModel()
        }
      }
  }
  
  
  
  
  func loadCoreMLModel() {
    // Load the compiled Core ML model from the bundle
    guard let modelURL = Bundle.main.url(forResource: "yolov8", withExtension: "mlmodelc"),
          let coreMLModel = try? MLModel(contentsOf: modelURL) else {
      print("Failed to load Core ML model")
      return
    }
    
    // Wrap it in a VNCoreMLModel for Vision requests
    detectionModel = try? VNCoreMLModel(for: coreMLModel)
    print("Core ML model loaded successfully")
  }
}
