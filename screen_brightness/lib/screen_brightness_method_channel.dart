import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screen_brightness_platform_interface.dart';

/// An implementation of [ScreenBrightnessPlatform] that uses method channels.
class MethodChannelScreenBrightness extends ScreenBrightnessPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_brightness');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
