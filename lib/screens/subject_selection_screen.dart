import 'package:flutter/material.dart';
import '../main.dart';
import 'unit_selection_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final int grade;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const SubjectSelectionScreen({
    super.key,
    required this.grade,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  // Translate title helper dynamically retrieving the language code
  String _local(String key, String languageCode) {
    final Map<String, Map<String, String>> localized = {
      'en': {
        'title': 'GRADE ${widget.grade}: SUBJECTS',
        'subtitle': 'Select your subject to access courses and resources.',
        'btn_start': 'START',
      },
      'am': {
        'title': 'ክፍል ${widget.grade}: የትምህርት ምድቦች',
        'subtitle': 'የትምህርት ዓይነቶችዎን ለመምረጥ ከዚህ በታች ይጫኑ።',
        'btn_start': 'ጀምር',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  // Define subjects with Amharic & English representation plus custom coloring/drawing style
  List<Map<String, dynamic>> _getSubjects() {
    return [
      {
        'id': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'enTitle': 'Mathematics',
        'color': const Color(0xFF0084FF),
        'illustration': const _DraftingGeometryWidget(),
      },
      {
        'id': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'enTitle': 'Biology',
        'color': const Color(0xFF2E7D32),
        'illustration': const _CellBiologyWidget(),
      },
      {
        'id': 'Physics',
        'amTitle': 'ፊዚክስ',
        'enTitle': 'Physics',
        'color': const Color(0xFFE53935),
        'illustration': const _AtomPhysicsWidget(),
      },
      {
        'id': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'enTitle': 'Chemistry',
        'color': const Color(0xFFEF6C00),
        'illustration': const _ChemistryFlaskWidget(),
      },
      {
        'id': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'enTitle': 'Geography',
        'color': const Color(0xFF8E24AA),
        'illustration': const _WorldMapGeographyWidget(),
      },
      {
        'id': 'History',
        'amTitle': 'ታሪክ',
        'enTitle': 'History',
        'color': const Color(0xFFF5B041),
        'illustration': const _AksumObeliskWidget(),
      },
      {
        'id': 'Civics',
        'amTitle': 'ዜግነት',
        'enTitle': 'Civics',
        'color': const Color(0xFF1E88E5),
        'illustration': const _CivicsGavelWidget(),
      },
      {
        'id': 'Agriculture',
        'amTitle': 'ግብርና',
        'enTitle': 'Agriculture',
        'color': const Color(0xFF8D6E63),
        'illustration': const _AgricultureSproutWidget(),
      },
    ];
  }

  void _navigateToUnitSelectionScreen(Map<String, dynamic> subject, AppStateProvider appState) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitSelectionScreen(
          grade: widget.grade,
          subjectId: subject['id'],
          enTitle: subject['enTitle'],
          amTitle: subject['amTitle'],
          color: subject['color'],
          icon: subject['illustration'],
          isDarkMode: appState.isDarkMode,
          languageCode: appState.languageCode,
          onToggleTheme: appState.onToggleTheme,
          onToggleLanguage: appState.onToggleLanguage,
        ),
      ),
    );
  }

  Color _getGradeColor() {
    switch (widget.grade) {
      case 9:
        return const Color(0xFF0084FF); // Blue
      case 10:
        return const Color(0xFF10B981); // Emerald Green
      case 11:
        return const Color(0xFFF59E0B); // Amber
      case 12:
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF0084FF);
    }
  }

  Widget _buildLanguageSegment({
    required String langCode,
    required String label,
    required bool isSelected,
    required bool isLight,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 8.0,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
            color: isSelected
                ? Colors.white
                : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically retrieve the latest real-time application values to bypass stale attributes
    final appState = AppStateProvider.of(context);
    final bool isDark = appState.isDarkMode;
    final bool isLight = !isDark;
    final String currentLang = appState.languageCode;
    final subjects = _getSubjects();
    final Color gradeColor = _getGradeColor();

    // Matching responsive top UI alignment and clean off-white platform canvas background
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headerTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _local('title', currentLang),
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Elegant theme mode toggles
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appState.onToggleTheme,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/education_bg_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: isLight ? 0.09 : 0.03,
            colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Beautiful descriptive subtitle
                Text(
                  _local('subtitle', currentLang),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                
                const SizedBox(height: 20.0),

                // Redesigned 2-column GridView subject selector matching request of 100% high-fidelity bento design
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return _InteractiveSubjectCard(
                      amTitle: subject['amTitle'],
                      enTitle: subject['enTitle'],
                      color: subject['color'],
                      illustration: subject['illustration'],
                      isLight: isLight,
                      gradeColor: gradeColor,
                      languageCode: currentLang,
                      grade: widget.grade,
                      btnStartText: _local('btn_start', currentLang),
                      onTap: () => _navigateToUnitSelectionScreen(subject, appState),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Redesigned 3D Center-Aligned Bento Card
class _InteractiveSubjectCard extends StatefulWidget {
  final String amTitle;
  final String enTitle;
  final Color color;
  final Widget illustration;
  final bool isLight;
  final Color gradeColor;
  final String languageCode;
  final int grade;
  final String btnStartText;
  final VoidCallback onTap;

  const _InteractiveSubjectCard({
    required this.amTitle,
    required this.enTitle,
    required this.color,
    required this.illustration,
    required this.isLight,
    required this.gradeColor,
    required this.languageCode,
    required this.grade,
    required this.btnStartText,
    required this.onTap,
  });

  @override
  State<_InteractiveSubjectCard> createState() => _InteractiveSubjectCardState();
}

class _InteractiveSubjectCardState extends State<_InteractiveSubjectCard> with SingleTickerProviderStateMixin {
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
                            widget.btnStartText,
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

// ============================================================================
// HIGH-FIDELITY VECTOR ILLUSTRATIONS IMPLEMENTED VIA CUSTOMPAINTERS
// ============================================================================

// 1. Mathematics Geometry Vector Widget
class _DraftingGeometryWidget extends StatelessWidget {
  const _DraftingGeometryWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _DraftingGeometryPainter(),
      ),
    );
  }
}

class _DraftingGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF0084FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF0084FF).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw grid/compass drafting tool representation
    // Protractor base semi-circle
    final center = Offset(size.width * 0.45, size.height * 0.55);
    final rect = Rect.fromCircle(center: center, radius: 14);
    canvas.drawArc(rect, 3.14159, 3.14159, false, linePaint);
    canvas.drawLine(Offset(center.dx - 14, center.dy), Offset(center.dx + 14, center.dy), linePaint);

    // Drafting ruler triangle line representation
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..lineTo(size.width * 0.85, size.height * 0.85)
      ..lineTo(size.width * 0.6, size.height * 0.25)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    // Dynamic compass divider outline
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.35, size.height * 0.75), linePaint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.65, size.height * 0.75), linePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.3), 3, Paint()..color = const Color(0xFF0084FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Biology Cell Vector Widget
class _CellBiologyWidget extends StatelessWidget {
  const _CellBiologyWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _CellBiologyPainter(),
      ),
    );
  }
}

