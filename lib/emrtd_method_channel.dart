import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'emrtd_platform_interface.dart';

class MethodChannelEmrtd extends EmrtdPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('emrtd');

  @override
  Future<String?> readAndVerify({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String documentNumber,
    required String dateOfBirth,
    required String dateOfExpiry,
  }) async {
    final result = await methodChannel.invokeMethod<String>('readAndVerify', {
      'clientId': clientId,
      'validationUri': validationUri,
      'validationId': validationId,
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'dateOfExpiry': dateOfExpiry,
    });
    return result;
  }

  @override
  Future<String?> readAndVerifyWithCan({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String can,
  }) async {
    final result =
        await methodChannel.invokeMethod<String>('readAndVerifyWithCan', {
      'clientId': clientId,
      'validationUri': validationUri,
      'validationId': validationId,
      'can': can,
    });
    return result;
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
    final result =
        await methodChannel.invokeMethod<String>('readAndVerifyWithPace', {
      'clientId': clientId,
      'validationUri': validationUri,
      'validationId': validationId,
      'canKey': canKey,
      'documentType': documentType,
      'issuingCountry': issuingCountry,
    });
    return result;
  }

  @override
  Future<String?> readAndVerifyWithPacePolling({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String can,
  }) async {
    final result =
        await methodChannel.invokeMethod<String>('readAndVerifyWithPacePolling', {
      'clientId': clientId,
      'validationUri': validationUri,
      'validationId': validationId,
      'can': can,
    });
    return result;
  }
}
