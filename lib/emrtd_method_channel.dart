import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'emrtd_platform_interface.dart';

class MethodChannelEmrtd extends EmrtdPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('emrtd');

  @override
  Future<String?> read({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String documentNumber,
    required String dateOfBirth,
    required String dateOfExpiry,
  }) async {
    final result = await methodChannel.invokeMethod<String>('read', {
      'clientId': clientId,
      'validationUri': validationUri,
      'validationId': validationId,
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'dateOfExpiry': dateOfExpiry,
    });
    return result;
  }
}
