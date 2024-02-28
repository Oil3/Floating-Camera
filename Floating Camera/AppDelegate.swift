//
//  AppDelegate.swift
//  Floating Camera
//  Created by ZZS on 14/02/2024.

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var runtimeData = RuntimeData()
    
    
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
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

