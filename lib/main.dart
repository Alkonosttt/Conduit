import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const Conduit());
}

class Conduit extends StatelessWidget {
  const Conduit({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conduit',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const Placeholder(),
    );
  }
}
