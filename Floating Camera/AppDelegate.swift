    //
    //  AppDelegate.swift
    //  Floating Camera
    //  Created by ZZS on 14/02/2024.

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var runtimeData = RuntimeData()
  var viewController: ViewController?

    
    @IBAction func openPreferences  (_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SettingsWctl")) as! NSWindowController
        windowController.showWindow(sender)
    }
    
        //ZZ this is the default behaviour but we need to be able to come back to it as we lock config
    @IBAction func setupCameraAutoFocusAndExposure(_ sender: AnyObject) {
        NotificationCenter.default.post(name: .setupCamera, object: nil)
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
            // Saving any settings or application state as needed
        let currentWindowSize = NSApplication.shared.mainWindow?.frame.size
        UserDefaults.standard.set(currentWindowSize, forKey: "lastWindowSize")
      viewController?.stopContinuousRecording()

    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    
    
}
extension CIContext {
  func createPixelBuffer(from ciImage: CIImage) -> CVPixelBuffer? {
    let attributes: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue
    ]
    
    let width = Int(ciImage.extent.width)
    let height = Int(ciImage.extent.height)
    var pixelBuffer: CVPixelBuffer?
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &pixelBuffer)
    
    guard let pxBuffer = pixelBuffer else {
      return nil
    }
    
    CVPixelBufferLockBaseAddress(pxBuffer, .readOnly)
    self.render(ciImage, to: pxBuffer)
    CVPixelBufferUnlockBaseAddress(pxBuffer, .readOnly)
    
    return pxBuffer
  }
}
