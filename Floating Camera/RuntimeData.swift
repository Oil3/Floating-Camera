//
//  Floating Camera
//  Created by ZZS on 14/02/2024.
import AppKit

class RuntimeData {
    var windowSize: CGSize = .zero {
        didSet {
            NotificationCenter.default.post(name: .windowSizeChanged, object: nil, userInfo: ["size": windowSize])
        }
    }

}

extension Notification.Name {
    static let windowSizeChanged = Notification.Name("windowSizeChanged")
    static let setupCamera = Notification.Name("setupCamera")
}
