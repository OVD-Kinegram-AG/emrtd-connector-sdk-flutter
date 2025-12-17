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

  Future<String?> readAndVerifyWithCan({
    required String clientId,
    required String validationUri,
    required String validationId,
    required String can,
  }) {
    return EmrtdPlatform.instance.readAndVerifyWithCan(
      clientId: clientId,
      validationUri: validationUri,
      validationId: validationId,
      can: can,
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
    return EmrtdPlatform.instance.readAndVerifyWithPace(
      clientId: clientId,
      validationUri: validationUri,
      validationId: validationId,
      canKey: canKey,
      documentType: documentType,
      issuingCountry: issuingCountry,
    );
  }
}
