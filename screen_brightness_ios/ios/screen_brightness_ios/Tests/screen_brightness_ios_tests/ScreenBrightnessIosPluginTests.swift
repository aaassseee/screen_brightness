import XCTest
@testable import screen_brightness_ios
import Flutter
import UIKit

// MARK: - Mocks

class MockBinaryMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {}
    func send(onChannel channel: String, message: Data?, binaryReply: FlutterBinaryReply?) {}
    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler: FlutterBinaryMessageHandler?) {}
}

class MockTextureRegistry: NSObject, FlutterTextureRegistry {
    func register(_ texture: FlutterTexture) -> Int64 { return 0 }
    func textureFrameAvailable(_ textureId: Int64) {}
    func unregisterTexture(_ textureId: Int64) {}
}

class MockPluginRegistrar: NSObject, FlutterPluginRegistrar {
    let mockMessenger = MockBinaryMessenger()
    var viewController: UIViewController? = nil

    func messenger() -> FlutterBinaryMessenger {
        return mockMessenger
    }

    func textures() -> FlutterTextureRegistry {
        return MockTextureRegistry()
    }

    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {}

    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {}

    func publish(_ value: NSObject) {}

    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {}

    func addApplicationDelegate(_ delegate: FlutterPlugin) {}
}

// MARK: - Tests

class ScreenBrightnessIosPluginTests: XCTestCase {
    var plugin: ScreenBrightnessIosPlugin!
    var mockRegistrar: MockPluginRegistrar!

    override func setUp() {
        super.setUp()
        mockRegistrar = MockPluginRegistrar()
        plugin = ScreenBrightnessIosPlugin(registrar: mockRegistrar)
    }

    override func tearDown() {
        plugin.detachFromEngine(for: mockRegistrar)
        plugin = nil
        mockRegistrar = nil
        super.tearDown()
    }

    func testInitialSystemScreenBrightnessIsSet() {
        XCTAssertNotNil(plugin.systemScreenBrightness)
    }

    func testIsAnimate_DefaultValueIsTrue() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertEqual(value as? Bool, true)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "isAnimate", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testSetAnimate_UpdatesValue() {
        let setExpectation = self.expectation(description: "set result called")
        let setResult: FlutterResult = { value in
            XCTAssertNil(value)
            setExpectation.fulfill()
        }

        let setCall = FlutterMethodCall(methodName: "setAnimate", arguments: ["isAnimate": false])
        plugin.handle(setCall, result: setResult)

        waitForExpectations(timeout: 1.0)

        let getExpectation = self.expectation(description: "get result called")
        let getResult: FlutterResult = { value in
            XCTAssertEqual(value as? Bool, false)
            getExpectation.fulfill()
        }

        let getCall = FlutterMethodCall(methodName: "isAnimate", arguments: nil)
        plugin.handle(getCall, result: getResult)

        waitForExpectations(timeout: 1.0)
    }

    func testSetAnimate_MissingArgument_ReturnsError() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            guard let error = value as? FlutterError else {
                XCTFail("Expected FlutterError")
                expectation.fulfill()
                return
            }
            XCTAssertEqual(error.code, "-2")
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "setAnimate", arguments: [:])
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testIsAutoReset_DefaultValueIsTrue() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertEqual(value as? Bool, true)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "isAutoReset", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testSetAutoReset_UpdatesValue() {
        let setExpectation = self.expectation(description: "set result called")
        let setResult: FlutterResult = { value in
            XCTAssertNil(value)
            setExpectation.fulfill()
        }

        let setCall = FlutterMethodCall(methodName: "setAutoReset", arguments: ["isAutoReset": false])
        plugin.handle(setCall, result: setResult)

        waitForExpectations(timeout: 1.0)

        let getExpectation = self.expectation(description: "get result called")
        let getResult: FlutterResult = { value in
            XCTAssertEqual(value as? Bool, false)
            getExpectation.fulfill()
        }

        let getCall = FlutterMethodCall(methodName: "isAutoReset", arguments: nil)
        plugin.handle(getCall, result: getResult)

        waitForExpectations(timeout: 1.0)
    }

    func testSetAutoReset_MissingArgument_ReturnsError() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            guard let error = value as? FlutterError else {
                XCTFail("Expected FlutterError")
                expectation.fulfill()
                return
            }
            XCTAssertEqual(error.code, "-2")
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "setAutoReset", arguments: [:])
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testCanChangeSystemBrightness_ReturnsTrue() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertEqual(value as? Bool, true)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "canChangeSystemBrightness", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testHasApplicationScreenBrightnessChanged_InitiallyFalse() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertEqual(value as? Bool, false)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "hasApplicationScreenBrightnessChanged", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testGetSystemScreenBrightness_ReturnsValue() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertNotNil(value)
            XCTAssertTrue(value is CGFloat || value is Double || value is NSNumber)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "getSystemScreenBrightness", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testSetSystemScreenBrightness_MissingArgument_ReturnsError() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            guard let error = value as? FlutterError else {
                XCTFail("Expected FlutterError")
                expectation.fulfill()
                return
            }
            XCTAssertEqual(error.code, "-2")
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "setSystemScreenBrightness", arguments: [:])
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testSetApplicationScreenBrightness_MissingArgument_ReturnsError() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            guard let error = value as? FlutterError else {
                XCTFail("Expected FlutterError")
                expectation.fulfill()
                return
            }
            XCTAssertEqual(error.code, "-2")
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "setApplicationScreenBrightness", arguments: [:])
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testResetApplicationScreenBrightness_WithSystemBrightnessSet_Succeeds() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertNil(value)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "resetApplicationScreenBrightness", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }

    func testHandleUnknownMethod_ReturnsNotImplemented() {
        let expectation = self.expectation(description: "result called")
        let result: FlutterResult = { value in
            XCTAssertNotNil(value)
            expectation.fulfill()
        }

        let call = FlutterMethodCall(methodName: "unknownMethod", arguments: nil)
        plugin.handle(call, result: result)

        waitForExpectations(timeout: 1.0)
    }
}
