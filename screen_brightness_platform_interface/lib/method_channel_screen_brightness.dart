import 'package:flutter/services.dart';
import 'package:screen_brightness_platform_interface/extension/num_extension.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

import 'constant/brightness.dart';
import 'constant/method_name.dart';
import 'constant/plugin_channel.dart';

/// Implementation of screen brightness platform interface
class MethodChannelScreenBrightness extends ScreenBrightnessPlatform {
  /// Private application screen brightness changed stream which is listened to
  /// event channel for preventing creating new stream.
  Stream<double>? _onApplicationScreenBrightnessChanged;

  /// Private system screen brightness changed stream which is listened to event
  /// channel for preventing creating new stream.
  Stream<double>? _onSystemScreenBrightnessChanged;

  /// Returns system screen brightness.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This parameter is useful for user to get system screen brightness value
  /// after calling [setSystemScreenBrightness]
  ///
  /// This parameter is useful for user to get system screen brightness value
  /// after calling [resetApplicationScreenBrightness]
  ///
  /// Platform difference:
  /// (macOS)(Windows): return initial brightness
  ///
  /// When [_channel.invokeMethod] fails to get system screen brightness, it
  /// throws [PlatformException] with code and message:
  ///
  /// Code: -9, Message: value returns null
  @override
  Future<double> get system async {
    final systemBrightness = await pluginMethodChannel
        .invokeMethod<double>(methodNameGetSystemScreenBrightness);
    if (systemBrightness == null) {
      throw PlatformException(code: "-9", message: "value returns null");
    }

    if (!systemBrightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(systemBrightness, minBrightness, maxBrightness);
    }

    return systemBrightness;
  }

  /// Set system screen brightness with double value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This method is useful for user to change system screen brightness.
  ///
  /// When [_channel.invokeMethod] fails to set system screen brightness, it
  /// throws [PlatformException] with code and message:
  ///
  /// Code: -1, Message: Unable to change system screen brightness
  /// Failed to set system brightness
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// Cannot read parameter from method channel map, or parameter is null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  @override
  Future<void> setSystemScreenBrightness(double brightness) async {
    if (!brightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(brightness, minBrightness, maxBrightness);
    }

    await pluginMethodChannel.invokeMethod(
        methodNameSetSystemScreenBrightness, {"brightness": brightness});
  }

  /// Returns stream with system screen brightness changes including
  /// [ScreenBrightness.setSystemScreenBrightness], system control center or
  /// system setting.
  ///
  /// This stream is useful for user to listen to system screen brightness
  /// changes.
  @override
  Stream<double> get onSystemScreenBrightnessChanged {
    _onSystemScreenBrightnessChanged ??=
        pluginEventChannelSystemBrightnessChanged
            .receiveBroadcastStream()
            .cast<double>();
    return _onSystemScreenBrightnessChanged!;
  }

  /// Returns application screen brightness value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This parameter is useful for user to get application screen brightness
  /// value after calling [setApplicationScreenBrightness]
  ///
  /// Calling this method after calling [resetApplicationScreenBrightness] may return wrong
  /// value in iOS because UIScreen.main.brightness returns old brightness value
  ///
  /// When [_channel.invokeMethod] fails to get application screen brightness,
  /// it throws [PlatformException] with code and message:
  ///
  /// Code: -9, Message: value returns null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  ///
  /// (Android only) (macOS only) Code: -11, Message: Could not found system
  /// screen brightness value
  /// Unexpected error when getting brightness from Setting using
  /// (Android) Settings.System.SCREEN_BRIGHTNESS
  @override
  Future<double> get application async {
    final currentBrightness = await pluginMethodChannel
        .invokeMethod<double>(methodNameGetApplicationScreenBrightness);
    if (currentBrightness == null) {
      throw PlatformException(code: "-9", message: "value returns null");
    }

    if (!currentBrightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(currentBrightness, minBrightness, maxBrightness);
    }

    return currentBrightness;
  }

