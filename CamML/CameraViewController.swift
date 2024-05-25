//
//  CameraViewController.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//
import AVFoundation
import UIKit

class CameraViewController: UIViewController {
    var cameraController: CameraController!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraController = CameraController()
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        DispatchQueue.main.async {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraController.session)
            self.previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer.frame = self.view.layer.bounds
            self.view.layer.addSublayer(self.previewLayer)
        }
    }
}
