import 'package:emrtd/emrtd.dart';
import 'package:emrtd/emrtd_method_channel.dart';
import 'package:emrtd/emrtd_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEmrtdPlatform
    with MockPlatformInterfaceMixin
    implements EmrtdPlatform {
  @override
  Future<String?> readAndVerify({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String documentNumber,
    required String dateOfBirth,
    required String dateOfExpiry,
  }) async {
    return 'mrz-result';
  }

  @override
  Future<String?> readAndVerifyWithCan({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String can,
  }) async {
    return 'can-result';
  }

  @override
  Future<String?> readAndVerifyWithPace({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String canKey,
    required String documentType,
    required String issuingCountry,
  }) async {
    return 'pace-result';
  }
}

void main() {
  final EmrtdPlatform initialPlatform = EmrtdPlatform.instance;

  tearDown(() {
    EmrtdPlatform.instance = initialPlatform;
  });

  test('$MethodChannelEmrtd is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEmrtd>());
  });

  test('readAndVerify delegates to platform implementation', () async {
    final emrtdPlugin = Emrtd();
    final fakePlatform = MockEmrtdPlatform();
    EmrtdPlatform.instance = fakePlatform;

    final result = await emrtdPlugin.readAndVerify(
      clientId: 'client',
      validationUri: 'uri',
      validationId: 'validation',
      documentNumber: 'DOC123',
      dateOfBirth: '1990-01-01',
      dateOfExpiry: '2030-01-01',
    );

    expect(result, 'mrz-result');
  });

  test('readAndVerifyWithCan delegates to platform implementation', () async {
    final emrtdPlugin = Emrtd();
    final fakePlatform = MockEmrtdPlatform();
    EmrtdPlatform.instance = fakePlatform;

    final result = await emrtdPlugin.readAndVerifyWithCan(
      clientId: 'client',
      validationUri: 'uri',
      validationId: 'validation',
      can: '123456',
    );

    expect(result, 'can-result');
  });

  test('readAndVerifyWithPace delegates to platform implementation', () async {
    final emrtdPlugin = Emrtd();
    final fakePlatform = MockEmrtdPlatform();
    EmrtdPlatform.instance = fakePlatform;

    final result = await emrtdPlugin.readAndVerifyWithPace(
      clientId: 'client',
      validationUri: 'uri',
      validationId: 'validation',
      canKey: '123456',
      documentType: 'ID',
      issuingCountry: 'D',
    );

    expect(result, 'pace-result');
  });
}
