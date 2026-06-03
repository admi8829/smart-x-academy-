import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'quiz_screen.dart'; // From prompt

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late YoutubePlayerController _ytController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(
      initialVideoId: 'FRjnr4UAhNk',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = !widget.isDarkMode;
    Color bgColor = isLight ? const Color(0xFFF3F5F9) : const Color(0xFF111827);
    Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.menu,
                color: textColor,
                size: 28,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }
        ),
        title: Text(
          "Smart X Academy",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: textColor,
              size: 24,
            ),
            onPressed: widget.onToggleTheme,
          ),
          GestureDetector(
            onTap: widget.onToggleLanguage,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 4.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language,
                      size: 20,
                      color: textColor,
                    ),
                    Text(
                      "EN/አማ",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: _buildBody(isLight, textColor),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isLight ? Colors.white : const Color(0xFF1F2937),
          selectedItemColor: const Color(0xFF1E88E5),
          unselectedItemColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isLight, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YouTube Tutorial Banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15.0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _isPlaying
                          ? YoutubePlayer(
                              controller: _ytController,
                              showVideoProgressIndicator: true,
                            )
                          : Stack(
                              children: [
                                // Placeholder Image
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                    image: const DecorationImage(
                                      image: NetworkImage('https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600&auto=format&fit=crop&q=80'), // Fallback background
                                      fit: BoxFit.cover,
                                    )
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ),
                                // Text inside video placeholder
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome to\nSmart X Academy!\nHow to Use\nthe App",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // YouTube Play Button
                                Positioned.fill(
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isPlaying = true;
                                        });
                                        _ytController.play();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Watch tutorial: Getting started with the Smart X",
                  style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28.0),

          // Headings
          Text(
            "Explore Your Learning Path",
            style: GoogleFonts.poppins(
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            "Select your grade to access courses and resources.",
            style: GoogleFonts.poppins(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 20.0),

          // 2x2 Grid for Grades
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.85,
            children: [
              // Grade 9
              _buildGradeCard(
                gradeTitle: "Grade 9",
                subtitle: "Start Your\nJourney!",
                buttonColor: const Color(0xFF1E88E5), // Blue
                bgColor: const Color(0xFFE3F2FD),
                bgDarkColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                iconWidget: _buildDecorativeIcon(
                  baseIcon: Icons.auto_stories,
                  color: const Color(0xFF1E88E5),
                ),
                isLight: isLight,
                textColor: textColor,
              ),
              // Grade 10
              _buildGradeCard(
                gradeTitle: "Grade 10",
                subtitle: "Expand your\nknowledge!",
                buttonColor: const Color(0xFF10B981), // Green
                bgColor: const Color(0xFFD1FAE5),
                bgDarkColor: const Color(0xFF064E3B).withOpacity(0.3),
                iconWidget: _buildDecorativeIcon(
                  baseIcon: Icons.shield_outlined,
                  color: const Color(0xFF10B981),
                ),
                isLight: isLight,
                textColor: textColor,
              ),
              // Grade 11
              _buildGradeCard(
                gradeTitle: "Grade 11",
                subtitle: "Prepare for\nexcellence!",
                buttonColor: const Color(0xFFF59E0B), // Orange
                bgColor: const Color(0xFFFEF3C7),
                bgDarkColor: const Color(0xFF78350F).withOpacity(0.3),
                iconWidget: _buildDecorativeIcon(
                  baseIcon: Icons.satellite_alt_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                isLight: isLight,
                textColor: textColor,
              ),
              // Grade 12
              _buildGradeCard(
                gradeTitle: "Grade 12",
                subtitle: "Achieve your\ngoals!",
                buttonColor: const Color(0xFFA855F7), // Purple
                bgColor: const Color(0xFFF3E8FF),
                bgDarkColor: const Color(0xFF4C1D95).withOpacity(0.3),
                iconWidget: _buildDecorativeIcon(
                  baseIcon: Icons.school_outlined,
                  color: const Color(0xFFA855F7),
                ),
                isLight: isLight,
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 30.0),

          // Coming Soon Section
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildComingSoonItem("Math", Icons.calculate_outlined, const Color(0xFF3B82F6), isLight, textColor),
                _buildComingSoonItem("Physics", Icons.science_outlined, const Color(0xFFA855F7), isLight, textColor),
                _buildComingSoonItem("Biology", Icons.biotech_outlined, const Color(0xFF10B981), isLight, textColor),
                _buildComingSoonItem("History", Icons.menu_book, const Color(0xFFF59E0B), isLight, textColor),
              ],
            ),
          ),
          
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildGradeCard({
    required String gradeTitle,
    required String subtitle,
    required Color buttonColor,
    required Color bgColor,
    required Color bgDarkColor,
    required Widget iconWidget,
    required bool isLight,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // Top half soft background color
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 90,
            child: Container(
              decoration: BoxDecoration(
                color: isLight ? bgColor : bgDarkColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    iconWidget,
                  ],
                ),
                const Spacer(),
                Text(
                  gradeTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QuizScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Start Course",
                      style: GoogleFonts.poppins(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon({required IconData baseIcon, required Color color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base Icon
        Icon(
          baseIcon,
          size: 40,
          color: color.withOpacity(0.8),
        ),
        // A+ Badge overlay
        Positioned(
          right: -5,
          top: -5,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              "A+",
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildComingSoonItem(String title, IconData icon, Color color, bool isLight, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: 20.0),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8.0,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              Positioned(
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Coming Soon",
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
