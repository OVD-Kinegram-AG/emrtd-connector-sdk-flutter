# EmrtdPlugin Example

This example uses the `emrtd` Flutter plugin to read the chip inside
electronic travel documents and verify the result with a backend validator.

## Quick start

1. Add the plugin to your `pubspec.yaml`:
   ```yaml
   dependencies:
     emrtd: ^latest
   ```
2. Import and create an instance in your widget:
   ```dart
   import 'package:emrtd/emrtd.dart';

   final _emrtd = Emrtd();
   ```
3. Read and verify the document using either MRZ values or the CAN:
   ```dart
   final result = await _emrtd.readAndVerify(
     clientId: 'your_client_id',
     validationUri: 'wss://docval.kurzdigital.com/ws2/validate',
     validationId: 'unique-session-id',
     documentNumber: 'C01X00000',
     dateOfBirth: '900101',
     dateOfExpiry: '300101',
   );

   // Alternatively, use the CAN (Card Access Number).
   final resultWithCan = await _emrtd.readAndVerifyWithCan(
     clientId: 'your_client_id',
     validationUri: 'wss://docval.kurzdigital.com/ws2/validate',
     validationId: 'unique-session-id',
     can: '123456',
   );
   ```

The `readAndVerify…` calls initiate an NFC session, read the eMRTD chip with
the provided credentials, and send the result to the validator referenced by
`validationUri`.
