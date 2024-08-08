import Flutter
import UIKit

public class SwiftScreenBrightnessIosPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
    var methodChannel: FlutterMethodChannel?

    var systemScreenBrightnessChangedEventChannel: FlutterEventChannel?
    let systemScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler = ScreenBrightnessChangedStreamHandler()

    var applicationScreenBrightnessChangedEventChannel: FlutterEventChannel?
    let applicationScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler = ScreenBrightnessChangedStreamHandler()
    
    var systemScreenBrightness: CGFloat?
    var applicationScreenBrightness: CGFloat?
    
    var isAutoReset: Bool = true
    var isAnimate: Bool = true
    
    let taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftScreenBrightnessIosPlugin()
        instance.methodChannel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        instance.systemScreenBrightnessChangedEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/system_brightness_changed", binaryMessenger: registrar.messenger())
        instance.systemScreenBrightnessChangedEventChannel!.setStreamHandler(instance.systemScreenBrightnessChangedStreamHandler)

        instance.applicationScreenBrightnessChangedEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/application_brightness_changed", binaryMessenger: registrar.messenger())
        instance.applicationScreenBrightnessChangedEventChannel!.setStreamHandler(instance.applicationScreenBrightnessChangedStreamHandler)
        
        registrar.addApplicationDelegate(instance)
    }
    
    override init() {
        super.init()
        systemScreenBrightness = UIScreen.main.brightness
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

        let _brightness = CGFloat(brightness.doubleValue)
        systemScreenBrightness = _brightness
        handleSystemScreenBrightnessChanged(_brightness)
        if (applicationScreenBrightness == nil) {
            setScreenBrightness(targetBrightness: _brightness, animated: isAnimate)
            handleApplicationScreenBrightnessChanged(_brightness)
        }
        result(nil)
    }

    private func handleSystemScreenBrightnessChanged(_ brightness: CGFloat) {
        systemScreenBrightnessChangedStreamHandler.addScreenBrightnessToEventSink(brightness)
    }
    
    private func handleGetApplicationScreenBrightnessMethodCall(result: FlutterResult) {
        result(UIScreen.main.brightness)
    }
    
    private func handleSetApplicationScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        let _brightness = CGFloat(brightness.doubleValue)
        setScreenBrightness(targetBrightness: _brightness, animated: isAnimate)
        
        applicationScreenBrightness = _brightness
        handleApplicationScreenBrightnessChanged(_brightness)
        result(nil)
    }
    
    private func handleResetApplicationScreenBrightnessMethodCall(result: FlutterResult) {
        guard let brightness = systemScreenBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        setScreenBrightness(targetBrightness: brightness, animated: isAnimate)
        
        applicationScreenBrightness = nil
        handleApplicationScreenBrightnessChanged(brightness)
        result(nil)
    }

    private func handleApplicationScreenBrightnessChanged(_ brightness: CGFloat) {
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
    
    public func applicationWillResignActive(_ application: UIApplication) {
        guard isAutoReset else {
            return
        }
        
        onApplicationPause()
        NotificationCenter.default.addObserver(self, selector: #selector(onSystemScreenBrightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        guard isAutoReset else {
            return
        }
        
        NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
        systemScreenBrightness = UIScreen.main.brightness
        handleSystemScreenBrightnessChanged(systemScreenBrightness!)
        if (applicationScreenBrightness == nil) {
            handleApplicationScreenBrightnessChanged(systemScreenBrightness!)
        }
        
        onApplicationResume()
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        onApplicationPause()
        NotificationCenter.default.removeObserver(self)
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        NotificationCenter.default.removeObserver(self)
        
        methodChannel?.setMethodCallHandler(nil)
        applicationScreenBrightnessChangedEventChannel?.setStreamHandler(nil)
        systemScreenBrightnessChangedEventChannel?.setStreamHandler(nil)
    }

    public func setScreenBrightness(targetBrightness: CGFloat, animated: Bool, duration: TimeInterval = 1.0) {
        taskQueue.cancelAllOperations()
        if !animated {
            UIScreen.main.brightness = targetBrightness
            return
        }

        let currentBrightness = UIScreen.main.brightness
        var framePerSecond = 60.0
        if #available(iOS 10.3, *) {
            framePerSecond = Double(UIScreen.main.maximumFramesPerSecond)
        }
        let changes = 0.01 / (framePerSecond / 60.0)
        let step = changes * ((targetBrightness > currentBrightness) ? 1 : -1)

        taskQueue.addOperations(stride(from: currentBrightness, through: targetBrightness, by: step).map({ _brightness -> Operation in
            let blockOperation = BlockOperation()
            unowned let _unownedOperation = blockOperation
            blockOperation.addExecutionBlock({
                guard !_unownedOperation.isCancelled else {
                    return
                }

                Thread.sleep(forTimeInterval: duration * changes)
                OperationQueue.main.addOperation({
                    UIScreen.main.brightness = _brightness
                })
            })
            return blockOperation
        }), waitUntilFinished: false)
    }
    
    @objc private func onSystemScreenBrightnessChanged(notification: Notification) {
        guard let screenObject = notification.object, let brightness = (screenObject as AnyObject).brightness else {
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
        
        setScreenBrightness(targetBrightness: systemScreenBrightness, animated: isAnimate, duration: 0.5)
    }
    
    func onApplicationResume() {
        guard let applicationScreenBrightness = applicationScreenBrightness else {
            return
        }
        
        setScreenBrightness(targetBrightness: applicationScreenBrightness, animated: isAnimate, duration: 0.5)
    }
}
