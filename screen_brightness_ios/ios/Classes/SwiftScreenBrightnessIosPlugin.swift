import Flutter
import UIKit

public class SwiftScreenBrightnessIosPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
    var methodChannel: FlutterMethodChannel?

    var currentBrightnessChangeEventChannel: FlutterEventChannel?
    let currentBrightnessChangeStreamHandler: CurrentBrightnessChangeStreamHandler = CurrentBrightnessChangeStreamHandler()

    var systemBrightness: CGFloat?
    var changedBrightness: CGFloat?

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

        default:
            result(FlutterMethodNotImplemented)
            break;
        }
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
        UIScreen.main.brightness = _changedBrightness

        changedBrightness = _changedBrightness
        handleCurrentBrightnessChanged(_changedBrightness)
        result(nil)
    }

    private func handleResetScreenBrightnessMethodCall(result: FlutterResult) {
        guard let initialBrightness = systemBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }

        UIScreen.main.brightness = initialBrightness

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

        UIScreen.main.brightness = initialBrightness
    }

    func onApplicationResume() {
        guard let changedBrightness = changedBrightness else {
            return
        }

        UIScreen.main.brightness = changedBrightness
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        onApplicationPause()
        NotificationCenter.default.addObserver(self, selector: #selector(onSystemBrightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
        onApplicationResume()
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        onApplicationPause()
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
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
