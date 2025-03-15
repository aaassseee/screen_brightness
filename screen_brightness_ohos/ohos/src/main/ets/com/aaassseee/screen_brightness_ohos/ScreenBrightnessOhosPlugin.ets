import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodChannel,
  MethodResult,
  AbilityPluginBinding,
  MethodCallHandler,
  FlutterManager,
  Log
} from "@ohos/flutter_ohos";
import settings from '@ohos.settings';
import { window } from "@kit.ArkUI";

const TAG = "ScreenBrightnessOhosPlugin"

export default class ScreenBrightnessOhosPlugin implements FlutterPlugin, MethodCallHandler {
  private methodChannel?: MethodChannel;
  private applicationScreenBrightness?: number;
  private abilityPluginBinding: AbilityPluginBinding | null = null;
  private mainWindow: window.Window | null = null;

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (!this.mainWindow) {
      this.getWindow();
    }
    switch (call.method) {
      case "getSystemScreenBrightness":
        this.handleGetSystemScreenBrightnessMethodCall(result);
        break;
      case "getApplicationScreenBrightness":
        this.handleGetApplicationScreenBrightnessMethodCall(result);
        break;
      case "setApplicationScreenBrightness":
        this.handleSetApplicationScreenBrightnessMethodCall(call, result);
        break;
      case "resetApplicationScreenBrightness":
        this.handleResetApplicationScreenBrightnessMethodCall(result);
        break;
      case "canChangeSystemBrightness":
        this.handleCanChangeSystemBrightness(result);
        break;
      default:
        result.notImplemented(); break;
    }
  }

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), "github.com/aaassseee/screen_brightness");
    this.methodChannel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
  }

  getWindow(): void {
    this.mainWindow = FlutterManager.getInstance()
      .getWindowStage(FlutterManager.getInstance().getUIAbility(this.abilityPluginBinding?.getAbility().context))
      .getMainWindowSync();
  }

  private handleGetSystemScreenBrightnessMethodCall(result: MethodResult): void {
    try {
      let value = settings.getValueSync(
        this.abilityPluginBinding?.getAbility().context,
        settings.display.SCREEN_BRIGHTNESS_STATUS,
        '100',
        settings.domainName.DEVICE_SHARED
      );
      this.applicationScreenBrightness = parseFloat(value) / 255;
      result.success(this.applicationScreenBrightness);
    } catch (err) {
      result.success(1.0);
      Log.e(TAG, "get screen brightness failed");
    }
  }

  private handleGetApplicationScreenBrightnessMethodCall(result: MethodResult): void {
    this.applicationScreenBrightness = this.mainWindow?.getWindowProperties().brightness;
    if (this.applicationScreenBrightness && this.applicationScreenBrightness >= 0) {
      result.success(this.applicationScreenBrightness);
      return;
    }
    try {
      let value = settings.getValueSync(
        this.abilityPluginBinding?.getAbility().context,
        settings.display.SCREEN_BRIGHTNESS_STATUS,
        '100',
        settings.domainName.DEVICE_SHARED
      );
      this.applicationScreenBrightness = parseFloat(value) / 255;
      result.success(this.applicationScreenBrightness);
    } catch (err) {
      result.success(1.0);
      Log.e(TAG, "get screen brightness failed");
    }
  }

  private handleSetApplicationScreenBrightnessMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      this.mainWindow?.setWindowBrightness(parseFloat(call.argument("brightness")));
      this.applicationScreenBrightness = this.mainWindow?.getWindowProperties().brightness;
      result.success(null);
    } catch (e) {
      result.error("-1", "Unable to change application screen brightness", null);
    }
  }

  private handleResetApplicationScreenBrightnessMethodCall(result: MethodResult): void {
    try {
      this.mainWindow?.setWindowBrightness(-1);
      // let value = settings.getValueSync(
      //   this.abilityPluginBinding?.getAbility().context,
      //   settings.display.SCREEN_BRIGHTNESS_STATUS,
      //   '100',
      // );
      // this.applicationScreenBrightness = parseFloat(value) / 255;
      // result.success(null);
    } catch (e) {
      // result.success(null);
      Log.e(TAG, `${e}`);
      result.error("-1", "Unable to change application screen brightness", null);
    }
  }

  private handleCanChangeSystemBrightness(result: MethodResult): void {
    result.success(false);
  }
}
