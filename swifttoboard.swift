//
//  swifttoboard.swift
//  Floating Camera
//
//  Created by ZZS on 28/02/2024.
//

import SwiftUI

class swifttoboard: NSHostingController<DeviceInfoView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: DeviceInfoView())
    }
}
