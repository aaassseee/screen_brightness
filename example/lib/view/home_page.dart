import 'package:flutter/material.dart';
import 'package:screen_brightness_example/view/controller_page.dart';
import 'package:screen_brightness_example/view/route_aware_page.dart';

class HomePage extends StatelessWidget {
  static const routeName = '/home';

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen brightness example'),
      ),
      body: ListView(
        children: [
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(ControllerPage.routeName),
            child: const Text('Controller example page'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteAwarePage.routeName),
            child: const Text('Route aware example page'),
          )
        ],
      ),
    );
  }
}
