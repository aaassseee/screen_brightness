import 'package:flutter/services.dart';
import 'package:screen_brightness/src/constant/brightness.dart';
import 'package:screen_brightness/src/constant/method_name.dart';
import 'package:screen_brightness/src/constant/plugin.dart';
import 'package:screen_brightness/src/extension/num_extension.dart';

class ScreenBrightness {
  static const MethodChannel _channel =
      const MethodChannel(pluginMethodChannelName);

  static Future<double> get current async {
    final double currentBrightness =
        await _channel.invokeMethod(methodNameGetScreenBrightness);
    if (!currentBrightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(currentBrightness, minBrightness, maxBrightness);
    }

    return currentBrightness;
  }

  static Future<void> setScreenBrightness(double brightness) async {
    if (!brightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(brightness, minBrightness, maxBrightness);
    }
    await _channel.invokeMethod<bool>(
        methodNameSetScreenBrightness, {"brightness": brightness});
  }

  static Future<void> resetScreenBrightness() async {
    await _channel.invokeMethod<bool>(methodNameResetScreenBrightness);
  }
}
