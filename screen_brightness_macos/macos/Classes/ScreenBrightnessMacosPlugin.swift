import Cocoa
import FlutterMacOS

enum ScreenBrightnessError: Error {
    case serviceMissing
}

public class ScreenBrightnessMacosPlugin: NSObject, FlutterPlugin {
    var methodChannel: FlutterMethodChannel?
    
    var systemScreenBrightnessChangedEventChannel: FlutterEventChannel?
    let systemScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler = ScreenBrightnessChangedStreamHandler()
    
    var applicationScreenBrightnessChangedEventChannel: FlutterEventChannel?
    let applicationScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler = ScreenBrightnessChangedStreamHandler()
    
    var systemScreenBrightness: Float?
    var applicationScreenBrightness: Float?
    
    var isAutoReset: Bool = true
    var isAnimate: Bool = true
    
    var brightnessPollingTimer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ScreenBrightnessMacosPlugin()
        instance.methodChannel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        instance.systemScreenBrightnessChangedEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/system_brightness_changed", binaryMessenger: registrar.messenger)
        instance.systemScreenBrightnessChangedEventChannel!.setStreamHandler(instance.systemScreenBrightnessChangedStreamHandler)

        instance.applicationScreenBrightnessChangedEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/application_brightness_changed", binaryMessenger: registrar.messenger)
        instance.applicationScreenBrightnessChangedEventChannel!.setStreamHandler(instance.applicationScreenBrightnessChangedStreamHandler)
    }
    
    override init() {
        super.init()
        systemScreenBrightness = try? getScreenBrightness()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSApplication.willTerminateNotification, object: nil)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSystemScreenBrightness":
            handleGetSystemScreenBrightnessMethodCall(result: result)
            break;

        case "setSystemScreenBrightness":
            handleSetSystemScreenBrightnessMethodCall(call: call, result: result)
            break;

        case "getApplicationScreenBrightness":
            handleGetApplicationScreenBrightnessMethodCall(result: result)
            break;
            
        case "setApplicationScreenBrightness":
            handleSetApplicationScreenBrightnessMethodCall(call: call, result: result)
            break;
            
        case "resetApplicationScreenBrightness":
            handleResetApplicationScreenBrightnessMethodCall(result: result)
            break;
            
        case "hasApplicationScreenBrightnessChanged":
            handleHasApplicationScreenBrightnessChangedMethodCall(result: result)
            break;
            
        case "isAutoReset":
            handleIsAutoResetMethodCall(result: result)
            
        case "setAutoReset":
            handleSetAutoResetMethodCall(call: call, result: result)

        case "isAnimate":
            handleIsAnimateMethodCall(result: result)

        case "setAnimate":
            handleSetAnimateMethodCall(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
            break;
        }
    }
    
    private func handleGetSystemScreenBrightnessMethodCall(result: FlutterResult) {
        guard let systemScreenBrightness = systemScreenBrightness else {
            result(FlutterError.init(code: "-11", message: "Could not found system screen brightness value", details: nil))
            return
        }
        
        result(systemScreenBrightness)
    }

    private func handleSetSystemScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }

        let _brightness = Float(brightness.doubleValue)
        do {
            if (applicationScreenBrightness == nil) {
                try setScreenBrightness(targetBrightness: _brightness)
                handleApplicationScreenBrightnessChanged(_brightness)
            }
            systemScreenBrightness = _brightness
            handleSystemScreenBrightnessChanged(_brightness)
            result(nil)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to change system screen brightness", details: nil))
        }
    }
    
    private func handleSystemScreenBrightnessChanged(_ brightness: Float) {
        systemScreenBrightnessChangedStreamHandler.addScreenBrightnessToEventSink(brightness)
    }
    
    private func handleGetApplicationScreenBrightnessMethodCall(result: FlutterResult) {
        do {
            let _brightness = try getScreenBrightness()
            result(_brightness)
        } catch {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
        }
    }
    
    private func handleSetApplicationScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        let _brightness = Float(brightness.doubleValue)
        do {
            try setScreenBrightness(targetBrightness: _brightness)
            applicationScreenBrightness = _brightness
            handleApplicationScreenBrightnessChanged(_brightness)
            result(nil)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to change application screen brightness", details: nil))
        }
    }
    
    private func handleResetApplicationScreenBrightnessMethodCall(result: FlutterResult) {
        guard let brightness = systemScreenBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        do {
            try setScreenBrightness(targetBrightness: brightness)
            applicationScreenBrightness = nil
            handleApplicationScreenBrightnessChanged(brightness)
            result(nil)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to reset screen brightness", details: nil))
        }
    }
    
    private func handleApplicationScreenBrightnessChanged(_ brightness: Float) {
        applicationScreenBrightnessChangedStreamHandler.addScreenBrightnessToEventSink(brightness)
    }
    
    private func handleHasApplicationScreenBrightnessChangedMethodCall(result: FlutterResult) {
        result(applicationScreenBrightness != nil)
    }
    
    private func handleIsAutoResetMethodCall(result: FlutterResult) {
        result(isAutoReset)
    }
    
    private func handleSetAutoResetMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let isAutoReset = parameters["isAutoReset"] as? Bool else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null isAutoReset", details: nil))
            return
        }
        
        self.isAutoReset = isAutoReset
        result(nil)
    }

    private func handleIsAnimateMethodCall(result: FlutterResult) {
        result(isAnimate)
    }

    private func handleSetAnimateMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let isAnimate = parameters["isAnimate"] as? Bool else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null isAnimate", details: nil))
            return
        }

        self.isAnimate = isAnimate
        result(nil)
    }
    
    @objc public func applicationWillResignActive(notification: Notification) {
        guard isAutoReset else {
            return
        }
        
        onApplicationPause()
        brightnessPollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getSystemBrightness), userInfo: nil, repeats: true)
    }
    
    @objc public func applicationDidBecomeActive(notification: Notification) {
        guard isAutoReset else {
            return
        }
        
        brightnessPollingTimer?.invalidate()
        brightnessPollingTimer = nil
        
        if let _systemScreenBrightness = try? getScreenBrightness() {
            systemScreenBrightness = _systemScreenBrightness
            handleSystemScreenBrightnessChanged(systemScreenBrightness!)
            if (applicationScreenBrightness == nil) {
                handleApplicationScreenBrightnessChanged(systemScreenBrightness!)
            }
        }
        
        onApplicationResume()
    }
    
    @objc public func applicationWillTerminate(notification: Notification) {
        onApplicationPause()
        NotificationCenter.default.removeObserver(self)
        
        brightnessPollingTimer?.invalidate()
        brightnessPollingTimer = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        methodChannel?.setMethodCallHandler(nil)
        applicationScreenBrightnessChangedEventChannel?.setStreamHandler(nil)
        systemScreenBrightnessChangedEventChannel?.setStreamHandler(nil)
    }
    
    @discardableResult private func getIODisplayConnectServices(iterator: inout io_iterator_t) throws -> kern_return_t {
        var port: mach_port_t = kIOMasterPortDefault
        if #available(macOS 12.0, *) {
            port = kIOMainPortDefault
        }
        
        let result = IOServiceGetMatchingServices(port, IOServiceMatching("IODisplayConnect"), &iterator)
        
        guard result == kIOReturnSuccess else {
            throw ScreenBrightnessError.serviceMissing
        }
        
        return result
    }
    
    private func getScreenBrightness() throws -> Float {
        var brightness: Float = 0.0
        
        var service: io_object_t = 1
        var iterator: io_iterator_t = 0
        try getIODisplayConnectServices(iterator: &iterator)
        
        while service != 0 {
            service = IOIteratorNext(iterator)
            IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
            IOObjectRelease(service)
        }
        
        return brightness
    }
    
    private func setScreenBrightness(targetBrightness: Float) throws {
        var service: io_object_t = 1
        var iterator: io_iterator_t = 0
        try getIODisplayConnectServices(iterator: &iterator)
        
        while service != 0 {
            service = IOIteratorNext(iterator)
            IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, targetBrightness)
            IOObjectRelease(service)
        }
    }

    @objc private func getSystemBrightness(_: Timer) {
        guard let brightness = try? getScreenBrightness(), systemScreenBrightness != brightness else {
            return
        }

        systemScreenBrightness = brightness
        handleSystemScreenBrightnessChanged(brightness)
        if (applicationScreenBrightness == nil) {
            handleApplicationScreenBrightnessChanged(brightness)
        }
    }

    func onApplicationPause() {
        guard let systemScreenBrightness = systemScreenBrightness else {
            return
        }

        try! setScreenBrightness(targetBrightness: systemScreenBrightness)
    }

    func onApplicationResume() {
        guard let applicationScreenBrightness = applicationScreenBrightness else {
            return
        }

        try! setScreenBrightness(targetBrightness: applicationScreenBrightness)
    }
}
