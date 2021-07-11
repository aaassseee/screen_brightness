import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screen_brightness/src/constant/brightness.dart';
import 'package:screen_brightness/src/constant/method_name.dart';
import 'package:screen_brightness/src/constant/plugin.dart';
import 'package:screen_brightness/src/extension/num_extension.dart';

void main() {
  const double initialBrightness = 0.5;

  const MethodChannel channel = MethodChannel(pluginMethodChannelName);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    double changedBrightness = initialBrightness;

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case methodNameGetInitialBrightness:
          return initialBrightness;

        case methodNameGetScreenBrightness:
          return changedBrightness;

        case methodNameSetScreenBrightness:
          changedBrightness = methodCall.arguments['brightness'];
          return null;

        case methodNameResetScreenBrightness:
          changedBrightness = initialBrightness;
          return changedBrightness;
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('num extension test', () {
    test('value in range', () async {
      expect(1.isInRange(minBrightness, maxBrightness), true);
    });

    test('value in range fail', () async {
      expect((-1).isInRange(minBrightness, maxBrightness), false);
    });
  });

  group('plugin test', () {
    test('get initial brightess', () async {
      expect(await ScreenBrightness.initial, initialBrightness);
    });

    test('get screen brightess', () async {
      expect(await ScreenBrightness.current, initialBrightness);
    });

    test('set screen brightess with valid number', () async {
      const targetBrightness = 0.1;
      await ScreenBrightness.setScreenBrightness(targetBrightness);
      expect(await ScreenBrightness.current, targetBrightness);
    });

    test('set screen brightess with invalid number', () async {
      Object? error;
      try {
        await ScreenBrightness.setScreenBrightness(2);
      } catch (e) {
        error = e;
      }

      expect(error, isNotNull);
    });

    test('reset screen brightess', () async {
      await ScreenBrightness.resetScreenBrightness();
      expect(await ScreenBrightness.initial, initialBrightness);
    });
  });
}
