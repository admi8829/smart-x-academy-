import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class RegistrationOverlay extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final Color primaryColor;

  const RegistrationOverlay({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.primaryColor,
  });

  @override
  State<RegistrationOverlay> createState() => _RegistrationOverlayState();
}

class _RegistrationOverlayState extends State<RegistrationOverlay> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  int _selectedGrade = 12; // Default grade level
  String _selectedCountryCode = '+251'; // Default to Ethiopia
  bool _isLoading = false;
  bool _acceptedTerms = false;

  final List<Map<String, String>> countryCodes = [
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Ethiopia'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _generateUuidV4() {
    final random = math.Random();
    String generateHex(int length) {
      final buffer = StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(random.nextInt(16).toRadixString(16));
      }
      return buffer.toString();
    }
    
    final y = (random.nextInt(4) + 8).toRadixString(16); // 8, 9, a, or b
    
    return '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-$y${generateHex(3)}-${generateHex(12)}';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final fullName = _nameController.text.trim();
    final phoneNumber = '$_selectedCountryCode ${_phoneController.text.trim()}';
    final email = _emailController.text.trim();
    final gradeLabel = 'Grade $_selectedGrade';

    try {
      final supabase = Supabase.instance.client;
      final String profileId = _generateUuidV4();
      
      // Perform database insertion to the 'student_profiles' table
      await supabase.from('student_profiles').insert({
        'id': profileId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'grade': _selectedGrade,
        'email': email.isNotEmpty ? email : '$profileId@smartx-offline.com',
      });

      debugPrint("Successfully inserted user registration details into Supabase 'student_profiles' table.");

      // Save registration state in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('user_id', profileId);
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_phoneNumber', phoneNumber);
      await prefs.setString('user_grade', gradeLabel);
      if (email.isNotEmpty) {
        await prefs.setString('user_email', email);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.languageCode == 'en'
                        ? 'Successfully registered! Welcome to Smart X.'
                        : 'በስኬት ተመዝግበዋል! ወደ ስማርት ኤክስ እንኳን ደህና መጡ።',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop('registered');
      }
    } catch (e) {
      debugPrint("Supabase insertion to 'student_profiles' failed: $e");

      // Translate specific database exceptions or limit exceptions to highly descriptive friendly messages
      String errMsg = _getFriendlyDatabaseErrorMessage(e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errMsg,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFriendlyDatabaseErrorMessage(dynamic e) {
    String englishMsg = 'Registration failed. Please check your internet connection and try again.';
    String amharicMsg = 'ምዝገባው አልተሳካም። እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።';

    if (e is PostgrestException) {
      final code = e.code;
      final message = e.message.toLowerCase();
      final details = (e.details?.toString() ?? '').toLowerCase();

      // Check for unique key constraint violations (SQL code 23505)
      if (code == '23505' || message.contains('unique') || details.contains('already exists')) {
        if (message.contains('phone_number') || details.contains('phone_number')) {
          englishMsg = 'This phone number is already registered. Please check or use another number.';
          amharicMsg = 'ይህ ስልክ ቁጥር ቀድሞ ተመዝግቧል። እባክዎ ሌላ ስልክ ቁጥር ይጠቀሙ ወይም ያረጋግጡ።';
        } else if (message.contains('email') || details.contains('email')) {
          englishMsg = 'This email address is already in use by another student.';
          amharicMsg = 'ይህ የኢሜል አድራሻ ቀድሞውኑ በሌላ ተማሪ ጥቅም ላይ ውሏል።';
        } else {
          englishMsg = 'A record with these details already exists in our database.';
          amharicMsg = 'እነዚህን ዝርዝሮች የያዘ ተማሪ ቀድሞ በመረጃ ቋቱ ውስጥ ተመዝግቧል።';
        }
      } else if (code == '42P01') {
        englishMsg = 'Service configuration error (profiles table is missing). Please contact support.';
        amharicMsg = 'የአገልግሎት ማዋቀር ስህተት (የተማሪዎች ሰንጠረዥ አልተገኘም)። እባክዎ ድጋፍ ሰጪዎችን ያግኙ።';
      } else if (code != null) {
        englishMsg = 'Database processing error (Code: $code): ${e.message}';
        amharicMsg = 'የመረጃ ቋት ማስኬጃ ስህተት (ኮድ: $code): ${e.message}';
      } else {
        englishMsg = 'Database insertion failed: ${e.message}';
        amharicMsg = 'የመረጃ ቋት ምዝገባ አልተሳካም: ${e.message}';
      }
    } else {
      final str = e.toString().toLowerCase();
      if (str.contains('timeout') || str.contains('time out') || str.contains('connection timed out')) {
        englishMsg = 'The database connection timed out. Please try again when your connection is stable.';
        amharicMsg = 'የመረጃ ቋት ግንኙነት ጊዜ አልፏል። እባክዎ ግንኙነትዎ ሲረጋጋ እንደገና ይሞክሩ።';
      } else if (str.contains('socketexception') || str.contains('failed host lookup') || str.contains('network') || str.contains('offline')) {
        englishMsg = 'Supabase network server is unreachable. Please check if your mobile data or Wi-Fi is active.';
        amharicMsg = 'የመረጃ ቋት አገልጋዩን ማግኘት አልተቻለም። እባክዎ የሞባይል ዳታ ወይም ዋይፋይ መብራቱን ያረጋግጡ።';
      } else if (str.contains('request limit') || str.contains('exceeded') || str.contains('cap')) {
        englishMsg = 'Network request limit reached (Max 5). Try starting a new session to clear.';
        amharicMsg = 'የአውታረ መረብ ጥያቄ ገደብ ላይ ደርሰዋል (ከፍተኛ 5)። አዲስ ክፍለ-ጊዜ በመጀመር እንደገና ይሞክሩ።';
      }
    }

    return widget.languageCode == 'en' ? englishMsg : amharicMsg;
  }

  Future<void> _handleCancel() async {
    debugPrint("User cancelled registration overlay.");
    if (mounted) {
      Navigator.of(context).pop('cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = !widget.isDarkMode;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background as requested
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450), // Gorgeous maximum width for card
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.15 : 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Smart X Branding
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_rounded, color: widget.primaryColor, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Smart X Academy',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Header Message
                            Text(
                              widget.languageCode == 'en' ? 'Create Account' : 'መለያ ይፍጠሩ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.languageCode == 'en'
                                  ? 'Sign up to manage your academic profile.'
                                  : 'የትምህርት መገለጫዎን ለማስተዳደር ይመዝገቡ።',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Full Name Field
                            _buildFieldLabel(widget.languageCode == 'en' ? 'Full Name' : 'ሙሉ ስም', isLight),
                            _buildFieldContainer(
                              isLight: isLight,
                              child: TextFormField(
                                controller: _nameController,
                                enabled: !_isLoading,
                                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: widget.languageCode == 'en' ? 'John Doe' : 'አበበ በቀለ',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: subtitleColor, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return widget.languageCode == 'en' ? 'Name is required' : 'እባክዎን ስምዎን ያስገቡ';
                                  }
                                  if (val.trim().length < 3) {
                                    return widget.languageCode == 'en' ? 'Name too short' : 'ስም በጣም አጭር ነው';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Grade Dropdown
                            _buildFieldLabel(widget.languageCode == 'en' ? 'Grade' : 'የክፍል ደረጃ', isLight),
                            _buildFieldContainer(
                              isLight: isLight,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedGrade,
                                  isExpanded: true,
                                  dropdownColor: cardColor,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: subtitleColor),
                                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                  items: [9, 10, 11, 12].map((g) {
                                    return DropdownMenuItem<int>(
                                      value: g,
                                      child: Row(
                                        children: [
                                          Icon(Icons.menu_book_rounded, color: subtitleColor, size: 18),
                                          const SizedBox(width: 10),
                                          Text(widget.languageCode == 'en' ? '${g}th Grade' : 'ክፍል $g'),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isLoading
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedGrade = val;
                                            });
                                          }
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Phone Number Field
                            _buildFieldLabel(widget.languageCode == 'en' ? 'Phone Number' : 'ስልክ ቁጥር', isLight),
                            _buildFieldContainer(
                              isLight: isLight,
                              child: TextFormField(
                                controller: _phoneController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '(123) 456-7890',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                                  prefixIcon: Icon(Icons.phone_outlined, color: subtitleColor, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return widget.languageCode == 'en' ? 'Phone is required' : 'እባክዎን ስልክ ቁጥር ያስገቡ';
                                  }
                                  final clean = val.replaceAll(RegExp(r'\D'), '');
                                  if (clean.length < 9) {
                                    return widget.languageCode == 'en' ? 'Invalid phone number' : 'ትክክለኛ ያልሆነ ስልክ ቁጥር';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            _buildFieldLabel(widget.languageCode == 'en' ? 'Email Address' : 'የኢሜል አድራሻ', isLight),
                            _buildFieldContainer(
                              isLight: isLight,
                              child: TextFormField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: widget.languageCode == 'en' ? 'john.doe@email.com' : 'ምሳሌ: john.doe@email.com',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                                  prefixIcon: Icon(Icons.mail_outline_rounded, color: subtitleColor, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return widget.languageCode == 'en' ? 'Email is required' : 'እባክዎን ኢሜል ያስገቡ';
                                  }
                                  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegExp.hasMatch(val.trim())) {
                                    return widget.languageCode == 'en' ? 'Enter a valid email' : 'እባክዎን ትክክለኛ ኢሜል ያስገቡ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Terms Agreement Checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (val) {
                                    setState(() {
                                      _acceptedTerms = val ?? false;
                                    });
                                  },
                                  activeColor: widget.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.languageCode == 'en'
                                        ? 'I agree to the terms and privacy policy.'
                                        : 'በአገልግሎት ውሎች እና ግላዊነት ፖሊሲ እስማማለሁ።',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons (Cancel / Register)
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _handleCancel,
                                    style: TextButton.styleFrom(
                                      backgroundColor: isLight ? const Color(0xFF64748B) : const Color(0xFF334155),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24), // Pill shape matching mockup
                                      ),
                                    ),
                                    child: Text(
                                      widget.languageCode == 'en' ? 'Cancel' : 'ሰርዝ',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: (_isLoading || !_acceptedTerms) ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF007AFF), // Blue color from mockup
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(0xFF007AFF).withOpacity(0.5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24), // Pill shape matching mockup
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            widget.languageCode == 'en' ? 'Register' : 'ይመዝገቡ',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Already have an account
                            Center(
                              child: Text(
                                widget.languageCode == 'en'
                                    ? 'Already have an account? Sign In.'
                                    : 'አካውንት አለዎት? ይግቡ።',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // "X" Close Button in Top Right Corner
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, color: subtitleColor, size: 22),
                        onPressed: _isLoading ? null : _handleCancel,
                        tooltip: widget.languageCode == 'en' ? 'Close' : 'ዝጋ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child, required bool isLight}) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: child,
    );
  }
}
