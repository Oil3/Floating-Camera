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
        .frame(width: 600, height: 400)
        .navigationTitle("Device Capabilities")
    }
}
