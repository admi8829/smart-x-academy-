import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final String profileId = 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
      
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.languageCode == 'en'
                        ? 'Registration failed. Please check your network and try again.'
                        : 'ምዝገባው አልተሳካም። እባክዎ ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።',
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

  Future<void> _handleCancel() async {
    debugPrint("User cancelled registration overlay.");
    if (mounted) {
      Navigator.of(context).pop('cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = !widget.isDarkMode;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lock/Premium Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_open_rounded,
                            color: widget.primaryColor,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header Message
                      Text(
                        widget.languageCode == 'en' ? 'Unlock Premium Material' : 'ፕሪሚየም ይዘቶችን ይክፈቱ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.languageCode == 'en'
                            ? 'Register once to unlock access to all advanced prep modules.'
                            : 'ሁሉንም የላቁ ይዘቶች ለመክፈት አንድ ጊዜ ይመዝገቡ።',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Full Name Field
                      _buildFieldLabel(widget.languageCode == 'en' ? 'Full Name *' : 'ሙሉ ስም *', isLight),
                      _buildFieldContainer(
                        isLight: isLight,
                        child: TextFormField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.languageCode == 'en' ? 'e.g. Abebe Bekele' : 'ምሳሌ: አበበ በቀለ',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.person_outline_rounded, color: widget.primaryColor, size: 20),
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

                      // Phone Number Field with Country Code Selection
                      _buildFieldLabel(widget.languageCode == 'en' ? 'Phone Number *' : 'ስልክ ቁጥር *', isLight),
                      _buildFieldContainer(
                        isLight: isLight,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCountryCode,
                                  dropdownColor: cardColor,
                                  icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                  items: countryCodes.map((country) {
                                    return DropdownMenuItem<String>(
                                      value: country['code'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(country['flag']!, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 4),
                                          Text(country['code']!, style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isLoading
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedCountryCode = val;
                                            });
                                          }
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '912345678',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: widget.primaryColor, size: 20),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grade Dropdown
                      _buildFieldLabel(widget.languageCode == 'en' ? 'Grade *' : 'የክፍል ደረጃ *', isLight),
                      _buildFieldContainer(
                        isLight: isLight,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedGrade,
                            isExpanded: true,
                            dropdownColor: cardColor,
                            icon: Icon(Icons.arrow_drop_down, color: widget.primaryColor),
                            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                            items: [9, 10, 11, 12].map((g) {
                              return DropdownMenuItem<int>(
                                value: g,
                                child: Row(
                                  children: [
                                    Icon(Icons.school_outlined, color: widget.primaryColor, size: 18),
                                    const SizedBox(width: 10),
                                    Text(widget.languageCode == 'en' ? 'Grade $g' : 'ክፍል $g'),
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

                      // Email Field
                      _buildFieldLabel(widget.languageCode == 'en' ? 'Email Address *' : 'የኢሜል አድራሻ *', isLight),
                      _buildFieldContainer(
                        isLight: isLight,
                        child: TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.languageCode == 'en' ? 'e.g. email@example.com' : 'ምሳሌ: email@example.com',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.mail_outline_rounded, color: widget.primaryColor, size: 20),
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
                      const SizedBox(height: 36),

                      // Register Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
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
                                widget.languageCode == 'en' ? 'Register Now' : 'አሁን ይመዝገቡ',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Cancel Bottom Button
                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          widget.languageCode == 'en' ? 'Cancel' : 'ሰርዝ',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
