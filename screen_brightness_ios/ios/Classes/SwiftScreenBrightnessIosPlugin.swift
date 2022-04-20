import Flutter
import UIKit

public class SwiftScreenBrightnessIosPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
    var methodChannel: FlutterMethodChannel?
    
    var currentBrightnessChangeEventChannel: FlutterEventChannel?
    let currentBrightnessChangeStreamHandler: CurrentBrightnessChangeStreamHandler = CurrentBrightnessChangeStreamHandler()
    
    var systemBrightness: CGFloat?
    var changedBrightness: CGFloat?
    
    var isAutoReset: Bool = true
    
    let taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftScreenBrightnessIosPlugin()
        instance.methodChannel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        
        instance.currentBrightnessChangeEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/change", binaryMessenger: registrar.messenger())
        instance.currentBrightnessChangeEventChannel!.setStreamHandler(instance.currentBrightnessChangeStreamHandler)
        
        registrar.addApplicationDelegate(instance)
    }
    
    override init() {
        super.init()
        systemBrightness = UIScreen.main.brightness
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
            
        default:
            result(FlutterMethodNotImplemented)
            break;
        }
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
    
    private func handleGetSystemBrightnessMethodCall(result: FlutterResult) {
        result(systemBrightness)
    }
    
    private func handleGetScreenBrightnessMethodCall(result: FlutterResult) {
        result(UIScreen.main.brightness)
    }
    
    private func handleSetScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        let _changedBrightness = CGFloat(brightness.doubleValue)
        setScreenBrightness(targetBrightness: _changedBrightness, animated: true)
        
        changedBrightness = _changedBrightness
        handleCurrentBrightnessChanged(_changedBrightness)
        result(nil)
    }
    
    private func handleResetScreenBrightnessMethodCall(result: FlutterResult) {
        guard let initialBrightness = systemBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        setScreenBrightness(targetBrightness: initialBrightness, animated: true)
        
        changedBrightness = nil
        handleCurrentBrightnessChanged(initialBrightness)
        result(nil)
    }
    
    private func handleHasChangedMethodCall(result: FlutterResult) {
        result(changedBrightness != nil)
    }
    
    private func handleCurrentBrightnessChanged(_ currentBrightness: CGFloat) {
        currentBrightnessChangeStreamHandler.addCurrentBrightnessToEventSink(currentBrightness)
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
    
    @objc private func onSystemBrightnessChanged(notification: Notification) {
        guard let screenObject = notification.object, let brightness = (screenObject as AnyObject).brightness else {
            return
        }
        
        systemBrightness = brightness
        if (changedBrightness == nil) {
            handleCurrentBrightnessChanged(brightness)
        }
    }
    
    func onApplicationPause() {
        guard let initialBrightness = systemBrightness else {
            return
        }
        
        setScreenBrightness(targetBrightness: initialBrightness, animated: true, duration: 0.5)
    }
    
    func onApplicationResume() {
        guard let changedBrightness = changedBrightness else {
            return
        }
        
        setScreenBrightness(targetBrightness: changedBrightness, animated: true, duration: 0.5)
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        guard isAutoReset else {
            return
        }
        
        onApplicationPause()
        NotificationCenter.default.addObserver(self, selector: #selector(onSystemBrightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        guard isAutoReset else {
            return
        }
        
        NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
        systemBrightness = UIScreen.main.brightness
        if (changedBrightness == nil) {
            handleCurrentBrightnessChanged(systemBrightness!)
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
        currentBrightnessChangeEventChannel?.setStreamHandler(nil)
    }
}
