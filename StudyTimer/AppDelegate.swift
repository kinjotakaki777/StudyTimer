import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timerManager: TimerManager!
    var remindersManager: RemindersManager!
    
    private var clickWorkItem: DispatchWorkItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        timerManager = TimerManager()
        remindersManager = RemindersManager()
        
        // Initialize Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.behavior = .transient
        
        let contentView = MainPopoverView(timerManager: timerManager, remindersManager: remindersManager)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Set up Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Apply a rounded white border frame as requested
            button.wantsLayer = true
            button.layer?.cornerRadius = 5.0
            button.layer?.borderWidth = 1.2
            button.layer?.borderColor = NSColor.white.cgColor
            
            // Use macOS system SF Symbol for a clean look
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Study Timer")
            button.imagePosition = .imageLeading
            
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            // Register for both left and right mouse click events
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Set initial white color as it starts at 0 seconds (start-prior)
            updateMenuBarTitle(timeString: "00:00")
        }
        
        // Update menu bar title when the timer ticks
        timerManager.onTick = { [weak self] timeString in
            DispatchQueue.main.async {
                self?.updateMenuBarTitle(timeString: timeString)
            }
        }
    }
    
    func updateMenuBarTitle(timeString: String) {
        guard let button = statusItem.button else { return }
        
        let color: NSColor
        if timerManager.secondsElapsed == 0 {
            color = NSColor.white
        } else if timerManager.isRunning {
            color = NSColor.labelColor
        } else {
            color = NSColor.systemRed
        }
        
        let font = button.font ?? NSFont.systemFont(ofSize: 13)
        
        let attributedTitle = NSAttributedString(
            string: timeString,
            attributes: [
                .foregroundColor: color,
                .font: font
            ]
        )
        button.attributedTitle = attributedTitle
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Cancel any pending single-click action
            clickWorkItem?.cancel()
            togglePopover(sender)
        } else if event.type == .leftMouseUp {
            if event.clickCount == 2 {
                // Double click: Reset timer
                clickWorkItem?.cancel()
                timerManager.reset()
                
                // Visual feedback in the menu bar button (briefly flash icon)
                flashStatusBarButton()
            } else if event.clickCount == 1 {
                // Single click: Start / Pause after a tiny delay to ensure it's not a double click
                clickWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.timerManager.toggle()
                }
                clickWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
            }
        }
    }
    
    func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                // Open Popover below the menu bar button
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Force focus popover window so keystrokes work for material name entry
                if let window = popover.contentViewController?.view.window {
                    window.makeKey()
                }
            }
        }
    }
    
    private func flashStatusBarButton() {
        guard let button = statusItem.button else { return }
        
        let originalImage = button.image
        button.image = NSImage(systemSymbolName: "arrow.clockwise.circle.fill", accessibilityDescription: "Reset")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            button.image = originalImage
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Save materials list before quitting
        timerManager.saveMaterials()
        timerManager.pause()
    }
}
