# Kinegram eMRTD Connector SDK for Flutter

The Kinegram eMRTD Connector enables your Flutter app to read and verify
electronic passports ([eMRTDs][emrtd]) and ID cards.

```
    ┌───────────────┐     Results     ┌─────────────────┐
    │ DocVal Server │────────────────▶│   Your Server   │
    └───────────────┘                 └─────────────────┘
            ▲
            │ WebSocket
            ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                        ┃
┃    eMRTD Connector     ┃
┃                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━┛
            ▲
            │ NFC
            ▼
    ┌──────────────┐
    │              │
    │   PASSPORT   │
    │              │
    │   ID CARD    │
    │              │
    │              │
    │   (eMRTD)    │
    │              │
    └──────────────┘
```

The Kinegram eMRTD Connector enables the
[Document Validation Server (DocVal)][docval]
to communicate with the eMRTD through a secure WebSocket connection.

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

   // Automatically (and only) use PACE polling for ID cards that
   // require it, such as the French and Omani ID cards.
   final paceResult = await _emrtd.readAndVerifyWithPace(
     clientId: 'your_client_id',
     validationUri: 'wss://docval.kurzdigital.com/ws2/validate',
     validationId: 'unique-session-id',
     canKey: '123456',
     documentType: 'ID',
     issuingCountry: 'FRA',
   );

   // Alternatively, always use PACE polling.
   //
   // IMPORTANT:
   // PACE polling is only available (and required) on iOS 16 and later.
   // PACE polling cannot detect standard passports - only use it when you
   // know the document requires it.
   final paceResult = await _emrtd.readAndVerifyWithPacePolling(
     clientId: 'your_client_id',
     validationUri: 'wss://docval.kurzdigital.com/ws2/validate',
     validationId: 'unique-session-id',
     canKey: '123456',
   );
   ```

The `readAndVerify…` calls initiate an NFC session, read the eMRTD chip with
the provided credentials, and send the result to the validator referenced by
`validationUri`.

## iOS requirements

The native `KinegramEmrtdConnector` SDK the plugin wraps requires
**iOS 15.0+**. Ensure your consuming Flutter app sets the same deployment
target in `ios/Podfile`, `ios/Runner.xcodeproj`, and
`ios/Flutter/AppFrameworkInfo.plist` before running `pod install` or
`flutter run` on iOS.

### 1. Enable NFC Capability

This needed entitlement is added automatically by Xcode when enabling the
**Near Field Communication Tag Reading** capability in the target
**Signing & Capabilities**.

After enabling the capability the `*.entitlements` file needs to contain
the `TAG` _(Application specific tag, including ISO 7816 Tags)_ and `PACE` _(Needed for PACE polling support (some ID cards))_ format:

```xml
...
<dict>
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>PACE</string>
        <string>TAG</string>
    </array>
</dict>
...
```

### 2. Info.plist (AID & NFCReaderUsageDescription)

The app needs to define the list of `AIDs` it can connect to, in the `Info.plist` file.

The `AID` is a way of uniquely identifying an application on a ISO 7816 tag.
eMRTDS use the AIDs `A0000002471001` and `A0000002472001`.
Your *Info.plist* entry should look like this:

```xml
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A0000002471001</string>
        <string>A0000002472001</string>
    </array>
```

- Additionally set the `NFCReaderUsageDescription` key:

```xml
    <key>NFCReaderUsageDescription</key>
    <string>This app uses NFC to verify passports</string>
```

[emrtd]: https://kta.pages.kurzdigital.com/kta-kinegram-document-validation-service/SecurityMechanisms
[docval]: https://kta.pages.kurzdigital.com/kta-kinegram-document-validation-service/
