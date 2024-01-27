import Cocoa

class KeystrokeMonitor {
    var onJustDetected: (() -> Void)?
    private var buffer = ""
    private var keystrokes = ""

    func startMonitoring() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] (event) in
            guard let self = self, let characters = event.charactersIgnoringModifiers else {
                return
            }

            self.keystrokes.append(contentsOf: characters.lowercased())
            self.buffer.append(contentsOf: characters.lowercased())
            
            if self.keystrokes.hasSuffix("just") {
                self.onJustDetected?()
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

    func captureContext() -> String {
        let justIndex = buffer.range(of: "just", options: .backwards)?.lowerBound ?? buffer.endIndex
        let startIdx = max(buffer.index(justIndex, offsetBy: -60, limitedBy: buffer.startIndex) ?? buffer.startIndex, buffer.startIndex)
        let endIdx = min(buffer.index(justIndex, offsetBy: 60, limitedBy: buffer.endIndex) ?? buffer.endIndex, buffer.endIndex)
        
        let contextRange = startIdx..<endIdx
        return String(buffer[contextRange])
    }
}
