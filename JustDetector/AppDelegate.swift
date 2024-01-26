import Cocoa
import SwiftUI
import AVFoundation
import SQLite3

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var keystrokes = ""
    var buffer = ""
    var menu: NSMenu!
    var db: OpaquePointer?
    var justCountMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        
        initializeDatabase()
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "StatusBarIconDefault")
        }
        
        menu = NSMenu()
        justCountMenuItem = NSMenuItem(title: "Just Count: 0", action: #selector(updateJustCount), keyEquivalent: "")
        menu.addItem(justCountMenuItem)
        menu.addItem(NSMenuItem(title: "Quit JustDetector", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem.menu = menu
        
        updateJustCount()
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] (event) in
            guard let characters = event.charactersIgnoringModifiers else {
                return
            }
            if let self = self {
                self.keystrokes.append(contentsOf: characters.lowercased())
                self.buffer.append(contentsOf: characters.lowercased())
                
                if self.keystrokes.hasSuffix("just") {
                    self.triggerAlert()
                    self.keystrokes = ""
                }
                
                if characters == " " || characters == "\r" {
                    self.keystrokes = ""
                }
                
                if self.buffer.count > 120 {
                    self.buffer.removeFirst(self.buffer.count - 120)
                }
            }
        }
    }

    func initializeDatabase() {
        let fileURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("JustDetector.sqlite")
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            return
        }

        let createTableQuery = "CREATE TABLE IF NOT EXISTS Logs (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT, word TEXT, context TEXT)"
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            return
        }
    }

    func logWord(timestamp: String, word: String, context: String) {
        var stmt: OpaquePointer?
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedTimestamp = formatter.string(from: Date())

        let insertQuery = "INSERT INTO Logs (timestamp, word, context) VALUES (?, ?, ?)"
        if sqlite3_prepare_v2(db, insertQuery, -1, &stmt, nil) != SQLITE_OK {
            return
        }

        sqlite3_bind_text(stmt, 1, (formattedTimestamp as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (word as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (context as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) == SQLITE_DONE {
            updateJustCount()
        }

        sqlite3_finalize(stmt)
    }

    func captureContext() -> String {
        let justIndex = buffer.range(of: "just", options: .backwards)?.lowerBound ?? buffer.endIndex
        let startIdx = max(buffer.index(justIndex, offsetBy: -60, limitedBy: buffer.startIndex) ?? buffer.startIndex, buffer.startIndex)
        let endIdx = min(buffer.index(justIndex, offsetBy: 60, limitedBy: buffer.endIndex) ?? buffer.endIndex, buffer.endIndex)
        
        let contextRange = startIdx..<endIdx
        return String(buffer[contextRange])
    }

    func triggerAlert() {
        flashMenuBarIcon()
        playSound()
        let context = captureContext()
        logWord(timestamp: ISO8601DateFormatter().string(from: Date()), word: "just", context: context)
    }

    func flashMenuBarIcon() {
        guard let button = self.statusBarItem.button else {
            return
        }
        
        DispatchQueue.main.async {
            button.image = NSImage(named: "StatusBarIconRed")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            button.image = NSImage(named: "StatusBarIconDefault")
        }
    }

    func playSound() {
        NSSound.beep()
    }

    @objc func updateJustCount() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let query = "SELECT COUNT(*) FROM Logs WHERE timestamp LIKE '\(today)%' AND word = 'just'"
        var queryStatement: OpaquePointer? = nil

        if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let count = sqlite3_column_int(queryStatement, 0)
                DispatchQueue.main.async {
                    self.justCountMenuItem.title = "Just Count: \(count)"
                }
            }
        }

        sqlite3_finalize(queryStatement)
    }
}
