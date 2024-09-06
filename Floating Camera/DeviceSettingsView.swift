import SwiftUI
import AVFoundation
struct DeviceSettingsView: View {
  @ObservedObject  var viewModel: DeviceInfoViewModel
  @State private var selectedFramerate: Double = 24.0 // Default framerate
  
  var body: some View {
    List {
      Section(header: Text("Camera Formats")) {
        ForEach(viewModel.cameraFormats.indices, id: \.self) { index in
          HStack {
            Text(viewModel.cameraFormats[index].description)
            Spacer()
            if viewModel.selectedFormatIndex == index {
              Image(systemName: "checkmark")
                .foregroundColor(.blue)
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.selectedFormatIndex = index
          }
        }
      }
      
      Section(header: Text("Video Codecs")) {
        ForEach(viewModel.videoCodecs.indices, id: \.self) { index in
          HStack {
            Text(viewModel.videoCodecs[index])
            Spacer()
            if viewModel.selectedCodecIndex == index {
              Image(systemName: "checkmark")
                .foregroundColor(.blue)
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.selectedCodecIndex = index
          }
        }
      }
      
      Section(header: Text("Presets")) {
        ForEach(viewModel.presets.indices, id: \.self) { index in
          HStack {
            Text(viewModel.presets[index])
            Spacer()
            if viewModel.selectedPresetIndex == index {
              Image(systemName: "checkmark")
                .foregroundColor(.blue)
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.selectedPresetIndex = index
          }
        }
      }
      
      // New Section for Framerate Control
      Section(header: Text("Framerate")) {
        HStack {
          Text("Framerate: \(Int(selectedFramerate)) fps")
          Slider(value: $selectedFramerate, in: 15...60, step: 1)
            .onChange(of: selectedFramerate) { newValue in
              setFixedFramerate(Int(newValue))
            }
        }
      }
    }
    .navigationTitle("Device Settings")
    .textSelection(.enabled)
  }
  
  // Function to apply the selected framerate
  private func setFixedFramerate(_ framerate: Int) {
    guard let device = viewModel.selectedDevice else { return }
    
    do {
      try device.lockForConfiguration()
      device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(framerate))
      device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(framerate))
      device.unlockForConfiguration()
    } catch {
      print("Failed to set framerate: \(error.localizedDescription)")
    }
  }
}
