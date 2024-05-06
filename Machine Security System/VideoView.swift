//
//  VideoView.swift
//  Machine Security System
//
//  Created by Almahdi Morris on 05/05/24.
//

import SwiftUI
import UIKit
import AVKit
import Vision
import CoreML

struct VideoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VideoViewController {
        VideoViewController()
    }

    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) {
        // Perform any updates to the UI based on changes in SwiftUI environment if necessary
    }

    typealias UIViewControllerType = VideoViewController
}
