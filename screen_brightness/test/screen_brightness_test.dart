import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

const double systemBrightness = 0.5;

late StreamController<double> controller;

class MockScreenBrightnessPlatform
    with MockPlatformInterfaceMixin
    implements ScreenBrightnessPlatform {
  double _currentBrightness = systemBrightness;
  double? _changedBrightness;

  @override
  Future<double> get system => Future.value(systemBrightness);

  @override
  Future<double> get current => Future.value(_currentBrightness);

  @override
  Future<void> setScreenBrightness(double brightness) async {
    _currentBrightness = brightness;
    _changedBrightness = brightness;
  }

  @override
  Future<void> resetScreenBrightness() async {
    _currentBrightness = systemBrightness;
    _changedBrightness = null;
  }

  @override
  Stream<double> get onCurrentBrightnessChanged => controller.stream;

  @override
  Future<bool> get hasChanged async => _changedBrightness != null;
}

void main() {
  late ScreenBrightness screenBrightness;
  late MockScreenBrightnessPlatform mockScreenBrightnessPlatform;

  setUp(() {
    mockScreenBrightnessPlatform = MockScreenBrightnessPlatform();
    ScreenBrightnessPlatform.instance = mockScreenBrightnessPlatform;
    screenBrightness = ScreenBrightness();
  });

  test('get system brightness', () async {
    expect(await screenBrightness.system, systemBrightness);
  });

  test('get screen brightness', () async {
    expect(await screenBrightness.current, systemBrightness);
  });

  test('set screen brightness with valid number', () async {
    const targetBrightness = 0.1;
    await screenBrightness.setScreenBrightness(targetBrightness);
    expect(await screenBrightness.current, targetBrightness);
  });

  test('reset screen brightness', () async {
    await screenBrightness.resetScreenBrightness();
    expect(await screenBrightness.current, systemBrightness);
  });

  group('on screen brightness changed stream', () {
    setUp(() {
      controller = StreamController<double>();
    });

    tearDown(() {
      controller.close();
    });

    test('receive values', () async {
      final queue =
          StreamQueue<double>(screenBrightness.onCurrentBrightnessChanged);

      controller.add(0.2);
      expect(await queue.next, 0.2);

      controller.add(systemBrightness);
      expect(await queue.next, systemBrightness);

      controller.add(0);
      expect(await queue.next, 0);

      controller.add(1);
      expect(await queue.next, 1);
    });
  });
}
