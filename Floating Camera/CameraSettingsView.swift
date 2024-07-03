//
//  CameraSettingsView.swift
import SwiftUI

struct CameraSettingsView: View {
    @StateObject var viewModel = DeviceInfoViewModel()

    var body: some View {
        VStack {
            Text("Select Camera Format")
                .font(.headline)

            Picker("Camera Format", selection: $viewModel.selectedFormatIndex) {
                ForEach(0..<viewModel.cameraFormats.count, id: \.self) { index in
                    Text(viewModel.cameraFormats[index].description).tag(index)
                }
            }

            // Display other device features
            List(viewModel.deviceFeatures, id: \.name) { feature in
                HStack {
                    Text(feature.name)
                    Spacer()
                    if let rawValue = feature.rawValue {
                        Text(rawValue)
                    } else {
                        Image(systemName: feature.isSupported ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(feature.isSupported ? .green : .red)
                    }
                }
            }
        }
        .padding()
    }
}

struct CameraSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CameraSettingsView()
    }
}
