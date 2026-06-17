import 'package:flutter/material.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

const List<Country> countriesList = [
  Country(name: "Ethiopia", code: "ET", dialCode: "+251", flag: "🇪🇹"),
  Country(name: "United States", code: "US", dialCode: "+1", flag: "🇺🇸"),
  Country(name: "United Kingdom", code: "GB", dialCode: "+44", flag: "🇬🇧"),
  Country(name: "Canada", code: "CA", dialCode: "+1", flag: "🇨🇦"),
  Country(name: "Kenya", code: "KE", dialCode: "+254", flag: "🇰🇪"),
  Country(name: "Djibouti", code: "DJ", dialCode: "+253", flag: "🇩🇯"),
  Country(name: "Sudan", code: "SD", dialCode: "+249", flag: "🇸🇩"),
  Country(name: "Eritrea", code: "ER", dialCode: "+291", flag: "🇪🇷"),
  Country(name: "Somalia", code: "SO", dialCode: "+252", flag: "🇸🇴"),
  Country(name: "United Arab Emirates", code: "AE", dialCode: "+971", flag: "🇦🇪"),
  Country(name: "Saudi Arabia", code: "SA", dialCode: "+966", flag: "🇸🇦"),
  Country(name: "South Africa", code: "ZA", dialCode: "+27", flag: "🇿🇦"),
  Country(name: "Nigeria", code: "NG", dialCode: "+234", flag: "🇳🇬"),
  Country(name: "Germany", code: "DE", dialCode: "+49", flag: "🇩🇪"),
  Country(name: "India", code: "IN", dialCode: "+91", flag: "🇮🇳"),
  Country(name: "Australia", code: "AU", dialCode: "+61", flag: "🇦🇺"),
];

class CustomPhoneField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isDark;
  final String? Function(String?)? validator;
  final ValueChanged<Country>? onCountryChanged;

  const CustomPhoneField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.isDark,
    this.validator,
    this.onCountryChanged,
  });

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  Country _selectedCountry = countriesList[0]; // Ethiopia (+251) by default
  String? _errorText;

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CountryPickerSheet(
          isDark: widget.isDark,
          selectedCountry: _selectedCountry,
          onSelect: (country) {
            setState(() {
              _selectedCountry = country;
            });
            if (widget.onCountryChanged != null) {
              widget.onCountryChanged!(country);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Label
        if (widget.label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2.0, bottom: 6.0, top: 12.0),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],

        // 2. TextFormField Container (Outer container bounds)
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _errorText != null
                  ? const Color(0xFFEF4444) // Clean red for errors
                  : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFD2D6DC)),
              width: _errorText != null ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _errorText != null
                    ? const Color(0xFFEF4444).withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.isDark ? Colors.white38 : Colors.grey[400],
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: GestureDetector(
                onTap: _showCountryPicker,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flag Emoji
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      // Dial Code
                      Text(
                        _selectedCountry.dialCode,
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: widget.isDark ? Colors.white54 : Colors.grey[600],
                        size: 20,
                      ),
                      // Sleek vertical dividing line separator
                      Container(
                        height: 20,
                        width: 1.2,
                        color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.only(left: 8),
                      ),
                    ],
                  ),
                ),
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            validator: (val) {
              final err = widget.validator?.call(val);
              if (err != _errorText) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _errorText = err;
                    });
                  }
                });
              }
              return err;
            },
          ),
        ),

        // 3. Clean Error message positioned perfectly below the container
        if (_errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6.0, top: 6.0, bottom: 4.0),
            child: Text(
              _errorText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final bool isDark;
  final Country selectedCountry;
  final ValueChanged<Country> onSelect;

  const _CountryPickerSheet({
    required this.isDark,
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _searchQuery = "";
  late List<Country> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _filteredCountries = countriesList;
  }

  void _filterCountries(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredCountries = countriesList;
      } else {
        _filteredCountries = countriesList.where((country) {
          final nameMatch = country.name.toLowerCase().contains(query.toLowerCase());
          final codeMatch = country.dialCode.contains(query);
          return nameMatch || codeMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final headerTextColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final inputBgColor = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          Text(
            "Select Country",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: headerTextColor,
            ),
          ),
          const SizedBox(height: 14),

          // Search Field inside Sheet
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: _filterCountries,
              style: TextStyle(color: headerTextColor, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Search country or country code...",
                hintStyle: TextStyle(
                  color: widget.isDark ? Colors.white38 : Colors.grey[500],
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: widget.isDark ? Colors.white54 : Colors.grey[600],
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Country list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _filteredCountries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: widget.isDark ? Colors.white38 : Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No countries found",
                          style: TextStyle(
                            color: widget.isDark ? Colors.white54 : Colors.grey[600],
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected = country.code == widget.selectedCountry.code;
                      return ListTile(
                        onTap: () {
                          widget.onSelect(country);
                          Navigator.pop(context);
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          country.name,
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.black : FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country.dialCode,
                              style: TextStyle(
                                color: widget.isDark ? Colors.white70 : Colors.grey[700],
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 10),
                              Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 18,
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
