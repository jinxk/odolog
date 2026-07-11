import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: OdoLogApp()));
}

class OdoLogApp extends StatelessWidget {
  const OdoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OdoLog',
      home: Scaffold(
        appBar: AppBar(title: const Text('OdoLog')),
        body: const Center(child: Text('OdoLog')),
      ),
    );
  }
}
