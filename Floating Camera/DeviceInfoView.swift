//
//  DeviceInfoView.swift
//  Floating Camera
//
//  Created by ZZS on 28/02/2024.
//

import SwiftUI

struct DeviceInfoView: View {
  @ObservedObject private var viewModel = DeviceInfoViewModel()
  
  var body: some View {
    List {
      Section(header: Text("Device Features")) {
        ForEach(viewModel.deviceFeatures, id: \.name) { feature in
          HStack {
            Text(feature.name)
            Spacer()
            Text(feature.isSupported ? "Supported" : "Not Supported")
              .foregroundColor(feature.isSupported ? .green : .red)
            Spacer()
            Text(feature.rawValue ?? "N/A")
          }
        }
      }
      
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
    }
    .frame(width: 600, height: 400)
    .navigationTitle("Device Capabilities")
  }
}

struct DeviceInfoView_Previews: PreviewProvider {
  static var previews: some View {
    DeviceInfoView()
  }
}
