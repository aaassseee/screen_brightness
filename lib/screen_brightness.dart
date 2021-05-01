import 'dart:async';

import 'package:flutter/services.dart';

class ScreenBrightness {
  static const MethodChannel _channel =
      const MethodChannel('github.com/aaassseee/screen_brightness');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
