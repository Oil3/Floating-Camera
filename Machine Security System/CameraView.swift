import SwiftUI
import UIKit
import AVKit
import Vision
import CoreML
import CoreVideo
import VideoToolbox
    import CoreImage
import CoreVideo

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Perform any updates to the UI based on changes in SwiftUI environment if necessary
    }

    typealias UIViewControllerType = CameraViewController
}
import CoreVideo
import VideoToolbox

import UIKit
import CoreImage
import CoreVideo
import AVFoundation

extension CMSampleBuffer {
    func toCGImage() -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else {
            print("Failed to get pixel buffer from sample buffer")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: CVPixelBufferGetWidth(pixelBuffer),
                                      height: CVPixelBufferGetHeight(pixelBuffer),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
              let cgImage = context.makeImage() else {
            print("Failed to create CGImage")
            return nil
        }
        
        return cgImage
    
}
}
