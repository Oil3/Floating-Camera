import Cocoa
import AVFoundation

class FloatingController: NSWindowController, NSWindowDelegate {
  static let shared = FloatingController()
  public var floatingWindow: NSWindow?

  func showFloatingWindow() {
    if floatingWindow == nil {
      // Initialize the window with a default size respecting the aspect ratio
      let initialRect = NSRect(x: 600, y: 200, width: 800, height: 600)
      let contentRect = calculateContentRect(for: initialRect, aspectRatio: 16.0 / 9.0) // Default aspect ratio
      floatingWindow = NSWindow(contentRect: contentRect, styleMask: [.fullSizeContentView, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
      floatingWindow?.minSize = NSSize(width: 64, height: 48) // so we don't "lose" the view when resizing too much
      floatingWindow?.backgroundColor = NSColor.black
      floatingWindow?.hasShadow = false
      floatingWindow?.titlebarAppearsTransparent = false
      floatingWindow?.delegate = self
      floatingWindow?.level = .floating
      floatingWindow?.title = "Floating Camera"
//      floatingWindow?.setFrameAutosaveName("FloatingCameraWindow")
      
      let viewController = ViewController()
//      viewController.delegate = self
      floatingWindow?.contentViewController = viewController
      floatingWindow?.orderFront(nil)

      //floatingWindow?.makeKeyAndOrderFront(nil)
    } else {
      floatingWindow?.orderFront(nil)

     // floatingWindow?.makeKeyAndOrderFront(nil)
    }
  }
  
//  func window(_ window: NSWindow, willResizeForVersionBrowserWithMaxPreferredSize maxPreferredSize: NSSize, maxAllowedSize: NSSize) -> NSSize {
//    // Enforce aspect ratio during resizing
//    var newSize = window.frame.size
//    newSize.height = newSize.width * aspectRatio.height / aspectRatio.width
//    return newSize
//  }
  
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    floatingWindow?.orderOut(nil)
    return false
  }
  
  func toggleFloating() {
    if let window = floatingWindow {
      window.level = (window.level == .floating) ? .normal : .floating
    }
  }
  
  func updateWindowTransparency(to newValue: Double) {
    floatingWindow?.animator().alphaValue = newValue
  }
  
  func closeFloatingWindow() {
    floatingWindow?.close()
    floatingWindow = nil
  }
  
  func windowDidResize(_ notification: Notification) {
    if let window = floatingWindow,
    let viewController = window.contentViewController as? ViewController {
    let aspectRatio = viewController.getActiveAspectRatio()

      window.setFrame(calculateContentRect(for: window.frame, aspectRatio: aspectRatio), display: true, animate: false)
    }
  }

  
  private func calculateContentRect(for frame: NSRect, aspectRatio: CGFloat) -> NSRect {
    var newFrame = frame
    if frame.width / frame.height > aspectRatio {
      newFrame.size.width = frame.height * aspectRatio
    } else {
      newFrame.size.height = frame.width / aspectRatio
    }
    return newFrame
  }
}
