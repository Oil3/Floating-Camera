//
//  WindowController.swift
//  Floating Camera
//
//  Created by ZZS on 14/02/2024.
//

import AppKit

class WindowController: NSWindowController, NSWindowDelegate {
    var runtimeData: RuntimeData!
    weak var keyWindow: NSWindow? = nil
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        runtimeData = (NSApplication.shared.delegate as? AppDelegate)?.runtimeData
        
        window?.delegate = self
        window?.level = .floating
//        window?.isOpaque = false
        window?.backgroundColor = NSColor.black
//        window?.backgroundColor = NSColor.white.withAlphaComponent(0.00)

//        NotificationCenter.default.addObserver(self, selector: #selector(updateWindowSize), name: .windowSizeChanged, object: nil)
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let newWidth = frameSize.width
        let newHeight = newWidth * 9 / 16  // this to maintain the 16/9 ratio of builtin macbook cam, later need to make it user selectable
        runtimeData.windowSize = CGSize(width: newWidth, height: newHeight)
        
        return NSSize(width: newWidth, height: newHeight)
    }
    // Safely unwraping runtimeData before using it
//        if let runtimeData = runtimeData {
//            runtimeData.windowSize = newWidth
//        }
//
//        return NSSize(width: newWidth, height: newHeight)
//    }
    
//    @objc func updateWindowSize(notification: Notification) {
//        if let size = notification.userInfo?["size"] as? CGFloat {
//            // Update the window size here if needed
//        }
//    }
}
