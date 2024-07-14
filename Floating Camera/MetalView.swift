//
//  MetalView.swift
//  Floating Camera
//
//  Created by Almahdi Morris on 4/7/24.
//

import SwiftUI
import AVFoundation
import CoreImage
import CoreML
import MetalKit

class CustomMTKView: MTKView {
  private var ciContext: CIContext?
  private var commandQueue: MTLCommandQueue?
  private var currentCIImage: CIImage?
  
  var selectedFilter: CIFilter?
  var mlModel: MLModel?
  var applyFilter = false
  var applyMLModel = false
  var brightness: CGFloat = 0.0
  var contrast: CGFloat = 1.0
  var saturation: CGFloat = 1.0
  var inputEV: CGFloat = 0.0
  var gamma: CGFloat = 1.0
  var hue: CGFloat = 0.0
  var highlightAmount: CGFloat = 1.0
  var shadowAmount: CGFloat = 0.0
  var temperature: CGFloat = 6500.0
  var tint: CGFloat = 0.0
  var whitePoint: CGFloat = 1.0
  var invert = false
  var posterize = false
  var sharpenLuminance = false
  var unsharpMask = false
  var edges = false
  var gaborGradients = false
  
  required init(coder: NSCoder) {
    super.init(coder: coder)
    self.device = MTLCreateSystemDefaultDevice()
    self.commandQueue = self.device?.makeCommandQueue()
    self.ciContext = CIContext(mtlDevice: self.device!)
  }
  
