import Cocoa
import SwiftUI
import AVFoundation
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var keystrokes = ""
    var buffer = ""
    var keystrokeMonitor: KeystrokeMonitor!
    var menuController: MenuController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        
        DatabaseManager.shared
        
        menuController = MenuController()
        DatabaseManager.shared.onWordLogged = { [weak self] in
            self?.updateJustCount()
        }
        
        updateJustCount()
        
        keystrokeMonitor = KeystrokeMonitor()
            keystrokeMonitor.onJustDetected = {
                let context = self.keystrokeMonitor.captureContext()
                self.triggerAlert(withContext: context)
            }
            keystrokeMonitor.startMonitoring()
    }

    func captureContext() -> String {
        let justIndex = buffer.range(of: "just", options: .backwards)?.lowerBound ?? buffer.endIndex
        let startIdx = max(buffer.index(justIndex, offsetBy: -60, limitedBy: buffer.startIndex) ?? buffer.startIndex, buffer.startIndex)
        let endIdx = min(buffer.index(justIndex, offsetBy: 60, limitedBy: buffer.endIndex) ?? buffer.endIndex, buffer.endIndex)
        
        let contextRange = startIdx..<endIdx
        return String(buffer[contextRange])
    }

    func triggerAlert(withContext context: String) {
        menuController.flashMenuBarIcon()
        playSound()
        DatabaseManager.shared.logWord(date: Date(), word: "just", context: context)
        updateJustCount()
    }

    func playSound() {
        NSSound.beep()
    }

    func updateJustCount() {
        let count = DatabaseManager.shared.countWords(for: Date())
        DispatchQueue.main.async {
            self.menuController.updateJustCount(count: count)
        }
    }
}
