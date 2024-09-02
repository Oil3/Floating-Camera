//
//  FiltersView.swift
//  Floating Camera
//
//  Created by Almahdi Morris on 2/9/24.
//

import SwiftUI
struct FiltersView: View {
  @State private var applyFilter = false
  @State private var applyMLModel = false
  @State private var selectedFilterName: String?
  private let filters = ["CIDocumentEnhancer", "CIColorHistogram"]
  
  var body: some View {
    VStack(alignment: .leading) {
      Toggle("Apply Filter", isOn: $applyFilter)
      Toggle("Apply CoreML Model", isOn: $applyMLModel)
      Picker("Filter", selection: $selectedFilterName) {
        ForEach(filters, id: \.self) { filter in
          Text(filter).tag(filter as String?)
        }
      }
      Spacer()
    }
    .padding()
  }
}

struct AdjustmentsView: View {
  @State private var brightness: CGFloat = 0.0
  @State private var contrast: CGFloat = 1.0
  @State private var saturation: CGFloat = 1.0
  
  var body: some View {
    VStack {
      Slider(value: $brightness, in: -1...1, step: 0.1) {
        Text("Brightness")
      }
      Slider(value: $contrast, in: 0...4, step: 0.1) {
        Text("Contrast")
      }
      Slider(value: $saturation, in: 0...4, step: 0.1) {
        Text("Saturation")
      }
      Spacer()
    }
    .padding()
  }
}



//struct AdjustmentsView: View {
//  @ObservedObject var coreModel: CoreModel
//  
//  var body: some View {
//    VStack {
//      Slider(value: $coreModel.brightness, in: -1...1, step: 0.1) {
//        Text("Brightness")
//      }
//      Slider(value: $coreModel.contrast, in: 0...4, step: 0.1) {
//        Text("Contrast")
//      }
//      Slider(value: $coreModel.saturation, in: 0...4, step: 0.1) {
//        Text("Saturation")
//      }
//      Slider(value: $coreModel.inputEV, in: -2...2, step: 0.1) {
//        Text("Exposure")
//      }
//      Slider(value: $coreModel.gamma, in: 0.1...3.0, step: 0.1) {
//        Text("Gamma")
//      }
//      Slider(value: $coreModel.hue, in: 0...2 * .pi, step: 0.1) {
//        Text("Hue")
//      }
//      Slider(value: $coreModel.highlightAmount, in: 0...1, step: 0.1) {
//        Text("Highlight Amount")
//      }
//      Slider(value: $coreModel.shadowAmount, in: -1...1, step: 0.1) {
//        Text("Shadow Amount")
//      }
//      Slider(value: $coreModel.temperature, in: 1000...10000, step: 100) {
//        Text("Temperature")
//      }
//      Slider(value: $coreModel.tint, in: -200...200, step: 1) {
//        Text("Tint")
//      }
//      Slider(value: $coreModel.whitePoint, in: 0...2, step: 0.1) {
//        Text("White Point")
//      }
//      Toggle("CIColorInvert", isOn: $coreModel.invert)
//      Toggle("CIColorPosterize", isOn: $coreModel.posterize)
//      Toggle("CISharpenLuminance", isOn: $coreModel.sharpenLuminance)
//      Toggle("CIUnsharpMask", isOn: $coreModel.unsharpMask)
//      Toggle("CIEdges", isOn: $coreModel.edges)
//      Toggle("CIGaborGradients", isOn: $coreModel.gaborGradients)
//      Spacer()
//    }
//    .padding()
//  }
//}
