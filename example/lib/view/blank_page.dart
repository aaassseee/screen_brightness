import 'package:flutter/material.dart';

class BlankPage extends StatelessWidget {
  static const routeName = '/blankPage';

  const BlankPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blank'),
      ),
    );
  }
}