class _CellBiologyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    // Main Cell body structure
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Drawing organic cell boundary
    final Path cellPath = Path();
    cellPath.moveTo(cx + 18, cy);
    cellPath.quadraticBezierTo(cx + 17, cy + 14, cx + 5, cy + 18);
    cellPath.quadraticBezierTo(cx - 15, cy + 17, cx - 18, cy - 2);
    cellPath.quadraticBezierTo(cx - 14, cy - 18, cx, cy - 18);
    cellPath.quadraticBezierTo(cx + 18, cy - 14, cx + 18, cy);
    cellPath.close();

    canvas.drawPath(cellPath, backgroundPaint);
    canvas.drawPath(cellPath, borderPaint);

    // Drawing nucleus
    final Paint nucleusPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 3, cy - 2), 6, nucleusPaint);

    // Drawing minor cell organelles / lines
    final Paint organellePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(cx + 6, cy + 6), 2.5, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawCircle(Offset(cx - 8, cy + 8), 2, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawLine(Offset(cx + 8, cy - 6), Offset(cx + 11, cy - 10), organellePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Physics Atom Vector Widget
class _AtomPhysicsWidget extends StatelessWidget {
  const _AtomPhysicsWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _AtomPhysicsPainter(),
      ),
    );
  }
}

class _AtomPhysicsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint centerPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    // Draw central nucleus proton
    canvas.drawCircle(Offset(cx, cy), 5, centerPaint);

    // Draw 3 orbiting ring ellipses
    canvas.save();
    canvas.translate(cx, cy);
    
    // Orbit 1
    canvas.rotate(0.0);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 36, height: 11), borderPaint);
    canvas.drawCircle(const Offset(18, 0), 2.5, centerPaint); // electron
    
    // Orbit 2
    canvas.rotate(1.047); // 60 degrees
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 36, height: 11), borderPaint);
    canvas.drawCircle(const Offset(-18, 0), 2.5, centerPaint); // electron

    // Orbit 3
    canvas.rotate(1.047); // 120 degrees
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 36, height: 11), borderPaint);
    canvas.drawCircle(const Offset(0, 5.5), 2.5, centerPaint); // electron

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Chemistry Flask Vector Widget
class _ChemistryFlaskWidget extends StatelessWidget {
  const _ChemistryFlaskWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _ChemistryFlaskPainter(),
      ),
    );
  }
}

