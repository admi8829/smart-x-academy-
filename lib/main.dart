import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(SmartXAcademyApp(prefs: prefs));
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
    return MaterialApp(
      title: 'Smart X Academy',
      debugShowCheckedModeBanner: false,
      
      // Sophisticated Light & Dark Themes matching the user's sleek palette
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF0D2353), // Modern dark blue
          background: const Color(0xFFF4F7FC), // Soft slate background
          surface: Colors.white,
          onPrimary: Colors.white,
          onBackground: const Color(0xFF1E2843),
          onSurface: const Color(0xFF1E2843),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2353)),
          bodyLarge: TextStyle(color: Color(0xFF42526E)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7A97FF),
          background: const Color(0xFF111827), // Deep grey-blue
          surface: const Color(0xFF1F2937),
          onPrimary: const Color(0xFF111827),
          onBackground: const Color(0xFFF9FAFB),
          onSurface: const Color(0xFFFAFAFA),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(color: Color(0xFF9CA3AF)),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        languageCode: _languageCode,
        onToggleTheme: toggleTheme,
        onToggleLanguage: toggleLanguage,
      ),
    );
  }
}
