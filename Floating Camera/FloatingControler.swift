import Cocoa
class FloatingController: NSWindowController, NSWindowDelegate {
  static let shared = FloatingController()
  public var floatingWindow: NSWindow?
  
  func showFloatingWindow() {
    if floatingWindow == nil {
      let contentRect = NSRect()// (x: 1250, y: 400, width: 800, height: 480)
      floatingWindow = NSWindow(contentRect: contentRect, styleMask: [.fullSizeContentView, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
      floatingWindow?.backgroundColor = NSColor.black
      floatingWindow?.hasShadow = false
      floatingWindow?.titlebarSeparatorStyle = .none
      floatingWindow?.delegate = self
      floatingWindow?.level = . floating
      floatingWindow?.titleVisibility = .hidden
      floatingWindow?.title = "Floating"
      floatingWindow?.orderFront(nil)
        
      let viewController = ViewController()
      floatingWindow?.contentViewController = viewController
    } else {
      floatingWindow?.orderFront(nil)
    }
  }
  
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
}
