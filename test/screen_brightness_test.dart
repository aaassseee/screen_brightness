import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screen_brightness/src/constant/plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel(pluginMethodChannelName);

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getScreenBrightness', () async {
    expect(await ScreenBrightness.current, '42');
  });
}
