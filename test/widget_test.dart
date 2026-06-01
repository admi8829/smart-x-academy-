import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_x_academy/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Safe mock channel setup for the Google Mobile Ads SDK to avoid MissingPluginException in test runners
    const MethodChannel adChannel = MethodChannel('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(adChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'initialize') {
        return <String, dynamic>{
          'status': <String, dynamic>{
            'ca-app-pub-3940256099942544~3347511713': <String, dynamic>{
              'state': 1,
              'description': 'Mock AdMob Init Success',
            }
          }
        };
      }
      // Return silent success/null for advertisement loads in simulation
      return null;
    });
  });

  testWidgets('Verify Smart X Academy App runs and loads QuizScreen or Arena gracefully', (WidgetTester tester) async {
    // Scaffold initial shared preferences values
    SharedPreferences.setMockInitialValues({
      'isDarkMode': false,
      'languageCode': 'en',
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Pump the App layout
    await tester.pumpWidget(SmartXAcademyApp(prefs: prefs));
    
    // Complete any initial scheduler frames smoothly
    await tester.pump();

    // Verify application starts gracefully and displays visual headers
    expect(find.textContaining('Smart X'), findsWidgets);
  });
}
