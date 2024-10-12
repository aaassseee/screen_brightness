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

class FakeMethodChannelScreenBrightness extends MethodChannelScreenBrightness {}

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
    double? applicationBrightness;
    bool isAutoReset = true;
    bool isAnimate = true;
    late MethodChannelScreenBrightness methodChannelScreenBrightness;
    const pluginEventChannelApplicationBrightnessChanged =
        MethodChannel(pluginEventChannelApplicationBrightnessChangedName);
    const pluginEventChannelSystemBrightnessChanged =
        MethodChannel(pluginEventChannelSystemBrightnessChangedName);

    setUp(() {
      systemBrightness = 0.5;
      methodChannelScreenBrightness = MethodChannelScreenBrightness();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pluginMethodChannel, (call) async {
        switch (call.method) {
          case methodNameGetSystemScreenBrightness:
            return systemBrightness;

          case methodNameSetSystemScreenBrightness:
            systemBrightness = call.arguments['brightness'];

          case methodNameGetApplicationScreenBrightness:
            return applicationBrightness ?? systemBrightness;

          case methodNameSetApplicationScreenBrightness:
            applicationBrightness = call.arguments['brightness'];
            return null;

          case methodNameResetApplicationScreenBrightness:
            applicationBrightness = null;
            return null;

          case methodNameHasApplicationScreenBrightnessChanged:
            return applicationBrightness != null;

          case methodNameIsAutoReset:
            return isAutoReset;

          case methodNameSetAutoReset:
            isAutoReset = call.arguments['isAutoReset'];
            return null;

          case methodNameIsAnimate:
            return isAnimate;

          case methodNameSetAnimate:
            isAnimate = call.arguments['isAnimate'];
        }

        return null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              pluginEventChannelApplicationBrightnessChanged, (call) async {
        switch (call.method) {
          case 'listen':
            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
              pluginEventChannelApplicationBrightnessChanged.name,
              pluginEventChannelApplicationBrightnessChanged.codec
                  .encodeSuccessEnvelope(0.2.toDouble()),
              (_) {},
            );
            break;

          case 'cancel':
          default:
            return null;
        }

        return null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pluginEventChannelSystemBrightnessChanged,
              (call) async {
        switch (call.method) {
          case 'listen':
            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
              pluginEventChannelSystemBrightnessChanged.name,
              pluginEventChannelSystemBrightnessChanged.codec
                  .encodeSuccessEnvelope(0.1.toDouble()),
              (_) {},
            );
            break;

          case 'cancel':
          default:
            return null;
        }

        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pluginMethodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              pluginEventChannelApplicationBrightnessChanged, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              pluginEventChannelSystemBrightnessChanged, null);
    });

    test('get platform instance', () {
      expect(ScreenBrightnessPlatform.instance, isNotNull);
    });

    test('set platform instance', () {
      ScreenBrightnessPlatform.instance = FakeMethodChannelScreenBrightness();
      expect(ScreenBrightnessPlatform.instance,
          isA<FakeMethodChannelScreenBrightness>());
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

    test('set system screen brightness', () async {
      const targetBrightness = 0.1;
      await methodChannelScreenBrightness
          .setSystemScreenBrightness(targetBrightness);
      expect(await methodChannelScreenBrightness.system, targetBrightness);
    });

    test('set system screen brightness with invalid number', () async {
      Object? error;
      try {
        await methodChannelScreenBrightness.setSystemScreenBrightness(2);
      } catch (e) {
        error = e;
      }

      expect(error, isA<RangeError>());
    });

    test('on system screen brightness changed', () async {
      final result = await methodChannelScreenBrightness
          .onSystemScreenBrightnessChanged.first;
      expect(result, 0.1);
    });

    test('get application screen brightness', () async {
      expect(await methodChannelScreenBrightness.application, systemBrightness);
    });

    test('get application screen brightness with null', () async {
      systemBrightness = null;
      expect(() async => methodChannelScreenBrightness.application,
          throwsA(isA<PlatformException>()));
    });

    test('get application screen brightness with invalid number', () async {
      applicationBrightness = -1;
      expect(() async => methodChannelScreenBrightness.application,
          throwsA(isA<RangeError>()));
    });

    test('set application screen brightness', () async {
      const targetBrightness = 0.1;
      await methodChannelScreenBrightness
          .setApplicationScreenBrightness(targetBrightness);
      expect(await methodChannelScreenBrightness.application, targetBrightness);
    });

    test('set application screen brightness with invalid number', () async {
      Object? error;
      try {
        await methodChannelScreenBrightness.setApplicationScreenBrightness(2);
      } catch (e) {
        error = e;
      }

      expect(error, isA<RangeError>());
    });

    test('reset application screen brightness', () async {
      await methodChannelScreenBrightness.resetApplicationScreenBrightness();
      expect(await methodChannelScreenBrightness.system, systemBrightness);
    });

    test('on application screen brightness changed', () async {
      final result = await methodChannelScreenBrightness
          .onApplicationBrightnessChanged.first;
      expect(result, 0.2);
    });

    test('on application screen brightness changed', () async {
      final result = await methodChannelScreenBrightness
          .onApplicationBrightnessChanged.first;
      expect(result, 0.2);
    });

    test('has application screen brightness changed', () async {
      expect(
          await methodChannelScreenBrightness
              .hasApplicationScreenBrightnessChanged,
          false);

      await methodChannelScreenBrightness.setApplicationScreenBrightness(0.1);
      expect(
          await methodChannelScreenBrightness
              .hasApplicationScreenBrightnessChanged,
          true);

      await methodChannelScreenBrightness.resetApplicationScreenBrightness();
      expect(
          await methodChannelScreenBrightness
              .hasApplicationScreenBrightnessChanged,
          false);
    });

    test('is auto reset', () async {
      expect(await methodChannelScreenBrightness.isAutoReset, true);

      await methodChannelScreenBrightness.setAutoReset(false);
      expect(await methodChannelScreenBrightness.isAutoReset, false);

      await methodChannelScreenBrightness.setAutoReset(true);
      expect(await methodChannelScreenBrightness.isAutoReset, true);
    });

    test('is animate', () async {
      expect(await methodChannelScreenBrightness.isAnimate, true);

      await methodChannelScreenBrightness.setAnimate(false);
      expect(await methodChannelScreenBrightness.isAnimate, false);

      await methodChannelScreenBrightness.setAnimate(true);
      expect(await methodChannelScreenBrightness.isAnimate, true);
    });
  });

  group('mock unimplemented platform interface test', () {
    final platform = MockUnimplementedScreenBrightnessPlatform();

    test('unimplemented system brightness', () {
      expect(() => platform.system, throwsUnimplementedError);
    });

    test('unimplemented set system screen brightness', () {
      expect(() => platform.setSystemScreenBrightness(0.2),
          throwsUnimplementedError);
    });

    test('unimplemented onSystemScreenBrightnessChanged stream', () {
      expect(() => platform.onSystemScreenBrightnessChanged,
          throwsUnimplementedError);
    });

    test('unimplemented application current brightness', () {
      expect(() => platform.application, throwsUnimplementedError);
    });

    test('unimplemented set application screen brightness', () {
      expect(() => platform.setApplicationScreenBrightness(0.2),
          throwsUnimplementedError);
    });

    test('unimplemented reset application screen brightness', () {
      expect(() => platform.resetApplicationScreenBrightness(),
          throwsUnimplementedError);
    });

    test('unimplemented onApplicationScreenBrightnessChanged stream', () {
      expect(() => platform.onApplicationScreenBrightnessChanged,
          throwsUnimplementedError);
    });

    test('unimplemented has application screen brightness changed', () {
      expect(() => platform.hasApplicationScreenBrightnessChanged,
          throwsUnimplementedError);
    });

    test('unimplemented is auto reset', () {
      expect(() => platform.isAutoReset, throwsUnimplementedError);
    });

    test('unimplemented set auto reset', () {
      expect(() => platform.setAutoReset(true), throwsUnimplementedError);
    });

    test('unimplemented is animate', () {
      expect(() => platform.isAnimate, throwsUnimplementedError);
    });

    test('unimplemented set animate', () {
      expect(() => platform.setAnimate(true), throwsUnimplementedError);
    });
  });
}
