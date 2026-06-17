import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;

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
          // Content cushioning is set carefully
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
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
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              // Setup custom clean error style that fits perfectly below the input box container without stretching it
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
                color: Color(0xFFEF4444), // Crimson red
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
