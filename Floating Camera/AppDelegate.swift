//    //
//    //  AppDelegate.swift
//    //  Floating Camera
//    //  Created by ZZS on 14/02/2024.
//

import SwiftUI

@main
struct floatingcamera: App {
  

var body: some Scene {
  WindowGroup {
    DeviceInfoView()
    .onAppear {
    FloatingController.shared.showFloatingWindow()
}
  }
  }
class AppDelegate: NSObject, NSApplicationDelegate {
  var windowController: FloatingController?
  var viewController: ViewController?
  var runtimeData = RuntimeData()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    windowController = FloatingController.shared
    windowController!.showFloatingWindow()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    viewController?.stopContinuousRecording()
  }
}
}
import Cocoa

extension NSViewController {
  func showFadingTooltip(message: String, at point: CGPoint, duration: TimeInterval = 2.0) {
    // Create a lightweight NSTextField for the tooltip
    let tooltip = NSTextField(labelWithString: message)
    tooltip.alignment = .center
  
    tooltip.textColor = .white
    tooltip.backgroundColor = NSColor.black.withAlphaComponent(0.8)
    tooltip.isBordered = false
    tooltip.isBezeled = false
    tooltip.drawsBackground = true
    tooltip.wantsLayer = true
    tooltip.layer?.cornerRadius = 8
    
    // Set the size and position of the tooltip
    let width: CGFloat = 200
    let height: CGFloat = 40
    tooltip.frame = NSRect(x: point.x, y: point.y, width: width, height: height)
    
    // Add the tooltip to the view
    view.addSubview(tooltip)
    
    // Animate the fade-in and fade-out effect
    tooltip.alphaValue = 0
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.3
      tooltip.animator().alphaValue = 1
    }, completionHandler: {
      DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        NSAnimationContext.runAnimationGroup({ context in
          context.duration = 0.3
          tooltip.animator().alphaValue = 0
        }, completionHandler: {
          tooltip.removeFromSuperview()
        })
      }
    })
  }
}

//import Cocoa
//import AVFoundation
//
//@main
//class AppDelegate: NSObject, NSApplicationDelegate {
//    var runtimeData = RuntimeData()
//  var viewController: ViewController?
//
//    
//    @IBAction func openPreferences  (_ sender: AnyObject) {
//        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
//        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SettingsWctl")) as! NSWindowController
//        windowController.showWindow(sender)
//    }
//    
//        //ZZ this is the default behaviour but we need to be able to come back to it as we lock config
//    @IBAction func setupCameraAutoFocusAndExposure(_ sender: AnyObject) {
//        NotificationCenter.default.post(name: .setupCamera, object: nil)
//    }
//    
//    
//    func applicationWillTerminate(_ aNotification: Notification) {
//            // Saving any settings or application state as needed
//        let currentWindowSize = NSApplication.shared.mainWindow?.frame.size
//        UserDefaults.standard.set(currentWindowSize, forKey: "lastWindowSize")
//      viewController?.stopContinuousRecording()
//
//    }
//    
//    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
//        true
//    }
//    
//    
//    
//}
//extension CIContext {
//  func createPixelBuffer(from ciImage: CIImage) -> CVPixelBuffer? {
//    let attributes: [String: Any] = [
//      kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue,
//      kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue
//    ]
//    
//    let width = Int(ciImage.extent.width)
//    let height = Int(ciImage.extent.height)
//    var pixelBuffer: CVPixelBuffer?
//    
//    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &pixelBuffer)
//    
//    guard let pxBuffer = pixelBuffer else {
//      return nil
//    }
//    
//    CVPixelBufferLockBaseAddress(pxBuffer, .readOnly)
//    self.render(ciImage, to: pxBuffer)
//    CVPixelBufferUnlockBaseAddress(pxBuffer, .readOnly)
//    
//    return pxBuffer
//  }
//}
