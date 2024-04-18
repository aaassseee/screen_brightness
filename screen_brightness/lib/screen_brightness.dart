import 'package:flutter/services.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

/// Plugin for changing screen brightness
class ScreenBrightness {
  /// ScreenBrightness designed as static method collection class
  /// So constructor should not provide to user.
  ScreenBrightness._();

  /// Plugin singleton
  static final ScreenBrightness _instance = ScreenBrightness._();

  /// Returns a singleton instance of [ScreenBrightness].
  ///
  /// [ScreenBrightness] is designed to work as a singleton.
  factory ScreenBrightness() => instance;

  /// Returns a singleton instance of [ScreenBrightness].
  ///
  /// [ScreenBrightness] is designed to work as a singleton.
  static ScreenBrightness get instance => _instance;

  /// Private platform prevent direct access or overriding
  static ScreenBrightnessPlatform get _platform {
    return ScreenBrightnessPlatform.instance;
  }

  /// Returns system screen brightness which is set when application is started.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This parameter is useful for user to get screen brightness value after
  /// calling [resetScreenBrightness]
  ///
  /// Platform difference:
  /// (macOS): return initial brightness
  ///
  /// When [_channel.invokeMethod] fails to get current brightness, it throws
  /// [PlatformException] with code and message:
  ///
  /// Code: -9, Message: Brightness value returns null
  Future<double> get system => _platform.system;

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
  /// (Android only) (macOS only) Code: -11, Message: Could not found system
  /// setting screen brightness value
  /// Unexpected error when getting brightness from Setting using
  /// (Android) Settings.System.SCREEN_BRIGHTNESS
  Future<double> get current => _platform.current;

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
  /// Code: -1, Message: Unable to change screen brightness
  /// Failed to set brightness
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// Cannot read parameter from method channel map, or parameter is null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  Future<void> setScreenBrightness(double brightness) =>
      _platform.setScreenBrightness(brightness);

  /// Reset screen brightness with (Android)-1 or (iOS)system brightness value.
  ///
  /// This method is useful for user to reset screen brightness when user leave
  /// the page which has change the brightness value.
  ///
  /// When [_channel.invokeMethod] fails to get current brightness, it throws
  /// [PlatformException] with code and message:
  ///
  /// Code: -1, Message: Unable to change screen brightness
  /// Failed to reset brightness
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// System brightness in plugin is null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  Future<void> resetScreenBrightness() => _platform.resetScreenBrightness();

  /// Returns stream with screen brightness changes including
  /// [ScreenBrightness.setScreenBrightness],
  /// [ScreenBrightness.resetScreenBrightness], system control center or system
  /// setting.
  ///
  /// This stream is useful for user to listen to brightness changes.
  Stream<double> get onCurrentBrightnessChanged =>
      _platform.onCurrentBrightnessChanged;

  /// Returns boolean to identify brightness has changed with this plugin.
  ///
  /// e.g
  /// [ScreenBrightness.setScreenBrightness] will make this true
  /// [ScreenBrightness.resetScreenBrightness] will make this false
  Future<bool> get hasChanged => _platform.hasChanged;

  /// Returns boolean to identify will auto reset when application lifecycle
  /// changed.
  ///
  /// This parameter is useful for user to determinate current state of auto reset.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  Future<bool> get isAutoReset => _platform.isAutoReset;

  /// Returns boolean for disable auto reset when application lifecycle changed
  ///
  /// This method is useful for user change weather this plugin should auto reset
  /// brightness when application lifecycle changed.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  Future<void> setAutoReset(bool isAutoReset) =>
      _platform.setAutoReset(isAutoReset);

  /// Returns boolean to identify will animate brightness transition
  ///
  /// This parameter is useful for user to determinate will there be animate
  /// transition.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  Future<bool> get isAnimate => _platform.isAnimate;

  /// Set animate when brightness transition
  ///
  /// This method is useful for user change weather this plugin should animate
  /// when brightness transition
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  Future<void> setAnimate(bool isAnimate) => _platform.setAnimate(isAnimate);
}
