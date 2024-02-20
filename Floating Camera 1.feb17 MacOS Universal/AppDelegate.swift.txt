//
//  AppDelegate.swift
//  Floating Camera
//  Created by ZZS on 14/02/2024.

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var runtimeData = RuntimeData()

    
    @IBAction func openPreferences  (_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SettingsWctl")) as! NSWindowController
        windowController.showWindow(sender)
    }
//    //automaticallyEnablesLowLightBoostWhenAvailable just for Ios
//    @IBAction func setupautomaticallyEnablesLowLightBoostWhenAvailable(_ sender: AnyObject) {
//    NotificationCenter.default.post(name: .setupCamera, object: nil)
//    }
    
    //ZZ this is the default behaviour but we need to be able to come back to it
    @IBAction func setupCameraAutoFocusAndExposure(_ sender: AnyObject) {
    NotificationCenter.default.post(name: .setupCamera, object: nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    // Saving any settings or application state as needed
        let currentWindowSize = NSApplication.shared.mainWindow?.frame.size
        UserDefaults.standard.set(currentWindowSize, forKey: "lastWindowSize")
    
    // Perform additional cleanup if required
    }

//    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
//        return true/Users/zzs/ASEPS/Floating Camera/Floating Camera/AppDelegate.swift.txt //here I must have pasted over by mistake
//    } // look it's a no for the moment because if we encrypt, then it's cryptographic, and that means paperwork. furthermore if something can access restorablestate already.... 

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

