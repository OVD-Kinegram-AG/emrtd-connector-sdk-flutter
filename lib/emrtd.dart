import 'emrtd_platform_interface.dart';

class Emrtd {
  Future<String?> readAndVerify({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String documentNumber,
    required String dateOfBirth,
    required String dateOfExpiry,
  }) {
    return EmrtdPlatform.instance.readAndVerify(
      clientId: clientId,
      validationUri: validationUri,
      validationId: validationId,
      documentNumber: documentNumber,
      dateOfBirth: dateOfBirth,
      dateOfExpiry: dateOfExpiry,
    );
  }
}
