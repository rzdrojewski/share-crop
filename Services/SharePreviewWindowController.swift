import AppKit

@MainActor
final class SharePreviewWindowController: NSWindowController {
    private let imageView = NSImageView()
    private let messageField = NSTextField(labelWithString: "Waiting for frames")

    init() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 960, height: 540))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.cgColor

        let imageView = NSImageView(frame: contentView.bounds)
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        imageView.animates = false

        let messageField = NSTextField(labelWithString: "Waiting for frames")
        messageField.textColor = .white
        messageField.font = .systemFont(ofSize: 28, weight: .semibold)
        messageField.alignment = .center
        messageField.backgroundColor = .clear
        messageField.frame = NSRect(x: 40, y: 24, width: 880, height: 40)
        messageField.autoresizingMask = [.width, .minYMargin]

        contentView.addSubview(imageView)
        contentView.addSubview(messageField)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Share Crop"
        window.contentView = contentView
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("ShareCropWindow")

        self.imageView.frame = imageView.frame
        self.messageField.frame = messageField.frame
        self.imageView.imageAlignment = imageView.imageAlignment
        self.imageView.imageScaling = imageView.imageScaling
        self.imageView.autoresizingMask = imageView.autoresizingMask
        self.messageField.textColor = messageField.textColor
        self.messageField.font = messageField.font
        self.messageField.alignment = messageField.alignment
        self.messageField.backgroundColor = .clear
        self.messageField.autoresizingMask = messageField.autoresizingMask

        super.init(window: window)

        window.contentView?.subviews.removeAll()
        window.contentView?.addSubview(self.imageView)
        window.contentView?.addSubview(self.messageField)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFrameNotification(_:)),
            name: .screenRecorderFrameReady,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func show(region: CaptureRegion) {
        guard let window else { return }

        let width: CGFloat = 960
        let height = max(240, width / max(region.aspectRatio, 0.2))
        let targetSize = NSSize(width: width, height: height)
        window.contentAspectRatio = targetSize
        window.setContentSize(targetSize)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showWaitingState() {
        imageView.image = nil
        messageField.stringValue = "Waiting for frames"
        messageField.isHidden = false
    }

    @objc private func handleFrameNotification(_ notification: Notification) {
        guard let image = notification.object as? NSImage else { return }
        imageView.image = image
        messageField.isHidden = true
    }
}
