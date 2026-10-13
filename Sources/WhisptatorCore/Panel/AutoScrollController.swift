import Foundation

/// Auto-scroll state machine for the live transcript panel.
///
/// Pinned (follow new lines) by default. Scrolling more than `engagementGap`
/// points above the bottom disengages; incoming lines then only increment the
/// unseen counter. Returning within the gap, or `jumpToLive()`, re-engages and
/// requests an immediate scroll to the newest line.
public final class AutoScrollController: @unchecked Sendable {
    private let lock = NSLock()
    public let engagementGap: Double
    public private(set) var isPinned: Bool
    public private(set) var unseenCount: Int = 0
    private var programmaticDeadline: Date = .distantPast
    private let followWindow: TimeInterval

    public init(pinned: Bool = true, engagementGap: Double = 40, followWindow: TimeInterval = 0.25) {
        self.isPinned = pinned
        self.engagementGap = engagementGap
        self.followWindow = followWindow
    }

    /// Transcript grew. Returns true when the view should scroll to the end.
    @discardableResult
    public func contentDidAppend(distanceFromBottom: Double, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if isPinned {
            if distanceFromBottom <= engagementGap || now <= programmaticDeadline {
                programmaticDeadline = now.addingTimeInterval(followWindow)
                return true
            }
            // Stale pinned state (viewport moved without a scroll event): free it.
            isPinned = false
            unseenCount += 1
            return false
        }
        unseenCount += 1
        return false
    }

    /// A user-driven scroll landed at `distanceFromBottom` from the end.
    /// Returns true when auto-scroll (re-)engaged and the view should jump live.
    @discardableResult
    public func userDidScroll(distanceFromBottom: Double, now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if now <= programmaticDeadline { return false } // our own scrollTo settling
        if distanceFromBottom <= engagementGap {
            isPinned = true
            unseenCount = 0
            programmaticDeadline = now.addingTimeInterval(followWindow)
            return true
        }
        isPinned = false
        return false
    }

    /// Pill / explicit "jump to live" action. Returns true when the view should
    /// scroll to the end.
    @discardableResult
    public func jumpToLive(now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        isPinned = true
        unseenCount = 0
        programmaticDeadline = now.addingTimeInterval(followWindow)
        return true
    }

    public func reset(pinned: Bool = true) {
        lock.lock()
        isPinned = pinned
        unseenCount = 0
        programmaticDeadline = .distantPast
        lock.unlock()
    }
}
