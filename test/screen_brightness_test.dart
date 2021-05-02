import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screen_brightness/src/constant/brightness.dart';
import 'package:screen_brightness/src/constant/method_name.dart';
import 'package:screen_brightness/src/constant/plugin.dart';
import 'package:screen_brightness/src/extension/num_extension.dart';

void main() {
  const MethodChannel channel = MethodChannel(pluginMethodChannelName);

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case methodNameGetScreenBrightness:
          return 0.0;
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
    test('get screen brightess', () async {
      expect(await ScreenBrightness.current, 0.0);
    });

    test('set screen brightess with valid number', () async {
      await ScreenBrightness.setScreenBrightness(0.1);
    });

    test('set screen brightess with invalid number', () async {
      Object? error;
      try {
        await ScreenBrightness.setScreenBrightness(2);
      } catch (e) {
        print(e);
        error = e;
      }

      expect(error, isNotNull);
    });

    test('reset screen brightess', () async {
      await ScreenBrightness.resetScreenBrightness();
    });
  });
}
