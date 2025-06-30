import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/device_discovery_service.dart';
import 'services/clipboard_service.dart';
import 'services/file_transfer_service.dart';

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
