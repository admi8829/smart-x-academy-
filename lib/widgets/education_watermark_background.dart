import 'package:flutter/material.dart';

class WatermarkPainter extends CustomPainter {
  final bool isDarkMode;
  WatermarkPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Choose beautiful education icons matching various subjects
    final List<IconData> icons = [
      Icons.school_outlined,
      Icons.book_outlined,
      Icons.science_outlined,
      Icons.calculate_outlined,
      Icons.psychology_outlined,
      Icons.history_edu_outlined,
      Icons.biotech_outlined,
      Icons.functions_outlined,
      Icons.lightbulb_outline,
    ];

    final double stepX = 130.0;
    final double stepY = 130.0;
    final double opacity = isDarkMode ? 0.012 : 0.024; // Subtle, elegant watermark
    final textColor = isDarkMode ? Colors.white : const Color(0xFF475569);

    for (double y = 50; y < size.height; y += stepY) {
      int indexRow = (y / stepY).floor();
      for (double x = 50; x < size.width; x += stepX) {
        int indexCol = (x / stepX).floor();
        final icon = icons[(indexRow + indexCol) % icons.length];
        
        textPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 32,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: textColor.withValues(alpha: opacity),
          ),
        );
        textPainter.layout();
        
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(0.24); // Beautiful light visual tilt!
        
        // Centered paint offset
        textPainter.paint(
          canvas, 
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EducationWatermarkBackground extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;

  const EducationWatermarkBackground({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDarkMode 
        ? const Color(0xFF0F172A) // Rich deep slate dark background
        : const Color(0xFFF1F5F9); // Beautiful light grayish-blue background!

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WatermarkPainter(isDarkMode: isDarkMode),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
