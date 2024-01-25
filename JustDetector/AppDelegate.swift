import Cocoa
import SwiftUI
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var keystrokes = ""
    var menu: NSMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Accessibility Permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)

        if accessEnabled {
            print("Accessibility permissions are enabled.")
        } else {
            print("Please enable accessibility permissions for JustDetector.")
        }

        // Setup Menu Bar Icon with a default image
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "StatusBarIconDefault") // Set your default icon here
            print("Default menu bar icon set.")
        } else {
            print("Failed to set default menu bar icon.")
        }
        
        // Create the menu
        menu = NSMenu()

        // Add a Quit App menu item
        menu.addItem(NSMenuItem(title: "Quit JustDetector", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // Attach the menu to the status bar item
        statusBarItem.menu = menu

        // Track Keystrokes
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] (event) in
            guard let characters = event.charactersIgnoringModifiers else {
                print("Key event could not be read.")
                return
            }
            
            self?.keystrokes.append(contentsOf: characters.lowercased())
            if self?.keystrokes.hasSuffix("just") ?? false {
                print("Detected 'just'.")
                self?.keystrokes = "" // Clear keystrokes after detection
                DispatchQueue.main.async {
                    self?.triggerAlert()
                }
            }

            // Clear the keystrokes buffer when space or return is pressed
            if characters == " " || characters == "\r" {
                self?.keystrokes = ""
            }
        }
    }

    func triggerAlert() {
        print("Triggering alert.")
        flashMenuBarIcon()
        playSound()
    }

    func flashMenuBarIcon() {
        guard let button = self.statusBarItem.button else {
            print("Failed to access the status bar button.")
            return
        }
        
        // Set the icon to a red version
        DispatchQueue.main.async {
            print("Changing menu bar icon to red.")
            button.image = NSImage(named: "StatusBarIconRed") // Set your red icon here
        }
        
        // Change back to the default icon after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Reverting menu bar icon to default.")
            button.image = NSImage(named: "StatusBarIconDefault") // Set your default icon here
        }
    }

    func playSound() {
        print("Playing sound.")
        NSSound.beep() // Play the system beep sound
    }
}
