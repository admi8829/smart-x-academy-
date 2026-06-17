import 'package:flutter/material.dart';

class PerformanceSubjectData {
  final String subjectName;
  final String subjectCode;
  final int scorePercentage;
  final IconData icon;

  const PerformanceSubjectData({
    required this.subjectName,
    required this.subjectCode,
    required this.scorePercentage,
    required this.icon,
  });
}

class PerformanceBarChart extends StatefulWidget {
  final List<PerformanceSubjectData>? data;
  final bool isDark;
  final String title;
  final String subtitle;

  const PerformanceBarChart({
    super.key,
    this.data,
    required this.isDark,
    this.title = "Performance Analytics 📉",
    this.subtitle = "Based on recent practice achievements",
  });

  @override
  State<PerformanceBarChart> createState() => _PerformanceBarChartState();
}

class _PerformanceBarChartState extends State<PerformanceBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Establish custom colors inspired by web Chart.js
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final headerColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final trackColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final shadowColor = widget.isDark 
        ? Colors.black.withOpacity(0.3) 
        : const Color(0xFF0F172A).withOpacity(0.06);

    // Default subjects if none provided
    final subjects = widget.data ?? const [
      PerformanceSubjectData(subjectName: 'Biology', subjectCode: 'BIO', scorePercentage: 84, icon: Icons.biotech),
      PerformanceSubjectData(subjectName: 'Physics', subjectCode: 'PHY', scorePercentage: 68, icon: Icons.bolt),
      PerformanceSubjectData(subjectName: 'Chemistry', subjectCode: 'CHE', scorePercentage: 74, icon: Icons.science_outlined),
      PerformanceSubjectData(subjectName: 'Mathematics', subjectCode: 'MAT', scorePercentage: 90, icon: Icons.calculate_outlined),
      PerformanceSubjectData(subjectName: 'Civics', subjectCode: 'CIV', scorePercentage: 80, icon: Icons.gavel_rounded),
      PerformanceSubjectData(subjectName: 'English', subjectCode: 'ENG', scorePercentage: 88, icon: Icons.translate_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: headerColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: subtextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF)).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  "Global Rank #128",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Horizontal scrollable/neatly spaced row of vertical bars
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(subjects.length, (index) {
                        final item = subjects[index];
                        final isHovered = _hoveredIndex == index;

                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _hoveredIndex = _hoveredIndex == index ? null : index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Floating Score Indicator above the track
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: 1.0,
                                    child: Transform.translate(
                                      offset: const Offset(0, 2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isHovered 
                                              ? (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF))
                                              : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "${item.scorePercentage}%",
                                          style: TextStyle(
                                            color: isHovered 
                                                ? Colors.white 
                                                : (widget.isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Bar Column Container (Light gray background track representing 100%)
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // Track (100% capacity)
                                        Container(
                                          width: 22,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: trackColor,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                          ),
                                        ),
                                        // Active Bar filled inside with gradient
                                        AnimatedBuilder(
                                          animation: _scaleAnimation,
                                          builder: (context, child) {
                                            final double animatedHeight = 120 * 
                                                (item.scorePercentage / 100) * 
                                                _scaleAnimation.value;
                                            return Container(
                                              width: 22,
                                              height: animatedHeight,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: widget.isDark
                                                      ? [const Color(0xFF0284C7), const Color(0xFF38BDF8)]
                                                      : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  topRight: Radius.circular(8),
                                                ),
                                                boxShadow: isHovered ? [
                                                  BoxShadow(
                                                    color: (widget.isDark 
                                                        ? const Color(0xFF38BDF8) 
                                                        : const Color(0xFF3B82F6)).withOpacity(0.4),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  )
                                                ] : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Subject Code label
                                  Text(
                                    item.subjectCode,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: isHovered 
                                          ? (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF))
                                          : subtextColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // Mini Icon under text
                                  Icon(
                                    item.icon,
                                    size: 13,
                                    color: isHovered 
                                        ? (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF))
                                        : subtextColor.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