class _ChemistryFlaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint linePaint = Paint()
      ..color = const Color(0xFFEF6C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFEF6C00).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Create beaker/flask path
    final flaskPath = Path()
      ..moveTo(w * 0.4, h * 0.18) // neck left
      ..lineTo(w * 0.6, h * 0.18) // neck right
      ..lineTo(w * 0.6, h * 0.38) // neck bottom-right
      ..lineTo(w * 0.85, h * 0.78) // base right
      ..quadraticBezierTo(w * 0.88, h * 0.84, w * 0.8, h * 0.84) // curve bottom-right
      ..lineTo(w * 0.2, h * 0.84) // base left
      ..quadraticBezierTo(w * 0.12, h * 0.84, w * 0.15, h * 0.78) // curve bottom-left
      ..lineTo(w * 0.4, h * 0.38) // neck bottom-left
      ..close();

    canvas.drawPath(flaskPath, fillPaint);
    canvas.drawPath(flaskPath, linePaint);

    // Beaker lip
    canvas.drawLine(Offset(w * 0.35, h * 0.18), Offset(w * 0.65, h * 0.18), linePaint);

    // Beaker orange liquid line inside
    final liquidPath = Path()
      ..moveTo(w * 0.3, h * 0.58)
      ..lineTo(w * 0.7, h * 0.58)
      ..lineTo(w * 0.8, h * 0.78)
      ..quadraticBezierTo(w * 0.82, h * 0.84, w * 0.78, h * 0.84)
      ..lineTo(w * 0.22, h * 0.84)
      ..quadraticBezierTo(w * 0.18, h * 0.84, w * 0.2, h * 0.78)
      ..close();

    canvas.drawPath(liquidPath, Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.45));

    // Dynamic rising bubbles
    canvas.drawCircle(Offset(w * 0.45, h * 0.66), 2, linePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.52), 3, Paint()..color = const Color(0xFFEF6C00));
    canvas.drawCircle(Offset(w * 0.36, h * 0.74), 1.5, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 5. Geography Map Vector Widget
class _WorldMapGeographyWidget extends StatelessWidget {
  const _WorldMapGeographyWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _WorldMapGeographyPainter(),
      ),
    );
  }
}

class _WorldMapGeographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    final Paint mapPaint = Paint()..style = PaintingStyle.fill;

    // Draw stylized continents as connected organic shapes
    // Africa-like polygon shape
    final Path africaPath = Path()
      ..moveTo(cx - 4, cy - 8)
      ..lineTo(cx + 8, cy - 10)
      ..lineTo(cx + 10, cy - 2)
      ..lineTo(cx + 4, cy + 6)
      ..lineTo(cx - 1, cy + 12)
      ..lineTo(cx - 3, cy + 6)
      ..lineTo(cx - 8, cy + 2)
      ..lineTo(cx - 6, cy - 4)
      ..close();
    canvas.drawPath(africaPath, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.85));

    // America-like shapes
    final Path northAmerica = Path()
      ..moveTo(cx - 18, cy - 14)
      ..lineTo(cx - 10, cy - 14)
      ..lineTo(cx - 12, cy - 4)
      ..lineTo(cx - 16, cy + 2)
      ..close();
    canvas.drawPath(northAmerica, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.4));

    final Path southAmerica = Path()
      ..moveTo(cx - 16, cy + 4)
      ..lineTo(cx - 12, cy + 4)
      ..lineTo(cx - 11, cy + 12)
      ..lineTo(cx - 15, cy + 14)
      ..close();
    canvas.drawPath(southAmerica, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.6));

    // Asia/Europe shape
    final Path eurasia = Path()
      ..moveTo(cx - 2, cy - 14)
      ..lineTo(cx + 18, cy - 16)
      ..lineTo(cx + 19, cy - 6)
      ..lineTo(cx + 11, cy - 2)
      ..lineTo(cx + 4, cy - 4)
      ..close();
    canvas.drawPath(eurasia, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.5));

    // Latitude longitude visual grid circle structure
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF8E24AA).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(Offset(cx, cy), 18, gridPaint);
    canvas.drawLine(Offset(cx - 18, cy), Offset(cx + 18, cy), gridPaint); // equator
    canvas.drawLine(Offset(cx, cy - 18), Offset(cx, cy + 18), gridPaint); // meridian
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 6. History Obelisk of Aksum Vector Widget
class _AksumObeliskWidget extends StatelessWidget {
  const _AksumObeliskWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _AksumObeliskPainter(),
      ),
    );
  }
}

