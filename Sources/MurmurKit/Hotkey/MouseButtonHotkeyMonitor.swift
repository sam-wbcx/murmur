import AppKit

enum MouseButtonEdge: Equatable {
    case down
    case up
}

struct MouseButtonEdgeTracker {
    /// NSEvent numbers buttons from zero: 0 left, 1 right, 2 middle, 3 back, 4 forward.
    static let forwardButtonNumber = 4

    let buttonNumber: Int
    private(set) var isDown = false

    init(buttonNumber: Int = Self.forwardButtonNumber) {
        self.buttonNumber = buttonNumber
    }

    mutating func consume(type: NSEvent.EventType, buttonNumber: Int) -> MouseButtonEdge? {
        guard buttonNumber == self.buttonNumber else { return nil }
        switch type {
        case .otherMouseDown where !isDown:
            isDown = true
            return .down
        case .otherMouseUp where isDown:
            isDown = false
            return .up
        default:
            return nil
        }
    }

    mutating func reset() -> MouseButtonEdge? {
        guard isDown else { return nil }
        isDown = false
        return .up
    }
}

/// Fires `onButtonDown` / `onButtonUp` while a non-primary mouse button is held.
///
/// Observes through NSEvent monitors, so the click still reaches the app under
/// the cursor. Mouse events need no Accessibility grant. All access occurs on
/// the main thread, where NSEvent delivers callbacks.
public final class MouseButtonHotkeyMonitor: @unchecked Sendable {
    public var onButtonDown: (() -> Void)?
    public var onButtonUp: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var tracker = MouseButtonEdgeTracker()

    public init() {}

    deinit { removeMonitors() }

    public func setEnabled(_ enabled: Bool) {
        if enabled { installMonitors() }
        else {
            removeMonitors()
            if tracker.reset() != nil { onButtonUp?() }
        }
    }

    private func installMonitors() {
        guard globalMonitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [.otherMouseDown, .otherMouseUp]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.dispatch(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.dispatch(event)
            return event
        }
    }

    private func removeMonitors() {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor); globalMonitor = nil }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor); localMonitor = nil }
    }

    private func dispatch(_ event: NSEvent) {
        switch tracker.consume(type: event.type, buttonNumber: event.buttonNumber) {
        case .down: onButtonDown?()
        case .up: onButtonUp?()
        case nil: break
        }
    }
}
