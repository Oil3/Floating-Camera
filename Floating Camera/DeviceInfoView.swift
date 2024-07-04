import SwiftUI

struct DeviceInfoView: View {
  @ObservedObject private var viewModel = DeviceInfoViewModel()
  
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
    }
    .frame(width: 600, height: 400)
    .navigationTitle("Device Settings")
    .textSelection(.enabled)
  }
}
