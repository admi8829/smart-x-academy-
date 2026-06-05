import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String duration;
  final bool isDarkMode;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.duration,
    required this.isDarkMode,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (mounted && _controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video when navigation shifts
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color textSecColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF1E88E5),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF1E88E5),
          handleColor: Color(0xFF0084FF),
        ),
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Smart X Video Lesson",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: textColor,
                  size: 22,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Link copied to clipboard! Share with classmates."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beautiful elevated Player bounds
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: AspectRatio(
                        aspectRatio: 16/9,
                        child: player,
                      ),
                    ),
                  ),

                  // Metadata Description Card below!
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: cardColor,
                      elevation: 4.0,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        size: 14,
                                        color: Color(0xFF1E88E5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Ethiopian Curriculum G9-12",
                                        style: TextStyle(
                                          color: const Color(0xFF1E88E5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 15,
                                  color: textSecColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.duration,
                                  style: TextStyle(
                                    color: textSecColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14.0),
                            Text(
                              widget.title,
                              style: TextStyle(
                                height: 1.3,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Divider(color: textSecColor.withOpacity(0.15)),
                            const SizedBox(height: 10.0),
                            Text(
                              "About This Lesson",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              "This is a high-yield study review specifically mapped out for high success in secondary school examinations. It will cover essential concept builders, textbook exercises, step-by-step math proofs, and practical review questions. Take notes while playing!",
                              style: TextStyle(
                                height: 1.5,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: textSecColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Learning aids and interactive action section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Class Activity",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10.0),

                        // Study Cards Layout inside the Video screen
                        _buildClassActivityItem(
                          icon: Icons.assignment_turned_in_outlined,
                          iconColor: const Color(0xFF10B981),
                          title: "Take Quiz on this Topic",
                          subtitle: "Solve 10 practice questions instantly",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Launch related unit quizzes from the course menu!"),
                              ),
                            );
                          },
                          cardColor: cardColor,
                          textColor: textColor,
                          textSecColor: textSecColor,
                        ),
                        const SizedBox(height: 12.0),
                        _buildClassActivityItem(
                          icon: Icons.bookmark_add_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          title: "Save Lesson Notes",
                          subtitle: "Keep key ideas saved for quick offline revisions",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Lesson bookmarked! Saved successfully."),
                              ),
                            );
                          },
                          cardColor: cardColor,
                          textColor: textColor,
                          textSecColor: textSecColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color textSecColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: textSecColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
