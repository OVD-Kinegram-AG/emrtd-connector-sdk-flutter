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

[emrtd]: https://kta.pages.kurzdigital.com/kta-kinegram-document-validation-service/SecurityMechanisms
[docval]: https://kta.pages.kurzdigital.com/kta-kinegram-document-validation-service/
