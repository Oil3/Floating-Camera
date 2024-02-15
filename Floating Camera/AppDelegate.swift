//
//  AppDelegate.swift
//  Floating Camera
//
//  Created by ZZS on 14/02/2024.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var runtimeData = RuntimeData()
    
    @IBAction func openPreferences  (_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SettingsWctl")) as! NSWindowController
        windowController.showWindow(sender)
    }


    func applicationWillTerminate(_ aNotification: Notification) {
    // Saving any settings or application state as needed
        let currentWindowSize = NSApplication.shared.mainWindow?.frame.size
        UserDefaults.standard.set(currentWindowSize, forKey: "lastWindowSize")
    
    // Perform additional cleanup if required
    }

//    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
//        return true
//    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

