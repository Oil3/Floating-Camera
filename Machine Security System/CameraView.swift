import SwiftUI
import UIKit
import AVKit
import Vision
import CoreML

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Perform any updates to the UI based on changes in SwiftUI environment if necessary
    }

    typealias UIViewControllerType = CameraViewController
}
