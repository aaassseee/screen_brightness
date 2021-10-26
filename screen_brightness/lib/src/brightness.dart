import 'package:flutter/services.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

/// Plugin for changing screen brightness
class ScreenBrightness {
  /// ScreenBrightness designed as static method collection class
  /// So constructor should not provide to user.
  ScreenBrightness._();

  /// PLugin singletone
  static ScreenBrightness? _singleton;

  /// Constructs a singleton instance of [Battery].
  ///
  /// [Battery] is designed to work as a singleton.
  ///
  /// When a second instance is created, the first instance will not be able to listen to the
  /// EventChannel because it is overridden. Forcing the class to be a singleton class can prevent
  /// misuse of creating a second instance from a programmer.
  factory ScreenBrightness() {
    _singleton ??= ScreenBrightness._();
    return _singleton!;
  }

  /// Private platform prevent direct access or overidding
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
  /// (Android only) Code: -11, Message: Could not found system setting screen
  /// brightness value
  /// Unexpected error when getting brightness from Setting using
  /// Settings.System.SCREEN_BRIGHTNESS
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
  /// Code: -2, Message: Unexpected error on null brightness
  /// Cannot read parameter from method channel map, or parameter is null
  ///
  /// Code: -1, Message: Unable to change screen brightness
  /// Compare changed value with set value fail
  ///
  /// Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  Future<void> setScreenBrightness(double brightness) =>
      _platform.setScreenBrightness(brightness);

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
  Future<void> resetScreenBrightness() => _platform.resetScreenBrightness();

  /// A stream return with screen brightness changes including
  /// [ScreenBrightness.setScreenBrightness],
  /// [ScreenBrightness.resetScreenBrightness], system control center or system
  /// setting.
  ///
  /// This stream is useful for user to listen to brightness changes.
  Stream<double> get onCurrentBrightnessChanged =>
      _platform.onCurrentBrightnessChanged;
}
