import 'package:flutter_test/flutter_test.dart';
import 'package:naci_brain/main.dart';
import 'package:naci_brain/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app shows the splash screen, then the home screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    await tester.pumpWidget(NaciBrainApp(storage: storage));
    expect(find.text('NACI BRAIN'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
  });
}
