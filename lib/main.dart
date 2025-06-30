import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
