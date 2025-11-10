import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:emrtd/emrtd.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('read test', (WidgetTester tester) async {
    final Emrtd plugin = Emrtd();
    final String? version = await plugin.read();
    expect(version?.isNotEmpty, true);
  });
}
