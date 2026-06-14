import XCTest
@testable import screen_brightness_ios
import Flutter

class BaseStreamHandlerTests: XCTestCase {
    var handler: BaseStreamHandler!

    override func setUp() {
        super.setUp()
        handler = BaseStreamHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    func testOnListen_SetsEventSink() {
        let mockEventSink: FlutterEventSink = { _ in }
        let error = handler.onListen(withArguments: nil, eventSink: mockEventSink)
        XCTAssertNil(error)
        XCTAssertNotNil(handler.eventSink)
    }

    func testOnCancel_ClearsEventSink() {
        let mockEventSink: FlutterEventSink = { _ in }
        _ = handler.onListen(withArguments: nil, eventSink: mockEventSink)
        _ = handler.onCancel(withArguments: nil)
        XCTAssertNil(handler.eventSink)
    }

    func testOnCancel_WhenEventSinkIsNil_ReturnsNil() {
        let error = handler.onCancel(withArguments: nil)
        XCTAssertNil(error)
    }
}
