import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tracker/main.dart';
import 'package:water_tracker/providers/water_provider.dart';

void main() {
  testWidgets('Water Tracker smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences for the widget test
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const WaterTrackerApp(),
      ),
    );

    // Verify that the title is present
    expect(find.text('Water Tracker'), findsOneWidget);
    // Verify that the initial progress of 0% is present
    expect(find.text('0%'), findsOneWidget);
  });
}
