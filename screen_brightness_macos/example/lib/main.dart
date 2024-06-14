import 'package:flutter/material.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final RouteObserver<Route> routeObserver = RouteObserver<Route>();

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      onGenerateRoute: (settings) {
        late final Widget page;
        switch (settings.name) {
          case HomePage.routeName:
            page = const HomePage();
            break;

          case ControllerPage.routeName:
            page = const ControllerPage();
            break;

          case RouteAwarePage.routeName:
            page = const RouteAwarePage();
            break;

          case BlankPage.routeName:
            page = const BlankPage();
            break;

          case SettingPage.routeName:
            page = const SettingPage();
            break;

          default:
            throw UnimplementedError('page name not found');
        }

        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
      navigatorObservers: [
        routeObserver,
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  static const routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen brightness example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<double>(
              future: ScreenBrightnessPlatform.instance.system,
              builder: (context, snapshot) {
                double systemScreenBrightness = 0;
                if (snapshot.hasData) {
                  systemScreenBrightness = snapshot.data!;
                }

                return StreamBuilder<double>(
                  stream: ScreenBrightnessPlatform
                      .instance.onSystemScreenBrightnessChanged,
                  builder: (context, snapshot) {
                    double changedSystemScreenBrightness =
                        systemScreenBrightness;
                    if (snapshot.hasData) {
                      changedSystemScreenBrightness = snapshot.data!;
                    }

                    return Text(
                        'System screen brightness $changedSystemScreenBrightness');
                  },
                );
              },
            ),
            FutureBuilder<double>(
              future: ScreenBrightnessPlatform.instance.application,
              builder: (context, snapshot) {
                double applicationScreenBrightness = 0;
                if (snapshot.hasData) {
                  applicationScreenBrightness = snapshot.data!;
                }

                return StreamBuilder<double>(
                  stream: ScreenBrightnessPlatform
                      .instance.onApplicationScreenBrightnessChanged,
                  builder: (context, snapshot) {
                    double changedApplicationScreenBrightness =
                        applicationScreenBrightness;
                    if (snapshot.hasData) {
                      changedApplicationScreenBrightness = snapshot.data!;
                    }

                    return Text(
                        'Application screen brightness $changedApplicationScreenBrightness');
                  },
                );
              },
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(ControllerPage.routeName),
              child: const Text('Controller example page'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteAwarePage.routeName),
              child: const Text('Route aware example page'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SettingPage.routeName),
              child: const Text('Setting page'),
            ),
          ],
        ),
      ),
    );
  }
}

class ControllerPage extends StatefulWidget {
  static const routeName = '/controller';

  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  Future<void> setSystemScreenBrightness(double brightness) async {
    try {
      await ScreenBrightnessPlatform.instance
          .setSystemScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set system screen brightness';
    }
  }

  Future<void> setApplicationScreenBrightness(double brightness) async {
    try {
      await ScreenBrightnessPlatform.instance
          .setApplicationScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set application screen brightness';
    }
  }

  Future<void> resetApplicationScreenBrightness() async {
    try {
      await ScreenBrightnessPlatform.instance
          .resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to reset application screen brightness';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<double>(
            future: ScreenBrightnessPlatform.instance.system,
            builder: (context, snapshot) {
              double systemScreenBrightness = snapshot.data ?? 0;

              return StreamBuilder<double>(
                stream: ScreenBrightnessPlatform
                    .instance.onSystemScreenBrightnessChanged,
                builder: (context, snapshot) {
                  double changedSystemScreenBrightness =
                      snapshot.data ?? systemScreenBrightness;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'System screen brightness: $changedSystemScreenBrightness'),
                      Slider.adaptive(
                        value: changedSystemScreenBrightness,
                        onChanged: (value) {
                          setSystemScreenBrightness(value);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          FutureBuilder<double>(
            future: ScreenBrightnessPlatform.instance.application,
            builder: (context, snapshot) {
              double applicationScreenBrightness = 0;
              if (snapshot.hasData) {
                applicationScreenBrightness = snapshot.data!;
              }

              return StreamBuilder<double>(
                stream: ScreenBrightnessPlatform
                    .instance.onApplicationScreenBrightnessChanged,
                builder: (context, snapshot) {
                  double changedApplicationScreenBrightness =
                      applicationScreenBrightness;
                  if (snapshot.hasData) {
                    changedApplicationScreenBrightness = snapshot.data!;
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<bool>(
                        future: ScreenBrightnessPlatform
                            .instance.hasApplicationScreenBrightnessChanged,
                        builder: (context, snapshot) {
                          return Text(
                              'Application screen brightness has changed via plugin: ${snapshot.data}');
                        },
                      ),
                      Text(
                          'Application screen brightness: $changedApplicationScreenBrightness'),
                      Slider.adaptive(
                        value: changedApplicationScreenBrightness,
                        onChanged: (value) {
                          setApplicationScreenBrightness(value);
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          resetApplicationScreenBrightness();
                        },
                        child: const Text('reset brightness'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class RouteAwarePage extends StatefulWidget {
  static const routeName = '/routeAware';

  const RouteAwarePage({super.key});

  @override
  State<RouteAwarePage> createState() => _RouteAwarePageState();
}

class _RouteAwarePageState extends State<RouteAwarePage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyApp.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    super.didPush();
    ScreenBrightnessPlatform.instance.setApplicationScreenBrightness(0.7);
  }

  @override
  void didPushNext() {
    super.didPushNext();
    ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
  }

  @override
  void didPop() {
    super.didPop();
    ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    ScreenBrightnessPlatform.instance.setApplicationScreenBrightness(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route aware'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(BlankPage.routeName),
          child: const Text('Next page'),
        ),
      ),
    );
  }
}

class BlankPage extends StatelessWidget {
  static const routeName = '/blankPage';

  const BlankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blank'),
      ),
    );
  }
}

class SettingPage extends StatefulWidget {
  static const routeName = '/setting';

  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isAutoReset = true;
  bool isAnimate = true;

  @override
  void initState() {
    super.initState();
    getIsAutoResetSetting();
    getIsAnimateSetting();
  }

  Future<void> getIsAutoResetSetting() async {
    final isAutoReset = await ScreenBrightnessPlatform.instance.isAutoReset;
    setState(() {
      this.isAutoReset = isAutoReset;
    });
  }

  Future<void> getIsAnimateSetting() async {
    final isAnimate = await ScreenBrightnessPlatform.instance.isAnimate;
    setState(() {
      this.isAnimate = isAnimate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Auto Reset'),
            trailing: Switch(
              value: isAutoReset,
              onChanged: (value) async {
                await ScreenBrightnessPlatform.instance.setAutoReset(value);
                await getIsAutoResetSetting();
              },
            ),
          ),
          ListTile(
            title: const Text('Animate'),
            trailing: Switch(
              value: isAnimate,
              onChanged: (value) async {
                await ScreenBrightnessPlatform.instance.setAnimate(value);
                await getIsAnimateSetting();
              },
            ),
          )
        ],
      ),
    );
  }
}
