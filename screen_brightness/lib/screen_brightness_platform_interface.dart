import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'screen_brightness_method_channel.dart';

abstract class ScreenBrightnessPlatform extends PlatformInterface {
  /// Constructs a ScreenBrightnessPlatform.
  ScreenBrightnessPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScreenBrightnessPlatform _instance = MethodChannelScreenBrightness();

  /// The default instance of [ScreenBrightnessPlatform] to use.
  ///
  /// Defaults to [MethodChannelScreenBrightness].
  static ScreenBrightnessPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScreenBrightnessPlatform] when
  /// they register themselves.
  static set instance(ScreenBrightnessPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
