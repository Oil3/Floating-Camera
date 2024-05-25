//
//  CameraView.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//
//
import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @ObservedObject var cameraController: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraController.session)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.bounds
        view.layer.addSublayer(videoPreviewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                    DispatchQueue.main.async {
layer.frame = uiView.bounds
        }
        }
    }
}
