//
//  RuntimeData.swift
//  Floating Camera
//  Created by ZZS on 14/02/2024.

import Foundation


class RuntimeData {
    var windowSize: CGSize = .zero {
        didSet {
            NotificationCenter.default.post(name: .windowSizeChanged, object: nil, userInfo: ["size": windowSize])
        }
    }
}


extension Notification.Name {
    static let windowSizeChanged = Notification.Name("windowSizeChanged")
}
