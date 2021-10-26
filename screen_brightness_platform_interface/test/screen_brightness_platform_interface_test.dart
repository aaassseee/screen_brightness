import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_brightness_platform_interface/constant/brightness.dart';
import 'package:screen_brightness_platform_interface/constant/method_name.dart';
import 'package:screen_brightness_platform_interface/constant/plugin_channel.dart';
import 'package:screen_brightness_platform_interface/extension/num_extension.dart';
import 'package:screen_brightness_platform_interface/method_channel_screen_brightness.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

class MockUnimplementedScreenBrightnessPlatform
    extends ScreenBrightnessPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('num extension test', () {
    test('value in range', () async {
      expect(1.isInRange(minBrightness, maxBrightness), true);
    });

    test('value in range fail', () async {
      expect((-1).isInRange(minBrightness, maxBrightness), false);
    });
  });

  group('plugin test', () {
    double? systemBrightness;
    double? changedBrightness;
    const pluginEventChannelCurrentBrightnessChange =
        MethodChannel(pluginEventChannelCurrentBrightnessChangeName);
    late MethodChannelScreenBrightness methodChannelScreenBrightness;

    setUp(() {
      systemBrightness = 0.5;
      changedBrightness = systemBrightness;
      methodChannelScreenBrightness = MethodChannelScreenBrightness();

      pluginMethodChannel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case methodNameGetSystemScreenBrightness:
            return systemBrightness;

          case methodNameGetScreenBrightness:
            return changedBrightness;

          case methodNameSetScreenBrightness:
            changedBrightness = methodCall.arguments['brightness'];
            return null;

          case methodNameResetScreenBrightness:
            changedBrightness = systemBrightness;
            return changedBrightness;
        }
      });

      pluginEventChannelCurrentBrightnessChange
          .setMockMethodCallHandler((call) async {
        switch (call.method) {
          case 'listen':
            await ServicesBinding.instance!.defaultBinaryMessenger
                .handlePlatformMessage(
              pluginEventChannelCurrentBrightnessChange.name,
              pluginEventChannelCurrentBrightnessChange.codec
                  .encodeSuccessEnvelope(0.2.toDouble()),
              (_) {},
            );
            break;

          case 'cancel':
          default:
            return null;
        }
      });
    });

    tearDown(() {
      pluginMethodChannel.setMockMethodCallHandler(null);
      pluginEventChannelCurrentBrightnessChange.setMockMethodCallHandler(null);
    });

    test('get system brightness', () async {
      expect(await methodChannelScreenBrightness.system, systemBrightness);
    });

    test('get system brightness with null', () async {
      systemBrightness = null;
      expect(() async => methodChannelScreenBrightness.system,
          throwsA(isA<PlatformException>()));
    });

    test('get system brightness with invalid number', () async {
      systemBrightness = -1;
      expect(() async => methodChannelScreenBrightness.system,
          throwsA(isA<RangeError>()));
    });

    test('get screen brightness', () async {
      expect(await methodChannelScreenBrightness.current, systemBrightness);
    });

    test('get screen brightness with null', () async {
      changedBrightness = null;
      expect(() async => methodChannelScreenBrightness.current,
          throwsA(isA<PlatformException>()));
    });

    test('get screen brightness with invalid number', () async {
      changedBrightness = -1;
      expect(() async => methodChannelScreenBrightness.current,
          throwsA(isA<RangeError>()));
    });

    test('set screen brightness', () async {
      const targetBrightness = 0.1;
      await methodChannelScreenBrightness.setScreenBrightness(targetBrightness);
      expect(await methodChannelScreenBrightness.current, targetBrightness);
    });

    test('set screen brightness with invalid number', () async {
      Object? error;
      try {
        await methodChannelScreenBrightness.setScreenBrightness(2);
      } catch (e) {
        error = e;
      }

      expect(error, isA<RangeError>());
    });

    test('reset screen brightness', () async {
      await methodChannelScreenBrightness.resetScreenBrightness();
      expect(await methodChannelScreenBrightness.system, systemBrightness);
    });

    test('on screen brightness changed', () async {
      final result =
          await methodChannelScreenBrightness.onCurrentBrightnessChanged.first;
      expect(result, 0.2);
    });
  });

  group('mock unimplemented platform interface test', () {
    final platform = MockUnimplementedScreenBrightnessPlatform();
    test('unimplemented system brightness', () {
      expect(() => platform.system, throwsUnimplementedError);
    });

    test('unimplemented current brightness', () {
      expect(() => platform.current, throwsUnimplementedError);
    });

    test('unimplemented set screen brightness', () {
      expect(() => platform.setScreenBrightness(0.2), throwsUnimplementedError);
    });

    test('unimplemented reset screen brightness', () {
      expect(() => platform.resetScreenBrightness(), throwsUnimplementedError);
    });

    test('unimplemented onCurrentBrightnessChanged stream', () {
      expect(
          () => platform.onCurrentBrightnessChanged, throwsUnimplementedError);
    });
  });
}