  /// Set application screen brightness with double value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This method is useful for user to change application screen brightness.
  ///
  /// When [_channel.invokeMethod] fails to set application screen brightness,
  /// it throws [PlatformException] with code and message:
  ///
  /// Code: -1, Message: Unable to change application screen brightness
  /// Failed to set brightness
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// Cannot read parameter from method channel map, or parameter is null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  @override
  Future<void> setApplicationScreenBrightness(double brightness) async {
    if (!brightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(brightness, minBrightness, maxBrightness);
    }

    await pluginMethodChannel.invokeMethod(
        methodNameSetApplicationScreenBrightness, {"brightness": brightness});
  }

  /// Reset application screen brightness with (Android) -1 or (iOS)system
  /// brightness value.
  ///
  /// This method is useful for user to reset application screen brightness
  /// when user leave the page which has change the application screen
  /// brightness value.
  ///
  /// When [_channel.invokeMethod] fails to get application screen brightness,
  /// it throws [PlatformException] with code and message:
  ///
  /// Code: -1, Message: Unable to reset application screen brightness
  /// Failed to reset application screen brightness
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// System brightness in plugin is null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  @override
  Future<void> resetApplicationScreenBrightness() async {
    await pluginMethodChannel
        .invokeMethod(methodNameResetApplicationScreenBrightness);
  }

  /// Old API on [onApplicationScreenBrightnessChanged]
  Stream<double> get onApplicationBrightnessChanged =>
      onApplicationScreenBrightnessChanged;

  /// Returns stream with application screen brightness changes including
  /// [ScreenBrightness.setApplicationScreenBrightness],
  /// [ScreenBrightness.resetApplicationScreenBrightness], system control center or system
  /// setting.
  ///
  /// This stream is useful for user to listen to brightness changes.
  @override
  Stream<double> get onApplicationScreenBrightnessChanged {
    _onApplicationScreenBrightnessChanged ??=
        pluginEventChannelApplicationBrightnessChanged
            .receiveBroadcastStream()
            .cast<double>();
    return _onApplicationScreenBrightnessChanged!;
  }

  /// Returns boolean to identify application screen brightness has changed by
  /// this plugin.
  ///
  /// e.g
  /// [ScreenBrightness.setApplicationScreenBrightness] will make this true
  /// [ScreenBrightness.resetApplicationScreenBrightness] will make this false
  @override
  Future<bool> get hasApplicationScreenBrightnessChanged async {
    return await pluginMethodChannel.invokeMethod<bool>(
            methodNameHasApplicationScreenBrightnessChanged) ??
        false;
  }

  /// Returns boolean to identify will auto reset to system brightness when
  /// application lifecycle changed.
  ///
  /// This parameter is useful for user to determinate current state of auto reset.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<bool> get isAutoReset async {
    return await pluginMethodChannel
            .invokeMethod<bool>(methodNameIsAutoReset) ??
        true;
  }

  /// Set auto reset when application lifecycle changed
  ///
  /// This method is useful for user change whether this plugin should auto reset
  /// to system brightness when application lifecycle changed.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<void> setAutoReset(bool isAutoReset) async {
    await pluginMethodChannel
        .invokeMethod(methodNameSetAutoReset, {"isAutoReset": isAutoReset});
  }

  /// Returns boolean to identify will animate when application screen brightness
  /// changed.
  ///
  /// This parameter is useful for user to determinate will there be animation
  /// transition when application screen brightness changed.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<bool> get isAnimate async {
    return await pluginMethodChannel.invokeMethod<bool>(methodNameIsAnimate) ??
        true;
  }

  /// Set will animate when application screen brightness changed.
  ///
  /// This method is useful for user change whether this plugin should animate
  /// when application screen brightness changed.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<void> setAnimate(bool isAnimate) async {
    await pluginMethodChannel
        .invokeMethod(methodNameSetAnimate, {"isAnimate": isAnimate});
  }
}
