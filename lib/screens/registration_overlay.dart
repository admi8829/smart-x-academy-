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
  final _phoneController = TextEditingController(text: '+251 ');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _selectedGrade = 12; // Default grade level
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _isLogin = false; // Toggle state between login & register
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final isEn = widget.languageCode == 'en';
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final supabase = Supabase.instance.client;

      if (_isLogin) {
        // --- LOG IN LOGIC ---
        final response = await supabase
            .from('student_profiles')
            .select()
            .eq('email', email)
            .eq('password', password)
            .maybeSingle();

        if (response == null) {
          throw Exception('invalid email or password');
        }

        final profileId = response['id'].toString();
        final fullName = response['full_name']?.toString() ?? 'ተማሪ';
        final phoneNumber = response['phone_number']?.toString() ?? '';
        final int gradeNum = int.tryParse(response['grade']?.toString() ?? '') ?? 12;
        final gradeLabel = 'Grade $gradeNum';

        // Save state in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_registered', true);
        await prefs.setBool('is_authenticated', true);
        await prefs.setString('user_id', profileId);
        await prefs.setString('user_fullName', fullName);
        await prefs.setString('user_phoneNumber', phoneNumber);
        await prefs.setString('user_grade', gradeLabel);
        await prefs.setString('user_email', email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn ? 'Welcome back, $fullName!' : 'እንኳን ደህና መጡ $fullName!',
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
      } else {
        // --- REGISTER LOGIC ---
        if (!_acceptedTerms) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEn
                    ? 'Please agree to the terms and privacy policy.'
                    : 'እባክዎ በአገልግሎት ውሎች እና ግላዊነት ፖሊሲ ላይ መስማማትዎን ያረጋግጡ።',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final fullName = _nameController.text.trim();
        final rawPhone = _phoneController.text.trim();
        
        // Normalize/Format Phone Number before sending to DB to ensure clean data consistency
        String cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
        String formattedPhone;
        if (cleanDigits.startsWith('251')) {
          formattedPhone = '+$cleanDigits';
        } else if (cleanDigits.startsWith('0')) {
          formattedPhone = '+251${cleanDigits.substring(1)}';
        } else {
          formattedPhone = '+251$cleanDigits';
        }

        final String profileId = _generateUuidV4();
        
        // Perform database insertion to the 'student_profiles' table
        await supabase.from('student_profiles').insert({
          'id': profileId,
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'email': email,
          'password': password,
        });

        debugPrint("Successfully inserted user registration details into Supabase 'student_profiles' table.");

        // Save registration state in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_registered', true);
        await prefs.setBool('is_authenticated', true);
        await prefs.setString('user_id', profileId);
        await prefs.setString('user_fullName', fullName);
        await prefs.setString('user_phoneNumber', formattedPhone);
        await prefs.setString('user_grade', 'Grade $_selectedGrade');
        await prefs.setString('user_email', email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn
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
      }
    } catch (e) {
      debugPrint("Supabase or auth action failed: $e");

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
    final isEn = widget.languageCode == 'en';
    String englishMsg = 'An error occurred. Please check your internet connection and try again.';
    String amharicMsg = 'ስህተት አጋጥሟል። እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።';

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
      } else if (code == '42P01' || message.contains('relation') || message.contains('table')) {
        englishMsg = 'Our academy database is currently undergoing maintenance. Please try again shortly!';
        amharicMsg = 'የአካዳሚው መረጃ ቋት በአሁኑ ጊዜ በጥገና ላይ ነው። እባክዎ በጥቂት ጊዜ ውስጥ እንደገና ይሞክሩ!';
      } else {
        englishMsg = 'We couldn\'t process your request on our servers. Please check your details and try again.';
        amharicMsg = 'በአገልጋዮቻችን ላይ ጥያቄዎን ማስተናገድ አልቻልንም። እባክዎ ዝርዝርዎን ደግመው ያረጋግጡና እንደገና ይሞክሩ።';
      }
    } else {
      final str = e.toString().toLowerCase();
      if (str.contains('timeout') || str.contains('time out') || str.contains('connection timed out')) {
        englishMsg = 'The database connection timed out. Please try again when your connection is stable.';
        amharicMsg = 'የመረጃ ቋት ግንኙነት ጊዜ አልፏል። እባክዎ ግንኙነትዎ ሲረጋጋ እንደገና ይሞክሩ።';
      } else if (str.contains('socketexception') || str.contains('failed host lookup') || str.contains('network') || str.contains('offline') || str.contains('xmlhttprequest')) {
        englishMsg = 'Database network server is unreachable. Please check if your mobile data or Wi-Fi is active.';
        amharicMsg = 'የመረጃ ቋት አገልጋዩን ማግኘት አልተቻለም። እባክዎ የሞባይል ዳታ ወይም ዋይፋይ መብራቱን ያረጋግጡ።';
      } else if (str.contains('invalid email or password')) {
        englishMsg = 'Incorrect email or password. Please check your credentials and try again.';
        amharicMsg = 'የተሳሳተ ኢሜል ወይም የይለፍ ቃል ያስገቡ። እባክዎ እንደገና ይሞክሩ።';
      }
    }

    return isEn ? englishMsg : amharicMsg;
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
    final isEn = widget.languageCode == 'en';

    final headerTitle = _isLogin 
        ? (isEn ? 'Welcome Back' : 'እንኳን ደህና መጡ')
        : (isEn ? 'Create Your Account' : 'መለያ ይፍጠሩ');
        
    final headerSubtitle = _isLogin
        ? (isEn ? 'Sign in to continue your learning journey' : 'የመማር ጉዞዎን ለመቀጠል ይግቡ')
        : (isEn ? 'Join Smart X Academy Today' : 'ዛሬ ስማርት ኤክስ አካዳሚን ይቀላቀሉ');

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background overlay
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450), // Responsive maximum width for container
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
                            // Smart X Academy Branding Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined, color: widget.primaryColor, size: 28),
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
                            
                            // Title & Subtitle
                            Text(
                              headerTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              headerSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // --- Conditional Input Fields ---
                            if (!_isLogin) ...[
                              // Full Name Field (Register Mode Only)
                              _buildCustomTextField(
                                label: isEn ? 'Full Name' : 'ሙሉ ስም',
                                hintText: isEn ? 'e.g., John Doe' : 'ምሳሌ: አበበ በቀለ',
                                prefixIcon: Icons.person_outline_rounded,
                                controller: _nameController,
                                isDarkMode: widget.isDarkMode,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return isEn ? 'Name is required' : 'እባክዎን ስምዎን ያስገቡ';
                                  }
                                  if (val.trim().length < 3) {
                                    return isEn ? 'Name too short' : 'ስም በጣም አጭር ነው';
                                  }
                                  return null;
                                },
                              ),

                              // Grade Dropdown Field (Register Mode Only)
                              _buildCustomDropdownField(
                                label: isEn ? 'Grade' : 'የክፍል ደረጃ',
                                prefixIcon: Icons.menu_book_rounded,
                                selectedValue: _selectedGrade,
                                isDarkMode: widget.isDarkMode,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedGrade = val;
                                    });
                                  }
                                },
                              ),

                              // Phone Field (Register Mode Only)
                              _buildCustomTextField(
                                label: isEn ? 'Phone Number' : 'ስልክ ቁጥር',
                                hintText: isEn ? 'e.g., +251 912 345 678' : 'ምሳሌ: +251 912 345 678',
                                prefixIcon: Icons.phone_outlined,
                                controller: _phoneController,
                                isDarkMode: widget.isDarkMode,
                                keyboardType: TextInputType.phone,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return isEn ? 'Phone number is required' : 'እባክዎን ስልክ ቁጥር ያስገቡ';
                                  }
                                  final clean = val.replaceAll(RegExp(r'\D'), '');
                                  if (clean.startsWith('251')) {
                                    if (clean.length != 12) {
                                      return isEn 
                                          ? 'Ethiopian phone number must be 12 digits with country code' 
                                          : 'ትክክለኛ ያልሆነ ስልክ ቁጥር (12 አሃዝ መሆን አለበት)';
                                    }
                                  } else if (clean.startsWith('0')) {
                                    if (clean.length != 10) {
                                      return isEn 
                                          ? 'Local phone number must be 10 digits starting with 0' 
                                          : 'ትክክለኛ ያልሆነ ስልክ ቁጥር (10 አሃዝ መሆን አለበት)';
                                    }
                                    final secondChar = clean[1];
                                    if (secondChar != '9' && secondChar != '7') {
                                      return isEn 
                                          ? 'Ethiopian mobile numbers start with 09 or 07' 
                                          : 'የሞባይል ስልክ ቁጥር በ09 ወይም 07 መጀመር አለበት';
                                    }
                                  } else {
                                    if (clean.length != 9) {
                                      return isEn 
                                          ? 'Standard mobile number must be 9 digits' 
                                          : 'ትክክለኛ ያልሆነ ስልክ ቁጥር (9 አሃዝ መሆን አለበት)';
                                    }
                                    final firstChar = clean[0];
                                    if (firstChar != '9' && firstChar != '7') {
                                      return isEn 
                                          ? 'Ethiopian mobile numbers start with 9 or 7' 
                                          : 'የሞባይል ስልክ ቁጥር በ9 ወይም 7 መጀመር አለበት';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],

                            // Email Address Field (Always Visible)
                            _buildCustomTextField(
                              label: isEn ? 'Email Address' : 'የኢሜል አድራሻ',
                              hintText: isEn ? 'e.g., john.doe@email.com' : 'ምሳሌ: john.doe@email.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              controller: _emailController,
                              isDarkMode: widget.isDarkMode,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return isEn ? 'Email is required' : 'እባክዎን ኢሜል ያስገቡ';
                                }
                                final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegExp.hasMatch(val.trim())) {
                                  return isEn ? 'Enter a valid email address' : 'እባክዎን ትክክለኛ ኢሜል ያስገቡ';
                                }
                                return null;
                              },
                            ),

                            // Password Field (Always Visible)
                            _buildCustomTextField(
                              label: isEn ? 'Password' : 'የይለፍ ቃል',
                              hintText: isEn ? 'Min. 8 characters' : 'ቢያንስ 8 ቁምፊዎች',
                              prefixIcon: Icons.lock_outline,
                              controller: _passwordController,
                              isDarkMode: widget.isDarkMode,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return isEn ? 'Password is required' : 'እባክዎን የይለፍ ቃል ያስገቡ';
                                }
                                if (val.length < 8) {
                                  return isEn ? 'Password must be at least 8 characters' : 'የይለፍ ቃል ቢያንስ 8 ቁምፊዎች መሆን አለበት';
                                }
                                return null;
                              },
                            ),

                            // Terms Agreement Checkbox (Register Mode Only)
                            if (!_isLogin) ...[
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
                                    activeColor: const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  Expanded(
                                    child: Text(
                                      isEn
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
                              const SizedBox(height: 20),
                            ],

                            // Top Action Pill Button: Register or Log In
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A), // Premium Dark Navy Blue
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50), // Exact 50px height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25), // Pill shape matching mockup
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
                                      _isLogin
                                          ? (isEn ? 'Log In' : 'ይግቡ')
                                          : (isEn ? 'Register' : 'ይመዝገቡ'),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // Bottom Outlined Action Pill Button: Cancel
                            OutlinedButton(
                              onPressed: _isLoading ? null : _handleCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B), // Gray text
                                minimumSize: const Size.fromHeight(50), // Exact 50px height
                                side: BorderSide(
                                  color: const Color(0xFFCBD5E1).withOpacity(0.8), // Light gray/blue border
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25), // Pill shape matching mockup
                                ),
                              ),
                              child: Text(
                                isEn ? 'Cancel' : 'ሰርዝ',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // "Switch Mode" Footer Link
                            Center(
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                          _formKey.currentState?.reset();
                                        });
                                      },
                                child: Text(
                                  _isLogin
                                      ? (isEn ? "Don't have an account? Register" : 'መለያ የለዎትም? ይመዝገቡ።')
                                      : (isEn ? 'Already have an account? Log In' : 'አካውንት አለዎት? ይግቡ።'),
                                  style: TextStyle(
                                    color: widget.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                        tooltip: isEn ? 'Close' : 'ዝጋ',
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

  // Beautiful Reusable Text Input Field conforming exactly to the Mockup Style
  Widget _buildCustomTextField({
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
    required bool isDarkMode,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final labelColor = isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final hintColor = isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF3B82F6), size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF93C5FD).withOpacity(0.5), // Thin, rounded light-blue border
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6), // Strong blue border on focus
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Beautiful Reusable Dropdown Input Field conforming exactly to the Mockup Style
  Widget _buildCustomDropdownField({
    required String label,
    required IconData prefixIcon,
    required int selectedValue,
    required bool isDarkMode,
    required void Function(int?) onChanged,
  }) {
    final labelColor = isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: selectedValue,
          dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF3B82F6), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF93C5FD).withOpacity(0.5), // Thin, rounded light-blue border
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6), // Strong blue border on focus
                width: 1.5,
              ),
            ),
          ),
          items: [9, 10, 11, 12].map((g) {
            return DropdownMenuItem<int>(
              value: g,
              child: Text(
                widget.languageCode == 'en' ? '$g\th Grade' : 'ክፍል $g',
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
