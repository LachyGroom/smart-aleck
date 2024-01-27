import Cocoa

class MenuController {
    var statusBarItem: NSStatusItem!
    var justCountMenuItem: NSMenuItem!

    init() {
        setupMenuBarItem()
    }

    private func setupMenuBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarIconDefault")
        }

        let menu = NSMenu()
        justCountMenuItem = NSMenuItem(title: "Today's count: 0", action: nil, keyEquivalent: "")
        menu.addItem(justCountMenuItem)
        menu.addItem(NSMenuItem(title: "Quit JustDetector", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem.menu = menu
    }

    func updateJustCount(count: Int) {
        justCountMenuItem.title = "Today's count: \(count)"
    }
    
    func flashMenuBarIcon() {
        guard let button = statusBarItem.button else {
            return
        }

        DispatchQueue.main.async {
            button.image = NSImage(named: "StatusBarIconRed")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            button.image = NSImage(named: "StatusBarIconDefault")
        }
    }
}
