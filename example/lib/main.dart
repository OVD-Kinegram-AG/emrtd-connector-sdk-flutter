import 'dart:async';
import 'dart:math';

import 'package:emrtd/emrtd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _clientId = 'example_client';
  final String _validationUri = 'wss://docval.kurzdigital.com/ws2/validate';
  static const _documentNumberKey = 'document_number';
  static const _dateOfBirthKey = 'date_of_birth';
  static const _dateOfExpiryKey = 'date_of_expiry';
  static const _canKey = 'can';
  final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  final _mrzFormKey = GlobalKey<FormState>();
  final _canFormKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController(text: 'C01X00000');
  final _dateOfBirthController = TextEditingController(text: '900101');
  final _dateOfExpiryController = TextEditingController(text: '300101');
  final _canController = TextEditingController(text: '123456');

  final _emrtdPlugin = Emrtd();

  String _result = 'Ready to read and verify.';
  bool _isMrzLoading = false;
  bool _isCanLoading = false;

  @override
  void initState() {
    super.initState();
    _documentNumberController.addListener(
      () => _persistValue(_documentNumberKey, _documentNumberController.text),
    );
    _dateOfBirthController.addListener(
      () => _persistValue(_dateOfBirthKey, _dateOfBirthController.text),
    );
    _dateOfExpiryController.addListener(
      () => _persistValue(_dateOfExpiryKey, _dateOfExpiryController.text),
    );
    _canController.addListener(
      () => _persistValue(_canKey, _canController.text),
    );
    _loadStoredValues();
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _dateOfBirthController.dispose();
    _dateOfExpiryController.dispose();
    _canController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredValues() async {
    final prefs = await _prefsFuture;
    final storedDocumentNumber = prefs.getString(_documentNumberKey);
    final storedDateOfBirth = prefs.getString(_dateOfBirthKey);
    final storedDateOfExpiry = prefs.getString(_dateOfExpiryKey);
    final storedCan = prefs.getString(_canKey);

    if (storedDocumentNumber?.isNotEmpty ?? false) {
      _documentNumberController.text = storedDocumentNumber!;
    }
    if (storedDateOfBirth?.isNotEmpty ?? false) {
      _dateOfBirthController.text = storedDateOfBirth!;
    }
    if (storedDateOfExpiry?.isNotEmpty ?? false) {
      _dateOfExpiryController.text = storedDateOfExpiry!;
    }
    if (storedCan?.isNotEmpty ?? false) {
      _canController.text = storedCan!;
    }
  }

  void _persistValue(String key, String value) {
    _prefsFuture.then((prefs) => prefs.setString(key, value));
  }

  Future<void> _readAndVerifyWithMrz() async {
    final isMrzValid = _mrzFormKey.currentState?.validate() ?? false;

    if (!isMrzValid) {
      return;
    }

    _setStateWhenMounted(() {
      _isMrzLoading = true;
      _result = 'Reading chip with MRZ data…';
    });

    try {
      final result =
          await _emrtdPlugin.readAndVerify(
            clientId: _clientId,
            validationUri: _validationUri,
            validationId: _randomId(),
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
        _isMrzLoading = false;
      });
    }
  }

  Future<void> _readAndVerifyWithCan() async {
    final isCanValid = _canFormKey.currentState?.validate() ?? false;

    if (!isCanValid) {
      return;
    }

    _setStateWhenMounted(() {
      _isCanLoading = true;
      _result = 'Reading chip with CAN…';
    });

    try {
      final result =
          await _emrtdPlugin.readAndVerifyWithCan(
            clientId: _clientId,
            validationUri: _validationUri,
            validationId: _randomId(),
            can: _canController.text.trim(),
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
        _isCanLoading = false;
      });
    }
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
                  _buildSectionCard(
                    context,
                    title: 'Read document with MRZ',
                    child: Form(
                      key: _mrzFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _documentNumberController,
                            label: 'Document Number',
                            textCapitalization: TextCapitalization.characters,
                          ),
                          _buildTextField(
                            controller: _dateOfBirthController,
                            label: 'Date of Birth (YYMMDD)',
                            keyboardType: TextInputType.datetime,
                          ),
                          _buildTextField(
                            controller: _dateOfExpiryController,
                            label: 'Date of Expiry (YYMMDD)',
                            keyboardType: TextInputType.datetime,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isMrzLoading
                                ? null
                                : _readAndVerifyWithMrz,
                            icon: _isMrzLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.badge_outlined),
                            label: Text(
                              _isMrzLoading ? 'Processing…' : 'Read & Verify',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Read document with CAN',
                    child: Form(
                      key: _canFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _canController,
                            label: 'CAN (Card Access Number)',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isCanLoading
                                ? null
                                : _readAndVerifyWithCan,
                            icon: _isCanLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.nfc),
                            label: Text(
                              _isCanLoading ? 'Processing…' : 'Read & Verify',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Result',
                    elevation: 2,
                    child: Text(_result),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _randomId() {
    final rand = Random();
    return List<int>.generate(
      16,
      (_) => rand.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _setStateWhenMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
    double elevation = 4,
  }) {
    return Card(
      elevation: elevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
