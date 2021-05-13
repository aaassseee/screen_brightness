import Flutter
import UIKit

public class SwiftScreenBrightnessPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
    var initialBrightness: CGFloat?
    var changedBrightness: CGFloat?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "github.com/aaassseee/screen_brightness", binaryMessenger: registrar.messenger())
        let instance = SwiftScreenBrightnessPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        registrar.addApplicationDelegate(instance)
    }
    
    override init() {
        super.init()
        initialBrightness = UIScreen.main.brightness
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInitialBrightness":
            getInitialBrightness(result: result)
            break;
            
        case "getScreenBrightness":
            getScreenBrightness(result: result)
            break;
            
        case "setScreenBrightness":
            setScreenBrightness(call: call, result: result)
            break;
            
        case "resetScreenBrightness":
            resetScreenBrightness(result: result)
            break;
            
        default:
            result(FlutterMethodNotImplemented)
            break;
        }
    }
    
    func getInitialBrightness(result: FlutterResult) {
        result(initialBrightness)
    }
    
    func getScreenBrightness(result: FlutterResult) {
        result(UIScreen.main.brightness)
    }
    
    func setScreenBrightness(call: FlutterMethodCall, result: FlutterResult) {
        guard let parameters = call.arguments as? Dictionary<String, Any>, let brightness = parameters["brightness"] as? NSNumber else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        changedBrightness = CGFloat(brightness.doubleValue)
        guard let changedBrightness = changedBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        UIScreen.main.brightness = changedBrightness
        result(nil)
    }
    
    func resetScreenBrightness(result: FlutterResult) {
        guard let originalBrightness = initialBrightness else {
            result(FlutterError.init(code: "-2", message: "Unexpected error on null brightness", details: nil))
            return
        }
        
        UIScreen.main.brightness = originalBrightness
        result(nil)
        
        changedBrightness = nil
    }
    
    func onApplicationPause() {
        guard let originalBrightness = initialBrightness else {
            return
        }
        UIScreen.main.brightness = originalBrightness
    }
    
    func onApplicationResume() {
        guard let changedBrightness = changedBrightness else {
            return
        }
        UIScreen.main.brightness = changedBrightness
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        onApplicationPause()
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
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
    }
}
