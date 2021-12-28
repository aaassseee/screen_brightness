import Cocoa
import FlutterMacOS

public class ScreenBrightnessMacosPlugin: NSObject, FlutterPlugin {
    var methodChannel: FlutterMethodChannel?
    
    var currentBrightnessChangeEventChannel: FlutterEventChannel?
    let currentBrightnessChangeStreamHandler: CurrentBrightnessChangeStreamHandler = CurrentBrightnessChangeStreamHandler()
    
    var systemBrightness: Float?
    var changedBrightness: Float?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ScreenBrightnessMacosPlugin()
        instance.methodChannel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        
        instance.currentBrightnessChangeEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/change", binaryMessenger: registrar.messenger)
        instance.currentBrightnessChangeEventChannel!.setStreamHandler(instance.currentBrightnessChangeStreamHandler)
    }
    
    override init() {
        super.init()
        systemBrightness = try? getDisplayBrightness()
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
            
        default:
            result(FlutterMethodNotImplemented)
            break;
        }
    }
    
    func getDisplayBrightness() throws -> Float {
        var brightness: Float = 1.0
        var service: io_object_t = 1
        var iterator: io_iterator_t = 0
        let result: kern_return_t = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
        
        if result != kIOReturnSuccess {
            throw ScreenBrightnessError.serviceMissing
        }
        
        while service != 0 {
            service = IOIteratorNext(iterator)
            IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
            IOObjectRelease(service)
        }
        
        return brightness
    }
    
    func setDisplayBrightness(brightness: Float) throws {
        var service: io_object_t = 1
        var iterator: io_iterator_t = 0
        let result: kern_return_t = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
        
        if result != kIOReturnSuccess {
            throw ScreenBrightnessError.serviceMissing
        }
        
        while service != 0 {
            service = IOIteratorNext(iterator)
            IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, brightness)
            IOObjectRelease(service)
        }
    }
    
    func handleGetSystemBrightnessMethodCall(result: FlutterResult) {
        guard let systemBrightness = systemBrightness else {
            result(FlutterError.init(code: "-11", message: "Could not found system setting screen brightness value", details: nil))
            return
        }
        
        result(systemBrightness)
    }
    
    func handleGetScreenBrightnessMethodCall(result: FlutterResult) {
        do {
            let brightness = try getDisplayBrightness()
            result(brightness)
        } catch {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
        }
    }
    
    func handleSetScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        let _changedBrightness = Float(brightness.doubleValue)
        
        do {
            try setDisplayBrightness(brightness: _changedBrightness)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to change screen brightness", details: nil))
        }
        
        changedBrightness = _changedBrightness
        handleCurrentBrightnessChanged(_changedBrightness)
        result(nil)
    }
    
    func handleResetScreenBrightnessMethodCall(result: FlutterResult) {
        guard let initialBrightness = systemBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        do {
            try setDisplayBrightness(brightness: initialBrightness)
        } catch {
            result(FlutterError.init(code: "-1", message: "Unable to change screen brightness", details: nil))
        }
        
        changedBrightness = nil
        handleCurrentBrightnessChanged(initialBrightness)
        result(nil)
    }
    
    public func handleCurrentBrightnessChanged(_ currentBrightness: Float) {
        currentBrightnessChangeStreamHandler.addCurrentBrightnessToEventSink(currentBrightness)
    }
}

enum ScreenBrightnessError: Error {
    case serviceMissing
}
