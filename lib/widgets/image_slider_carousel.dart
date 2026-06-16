import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageSliderCarousel extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;

  const ImageSliderCarousel({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<ImageSliderCarousel> createState() => _ImageSliderCarouselState();
}

class _ImageSliderCarouselState extends State<ImageSliderCarousel> {
  int _currentSlideIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  // 3 Education Oriented high quality slides with translated titles and descriptions
  final List<Map<String, dynamic>> _slidesData = [
    {
      'imageUrl': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=800&auto=format&fit=crop',
      'titleEn': 'Collaborative Learning',
      'titleAm': 'የጋራ ጥናት ቡድን',
      'descEn': 'Connect and share summaries and matric preparation strategies with students nationwide.',
      'descAm': 'አጠቃላይ ማጠቃለያዎችን እና የማትሪክ ዝግጅቶችን በሀገር አቀፍ ደረጃ ካሉ ተማሪዎች ጋር ይጋሩ።',
      'accentColor': Color(0xFF0084FF),
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?q=80&w=800&auto=format&fit=crop',
      'titleEn': 'Excellence in Exams',
      'titleAm': 'ለማትሪክ አሸናፊነት',
      'descEn': 'Unlock high-quality practice tests, interactive flashcards, and verified solutions.',
      'descAm': 'ከፍተኛ ጥራት ያላቸው የልምምድ ፈተናዎች፣ አጫጭር ካርዶች እና የተረጋገጡ ማብራሪያዎችን ያግኙ።',
      'accentColor': Color(0xFF10B981),
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=800&auto=format&fit=crop',
      'titleEn': 'Track Your Progression',
      'titleAm': 'የእርስዎን ጉዞ ይከታተሉ',
      'descEn': 'Monitor study hours, completed chapters, and detailed mock success statistics.',
      'descAm': 'የጥናት ሰዓታትን፣ ያለቁ ምዕራፎችን እና ዝርዝር የፈተና ውጤቶችን ይቆጣጠሩ።',
      'accentColor': Color(0xFFF59E0B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _slidesData.length,
          options: CarouselOptions(
            height: 190.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: true,
            viewportFraction: 0.92,
            onPageChanged: (index, reason) {
              setState(() {
                _currentSlideIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final slide = _slidesData[index];
            final String title = widget.languageCode == 'en' ? slide['titleEn']! : slide['titleAm']!;
            final String desc = widget.languageCode == 'en' ? slide['descEn']! : slide['descAm']!;
            final Color accentColor = slide['accentColor']!;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.08 : 0.35),
                    blurRadius: 12.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: Stack(
                  children: [
                    // Slide Image background
                    Positioned.fill(
                      child: Image.network(
                        slide['imageUrl']!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0084FF)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF1E293B),
                          child: Icon(Icons.school_rounded, size: 48, color: accentColor.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    // High-quality dark multi-gradient mask overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Text details and badge info overlay
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accentColor, width: 1),
                            ),
                            child: Text(
                              widget.languageCode == 'en' ? 'SMART X LEARNING' : 'ስማርት ኤክስ ትምህርት',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 10.5,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Dots Indicator for slide selection
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _slidesData.asMap().entries.map((entry) {
            final int index = entry.key;
            final bool isActive = _currentSlideIndex == index;
            final Color dotColor = _slidesData[index]['accentColor']!;

            return GestureDetector(
              onTap: () => _carouselController.animateToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 18.0 : 7.0,
                height: 7.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: isActive
                      ? dotColor
                      : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
