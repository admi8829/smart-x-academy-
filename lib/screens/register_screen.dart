import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_phone_field.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool embedInTab;

  const RegisterScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.embedInTab = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Text Editing Controllers for Email & Password Sign-Up / Log-In
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Authentication & toggle states
  bool _isLoginForm = false; // defaults to Create Account screen
  int _selectedGrade = 12;   // default chosen grade level
  bool _isLoading = false;   // loading states during async calls
  String? _errorMessage;     // dynamic inline error validation tracker
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Multi-language localizations matching original design language & themes
  String _local(String key) {
    final translations = {
      'en': {
        'title': 'Create Account',
        'title_login': 'Welcome Back!',
        'subtitle': 'Join Smart X Academy and boost your grades',
        'subtitle_login': 'Log in to continue your learning journey',
        'field_fullname': 'Full Name',
        'field_email': 'Email Address',
        'field_phone': 'Phone Number',
        'field_password': 'Password',
        'field_grade': 'Grade Level',
        'btn_register': 'Create Account',
        'btn_login': 'Log In',
        'already_have_account': 'Already have an account? ',
        'dont_have_account': "Don't have an account? ",
        'terms_text': 'By registering, you agree to our ',
      },
      'am': {
        'title': 'መለያ ይፍጠሩ',
        'title_login': 'እንኳን ደህና መጡ!',
        'subtitle': 'ስማርት ኤክስ አካዳሚን በመቀላቀል ውጤትዎን ያሻሽሉ',
        'subtitle_login': 'የትምህርት ጉዞዎን ለመቀጠል ይግቡ',
        'field_fullname': 'ሙሉ ስም',
        'field_email': 'የኢሜል አድራሻ',
        'field_phone': 'ስልክ ቁጥር',
        'field_password': 'የይለፍ ቃል',
        'field_grade': 'የክፍል ደረጃ',
        'btn_register': 'መለያ ፍጠር',
        'btn_login': 'ይግቡ',
        'already_have_account': 'ቀድሞ መለያ አለዎት? ',
        'dont_have_account': "መለያ የለዎትም? ",
        'terms_text': 'በመመዝገብዎ፣ በሚከተሉት ደንቦች ይስማማሉ ',
      }
    };

    return translations[widget.languageCode]?[key] ?? translations['en']![key]!;
  }

  // Clear inputs & errors on mode flip
  void _resetInputStates() {
    setState(() {
      _errorMessage = null;
      _passwordController.clear();
    });
  }

  // Floating customizable SnackBar helper
  void _showFloatingSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Execute Supabase Registration with direct verification free flow
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String fullName = _fullNameController.text.trim();
      final String email = _emailController.text.trim();
      final String phone = _phoneController.text.trim();
      final String password = _passwordController.text;

      // Register with Supabase and write profile data
      await _authService.signUpStudent(
        fullName: fullName,
        email: email,
        phoneNumber: phone,
        grade: _selectedGrade,
        password: password,
      );

      setState(() {
        _isLoading = false;
      });

      _showFloatingSnackBar("Account created successfully! Welcome to Smart X!", isError: false);
      _navigateToHome();

    } catch (e) {
      debugPrint("Registration error: $e");
      String errMsg = "An error occurred during registration. Please try again.";
      if (e.toString().contains("already registered") || e.toString().contains("User already exists")) {
        errMsg = "This email is already registered. Please login instead.";
      } else if (e.toString().contains("network") || e.toString().contains("SocketException")) {
        errMsg = "Connection issue. Please check your internet connection.";
      } else {
        errMsg = e.toString().replaceAll("Exception: ", "").replaceAll("AuthException: ", "");
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errMsg;
      });
      _showFloatingSnackBar(errMsg, isError: true);
    }
  }

  // Execute Supabase Password Log In
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      // Authenticate with Supabase Auth
      await _authService.loginStudent(
        email: email,
        password: password,
      );

      setState(() {
        _isLoading = false;
      });

      _showFloatingSnackBar("Logged in successfully! Welcome back!", isError: false);
      _navigateToHome();

    } catch (e) {
      debugPrint("Login error: $e");
      String errMsg = "Invalid email or password. Please try again.";
      if (e.toString().contains("Invalid login credentials")) {
        errMsg = "Invalid email or password. Please check your credentials.";
      } else if (e.toString().contains("network") || e.toString().contains("SocketException")) {
        errMsg = "Network error. Please connect to the internet.";
      } else {
        errMsg = e.toString().replaceAll("Exception: ", "").replaceAll("AuthException: ", "");
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errMsg;
      });
      _showFloatingSnackBar(errMsg, isError: true);
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          isDarkMode: widget.isDarkMode,
          languageCode: widget.languageCode,
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
    );
  }

  // UI input container styles
  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0, bottom: 6.0, top: 12.0),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child, required bool isDark}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFD2D6DC),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color outerBgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final Color navyColor = const Color(0xFF0D2353);

    final Widget mainBody = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: outerBgColor,
        image: DecorationImage(
          image: const AssetImage('assets/images/education_bg_pattern.png'),
          repeat: ImageRepeat.repeat,
          opacity: isDark ? 0.02 : 0.08,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildFormView(isDark, navyColor),
              ),
            ),
            if (!widget.embedInTab)
              _buildBottomNavigationBar(isDark, navyColor),
          ],
        ),
      ),
    );

    if (widget.embedInTab) {
      return mainBody;
    }

    return Scaffold(
      backgroundColor: outerBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : navyColor, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          _isLoginForm ? _local('title_login') : _local('title'),
          style: TextStyle(
            fontSize: 19.0,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : navyColor,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isLoginForm = !_isLoginForm;
                _resetInputStates();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isLoginForm ? 'Register' : 'Log In',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.0,
                ),
              ),
            ),
          )
        ],
      ),
      body: mainBody,
    );
  }

  // Form Field layout
  Widget _buildFormView(bool isDark, Color navyColor) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centered Header Branding
            Center(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                      border: Border.all(
                        color: const Color(0xFF1E88E5).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isLoginForm ? Icons.lock_person_rounded : Icons.person_add_rounded,
                      color: const Color(0xFF1E88E5),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLoginForm ? _local('title_login') : _local('title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : navyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoginForm ? _local('subtitle_login') : _local('subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Full Name input (sign-up only)
            if (!_isLoginForm) ...[
              CustomTextField(
                label: _local('field_fullname'),
                hintText: 'Abebe Bekele',
                controller: _fullNameController,
                isDark: isDark,
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: isDark ? Colors.white70 : navyColor,
                  size: 20,
                ),
                validator: (val) {
                  if (!_isLoginForm && (val == null || val.trim().isEmpty)) {
                    return 'Full Name is required';
                  }
                  return null;
                },
              ),
            ],

            // 2. Email Address input (both login and register)
            CustomTextField(
              label: _local('field_email'),
              hintText: 'abebe@smartx.com',
              controller: _emailController,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email Address is required';
                }
                final bool emailValid = RegExp(
                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
                ).hasMatch(val.trim());
                if (!emailValid) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            // 3. Phone Number input (sign-up only)
            if (!_isLoginForm) ...[
              CustomPhoneField(
                label: _local('field_phone'),
                hintText: '0911223344',
                controller: _phoneController,
                isDark: isDark,
                validator: (val) {
                  if (!_isLoginForm && (val == null || val.trim().isEmpty)) {
                    return 'Phone Number is required';
                  }
                  return null;
                },
              ),
            ],

            // 4. DropdownButtonFormField for Grade Level (sign-up only)
            if (!_isLoginForm) ...[
              _buildLabel(_local('field_grade'), isDark),
              _buildFieldContainer(
                isDark: isDark,
                child: DropdownButtonFormField<int>(
                  value: _selectedGrade,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : navyColor),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.school_outlined,
                      color: isDark ? Colors.white70 : navyColor,
                      size: 20,
                    ),
                  ),
                  items: [9, 10, 11, 12].map((grade) {
                    return DropdownMenuItem<int>(
                      value: grade,
                      child: Text('Grade $grade'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGrade = val;
                      });
                    }
                  },
                ),
              ),
            ],

            // 5. Password field (both login and register)
            CustomTextField(
              label: _local('field_password'),
              hintText: '••••••••',
              controller: _passwordController,
              isDark: isDark,
              obscureText: !_isPasswordVisible,
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: isDark ? Colors.white70 : navyColor,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.white54 : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Password is required';
                }
                if (val.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Inline validation error container preview
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red[500]!.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[500]!.withOpacity(0.25), width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Primary Log In or Register Authentication button
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF133B61), Color(0xFF0B1F40)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: navyColor.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: _isLoginForm ? _handleLogin : _handleRegister,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _isLoginForm ? _local('btn_login') : _local('btn_register'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            // Switch option link
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isLoginForm = !_isLoginForm;
                    _resetInputStates();
                  });
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _isLoginForm ? _local('dont_have_account') : _local('already_have_account'),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: _isLoginForm ? 'Register Now' : 'Log In',
                        style: TextStyle(
                          color: isDark ? Colors.blueAccent : navyColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Legal Terms
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _local('terms_text'),
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: isDark ? Colors.blueAccent : navyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual Bottom Navigation Bar to mimic application layout constraints
  Widget _buildBottomNavigationBar(bool isDark, Color navyColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(38.0),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38.0),
          child: BottomNavigationBar(
            currentIndex: 4,
            elevation: 0,
            onTap: (index) {
              Navigator.of(context).pop();
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFF1E88E5),
            unselectedItemColor: isDark ? Colors.white60 : Colors.black45,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 24, color: isDark ? Colors.white60 : Colors.black45),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined, size: 23, color: isDark ? Colors.white60 : Colors.black45),
                label: 'Offline',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_box_outlined, size: 23, color: isDark ? Colors.white60 : Colors.black45),
                label: 'Quizzes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined, size: 23, color: isDark ? Colors.white60 : Colors.black45),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 22, color: navyColor),
                ),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
