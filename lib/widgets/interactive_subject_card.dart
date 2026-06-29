import 'package:flutter/material.dart';

// Reusable animated 3D Center-Aligned Bento Card
class InteractiveSubjectCard extends StatefulWidget {
  final String amTitle;
  final String enTitle;
  final Color color;
  final Widget illustration;
  final bool isLight;
  final Color gradeColor;
  final String languageCode;
  final int grade;
  final String btnText;
  final VoidCallback onTap;

  const InteractiveSubjectCard({
    super.key,
    required this.amTitle,
    required this.enTitle,
    required this.color,
    required this.illustration,
    required this.isLight,
    required this.gradeColor,
    required this.languageCode,
    required this.grade,
    required this.btnText,
    required this.onTap,
  });

  @override
  State<InteractiveSubjectCard> createState() => _InteractiveSubjectCardState();
}

class _InteractiveSubjectCardState extends State<InteractiveSubjectCard> with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _scale = 1.0;
  late AnimationController _levitateController;

  @override
  void initState() {
    super.initState();
    _levitateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _levitateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _levitateController,
      builder: (context, child) {
        final double pulse = _levitateController.value;
        final double floatOffsetY = (pulse - 0.5) * 5.0; // 5px float height
        final double autoTilt = (pulse - 0.5) * 0.015;

        return Listener(
          onPointerDown: (event) {
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final Offset localPos = box.globalToLocal(event.position);
            final double midX = box.size.width / 2;
            final double midY = box.size.height / 2;
            setState(() {
              _scale = 0.94;
              _tiltY = ((localPos.dx - midX) / midX) * 0.08;
              _tiltX = -((localPos.dy - midY) / midY) * 0.08;
            });
          },
          onPointerMove: (event) {
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final Offset localPos = box.globalToLocal(event.position);
            final double midX = box.size.width / 2;
            final double midY = box.size.height / 2;
            setState(() {
              _tiltY = ((localPos.dx - midX) / midX) * 0.08;
              _tiltX = -((localPos.dy - midY) / midY) * 0.08;
            });
          },
          onPointerUp: (event) {
            setState(() {
              _scale = 1.0;
              _tiltX = 0.0;
              _tiltY = 0.0;
            });
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // 3D Perspective Depth
                ..translate(0.0, floatOffsetY) // Levitation float offset
                ..scale(_scale)
                ..rotateX(_tiltX)
                ..rotateY(_tiltY + autoTilt),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.isLight ? Colors.white : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: widget.isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isLight ? 0.04 : 0.16),
                    blurRadius: 16.0,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Center premium vector illustration container with a subtle background shade
                    Container(
                      height: 38.0,
                      width: 38.0,
                      padding: const EdgeInsets.all(7.0),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: widget.illustration,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    // Center aligned subject header title
                    Text(
                      widget.languageCode == 'en' ? widget.enTitle : widget.amTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        color: widget.isLight ? const Color(0xFF0F172A) : Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    // English / Grade level description subtitle
                    Text(
                      widget.languageCode == 'en'
                          ? 'Grade ${widget.grade}'
                          : 'ክፍል ${widget.grade}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: widget.isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Pill button styled with a compact, beautiful rounded pill
                    Container(
                      width: 95.0,
                      height: 26.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF52C29F), // Vibrant mint teal
                            widget.color, // Subject custom color
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(100.0), // Fully rounded pill-shaped corners
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.18),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.btnText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          const Icon(
                            Icons.chevron_right, // Required chevron_right arrow icon
                            color: Colors.white,
                            size: 11.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
