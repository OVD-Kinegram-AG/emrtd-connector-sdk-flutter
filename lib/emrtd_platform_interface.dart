import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'emrtd_method_channel.dart';

abstract class EmrtdPlatform extends PlatformInterface {
  EmrtdPlatform() : super(token: _token);

  static final Object _token = Object();

  static EmrtdPlatform _instance = MethodChannelEmrtd();

  static EmrtdPlatform get instance => _instance;

  static set instance(EmrtdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> readAndVerify({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String documentNumber,
    required String dateOfBirth,
    required String dateOfExpiry,
  }) {
    throw UnimplementedError('readAndVerify() has not been implemented.');
  }

  Future<String?> readAndVerifyWithCan({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String can,
  }) {
    throw UnimplementedError(
      'readAndVerifyWithCan() has not been implemented.',
    );
  }

  Future<String?> readAndVerifyWithPace({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String canKey,
    required String documentType,
    required String issuingCountry,
  }) {
    throw UnimplementedError(
      'readAndVerifyWithPace() has not been implemented.',
    );
  }

  Future<String?> readAndVerifyWithPacePolling({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String can,
  }) {
    throw UnimplementedError(
      'readAndVerifyWithPacePolling() has not been implemented.',
    );
  }
}
