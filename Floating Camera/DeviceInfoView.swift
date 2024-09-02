import SwiftUI
struct DeviceInfoView: View {
  @ObservedObject private var viewModel = DeviceInfoViewModel()
  @ObservedObject private var coreModel = CoreModel()

  var body: some View {
    NavigationSplitView(sidebar: {
      leftColumn
    }, content: {
      rightColumn
    }, detail: {
      DeviceInfoView4()
    })
    .navigationTitle("Settings")
    .textSelection(.enabled)
  }
  
  private var leftColumn: some View {
    VStack(alignment: .leading) {
      Toggle("Apply Filter", isOn: $coreModel.applyFilter)
      Toggle("Apply CoreML Model", isOn: $coreModel.applyMLModel)
      Picker("Filter", selection: $coreModel.selectedFilterName) {
        ForEach(coreModel.filters, id: \.self) { filter in
          Text(filter).tag(filter as String?)
        }
      }
      .onChange(of: coreModel.selectedFilterName) { newFilter in
        coreModel.selectedFilter = CIFilter(name: newFilter ?? "")
      }
      Spacer()
    }
    .padding()
    .frame(width: 200)
  }
  
  private var rightColumn: some View {
    VStack {
      Slider(value: $coreModel.brightness, in: -1...1, step: 0.1) {
        Text("Brightness")
      }
      Slider(value: $coreModel.contrast, in: 0...4, step: 0.1) {
        Text("Contrast")
      }
      Slider(value: $coreModel.saturation, in: 0...4, step: 0.1) {
        Text("Saturation")
      }
      Slider(value: $coreModel.inputEV, in: -2...2, step: 0.1) {
        Text("Exposure")
      }
      Slider(value: $coreModel.gamma, in: 0.1...3.0, step: 0.1) {
        Text("Gamma")
      }
      Slider(value: $coreModel.hue, in: 0...2 * .pi, step: 0.1) {
        Text("Hue")
      }
      Slider(value: $coreModel.highlightAmount, in: 0...1, step: 0.1) {
        Text("Highlight Amount")
      }
      Slider(value: $coreModel.shadowAmount, in: -1...1, step: 0.1) {
        Text("Shadow Amount")
      }
      Slider(value: $coreModel.temperature, in: 1000...10000, step: 100) {
        Text("Temperature")
      }
      Slider(value: $coreModel.tint, in: -200...200, step: 1) {
        Text("Tint")
      }
      Slider(value: $coreModel.whitePoint, in: 0...2, step: 0.1) {
        Text("White Point")
      }
      Toggle("CIColorInvert", isOn: $coreModel.invert)
      Toggle("CIColorPosterize", isOn: $coreModel.posterize)
      Toggle("CISharpenLuminance", isOn: $coreModel.sharpenLuminance)
      Toggle("CIUnsharpMask", isOn: $coreModel.unsharpMask)
      Toggle("CIEdges", isOn: $coreModel.edges)
      Toggle("CIGaborGradients", isOn: $coreModel.gaborGradients)
      Spacer()
    }
    .padding()
    .frame(width: 200)
  }
}

class CoreModel: ObservableObject {
  @Published var applyFilter = false
  @Published var applyMLModel = false
  @Published var selectedFilterName: String?
  @Published var selectedFilter: CIFilter?
  @Published var brightness: CGFloat = 0.0
  @Published var contrast: CGFloat = 1.0
  @Published var saturation: CGFloat = 1.0
  @Published var inputEV: CGFloat = 0.0
  @Published var gamma: CGFloat = 1.0
  @Published var hue: CGFloat = 0.0
  @Published var highlightAmount: CGFloat = 1.0
  @Published var shadowAmount: CGFloat = 0.0
  @Published var temperature: CGFloat = 6500.0
  @Published var tint: CGFloat = 0.0
  @Published var whitePoint: CGFloat = 1.0
  @Published var invert = false
  @Published var posterize = false
  @Published var sharpenLuminance = false
  @Published var unsharpMask = false
  @Published var edges = false
  @Published var gaborGradients = false
  
  let filters = ["CIDocumentEnhancer", "CIColorHistogram"]
}

struct DeviceInfoView4: View {
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
