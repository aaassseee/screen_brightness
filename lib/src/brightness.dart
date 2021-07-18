import 'package:flutter/services.dart';
import 'package:screen_brightness/src/constant/brightness.dart';
import 'package:screen_brightness/src/constant/method_name.dart';
import 'package:screen_brightness/src/constant/plugin.dart';
import 'package:screen_brightness/src/extension/num_extension.dart';

/// Plugin for changing screen brightness
class ScreenBrightness {
  /// ScreenBrightness designed as static method collection class
  /// So constructor should not provide to user.
  ScreenBrightness._();

  /// Method channel which can interact with native platform
  static const MethodChannel _channel = MethodChannel(pluginMethodChannelName);

  /// Returns intial screen brightness which is set when application is started.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This parameter is useful for user to get screen brightness value after
  /// calling [resetScreenBrightness]
  ///
  /// When [_channel.invokeMethod] fails to get current brightness, it throws
  /// [PlatformException] with code and message:
  ///
  /// Code: -9, Message: Brightness value returns null
  static Future<double> get initial async {
    final initialBrightness =
        await _channel.invokeMethod<double>(methodNameGetInitialBrightness);
    if (initialBrightness == null) {
      throw PlatformException(
          code: "-9", message: "Brightness value returns null");
    }

    if (!initialBrightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(initialBrightness, minBrightness, maxBrightness);
    }

    return initialBrightness;
  }

  /// Returns current screen brightness which is current screen brightness value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This parameter is useful for user to get screen brightness value after
  /// calling [setScreenBrightness]
  ///
  /// Calling this method after calling [resetScreenBrightness] may return wrong
  /// value in iOS because UIScreen.main.brightness returns old brightness value
  ///
  /// When [_channel.invokeMethod] fails to get current brightness, it throws
  /// [PlatformException] with code and message:
  ///
  /// Code: -9, Message: Brightness value returns null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  ///
  /// (Android only) Code: -11, Message: Could not found system setting screen
  /// brightness value
  /// Unexpected error when getting brightness from Setting using
  /// Settings.System.SCREEN_BRIGHTNESS
  static Future<double> get current async {
    final currentBrightness =
        await _channel.invokeMethod<double>(methodNameGetScreenBrightness);
    if (currentBrightness == null) {
      throw PlatformException(
          code: "-9", message: "Brightness value returns null");
    }

    if (!currentBrightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(currentBrightness, minBrightness, maxBrightness);
    }

    return currentBrightness;
  }

  /// Set screen brightness with double value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This method is useful for user to change screen brightness.
  ///
  /// When [_channel.invokeMethod] fails to get current brightness, it throws
  /// [PlatformException] with code and message:
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// Cannot read parameter from method channel map, or parameter is null
  ///
  /// Code: -1, Message: Unable to change screen brightness
  /// Compare changed value with set value fail
  ///
  /// Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  static Future<void> setScreenBrightness(double brightness) async {
    if (!brightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(brightness, minBrightness, maxBrightness);
    }

    await _channel.invokeMethod(
        methodNameSetScreenBrightness, {"brightness": brightness});
  }

  /// Reset screen brightness with (Android)-1 or (iOS)initial brightness value.
  ///
  /// This method is useful for user to reset screen brightness when user leave
  /// the page which has change the brightness value.
  ///
  /// When [_channel.invokeMethod] fails to get current brightness, it throws
  /// [PlatformException] with code and message:
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// Initial brightness in plugin is null
  ///
  /// Code: -1, Message: Unable to change screen brightness
  /// Compare changed value with set value fail
  ///
  /// Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  static Future<void> resetScreenBrightness() async {
    await _channel.invokeMethod(methodNameResetScreenBrightness);
  }
}
