import 'package:emrtd/emrtd_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelEmrtd();
  const channel = MethodChannel('emrtd');
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return 'mock-result';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('readAndVerify uses the method channel', () async {
    final result = await platform.readAndVerify(
      clientId: 'client',
      validationUri: 'uri',
      validationId: 'id',
      documentNumber: 'DOC123',
      dateOfBirth: '1990-01-01',
      dateOfExpiry: '2030-01-01',
    );

    expect(result, 'mock-result');
    expect(log, hasLength(1));
    expect(log.single.method, 'readAndVerify');
    expect(log.single.arguments, {
      'clientId': 'client',
      'validationUri': 'uri',
      'validationId': 'id',
      'documentNumber': 'DOC123',
      'dateOfBirth': '1990-01-01',
      'dateOfExpiry': '2030-01-01',
    });
  });

  test('readAndVerifyWithCan uses the method channel', () async {
    final result = await platform.readAndVerifyWithCan(
      clientId: 'client',
      validationUri: 'uri',
      validationId: 'id',
      can: '123456',
    );

    expect(result, 'mock-result');
    expect(log, hasLength(1));
    expect(log.single.method, 'readAndVerifyWithCan');
    expect(log.single.arguments, {
      'clientId': 'client',
      'validationUri': 'uri',
      'validationId': 'id',
      'can': '123456',
    });
  });
}
