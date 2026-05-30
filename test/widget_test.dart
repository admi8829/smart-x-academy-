import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_x_academy/main.dart';

void main() {
  testWidgets('Verify Smart X Academy App runs and loads HomeScreen', (WidgetTester tester) async {
    // Scaffold initial shared preferences values
    SharedPreferences.setMockInitialValues({
      'isDarkMode': false,
      'languageCode': 'en',
    });
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Pump the full layout
    await tester.pumpWidget(SmartXAcademyApp(prefs: prefs));

    // Verify application starts on default HomeScreen with AppBar title
    expect(find.byType(AppBar), findsOneWidget);
    
    // Check that we render search icons or standard buttons
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
