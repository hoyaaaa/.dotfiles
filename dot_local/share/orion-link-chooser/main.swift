import AppKit
let appID = "local.hoya.orion-link-chooser"
func zenRunning() -> Bool { NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier?.hasPrefix("com.kagi.kagimacOS") == true } }
struct Profile { let name: String; let path: String; let isDefault: Bool; var containerID: Int?; var emoji: String? }
func containerChoices(root: String) throws -> [Profile] {
    let data = try Data(contentsOf: URL(fileURLWithPath: root + "/profiles"))
    let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
    let all = [plist["defaults"] as! [String: Any]] + (plist["profiles"] as? [[String: Any]] ?? [])
    let emojis = ["개인": "👨‍🚀", "회사": "🖥️", "베이스": "🧿", "이전 · 개인": "📚", "이전 · 회사": "🏢", "이전 · 베이스": "🧮", "추가 Chrome (Profile 7)": "🗃️"]
    return all.enumerated().compactMap { index, p in
        guard let name = p["name"] as? String, let id = p["identifier"] as? String else { return nil }
        let path: String
        if id == "Defaults" { path = NSHomeDirectory() + "/Applications/Orion/Orion Profiles/Defaults/Orion - 개인.app" }
        else {
            let dir = NSHomeDirectory() + "/Applications/Orion/Orion Profiles/" + id
            guard let app = try? FileManager.default.contentsOfDirectory(atPath: dir).first(where: { $0.hasSuffix(".app") }) else { return nil }
            path = dir + "/" + app
        }
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return Profile(name: name, path: path, isDefault: id == "Defaults", containerID: index + 1, emoji: emojis[name])
    }
}
class PickerPanel: NSPanel {
    var handleKey: ((NSEvent) -> Bool)?
    var handleModifiers: ((NSEvent) -> Void)?
    var quickCopy: (() -> Void)?
    private var shiftOnly = false
    override var canBecomeKey: Bool { true }
    override func keyDown(with event: NSEvent) {
        shiftOnly = false
        if handleKey?(event) != true { super.keyDown(with: event) }
    }
    override func flagsChanged(with event: NSEvent) {
        let flags = event.modifierFlags.intersection([.shift, .control, .option, .command])
        if event.keyCode == 56 || event.keyCode == 60 {
            if flags.contains(.shift) { shiftOnly = flags == [.shift] }
            else if shiftOnly { shiftOnly = false; quickCopy?() }
        } else { shiftOnly = false }
        handleModifiers?(event)
    }
}

class DestinationButton: NSButton {
    override var isFlipped: Bool { false }
    var onHover: ((Int) -> Void)?
    var focused = false { didSet { needsDisplay = true } }
    private var tracking: NSTrackingArea?
    override var acceptsFirstResponder: Bool { true }
    override func updateTrackingAreas() {
        if let tracking { removeTrackingArea(tracking) }
        tracking = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(tracking!); super.updateTrackingAreas()
    }
    override func mouseEntered(with event: NSEvent) { onHover?(tag) }
    override func draw(_ dirtyRect: NSRect) {
        if focused || isHighlighted {
            NSColor.labelColor.withAlphaComponent(isHighlighted ? 0.16 : 0.08).setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 3, dy: 3), xRadius: 11, yRadius: 11).fill()
        }
        let shortcut = tag < 9 ? String(tag + 1) : ""
        let number = NSAttributedString(string: shortcut, attributes: [.font: NSFont.systemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.secondaryLabelColor])
        number.draw(at: NSPoint(x: (bounds.width - number.size().width) / 2, y: bounds.height - 19))
        image?.draw(in: NSRect(x: (bounds.width - 64) / 2, y: 13, width: 64, height: 64), from: .zero, operation: .sourceOver, fraction: isEnabled ? 1 : 0.45)
    }
}

func destinationIcon(_ profile: Profile, index: Int) -> NSImage {
    NSImage(size: NSSize(width: 64, height: 64), flipped: false) { rect in
        let text = NSAttributedString(string: profile.emoji ?? String(profile.name.prefix(1)), attributes: [
            .font: NSFont.systemFont(ofSize: profile.emoji == nil ? 43 : 52, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ])
        let size = text.size()
        text.draw(at: NSPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2))
        return true
    }
}

