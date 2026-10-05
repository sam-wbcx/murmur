import XCTest
import AppKit
@testable import MurmurKit

final class MouseButtonHotkeyMonitorTests: XCTestCase {
    private let forward = MouseButtonEdgeTracker.forwardButtonNumber

    func testOneDownAndUpPerHold() {
        var tracker = MouseButtonEdgeTracker()
        XCTAssertEqual(tracker.consume(type: .otherMouseDown, buttonNumber: forward), .down)
        XCTAssertNil(tracker.consume(type: .otherMouseDown, buttonNumber: forward))
        XCTAssertEqual(tracker.consume(type: .otherMouseUp, buttonNumber: forward), .up)
        XCTAssertNil(tracker.consume(type: .otherMouseUp, buttonNumber: forward))
    }

    func testOtherButtonsNeverFire() {
        var tracker = MouseButtonEdgeTracker()
        for button in [2, 3] {
            XCTAssertNil(tracker.consume(type: .otherMouseDown, buttonNumber: button))
            XCTAssertNil(tracker.consume(type: .otherMouseUp, buttonNumber: button))
        }
        XCTAssertFalse(tracker.isDown)
    }

    func testOtherButtonReleaseDuringHoldKeepsHold() {
        var tracker = MouseButtonEdgeTracker()
        XCTAssertEqual(tracker.consume(type: .otherMouseDown, buttonNumber: forward), .down)
        XCTAssertNil(tracker.consume(type: .otherMouseUp, buttonNumber: 3))
        XCTAssertTrue(tracker.isDown)
    }

    func testReleaseWithoutPressIsIgnored() {
        var tracker = MouseButtonEdgeTracker()
        XCTAssertNil(tracker.consume(type: .otherMouseUp, buttonNumber: forward))
    }

    func testDisableSynthesizesOneRelease() {
        var tracker = MouseButtonEdgeTracker()
        XCTAssertEqual(tracker.consume(type: .otherMouseDown, buttonNumber: forward), .down)
        XCTAssertEqual(tracker.reset(), .up)
        XCTAssertNil(tracker.reset())
    }
}
