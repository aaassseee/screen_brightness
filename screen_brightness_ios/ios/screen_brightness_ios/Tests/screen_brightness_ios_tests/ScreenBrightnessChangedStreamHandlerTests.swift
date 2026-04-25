import XCTest
@testable import screen_brightness_ios
import Flutter

class ScreenBrightnessChangedStreamHandlerTests: XCTestCase {
    var handler: ScreenBrightnessChangedStreamHandler!

    override func setUp() {
        super.setUp()
        handler = ScreenBrightnessChangedStreamHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    func testAddScreenBrightnessToEventSink_WithNilEventSink_DoesNotCrash() {
        handler.addScreenBrightnessToEventSink(0.5)
    }

    func testAddScreenBrightnessToEventSink_WithEventSink_SendsBrightnessValue() {
        var receivedValue: Any?
        let mockEventSink: FlutterEventSink = { event in
            receivedValue = event
        }

        let error = handler.onListen(withArguments: nil, eventSink: mockEventSink)
        XCTAssertNil(error)

        handler.addScreenBrightnessToEventSink(0.75)

        XCTAssertNotNil(receivedValue)
        XCTAssertEqual(receivedValue as? Double, 0.75, accuracy: 0.001)
    }

    func testOnCancel_ClearsEventSink() {
        var receivedValue: Any?
        let mockEventSink: FlutterEventSink = { event in
            receivedValue = event
        }

        _ = handler.onListen(withArguments: nil, eventSink: mockEventSink)
        _ = handler.onCancel(withArguments: nil)

        handler.addScreenBrightnessToEventSink(0.5)
        XCTAssertNil(receivedValue)
    }

    func testOnListen_ReturnsNilError() {
        let mockEventSink: FlutterEventSink = { _ in }
        let error = handler.onListen(withArguments: nil, eventSink: mockEventSink)
        XCTAssertNil(error)
    }

    func testOnCancel_ReturnsNilError() {
        let error = handler.onCancel(withArguments: nil)
        XCTAssertNil(error)
    }
}