  override func draw(_ rect: CGRect) {
    guard let ciImage = currentCIImage else { return }
    guard let commandBuffer = commandQueue?.makeCommandBuffer(),
          let drawable = currentDrawable else { return }
    let filteredImage = applyCurrentFilters(to: ciImage)
    ciContext?.render(filteredImage, to: drawable.texture, commandBuffer: commandBuffer, bounds: filteredImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func updateImage(_ ciImage: CIImage) {
    self.currentCIImage = ciImage
    self.draw()
  }
  
  private func applyCurrentFilters(to ciImage: CIImage) -> CIImage {
    var ciImage = ciImage
    
    if applyFilter {
      if let selectedFilter = selectedFilter {
        selectedFilter.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = selectedFilter.outputImage ?? ciImage
      }
      
      if invert {
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if posterize {
        let filter = CIFilter(name: "CIColorPosterize")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if sharpenLuminance {
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if unsharpMask {
        let filter = CIFilter(name: "CIUnsharpMask")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if edges {
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if gaborGradients {
        let filter = CIFilter(name: "CIGaborGradients")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      let colorControlsFilter = CIFilter(name: "CIColorControls")
      colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      colorControlsFilter?.setValue(brightness, forKey: kCIInputBrightnessKey)
      colorControlsFilter?.setValue(contrast, forKey: kCIInputContrastKey)
      colorControlsFilter?.setValue(saturation, forKey: kCIInputSaturationKey)
      ciImage = colorControlsFilter?.outputImage ?? ciImage
      
      let gammaFilter = CIFilter(name: "CIGammaAdjust")
      gammaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      gammaFilter?.setValue(gamma, forKey: "inputPower")
      ciImage = gammaFilter?.outputImage ?? ciImage
      
      let hueFilter = CIFilter(name: "CIHueAdjust")
      hueFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      hueFilter?.setValue(hue, forKey: kCIInputAngleKey)
      ciImage = hueFilter?.outputImage ?? ciImage
      
      let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
      highlightShadowFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      highlightShadowFilter?.setValue(highlightAmount, forKey: "inputHighlightAmount")
      highlightShadowFilter?.setValue(shadowAmount, forKey: "inputShadowAmount")
      ciImage = highlightShadowFilter?.outputImage ?? ciImage
      
      let temperatureAndTintFilter = CIFilter(name: "CITemperatureAndTint")
      temperatureAndTintFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      temperatureAndTintFilter?.setValue(CIVector(x: temperature, y: tint), forKey: "inputNeutral")
      ciImage = temperatureAndTintFilter?.outputImage ?? ciImage
      
      let whitePointAdjustFilter = CIFilter(name: "CIWhitePointAdjust")
      whitePointAdjustFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      whitePointAdjustFilter?.setValue(CIColor(red: CGFloat(Float(whitePoint)), green: CGFloat(Float(whitePoint)), blue: CGFloat(Float(whitePoint))), forKey: kCIInputColorKey)
      ciImage = whitePointAdjustFilter?.outputImage ?? ciImage
    }
    
    if let mlModel = mlModel, applyMLModel {
      let mlFilter = CIFilter(name: "CICoreMLModelFilter")!
      mlFilter.setValue(mlModel, forKey: "inputModel")
      mlFilter.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = mlFilter.outputImage ?? ciImage
    }
    
    return ciImage
  }
}

struct DeviceInfoView: View {
  @ObservedObject private var metalViewModel = MetaInfoViewModel()
  @State private var metalView: CustomMTKView?
  
  var body: some View {
    NavigationView {
      HStack {
        leftColumn
        rightColumn
      }
      .frame(width: 600, height: 800)

//      .frame(maxHeight: .infinity)
      
      CustomMTKViewRepresentable(metalView: $metalView)
        .frame(width: 600, height: 800)

//        .frame(maxHeight: .infinity)
    }
    .frame(width: 800, height: 800)
    .navigationTitle("Device Settings")
    .textSelection(.enabled)
    .onAppear {
      setupMetalView()
    }
  }
  
  private var leftColumn: some View {
    VStack(alignment: .leading) {
      Toggle("Apply Filter", isOn: $metalViewModel.applyFilter)
      Toggle("Apply CoreML Model", isOn: $metalViewModel.applyMLModel)
      Picker("Filter", selection: $metalViewModel.selectedFilterName) {
        ForEach(metalViewModel.filters, id: \.self) { filter in
          Text(filter).tag(filter as String?)
        }
      }
      .onChange(of: metalViewModel.selectedFilterName) { newFilter in
        metalViewModel.selectedFilter = CIFilter(name: newFilter ?? "")
      }
      Spacer()
    }
    .padding()
    .frame(width: 200)
  }
  
  private var rightColumn: some View {
    VStack {
      Slider(value: $metalViewModel.brightness, in: -1...1, step: 0.1) {
        Text("Brightness")
      }
      Slider(value: $metalViewModel.contrast, in: 0...4, step: 0.1) {
        Text("Contrast")
      }
      Slider(value: $metalViewModel.saturation, in: 0...4, step: 0.1) {
        Text("Saturation")
      }
      Slider(value: $metalViewModel.inputEV, in: -2...2, step: 0.1) {
        Text("Exposure")
      }
      Slider(value: $metalViewModel.gamma, in: 0.1...3.0, step: 0.1) {
        Text("Gamma")
      }
      Slider(value: $metalViewModel.hue, in: 0...2 * .pi, step: 0.1) {
        Text("Hue")
      }
      Slider(value: $metalViewModel.highlightAmount, in: 0...1, step: 0.1) {
        Text("Highlight Amount")
      }
      Slider(value: $metalViewModel.shadowAmount, in: -1...1, step: 0.1) {
        Text("Shadow Amount")
      }
      Slider(value: $metalViewModel.temperature, in: 1000...10000, step: 100) {
        Text("Temperature")
      }
      Slider(value: $metalViewModel.tint, in: -200...200, step: 1) {
        Text("Tint")
      }
      Slider(value: $metalViewModel.whitePoint, in: 0...2, step: 0.1) {
        Text("White Point")
      }
      Toggle("CIColorInvert", isOn: $metalViewModel.invert)
      Toggle("CIColorPosterize", isOn: $metalViewModel.posterize)
      Toggle("CISharpenLuminance", isOn: $metalViewModel.sharpenLuminance)
      Toggle("CIUnsharpMask", isOn: $metalViewModel.unsharpMask)
      Toggle("CIEdges", isOn: $metalViewModel.edges)
      Toggle("CIGaborGradients", isOn: $metalViewModel.gaborGradients)
      Spacer()
    }
    .padding()
    .frame(width: 200)
  }
  
  private func setupMetalView() {
    guard let metalView = metalView else { return }
    metalView.selectedFilter = metalViewModel.selectedFilter
//    metalView.mlModel = metalViewModel.mlModel
    metalView.applyFilter = metalViewModel.applyFilter
    metalView.applyMLModel = metalViewModel.applyMLModel
    metalView.brightness = metalViewModel.brightness
    metalView.contrast = metalViewModel.contrast
    metalView.saturation = metalViewModel.saturation
    metalView.inputEV = metalViewModel.inputEV
    metalView.gamma = metalViewModel.gamma
    metalView.hue = metalViewModel.hue
    metalView.highlightAmount = metalViewModel.highlightAmount
    metalView.shadowAmount = metalViewModel.shadowAmount
    metalView.temperature = metalViewModel.temperature
    metalView.tint = metalViewModel.tint
    metalView.whitePoint = metalViewModel.whitePoint
    metalView.invert = metalViewModel.invert
    metalView.posterize = metalViewModel.posterize
    metalView.sharpenLuminance = metalViewModel.sharpenLuminance
    metalView.unsharpMask = metalViewModel.unsharpMask
    metalView.edges = metalViewModel.edges
    metalView.gaborGradients = metalViewModel.gaborGradients
  }
}

struct CustomMTKViewRepresentable: NSViewRepresentable {
  @Binding var metalView: CustomMTKView?
  
  func makeNSView(context: Context) -> CustomMTKView {
    let metalView = CustomMTKView(coder: NSCoder())//  (frame: .zero, device: MTLCreateSystemDefaultDevice())
    self.metalView = metalView
    return metalView
  }
  
  func updateNSView(_ nsView: CustomMTKView, context: Context) {}
}

class MetaInfoViewModel: ObservableObject {
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
