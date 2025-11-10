import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:emrtd/emrtd.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = 'Pending…';
  final _emrtdPlugin = Emrtd();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    final result = await _emrtdPlugin.read(
      clientId: 'your-client-id',
      validationUri: 'https://example.com/validate',
      validationId: 'abc123',
      documentNumber: 'C01X00000',
      dateOfBirth: '1990-01-01',
      dateOfExpiry: '2030-01-01',
    ) ?? 'No result';

    if (!mounted) {
      return;
    }

    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('eMRTD example app')),
        body: Center(child: Text(_result)),
      ),
    );
  }
}