class _AksumObeliskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double h = size.height;

    final Paint towerPaint = Paint()
      ..color = const Color(0xFFEFAD21)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFEFAD21).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw towering monument shape (wider down, narrower up, with circular decorated apex)
    final Path tower = Path()
      ..moveTo(cx - 6, h * 0.86) // left base
      ..lineTo(cx + 6, h * 0.86) // right base
      ..lineTo(cx + 2.8, h * 0.22) // right top
      ..quadraticBezierTo(cx, h * 0.12, cx - 2.8, h * 0.22) // curved apex
      ..lineTo(cx - 6, h * 0.86) // link closing
      ..close();

    canvas.drawPath(tower, fillPaint);
    canvas.drawPath(tower, towerPaint);

    // Architectural horizontal floor notches/rows
    for (double f = 0.35; f < 0.85; f += 0.14) {
      final double y = h * f;
      final double widthHalf = 6.0 * (1.0 - (f - 0.2) * 0.4);
      canvas.drawLine(Offset(cx - widthHalf, y), Offset(cx + widthHalf, y), towerPaint);
      
      // Little window dot
      canvas.drawCircle(Offset(cx, y - 4), 1.2, Paint()..color = const Color(0xFFEFAD21));
    }

    // Heavy platform slab base
    canvas.drawLine(Offset(cx - 12, h * 0.86), Offset(cx + 12, h * 0.86), towerPaint);
    canvas.drawLine(Offset(cx - 9, h * 0.91), Offset(cx + 9, h * 0.91), towerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 7. Civics Gavel Vector Widget
class _CivicsGavelWidget extends StatelessWidget {
  const _CivicsGavelWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _CivicsGavelPainter(),
      ),
    );
  }
}

class _CivicsGavelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF1E88E5).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Drawing judge block platform
    final Path blockPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.82)
      ..lineTo(size.width * 0.55, size.height * 0.82)
      ..lineTo(size.width * 0.48, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.72)
      ..close();
    canvas.drawPath(blockPath, fillPaint);
    canvas.drawPath(blockPath, linePaint);

    // Drawing Gavel mallet tilted
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.5); // Tilt hammer

    // Gavel Head cylindrical container
    final Rect headRect = Rect.fromCenter(center: const Offset(0, -10), width: 14, height: 24);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(3)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(3)), linePaint);

    // Mallet Handle stem stick representation
    canvas.drawLine(const Offset(0, 0), const Offset(0, 22), linePaint);
    canvas.drawCircle(const Offset(0, 24), 2.5, Paint()..color = const Color(0xFF1E88E5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 8. Agriculture Sprout Vector Widget
class _AgricultureSproutWidget extends StatelessWidget {
  const _AgricultureSproutWidget();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: _AgricultureSproutPainter(),
      ),
    );
  }
}

class _AgricultureSproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;

    final Paint stemPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint leafPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    // Draw ground level soil line inside seed-brown representation
    final Paint soilPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.8), Offset(size.width * 0.85, size.height * 0.8), soilPaint);

    // Draw curved plant stem rising
    final Path stemPath = Path()
      ..moveTo(cx - 3, size.height * 0.8)
      ..quadraticBezierTo(cx - 4, size.height * 0.5, cx + 2, size.height * 0.3);
    canvas.drawPath(stemPath, stemPaint);

    // Leaf 1: Tilted Left
    final Path leafLeft = Path()
      ..moveTo(cx + 1, size.height * 0.44)
      ..quadraticBezierTo(cx - 10, size.height * 0.44, cx - 11, size.height * 0.3)
      ..quadraticBezierTo(cx, size.height * 0.28, cx + 1, size.height * 0.44)
      ..close();
    canvas.drawPath(leafLeft, leafPaint);
    canvas.drawPath(leafLeft, Paint()..color = const Color(0xFF1B5E20)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Leaf 2: Tilted Right (Higher Apex)
    final Path leafRight = Path()
      ..moveTo(cx + 2, size.height * 0.32)
      ..quadraticBezierTo(cx + 12, size.height * 0.32, cx + 13, size.height * 0.18)
      ..quadraticBezierTo(cx + 4, size.height * 0.16, cx + 2, size.height * 0.32)
      ..close();
    canvas.drawPath(leafRight, leafPaint);
    canvas.drawPath(leafRight, Paint()..color = const Color(0xFF1B5E20)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Stylized seed pod opening on ground
    final Paint seedPaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 6, size.height * 0.78), width: 8, height: 5), seedPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1, size.height * 0.79), width: 6, height: 4), seedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SubjectVectors {
  static Widget getIconForSubject(String id) {
    switch (id) {
      case 'Mathematics':
        return const _DraftingGeometryWidget();
      case 'Biology':
        return const _CellBiologyWidget();
      case 'Physics':
        return const _AtomPhysicsWidget();
      case 'Chemistry':
        return const _ChemistryFlaskWidget();
      case 'Geography':
        return const _WorldMapGeographyWidget();
      case 'History':
        return const _AksumObeliskWidget();
      case 'Civics':
        return const _CivicsGavelWidget();
      case 'Agriculture':
        return const _AgricultureSproutWidget();
      default:
        return const Icon(Icons.book);
    }
  }
}

