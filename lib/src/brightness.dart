import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
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
    if (currentBrightness.isInRange(minBrightness, maxBrightness)) {
      throw RangeError.range(currentBrightness, minBrightness, maxBrightness);
    }

    return currentBrightness;
  }

  static Future<bool> setScreenBrightness(num brightness) async {
    assert(brightness.isInRange(minBrightness, maxBrightness));
    final isBrigntnessSet =
        await _channel.invokeMethod<bool>(methodNameSetScreenBrightness);
    if (isBrigntnessSet == null) {
      throw UnexpectedError();
    }

    return isBrigntnessSet;
  }

  static Future<bool> resetScreenBrightness() async {
    final isBrigntnessReset =
        await _channel.invokeMethod<bool>(methodNameResetScreenBrightness);
    if (isBrigntnessReset == null) {
      throw UnexpectedError();
    }

    return isBrigntnessReset;
  }
}
