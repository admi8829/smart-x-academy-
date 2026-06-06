import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';

// Application State Model for clean global notifier tracking
class AppState {
  final bool isDarkMode;
  final String languageCode;

  const AppState({
    required this.isDarkMode,
    required this.languageCode,
  });

  AppState copyWith({
    bool? isDarkMode,
    String? languageCode,
  }) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

// Global ValueNotifier to track changes dynamically across all views
late final ValueNotifier<AppState> appStateNotifier;

void main() async {
  // Ensure widget bindings are safely initialized before calling native platforms/plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Push Notifications via Firebase
  await PushNotificationService.initialize();

  // Initialize the Mobile Ads SDK asynchronously
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("Failed to initialize Google Mobile Ads SDK: $e");
  }

  // Retrieve shared preferences for persistent theme & language choices
  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final String languageCode = prefs.getString('languageCode') ?? 'en';

  appStateNotifier = ValueNotifier<AppState>(AppState(
    isDarkMode: isDarkMode,
    languageCode: languageCode,
  ));
  
  runApp(SmartXAcademyApp(prefs: prefs));
}

class AppStateProvider extends InheritedWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const AppStateProvider({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required super.child,
  });

  static AppStateProvider of(BuildContext context) {
    final AppStateProvider? result = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(result != null, 'No AppStateProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppStateProvider oldWidget) {
    return oldWidget.isDarkMode != isDarkMode || oldWidget.languageCode != languageCode;
  }
}

class SmartXAcademyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const SmartXAcademyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppState>(
      valueListenable: appStateNotifier,
      builder: (context, state, child) {
        return AppStateProvider(
          isDarkMode: state.isDarkMode,
          languageCode: state.languageCode,
          onToggleTheme: () async {
            final nextMode = !state.isDarkMode;
            appStateNotifier.value = state.copyWith(isDarkMode: nextMode);
            await prefs.setBool('isDarkMode', nextMode);
          },
          onToggleLanguage: () async {
            final nextLang = state.languageCode == 'en' ? 'am' : 'en';
            appStateNotifier.value = state.copyWith(languageCode: nextLang);
            await prefs.setString('languageCode', nextLang);
          },
          child: MaterialApp(
            title: 'Smart X Academy',
            debugShowCheckedModeBanner: false,
            
            // Sophisticated Light & Dark Themes matching the user's sleek palette
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0D2353), // Modern dark blue
                surface: Color(0xFFF1F5F9), // Soft slate background
                onPrimary: Colors.white,
                onSurface: Color(0xFF1E2843),
              ),
              textTheme: const TextTheme(
                titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2353)),
                bodyLarge: TextStyle(color: Color(0xFF42526E)),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF38BDF8), // Sky blue
                surface: Color(0xFF0F172A), // Deep dark-slate background
                onPrimary: Color(0xFF0F172A),
                onSurface: Color(0xFFFAFAFA),
              ),
              textTheme: const TextTheme(
                titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                bodyLarge: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Launch the beautiful animated open-application process (Splash Screen)
            home: SplashScreen(
              isDarkMode: state.isDarkMode,
              languageCode: state.languageCode,
              onToggleTheme: () async {
                final nextMode = !state.isDarkMode;
                appStateNotifier.value = state.copyWith(isDarkMode: nextMode);
                await prefs.setBool('isDarkMode', nextMode);
              },
              onToggleLanguage: () async {
                final nextLang = state.languageCode == 'en' ? 'am' : 'en';
                appStateNotifier.value = state.copyWith(languageCode: nextLang);
                await prefs.setString('languageCode', nextLang);
              },
            ),
          ),
        );
      },
    );
  }
}
