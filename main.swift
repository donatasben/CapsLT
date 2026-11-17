// CapsLT — hold CapsLock + a key to type a Lithuanian letter. Tap CapsLock alone for Return / Escape / Caps Lock.
import SwiftUI
import ServiceManagement
import ApplicationServices
import IOKit.hidsystem

// Physical key (macOS virtual keycode) → letter. Shift or Caps Lock on → uppercase.
let letters: [Int64: String] = [
    0: "ą", 8: "č", 14: "ę", 13: "ė", 34: "į", 1: "š", 32: "ų", 16: "ū", 6: "ž",    // a c e w i s u y z
    18: "ą", 19: "č", 20: "ę", 21: "ė", 23: "į", 22: "š", 26: "ų", 28: "ū", 24: "ž", // 1 2 3 4 5 6 7 8 =
]
let f18: Int64 = 79
let capsHID = 0x700000039, f18HID = 0x70000006D

enum TapAction: String, CaseIterable { case returnKey = "Return", escape = "Escape", capsLock = "Caps Lock" }

// MARK: - CapsLock → F18 remap (hidutil, keeps any other remaps the user has)

enum Remap {
    @discardableResult static func hidutil(_ args: String...) -> String {
        let p = Process(), pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        p.arguments = args
        p.standardOutput = pipe
        try? p.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }

    /// Current remaps, without ours.
    static func others() -> [[String: Int]] {
        let out = hidutil("property", "--get", "UserKeyMapping")
        var pairs = Set<[Int]>()
        for block in out.matches(of: try! Regex(#"\{([^}]*)\}"#)) {
            let b = String(out[block.range])
            if let s = b.firstMatch(of: try! Regex(#"Src = (\d+)"#))?[1].substring,
               let d = b.firstMatch(of: try! Regex(#"Dst = (\d+)"#))?[1].substring,
               let src = Int(s), let dst = Int(d), src != capsHID { pairs.insert([src, dst]) }
        }
        return pairs.map { ["HIDKeyboardModifierMappingSrc": $0[0], "HIDKeyboardModifierMappingDst": $0[1]] }
    }

    static func set(_ m: [[String: Int]]) {
        let json = try! JSONSerialization.data(withJSONObject: ["UserKeyMapping": m])
        hidutil("property", "--set", String(decoding: json, as: UTF8.self))
    }

    static func apply() { set(others() + [["HIDKeyboardModifierMappingSrc": capsHID, "HIDKeyboardModifierMappingDst": f18HID]]) }
    static func remove() { set(others()) }
}

// MARK: - Key handling

final class Keys: ObservableObject {
    static let shared = Keys()
    @Published var running = false
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled

    func setLaunchAtLogin(_ on: Bool) {
        try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    private var tap: CFMachPort?
    private var layerSince: Date?
    private var used = false

    /// Starts the key listener. Returns false while Accessibility permission is missing.
    func start() -> Bool {
        guard tap == nil else { return true }
        guard AXIsProcessTrusted() else { return false }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                eventsOfInterest: mask, callback: { _, type, event, _ in Keys.shared.handle(type, event) },
                                userInfo: nil)
        guard let tap else { return false }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        Remap.apply()
        running = true
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass
        }
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        if key == f18 {
            if type == .keyDown, layerSince == nil { layerSince = Date(); used = false }
            if type == .keyUp, let since = layerSince {
                layerSince = nil
                if !used, Date().timeIntervalSince(since) < 1 { tapAction() }
            }
            return nil
        }
        guard layerSince != nil else { return pass }
        used = true
        let flags = event.flags
        guard let letter = letters[key], flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate]) else { return pass }
        var text = Array((flags.contains(.maskShift) || flags.contains(.maskAlphaShift) ? letter.uppercased() : letter).utf16)
        event.keyboardSetUnicodeString(stringLength: text.count, unicodeString: &text)
        event.flags = []
        return pass
    }

    private func tapAction() {
        switch TapAction(rawValue: UserDefaults.standard.string(forKey: "tapAction") ?? "") ?? .returnKey {
        case .returnKey: press(36)
        case .escape: press(53)
        case .capsLock: toggleCapsLock()
        }
    }

    private func press(_ key: CGKeyCode) {
        for down in [true, false] { CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down)?.post(tap: .cghidEventTap) }
    }

    private func toggleCapsLock() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        defer { IOObjectRelease(service) }
        var conn: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &conn) == KERN_SUCCESS else { return }
        defer { IOServiceClose(conn) }
        var on = false
        IOHIDGetModifierLockState(conn, Int32(kIOHIDCapsLockState), &on)
        IOHIDSetModifierLockState(conn, Int32(kIOHIDCapsLockState), !on)
    }
}

// MARK: - App and menu bar UI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { t in if Keys.shared.start() { t.invalidate() } }.fire()
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            if Keys.shared.running { Remap.apply() }
        }
    }

    func applicationWillTerminate(_: Notification) { Remap.remove() }
}

@main
struct CapsLTApp: App {
    @NSApplicationDelegateAdaptor var delegate: AppDelegate
    @ObservedObject var keys = Keys.shared
    @AppStorage("tapAction") var tapAction = TapAction.returnKey.rawValue

    var body: some Scene {
        MenuBarExtra {
            if keys.running {
                Text("Active: hold CapsLock + a c e w i s u y z")
            } else {
                Button("Grant Accessibility permission…") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
            Picker("Tap CapsLock alone", selection: $tapAction) {
                ForEach(TapAction.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
            }
            Toggle("Launch at login", isOn: Binding(get: { keys.launchAtLogin }, set: keys.setLaunchAtLogin))
            Divider()
            Button("Quit CapsLT") { NSApp.terminate(nil) }.keyboardShortcut("q")
        } label: {
            Text("Ą")
        }
    }
}
