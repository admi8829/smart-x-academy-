import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';

void main() async {
  // Ensure widget bindings are safely initialized before calling native platforms/plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://rdaaqdezaeoyfmuresfa.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkYWFxZGV6YWVveWZtdXJlc2ZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NjY4NzUsImV4cCI6MjA5NjQ0Mjg3NX0.5XjuJCWrax50wKPGYeCEUTDCq0nF9-QiZ4eIN_BD-pk',
    );
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
  }
  
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

class SmartXAcademyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const SmartXAcademyApp({super.key, required this.prefs});

  @override
  State<SmartXAcademyApp> createState() => _SmartXAcademyAppState();
}

class _SmartXAcademyAppState extends State<SmartXAcademyApp> {
  late bool _isDarkMode;
  late String _languageCode; // 'en' or 'am' (Amharic)

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefs.getBool('isDarkMode') ?? false;
    _languageCode = widget.prefs.getString('languageCode') ?? 'en';
  }

  void toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await widget.prefs.setBool('isDarkMode', _isDarkMode);
  }

  void toggleLanguage() async {
    setState(() {
      _languageCode = _languageCode == 'en' ? 'am' : 'en';
    });
    await widget.prefs.setString('languageCode', _languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      isDarkMode: _isDarkMode,
      languageCode: _languageCode,
      onToggleTheme: toggleTheme,
      onToggleLanguage: toggleLanguage,
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
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        
        // Launch the beautiful animated open-application process (Splash Screen)
        home: SplashScreen(
          isDarkMode: _isDarkMode,
          languageCode: _languageCode,
          onToggleTheme: toggleTheme,
          onToggleLanguage: toggleLanguage,
        ),
      ),
    );
  }
}
