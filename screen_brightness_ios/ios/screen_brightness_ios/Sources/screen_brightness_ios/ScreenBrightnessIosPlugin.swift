import Flutter
import UIKit

public class ScreenBrightnessIosPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    var registrar: FlutterPluginRegistrar
    var methodChannel: FlutterMethodChannel?

    var systemScreenBrightnessChangedEventChannel: FlutterEventChannel?
    let systemScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler = ScreenBrightnessChangedStreamHandler()

    var applicationScreenBrightnessChangedEventChannel: FlutterEventChannel?
    let applicationScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler = ScreenBrightnessChangedStreamHandler()
    
    var systemScreenBrightness: CGFloat?
    var applicationScreenBrightness: CGFloat?
    private var pendingSystemScreenBrightnessRestoration: (target: CGFloat, expiresAt: TimeInterval)?
    
    var isAutoReset: Bool = true
    var isAnimate: Bool = true
    
    let taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
        systemScreenBrightness = currentScreenBrightness
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ScreenBrightnessIosPlugin(registrar: registrar)
        instance.methodChannel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        instance.systemScreenBrightnessChangedEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/system_brightness_changed", binaryMessenger: registrar.messenger())
        instance.systemScreenBrightnessChangedEventChannel!.setStreamHandler(instance.systemScreenBrightnessChangedStreamHandler)

        instance.applicationScreenBrightnessChangedEventChannel = FlutterEventChannel(name: "github.com/aaassseee/screen_brightness/application_brightness_changed", binaryMessenger: registrar.messenger())
        instance.applicationScreenBrightnessChangedEventChannel!.setStreamHandler(instance.applicationScreenBrightnessChangedStreamHandler)
        
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
    }

    private var currentScreen: UIScreen? {
        return registrar.viewController?.view.window?.windowScene?.screen
    }

    var currentScreenBrightness: CGFloat {
        return currentScreen?.brightness ?? UIScreen.main.brightness
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

        case "canChangeSystemBrightness":
            handleCanChangeSystemBrightnessMethodCall(result: result)

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
        pendingSystemScreenBrightnessRestoration = nil
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
        result(currentScreenBrightness)
    }
    
    private func handleSetApplicationScreenBrightnessMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        // The system may have adjusted brightness while the app was active.
        // Capture it only before the first override, never from our own override.
        if applicationScreenBrightness == nil {
            systemScreenBrightness = systemBrightnessForApplicationOverrideStart()
        }

        let _brightness = CGFloat(brightness.doubleValue)
        setScreenBrightness(targetBrightness: _brightness, animated: isAnimate)
        
        applicationScreenBrightness = _brightness
        handleApplicationScreenBrightnessChanged(_brightness)
        result(nil)
    }
    
    private func handleResetApplicationScreenBrightnessMethodCall(result: FlutterResult) {
        // With no override there is nothing to write. Preserve the stream event
        // so reset remains observable without restoring a potentially stale value.
        guard applicationScreenBrightness != nil else {
            handleApplicationScreenBrightnessChanged(currentScreenBrightness)
            result(nil)
            return
        }

        guard let brightness = systemScreenBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        recordSystemBrightnessRestoration(targetBrightness: brightness, duration: 1.0)
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

    private func handleCanChangeSystemBrightnessMethodCall(result: FlutterResult) {
        result(true)
    }
    
    public func sceneWillResignActive(_ scene: UIScene) {
        guard isAutoReset else {
            return
        }
        
        onApplicationPause()
        NotificationCenter.default.addObserver(self, selector: #selector(onSystemScreenBrightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }
    
    public func sceneDidBecomeActive(_ scene: UIScene) {
        guard isAutoReset else {
            return
        }
        
        NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
        pendingSystemScreenBrightnessRestoration = nil
        // This is intentionally refreshed even while an override exists: changes
        // made in the background become the baseline for the next lifecycle restore.
        systemScreenBrightness = currentScreenBrightness
        handleSystemScreenBrightnessChanged(systemScreenBrightness!)
        if (applicationScreenBrightness == nil) {
            handleApplicationScreenBrightnessChanged(systemScreenBrightness!)
        }
        
        onApplicationResume()
    }
    
    public func sceneDidDisconnect(_ scene: UIScene) {
        onApplicationTerminate()
        NotificationCenter.default.removeObserver(self)
        pendingSystemScreenBrightnessRestoration = nil
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        NotificationCenter.default.removeObserver(self)
        
        methodChannel?.setMethodCallHandler(nil)
        applicationScreenBrightnessChangedEventChannel?.setStreamHandler(nil)
        systemScreenBrightnessChangedEventChannel?.setStreamHandler(nil)
    }

    public func setScreenBrightness(targetBrightness: CGFloat, animated: Bool, duration: TimeInterval = 1.0) {
        taskQueue.cancelAllOperations()
        let screen = currentScreen ?? UIScreen.main
        if !animated {
            screen.brightness = targetBrightness
            return
        }

        let currentBrightness = screen.brightness
        var framePerSecond = 60.0
        if #available(iOS 10.3, *) {
            framePerSecond = Double(screen.maximumFramesPerSecond)
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
                    (self.currentScreen ?? UIScreen.main).brightness = _brightness
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
        guard applicationScreenBrightness != nil,
              let systemScreenBrightness = systemScreenBrightness else {
            return
        }
        
        recordSystemBrightnessRestoration(targetBrightness: systemScreenBrightness, duration: 0.5)
        setScreenBrightness(targetBrightness: systemScreenBrightness, animated: isAnimate, duration: 0.5)
    }
    
    func onApplicationResume() {
        pendingSystemScreenBrightnessRestoration = nil
        guard let applicationScreenBrightness = applicationScreenBrightness else {
            return
        }
        
        setScreenBrightness(targetBrightness: applicationScreenBrightness, animated: isAnimate, duration: 0.5)
    }
    
    func onApplicationTerminate() {
        guard applicationScreenBrightness != nil,
              let systemScreenBrightness = systemScreenBrightness else {
            return
        }
        
        pendingSystemScreenBrightnessRestoration = nil
        setScreenBrightness(targetBrightness: systemScreenBrightness, animated: false)
    }

    private func recordSystemBrightnessRestoration(targetBrightness: CGFloat, duration: TimeInterval) {
        guard isAnimate else {
            pendingSystemScreenBrightnessRestoration = nil
            return
        }

        pendingSystemScreenBrightnessRestoration = (
            target: targetBrightness,
            expiresAt: ProcessInfo.processInfo.systemUptime + duration
        )
    }

    private func systemBrightnessForApplicationOverrideStart() -> CGFloat {
        defer { pendingSystemScreenBrightnessRestoration = nil }

        if let pending = pendingSystemScreenBrightnessRestoration,
           ProcessInfo.processInfo.systemUptime <= pending.expiresAt {
            return pending.target
        }

        return currentScreenBrightness
    }
}
