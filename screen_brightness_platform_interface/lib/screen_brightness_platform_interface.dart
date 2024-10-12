// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_screen_brightness.dart';

/// Screen brightness platform interface which is implemented with
/// [federated plugins](flutter.dev/go/federated-plugins)
abstract class ScreenBrightnessPlatform extends PlatformInterface {
  /// Default constructor for [ScreenBrightnessPlatform]
  ScreenBrightnessPlatform() : super(token: _token);

  /// The token which [PlatformInterface.verifyToken] needs to be verify
  static final Object _token = Object();

  /// Private instance which will be only create once
  static ScreenBrightnessPlatform _instance = MethodChannelScreenBrightness();

  /// The default instance of [ScreenBrightnessPlatform] to use.
  ///
  /// Defaults to [MethodChannelScreenBrightness].
  static ScreenBrightnessPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ScreenBrightnessPlatform] when they register themselves.
  static set instance(ScreenBrightnessPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

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
  Future<double> get system async {
    throw UnimplementedError('system brightness has not been implemented.');
  }

  /// Set system screen brightness with double value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This method is useful for user to change system screen brightness.
  Future<void> setSystemScreenBrightness(double brightness) async {
    throw UnimplementedError(
        'setSystemScreenBrightness(brightness) has not been implemented.');
  }

  /// Returns stream with system screen brightness changes including
  /// [ScreenBrightness.setSystemScreenBrightness], system control center or
  /// system setting.
  ///
  /// This stream is useful for user to listen to system screen brightness
  /// changes.
  Stream<double> get onSystemScreenBrightnessChanged {
    throw UnimplementedError(
        'onApplicationBrightnessChanged has not been implemented.');
  }

  /// Returns application screen brightness value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This parameter is useful for user to get application screen brightness
  /// value after calling [setApplicationScreenBrightness]
  Future<double> get application async {
    throw UnimplementedError(
        'application brightness has not been implemented.');
  }

  /// Set application screen brightness with double value.
  ///
  /// The value should be within 0.0 - 1.0. Otherwise, [RangeError.range] will
  /// be throw.
  ///
  /// This method is useful for user to change application screen brightness.
  Future<void> setApplicationScreenBrightness(double brightness) async {
    throw UnimplementedError(
        'setApplicationScreenBrightness(brightness) has not been implemented.');
  }

  /// Reset application screen brightness with (Android) -1 or (iOS)system
  /// brightness value.
  ///
  /// This method is useful for user to reset application screen brightness
  /// when user leave the page which has change the brightness value.
  Future<void> resetApplicationScreenBrightness() async {
    throw UnimplementedError(
        'resetApplicationScreenBrightness() has not been implemented.');
  }

  /// Returns stream with application screen brightness changes including
  /// [ScreenBrightness.setApplicationScreenBrightness],
  /// [ScreenBrightness.resetApplicationScreenBrightness], system control center or system
  /// setting.
  ///
  /// This stream is useful for user to listen to brightness changes.
  Stream<double> get onApplicationScreenBrightnessChanged {
    throw UnimplementedError(
        'onApplicationBrightnessChanged has not been implemented.');
  }

  /// Returns boolean to identify application screen brightness has changed by
  /// this plugin.
  ///
  /// e.g
  /// [ScreenBrightness.setApplicationScreenBrightness] will make this true
  /// [ScreenBrightness.resetApplicationScreenBrightness] will make this false
  Future<bool> get hasApplicationScreenBrightnessChanged {
    throw UnimplementedError(
        'hasApplicationScreenBrightnessChanged has not been implemented.');
  }

  /// Returns boolean to identify will auto reset to system brightness when
  /// application lifecycle changed.
  ///
  /// This parameter is useful for user to determinate current state of auto reset.
  Future<bool> get isAutoReset async {
    throw UnimplementedError('isAutoReset has not been implemented.');
  }

  /// Set auto reset when application lifecycle changed
  ///
  /// This method is useful for user change whether this plugin should auto reset
  /// to system brightness when application lifecycle changed.
  Future<void> setAutoReset(bool isAutoReset) async {
    throw UnimplementedError('setAutoReset has not been implemented.');
  }

  /// Returns boolean to identify will animate when application screen brightness
  /// change.
  ///
  /// This parameter is useful for user to determinate will there be animation
  /// transition when application screen brightness changed.
  Future<bool> get isAnimate async {
    throw UnimplementedError('isAnimate has not been implemented.');
  }

  /// Set will animate when application screen brightness changed.
  ///
  /// This method is useful for user change whether this plugin should animate
  /// when application screen brightness changed.
  Future<void> setAnimate(bool isAnimate) async {
    throw UnimplementedError('setAnimate has not been implemented.');
  }
}