func wrappedIndex(_ current: Int, delta: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    if current < 0 { return delta < 0 ? count - 1 : 0 }
    return ((current + delta) % count + count) % count
}

class Delegate: NSObject, NSApplicationDelegate, NSSharingServicePickerDelegate, NSMenuDelegate {
    var queue: [URL] = []
    var window: NSWindow?
    var choices: [Profile] = []
    var timer: Timer?
    var seenOrion = zenRunning()
    var launchingUntil = Date.distantPast
    var status: NSStatusItem?
    var buttons: [DestinationButton] = []
    var accessoryButtons: [NSButton] = []
    var sharingPicker: NSSharingServicePicker?
    var selected = 0
    var opening = false
    var workspaceStamp = ""
    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status?.button?.image = NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: "Orion 공간 선택")
        let menu = NSMenu()
        menu.delegate = self
        status?.menu = menu
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.refreshWorkspaceEmojis()
            if zenRunning() { self.seenOrion = true }
            else if self.seenOrion && self.queue.isEmpty && Date() > self.launchingUntil { NSApp.terminate(nil) }
        }
        if CommandLine.arguments.contains("--set-default") { setDefault() }
        showNext()
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let clipboard = menu.addItem(withTitle: "클립보드에서 링크 열기", action: #selector(openClipboard), keyEquivalent: "")
        clipboard.target = self
        menu.addItem(.separator())
        let heading = menu.addItem(withTitle: "Orion 프로필", action: nil, keyEquivalent: "")
        heading.isEnabled = false
        let available = (try? containerChoices(root: NSHomeDirectory() + "/Library/Application Support/Orion")) ?? []
        for (i, profile) in available.enumerated() {
            let item = menu.addItem(withTitle: profile.name, action: #selector(openContainerFromMenu(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = profile.containerID
            item.image = destinationIcon(profile, index: i); item.image?.size = NSSize(width: 24, height: 24)
            if profile.containerID == UserDefaults.standard.integer(forKey: "lastContainer") { item.state = .on }
        }
        menu.addItem(.separator())
        for (title, selector) in [("프로필 설정…", #selector(openContainerSettings)), ("기본 링크 앱 설정…", #selector(setDefault))] {
            let item = menu.addItem(withTitle: title, action: selector, keyEquivalent: ""); item.target = self
        }
    }
    @objc func openClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            showError("클립보드에 HTTP 또는 HTTPS 링크가 없습니다."); return
        }
        queue.append(url); showNext()
    }
    @objc func openContainerFromMenu(_ sender: NSMenuItem) {
        guard window == nil, queue.isEmpty, let id = sender.representedObject as? Int else { return }
        do { choices = try containerChoices(root: NSHomeDirectory() + "/Library/Application Support/Orion") }
        catch { showError(error.localizedDescription); return }
        guard let index = choices.firstIndex(where: { $0.containerID == id }) else { return }
        queue.append(URL(string: "about:blank")!)
        let button = NSButton(); button.tag = index; selectProfile(button)
    }
    @objc func openContainerSettings() {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Orion.app"), configuration: NSWorkspace.OpenConfiguration())
    }
    @objc func setDefault() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!)
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        queue.append(contentsOf: urls.filter { ["http", "https"].contains($0.scheme?.lowercased() ?? "") })
        showNext()
    }
    func showNext() {
        guard window == nil, let url = queue.first else { return }
        let root = NSHomeDirectory() + "/Library/Application Support/Orion"
        do {
            choices = try containerChoices(root: root)
                .filter { FileManager.default.fileExists(atPath: $0.path) }
            guard !choices.isEmpty else { throw NSError(domain: appID, code: 1, userInfo: [NSLocalizedDescriptionKey: "기본 프로필의 프로필를 찾을 수 없습니다."]) }
        } catch { showError(error.localizedDescription); return }
        selected = -1
        opening = false
        buttons = []
        workspaceStamp = ""
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main!
        let bounds = screen.visibleFrame
        let width = min(CGFloat(choices.count * 100 + 38), bounds.width - 32)
        let panel = PickerPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: 116), styleMask: [.borderless], backing: .buffered, defer: false)
        panel.title = "Orion · 공간 선택"
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        let background = NSVisualEffectView(frame: panel.contentView!.bounds)
        background.material = .popover; background.blendingMode = .behindWindow; background.state = .active
        background.autoresizingMask = [.width, .height]
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.layer?.borderWidth = 0.5
        background.layer?.borderColor = NSColor.separatorColor.cgColor
        background.layer?.masksToBounds = true
        panel.contentView = background
        let scroll = NSScrollView(frame: NSRect(x: 8, y: 5, width: width - 30, height: 106))
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = CGFloat(choices.count * 100) > scroll.frame.width
        scroll.autohidesScrollers = true
        let document = NSView(frame: NSRect(x: 0, y: 0, width: choices.count * 100, height: 106))
        scroll.documentView = document
        background.addSubview(scroll)
        for (i, profile) in choices.enumerated() {
            let button = DestinationButton(frame: NSRect(x: i * 100, y: 0, width: 100, height: 104))
            button.title = ""; button.target = self; button.action = #selector(selectProfile(_:)); button.tag = i
            button.isBordered = false; button.image = destinationIcon(profile, index: i)
            button.toolTip = "\(profile.name)\n\(url.host ?? "외부 링크")" + (i < 9 ? "\n\(i + 1) 키로 열기" : "")
            button.setAccessibilityLabel(profile.name + " 프로필로 링크 열기")
            button.setAccessibilityHelp(i < 9 ? "\(i + 1) 키로 선택. 방향키로 이동, Return 또는 Space로 열기" : "방향키로 이동, Return 또는 Space로 열기")
            button.onHover = { [weak self] index in self?.selected = index; self?.highlight() }
            buttons.append(button); document.addSubview(button)
        }
        let more = NSButton(frame: NSRect(x: width - 24, y: 45, width: 18, height: 22))
        more.isBordered = false; more.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "더 보기")
        more.target = self; more.action = #selector(showMore(_:)); more.toolTip = "더 보기 · Option으로 복사·공유"
        more.setAccessibilityLabel("더 보기")
        background.addSubview(more)
        accessoryButtons = []
        for (i, symbol) in ["doc.on.doc", "square.and.arrow.up"].enumerated() {
            let button = NSButton(frame: NSRect(x: width - 24, y: i == 0 ? 64 : 28, width: 18, height: 24))
            button.isBordered = false; button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: i == 0 ? "링크 복사" : "링크 공유")
            button.target = self; button.action = i == 0 ? #selector(copyLink) : #selector(shareLink(_:))
            button.toolTip = i == 0 ? "링크 복사 · ⌘C" : "링크 공유"
            button.isHidden = true; background.addSubview(button); accessoryButtons.append(button)
        }
        panel.quickCopy = { [weak self] in self?.copyLink() }
        panel.handleModifiers = { [weak self, weak more] event in
            let option = event.modifierFlags.contains(.option)
            more?.isHidden = option
            self?.accessoryButtons.forEach { $0.isHidden = !option }
        }
        panel.handleKey = { [weak self] event in
            guard let self, !self.opening else { return true }
            let flags = event.modifierFlags
            if flags.contains(.command), event.charactersIgnoringModifiers == "c" { self.copyLink(); return true }
            switch event.keyCode {
            case 53: self.cancelLink()
            case 36, 76, 49: self.selectProfile(self.buttons[max(0, self.selected)])
            case 123, 126: self.selected = wrappedIndex(self.selected, delta: -1, count: self.buttons.count); self.highlight()
            case 124, 125: self.selected = wrappedIndex(self.selected, delta: 1, count: self.buttons.count); self.highlight()
            case 48:
                self.selected = wrappedIndex(self.selected, delta: flags.contains(.shift) ? -1 : 1, count: self.buttons.count); self.highlight()
            default:
                guard flags.intersection([.command, .control, .option]).isEmpty,
                      let key = event.charactersIgnoringModifiers, let number = Int(key), (1...9).contains(number), self.buttons.indices.contains(number - 1) else { return false }
                self.selectProfile(self.buttons[number - 1])
            }
            return true
        }
        window = panel
        panel.setFrameOrigin(NSPoint(x: max(bounds.minX + 12, min(mouse.x - width / 2, bounds.maxX - width - 12)), y: max(bounds.minY + 12, min(mouse.y - panel.frame.height / 2, bounds.maxY - panel.frame.height - 12))))
        panel.makeKeyAndOrderFront(nil); panel.makeFirstResponder(panel); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func showMore(_ sender: NSButton) {
        let menu = NSMenu()
        let host = NSMenuItem(title: queue.first?.host ?? "외부 링크", action: nil, keyEquivalent: "")
        host.isEnabled = false; menu.addItem(host); menu.addItem(.separator())
        for (title, action) in [("링크 복사", #selector(copyLink)), ("링크 공유…", #selector(shareLink(_:))), ("취소", #selector(cancelLink))] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: ""); item.target = self
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY), in: sender)
        window?.makeFirstResponder(window)
    }
    @objc func shareLink(_ sender: Any?) {
        guard !opening, let url = queue.first, let view = window?.contentView else { return }
        sharingPicker = NSSharingServicePicker(items: [url])
        sharingPicker?.delegate = self
        sharingPicker?.show(relativeTo: NSRect(x: view.bounds.maxX - 20, y: 20, width: 1, height: 1), of: view, preferredEdge: .maxY)
    }
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        sharingPicker = nil
        if service != nil { finishLink() }
        else { window?.makeFirstResponder(window) }
    }
    func applicationDidResignActive(_ notification: Notification) {
        // Keep a pending share sheet alive; ordinary outside clicks cancel the prompt.
        if window != nil && !opening && sharingPicker == nil { cancelLink() }
    }
    func refreshWorkspaceEmojis() {}
    func highlight() {
        for (i, button) in buttons.enumerated() {
            button.focused = i == selected
        }
        if buttons.indices.contains(selected) { buttons[selected].scrollToVisible(buttons[selected].bounds) }
    }
    @objc func copyLink() {
        guard !opening, let url = queue.first else { return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(url.absoluteString, forType: .string)
        finishLink()
    }
    @objc func selectProfile(_ sender: NSButton) {
        guard !opening, choices.indices.contains(sender.tag), let url = queue.first else { return }
        opening = true
        buttons.forEach { $0.isEnabled = false }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = false
        config.activates = true
        launchingUntil = Date().addingTimeInterval(30)
        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: choices[sender.tag].path), configuration: config) { _, error in
            if let error { DispatchQueue.main.async { self.showError(error.localizedDescription) } }
        }
        // Orion profile shims can deliver the URL before LaunchServices completes its callback.
        UserDefaults.standard.set(choices[sender.tag].containerID, forKey: "lastContainer")
        finishLink()
    }
    @objc func cancelLink() { if !opening { finishLink() } }
    func finishLink() {
        opening = false
        if !queue.isEmpty { queue.removeFirst() }
        window?.close(); window = nil
        sharingPicker = nil
        if queue.isEmpty && !zenRunning() && Date() > launchingUntil { NSApp.terminate(nil) }
        else { showNext() }
    }
    func showError(_ message: String) { let alert = NSAlert(); alert.messageText = "Orion 링크 선택"; alert.informativeText = message; alert.runModal() }
}

if CommandLine.arguments.contains("--self-test") {
    let choices = try containerChoices(root: NSHomeDirectory() + "/Library/Application Support/Orion")
    precondition(choices.filter { ["개인", "회사", "베이스"].contains($0.name) }.count == 3)
    precondition(Set(choices.map(\.path)).count == choices.count)
    precondition(wrappedIndex(2, delta: 1, count: 3) == 0)
    for choice in choices { print(choice.name, choice.path) }
    print("Orion profile routing checks passed")
} else {
    let app = NSApplication.shared
    let delegate = Delegate(); app.delegate = delegate
    app.setActivationPolicy(.accessory); app.run()
}
