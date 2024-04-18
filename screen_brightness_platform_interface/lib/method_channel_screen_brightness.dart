import 'package:flutter/services.dart';
import 'package:screen_brightness_platform_interface/extension/num_extension.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

import 'constant/brightness.dart';
import 'constant/method_name.dart';
import 'constant/plugin_channel.dart';

/// Implementation of screen brightness platform interface
class MethodChannelScreenBrightness extends ScreenBrightnessPlatform {
  /// Private stream which is listened to event channel for preventing
  Stream<double>? _onCurrentBrightnessChanged;

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
  /// Code: -9, Message: value returns null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  ///
  /// (Android only) (macOS only) Code: -11, Message: Could not found system
  /// setting screen brightness value
  /// Unexpected error when getting brightness from Setting using
  /// (Android) Settings.System.SCREEN_BRIGHTNESS
  @override
  Future<double> get current async {
    final currentBrightness = await pluginMethodChannel
        .invokeMethod<double>(methodNameGetScreenBrightness);
    if (currentBrightness == null) {
      throw PlatformException(code: "-9", message: "value returns null");
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
  /// Code: -1, Message: Unable to change screen brightness
  /// Failed to set brightness
  ///
  /// Code: -2, Message: Unexpected error on null brightness
  /// Cannot read parameter from method channel map, or parameter is null
  ///
  /// (Android only) Code: -10, Message: Unexpected error on activity binding
  /// Unexpected error when getting activity, activity may be null
  @override
  Future<void> setScreenBrightness(double brightness) async {
    if (!brightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(brightness, minBrightness, maxBrightness);
    }

    await pluginMethodChannel.invokeMethod(
        methodNameSetScreenBrightness, {"brightness": brightness});
  }

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
  @override
  Future<void> resetScreenBrightness() async {
    await pluginMethodChannel.invokeMethod(methodNameResetScreenBrightness);
  }

  /// Returns stream with screen brightness changes including
  /// [ScreenBrightness.setScreenBrightness],
  /// [ScreenBrightness.resetScreenBrightness], system control center or system
  /// setting.
  ///
  /// This stream is useful for user to listen to brightness changes.
  @override
  Stream<double> get onCurrentBrightnessChanged {
    _onCurrentBrightnessChanged ??= pluginEventChannelCurrentBrightnessChange
        .receiveBroadcastStream()
        .cast<double>();
    return _onCurrentBrightnessChanged!;
  }

  /// Returns boolean to identify brightness has changed with this plugin.
  ///
  /// e.g
  /// [ScreenBrightness.setScreenBrightness] will make this true
  /// [ScreenBrightness.resetScreenBrightness] will make this false
  @override
  Future<bool> get hasChanged async {
    return await pluginMethodChannel.invokeMethod<bool>(methodNameHasChanged) ??
        false;
  }

  /// Returns boolean to identify will auto reset when application lifecycle
  /// changed.
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
  /// This method is useful for user change weather this plugin should auto reset
  /// brightness when application lifecycle changed.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<void> setAutoReset(bool isAutoReset) async {
    await pluginMethodChannel
        .invokeMethod(methodNameSetAutoReset, {"isAutoReset": isAutoReset});
  }

  /// Returns boolean to identify will animate brightness transition
  ///
  /// This parameter is useful for user to determinate will there be animate
  /// transition.
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<bool> get isAnimate async {
    return await pluginMethodChannel.invokeMethod<bool>(methodNameIsAnimate) ??
        true;
  }

  /// Set animate when brightness transition
  ///
  /// This method is useful for user change weather this plugin should animate
  /// when brightness transition
  ///
  /// (iOS only) implemented in iOS only because only iOS native side does not
  /// having reset method.
  @override
  Future<void> setAnimate(bool isAnimate) async {
    await pluginMethodChannel
        .invokeMethod(methodNameSetAnimate, {"isAnimate": isAnimate});
  }
}
