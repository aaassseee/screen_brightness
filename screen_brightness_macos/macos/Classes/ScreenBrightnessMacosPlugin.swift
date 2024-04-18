import Cocoa
import FlutterMacOS

enum ScreenBrightnessError: Error {
    case serviceMissing
}

public class ScreenBrightnessMacosPlugin: NSObject, FlutterPlugin {
    var methodChannel: FlutterMethodChannel?
    
    var currentBrightnessChangeEventChannel: FlutterEventChannel?
    let currentBrightnessChangeStreamHandler: CurrentBrightnessChangeStreamHandler = CurrentBrightnessChangeStreamHandler()
    
    var systemBrightness: Float?
    var changedBrightness: Float?
    
    var isAutoReset: Bool = true
    var isAnimate: Bool = true
    
    var brightnessPollingTimer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ScreenBrightnessMacosPlugin()
        instance.methodChannel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        
        instance.currentBrightnessChangeEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/change", binaryMessenger: registrar.messenger)
        instance.currentBrightnessChangeEventChannel!.setStreamHandler(instance.currentBrightnessChangeStreamHandler)
    }
    
    override init() {
        super.init()
        systemBrightness = try? getScreenBrightness()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSApplication.willTerminateNotification, object: nil)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSystemScreenBrightness":
            handleGetSystemBrightnessMethodCall(result: result)
            break;
            
        case "getScreenBrightness":
            handleGetScreenBrightnessMethodCall(result: result)
            break;
            
        case "setScreenBrightness":
            handleSetScreenBrightnessMethodCall(call: call, result: result)
            break;
            
        case "resetScreenBrightness":
            handleResetScreenBrightnessMethodCall(result: result)
            break;
            
        case "hasChanged":
            handleHasChangedMethodCall(result: result)
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
    
    private func handleGetSystemBrightnessMethodCall(result: FlutterResult) {
        guard let systemBrightness = systemBrightness else {
            result(FlutterError.init(code: "-11", message: "Could not found system setting screen brightness value", details: nil))
            return
        }
        
        result(systemBrightness)
    }
    
    private func handleGetScreenBrightnessMethodCall(result: FlutterResult) {
        do {
            let brightness = try getScreenBrightness()
            result(brightness)
        } catch {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
        }
    }
    
    private func handleSetScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        let _changedBrightness = Float(brightness.doubleValue)
        
        do {
            try setScreenBrightness(targetBrightness: _changedBrightness)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to change screen brightness", details: nil))
        }
        
        changedBrightness = _changedBrightness
        handleCurrentBrightnessChanged(_changedBrightness)
        result(nil)
    }
    
    private func handleResetScreenBrightnessMethodCall(result: FlutterResult) {
        guard let initialBrightness = systemBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        do {
            try setScreenBrightness(targetBrightness: initialBrightness)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to change screen brightness", details: nil))
        }
        
        changedBrightness = nil
        handleCurrentBrightnessChanged(initialBrightness)
        result(nil)
    }
    
    private func handleCurrentBrightnessChanged(_ currentBrightness: Float) {
        currentBrightnessChangeStreamHandler.addCurrentBrightnessToEventSink(currentBrightness)
    }
    
    private func handleHasChangedMethodCall(result: FlutterResult) {
        result(changedBrightness != nil)
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
    
    @objc private func getSystemBrightness(_: Timer) {
        guard let _systemBrightness = try? getScreenBrightness(), systemBrightness != _systemBrightness else {
            return
        }
        
        systemBrightness = _systemBrightness
        if (changedBrightness == nil) {
            handleCurrentBrightnessChanged(_systemBrightness)
        }
    }
    
    func onApplicationPause() {
        guard let initialBrightness = systemBrightness else {
            return
        }
        
        try! setScreenBrightness(targetBrightness: initialBrightness)
    }
    
    func onApplicationResume() {
        guard let changedBrightness = changedBrightness else {
            return
        }
        
        try! setScreenBrightness(targetBrightness: changedBrightness)
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
        
        if let _systemBrightness = try? getScreenBrightness() {
            systemBrightness = _systemBrightness
            if (changedBrightness == nil) {
                handleCurrentBrightnessChanged(systemBrightness!)
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
        currentBrightnessChangeEventChannel?.setStreamHandler(nil)
    }
}
