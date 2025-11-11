import 'package:emrtd/emrtd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('readAndVerify with MRZ completes', (WidgetTester tester) async {
    final plugin = Emrtd();
    expect(
      plugin.readAndVerify(
        clientId: 'your-client-id',
        validationUri: 'wss://kinegramdocval.lkis.de/ws1/validate',
        validationId: 'integration-test',
        documentNumber: 'C01X00000',
        dateOfBirth: '1990-01-01',
        dateOfExpiry: '2030-01-01',
      ),
      completes,
    );
  });

  testWidgets('readAndVerify with CAN completes', (WidgetTester tester) async {
    final plugin = Emrtd();
    expect(
      plugin.readAndVerifyWithCan(
        clientId: 'your-client-id',
        validationUri: 'wss://kinegramdocval.lkis.de/ws1/validate',
        validationId: 'integration-test',
        can: '123456',
      ),
      completes,
    );
  });
}
