import UIKit
import SwiftUI
import Vision
import AVFoundation

class BoundingBoxView: UIView {
    private let strokeWidth: CGFloat = 2
    private var imageRect: CGRect = .zero
    
    var observations: [VNRecognizedObjectObservation]? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var faceObservations: [VNFaceObservation]? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func updateSize(for imageSize: CGSize) {
        imageRect = AVMakeRect(aspectRatio: imageSize, insideRect: self.bounds)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if let observations = observations, !observations.isEmpty {
            subviews.forEach({ $0.removeFromSuperview() })
            for (i, observation) in observations.enumerated() {
                guard ["person", "cat", "dog", "remote"].contains(observation.labels.first?.identifier ?? "") else { continue }
                
                var color = UIColor(hue: CGFloat(i) / CGFloat(observations.count), saturation: 1, brightness: 1, alpha: 1)
                if #available(iOS 12.0, *), let recognizedObjectObservation = observation as? VNRecognizedObjectObservation {
                    let firstLabelHash = recognizedObjectObservation.labels.first?.identifier.hashValue ?? 0
                    color = UIColor(hue: CGFloat(firstLabelHash % 256) / 256.0, saturation: 1, brightness: 1, alpha: 1)
                }
                
                let rect = drawBoundingBox(context: context, observation: observation, color: color)
                addLabel(on: rect, observation: observation, color: color)
            }
        }
        
        if let faceObservations = faceObservations, !faceObservations.isEmpty {
            for observation in faceObservations {
                let color = UIColor.systemBlue
                _ = drawBoundingBox(context: context, observation: observation, color: color)
            }
        }
    }
    
    func drawBoundingBox(context: CGContext, observation: VNDetectedObjectObservation, color: UIColor) -> CGRect {
        let convertedRect = VNImageRectForNormalizedRect(observation.boundingBox, Int(imageRect.width), Int(imageRect.height))
        let x = convertedRect.minX + imageRect.minX
        let y = imageRect.maxY - convertedRect.minY - convertedRect.height
        let rect = CGRect(x: x, y: y, width: convertedRect.width, height: convertedRect.height)
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(strokeWidth)
        context.stroke(rect)
        
        return rect
    }
    
     func addLabel(on rect: CGRect, observation: VNRecognizedObjectObservation, color: UIColor) {
        guard let firstLabel = observation.labels.first?.identifier else { return }
        
        let label = UILabel()
        label.text = firstLabel
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = .black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: rect.origin.x - strokeWidth / 2,
                             y: rect.origin.y - label.frame.height,
                             width: label.frame.width,
                             height: label.frame.height)
        addSubview(label)
    }
}
