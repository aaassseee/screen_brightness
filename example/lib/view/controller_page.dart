import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ControllerPage extends StatefulWidget {
  static const routeName = '/controller';

  const ControllerPage({Key? key}) : super(key: key);

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  double brightness = 0;

  @override
  void initState() {
    super.initState();
    initScreenBrightness();
  }

  Future<void> initScreenBrightness() async {
    double _brightness;

    try {
      final currentBrightness = await ScreenBrightness.current;
      final initialBrightness = await ScreenBrightness.initial;
      _brightness = initialBrightness == currentBrightness
          ? initialBrightness
          : currentBrightness;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to get initial brightness';
    }

    if (!mounted) return;

    setState(() {
      brightness = _brightness;
    });
  }

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness.setScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set brightness';
    }
  }

  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness.resetScreenBrightness();
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to reset brightness';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current brightness: $brightness'),
            Slider.adaptive(
              value: brightness,
              onChanged: (value) async {
                await setBrightness(value);
                setState(() {
                  brightness = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                await resetBrightness();
                await initScreenBrightness();
              },
              child: const Text('reset brightness'),
            ),
          ],
        ),
      ),
    );
  }
}
