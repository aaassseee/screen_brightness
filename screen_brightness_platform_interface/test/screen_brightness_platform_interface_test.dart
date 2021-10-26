import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_brightness_platform_interface/constant/brightness.dart';
import 'package:screen_brightness_platform_interface/constant/method_name.dart';
import 'package:screen_brightness_platform_interface/constant/plugin_channel.dart';
import 'package:screen_brightness_platform_interface/extension/num_extension.dart';
import 'package:screen_brightness_platform_interface/method_channel_screen_brightness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double systemBrightness = 0.5;
  const pluginEventChannelCurrentBrightnessChange =
      MethodChannel(pluginEventChannelCurrentBrightnessChangeName);

  group('num extension test', () {
    test('value in range', () async {
      expect(1.isInRange(minBrightness, maxBrightness), true);
    });

    test('value in range fail', () async {
      expect((-1).isInRange(minBrightness, maxBrightness), false);
    });
  });

  group('plugin test', () {
    late MethodChannelScreenBrightness methodChannelScreenBrightness;

    setUp(() {
      double changedBrightness = systemBrightness;

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

    test('get system brightess', () async {
      expect(await methodChannelScreenBrightness.system, systemBrightness);
    });

    test('get screen brightess', () async {
      expect(await methodChannelScreenBrightness.current, systemBrightness);
    });

    test('set screen brightess with valid number', () async {
      const targetBrightness = 0.1;
      await methodChannelScreenBrightness.setScreenBrightness(targetBrightness);
      expect(await methodChannelScreenBrightness.current, targetBrightness);
    });

    test('set screen brightess with invalid number', () async {
      Object? error;
      try {
        await methodChannelScreenBrightness.setScreenBrightness(2);
      } catch (e) {
        error = e;
      }

      expect(error, isNotNull);
    });

    test('reset screen brightess', () async {
      await methodChannelScreenBrightness.resetScreenBrightness();
      expect(await methodChannelScreenBrightness.system, systemBrightness);
    });

    test('on screen brightness changed', () async {
      final result =
          await methodChannelScreenBrightness.onCurrentBrightnessChanged.first;
      expect(result, 0.2);
    });
  });
}
