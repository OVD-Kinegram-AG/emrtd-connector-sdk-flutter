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

  // Public API that every platform must implement
  Future<String?> read({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String documentNumber,
    required String dateOfBirth,
    required String dateOfExpiry,
  }) {
    throw UnimplementedError('read() has not been implemented.');
  }
}
