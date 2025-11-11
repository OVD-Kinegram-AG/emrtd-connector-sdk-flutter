import 'dart:async';

import 'package:emrtd/emrtd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController(text: 'C01X00000');
  final _dateOfBirthController = TextEditingController(text: '1990-01-01');
  final _dateOfExpiryController = TextEditingController(text: '2030-01-01');

  final _emrtdPlugin = Emrtd();

  String _result = 'Ready to read and verify.';
  bool _isLoading = false;

  @override
  void dispose() {
    _documentNumberController.dispose();
    _dateOfBirthController.dispose();
    _dateOfExpiryController.dispose();
    super.dispose();
  }

  Future<void> _readAndVerify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Reading chip and verifying…';
    });

    try {
      final result =
          await _emrtdPlugin.readAndVerify(
            clientId: "your-client-id",
            validationUri: "wss://kinegramdocval.lkis.de/ws1/validate",
            validationId: Uuid().v4(),
            documentNumber: _documentNumberController.text.trim(),
            dateOfBirth: _dateOfBirthController.text.trim(),
            dateOfExpiry: _dateOfExpiryController.text.trim(),
          ) ??
          'No result';
      _setStateWhenMounted(() {
        _result = result;
      });
    } on PlatformException catch (e) {
      _setStateWhenMounted(() {
        _result = 'Platform error: ${e.message ?? e.code}';
      });
    } catch (e) {
      _setStateWhenMounted(() {
        _result = 'Unexpected error: $e';
      });
    } finally {
      _setStateWhenMounted(() {
        _isLoading = false;
      });
    }
  }

  void _setStateWhenMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('eMRTD example app')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Input document details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _documentNumberController,
                              label: 'Document Number',
                              textCapitalization: TextCapitalization.characters,
                            ),
                            _buildTextField(
                              controller: _dateOfBirthController,
                              label: 'Date of Birth (YYYY-MM-DD)',
                              keyboardType: TextInputType.datetime,
                            ),
                            _buildTextField(
                              controller: _dateOfExpiryController,
                              label: 'Date of Expiry (YYYY-MM-DD)',
                              keyboardType: TextInputType.datetime,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _readAndVerify,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.document_scanner_outlined),
                              label: Text(
                                _isLoading ? 'Processing…' : 'Read & Verify',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Result',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_result),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
