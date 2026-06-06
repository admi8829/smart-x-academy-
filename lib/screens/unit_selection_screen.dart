import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';
import '../main.dart';
import 'quiz_screen.dart';

class UnitSelectionScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final String enTitle;
  final String amTitle;
  final Color color;
  final Widget icon;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const UnitSelectionScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.enTitle,
    required this.amTitle,
    required this.color,
    required this.icon,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  // Simple in-memory tracker for downloaded units & download progress states
  final Set<String> _downloadedUnits = {};
  final Map<String, double> _downloadProgress = {}; // unitId -> 0.0 to 1.0

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('UnitSelectionScreen BannerAd failed to load: $err. Code: ${err.code}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  // Bilingual translation helper
  String _local(String key) {
    // Dynamic retrieval from AppStateProvider context
    final String languageCode = AppStateProvider.of(context).languageCode;
    final Map<String, Map<String, String>> localized = {
      'en': {
        'back': 'Back',
        'units_title': 'Unit Explorer',
        'download': 'Download',
        'downloading': 'Downloading...',
        'downloaded': 'Downloaded',
        'start_quiz': 'Start Practice',
        'completed': 'Completed',
        'units_count': 'Units Available',
        'progress_label': 'My Learning Progress',
        'search_hint': 'Search unit topics...',
        'no_results': 'No units match your search.',
        'bytes_info': 'Size: 12.4 MB • Complete PDF & offline questions',
        'info_sheet': 'Unit Offline Package',
        'info_desc': 'Downloading saves high-yield summaries, diagrams, and local question databases directly to your device for complete offline learning.',
      },
      'am': {
        'back': 'ተመለስ',
        'units_title': 'የትምህርት ክፍሎች',
        'download': 'ያውርዱ',
        'downloading': 'በማውረድ ላይ...',
        'downloaded': 'ተጠናቋል',
        'start_quiz': 'መጠይቅ ጀምር',
        'completed': 'የተጠናቀቀ',
        'units_count': 'ያሉ የትምህርት ክፍሎች',
        'progress_label': 'የእኔ የመማር ሂደት',
        'search_hint': 'የክፍል አርዕስቶችን ፈልግ...',
        'no_results': 'ማንኛውም ክፍል ከአሰሳዎ ጋር አልተገኘም።',
        'bytes_info': 'መጠን: 12.4 MB • ሙሉ የፒዲኤፍ ማጠቃለያዎች',
        'info_sheet': 'ክላሲክ የትምህርት ጥቅል',
        'info_desc': 'ማውረድ ያለ በይነመረብ (ከመስመር ውጭ) እንዲማሩ እና ጥያቄዎችን እንዲለማመዱ ሁሉንም የትምህርት ማጠቃለያዎች ያከማቻል።',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  // Generate customized realistic units and descriptions for each subject + grade
  List<Map<String, dynamic>> _getUnits() {
    switch (widget.subjectId) {
      case 'Mathematics':
        return [
          {
            'id': 'math_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: The Number System',
            'amUnit': 'ክፍል 1: የቁጥር ስርዓት',
            'enDesc': 'Exploring rational & irrational numbers, operations, proofs, and sequence properties.',
            'amDesc': 'አሳማኝ እና አሳማኝ ያልሆኑ ቁጥሮች፣ ስሌቶች፣ ቀመሮች እና ቅደም ተከተሎችን ማሰስ።',
          },
          {
            'id': 'math_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Equations & Inequalities',
            'amUnit': 'ክፍል 2: እኩልታዎች እና አለመساባዎች',
            'enDesc': 'Solving quadratic systems, absolute values, and application models in real contexts.',
            'amDesc': 'የሁለተኛ ዲግሪ እኩልታዎችን፣ ፍጹም እሴቶችን እና ተግባራዊ አተገባበር መፍታት።',
          },
          {
            'id': 'math_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Coordinates & Vector Spaces',
            'amUnit': 'ክፍል 3: መጋጠሚያዎች እና የቬክተር ክፍተቶች',
            'enDesc': 'Distance formulas, midpoint vectors, linear equations slope, and spatial points.',
            'amDesc': 'የነጥቦች ርቀቶች ቀመር፣ የመካከለኛ ነጥብ፣ የቁልቁለት እና የቬክተር አቀማመጦች።',
          },
          {
            'id': 'math_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Geometry & Trigonometry',
            'amUnit': 'ክፍል 4: ጂኦሜትሪ እና ትሪጎኖሜትሪ',
            'enDesc': 'Congruent shapes, sine & cosine rules, area theorems, and complex angle measures.',
            'amDesc': 'ተመሳሳይ ቅርጾች፣ ሳይን እና ኮሳይን ህግጋት፣ የቦታ ይዘት እና አንግሎች።',
          },
          {
            'id': 'math_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Statistics & Probability',
            'amUnit': 'ክፍል 5: ስታቲስቲክስ እና ፕሮባብሊቲ',
            'enDesc': 'Data variance indices, standard deviations, permutation and independent compound events.',
            'amDesc': 'የዳታ ልዩነቶች እና ስታንዳርድ ዴቪዬሽን፣ ፐርሙቴሽን እና የተለያዩ የዕድል ሁኔታዎች።',
          },
        ];

      case 'Biology':
        return [
          {
            'id': 'bio_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Introduction to Biology',
            'amUnit': 'ክፍል 1: ስለ ስነ-ህይወት መግቢያ',
            'enDesc': 'General scope of biological sciences, history, instruments, and microscopic observations.',
            'amDesc': 'የስነ-ህይወት ሳይንስ አጠቃላይ ድንጋጌዎች፣ ታሪክ፣ መሳሪያዎች እና የማይክሮስኮፕ አጠቃቀም።',
          },
          {
            'id': 'bio_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Cellular Chemistry & Functions',
            'amUnit': 'ክፍል 2: የህዋስ ኬሚስትሪ እና ተግባራት',
            'enDesc': 'Primary organelles structure, cellular respiration pathway, and DNA replication mechanisms.',
            'amDesc': 'የኦርጋኔሎች መዋቅር፣ የህዋስ መተንፈስ ተግባር እና የዲኤንኤ ገለጻ መርሆዎች።',
          },
          {
            'id': 'bio_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Plant Structure and Physiology',
            'amUnit': 'ክፍል 3: የዕፅዋት መዋቅር እና ስነ-ተግባር',
            'enDesc': 'Photosynthesis processes, stomatal movements, transpiration forces and nutrient transport.',
            'amDesc': 'ፎቶሲንተሲስ፣ የስቶማታ እንቅስቃሴ፣ ትራንስፓይሬሽን እና የዕፅዋት ምግብ ዝውውር።',
          },
          {
            'id': 'bio_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Human Anatomy & Health Systems',
            'amUnit': 'ክፍል 4: የሰው አካል የአካል ክፍሎች እና ጤና',
            'enDesc': 'Nervous transmission pathways, endocrinal regulatory glands, and immune system response.',
            'amDesc': 'የነርቭ ዝውውር መቆጣጠሪያ፣ የሆርሞኖች እጢዎች እና የበሽታ መከላከያ ስርዓቶች።',
          },
          {
            'id': 'bio_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Ecology & Environmental Physics',
            'amUnit': 'ክፍል 5: ስነ-ምህዳር እና አካባቢ',
            'enDesc': 'Biosphere interactions, biogeochemical nutrient loops, and habitat preservation dynamics.',
            'amDesc': 'በባዮስፌር ውስጥ ያሉ ግንኙነቶች፣ አልሚ ንጥረ ነገሮች ኡደት እና አካባቢ ጥበቃ።',
          },
        ];

      case 'Physics':
        return [
          {
            'id': 'phys_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Physical Quantities & Vectors',
            'amUnit': 'ክፍል 1: ፊዚካዊ መጠኖች እና ቬክተሮች',
            'enDesc': 'Vector resolutions, scalar products, dimension analysis, and precision measurements.',
            'amDesc': 'የቬክተር ክፍፍሎች፣ መስቀለኛ እና ስካላር ብዜቶች፣ እና የልኬት ትክክለኛነት ሞዴሎች።',
          },
          {
            'id': 'phys_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Kinematics & Mechanics',
            'amUnit': 'ክፍል 2: ኪነማቲክስ እና መካኒክስ',
            'enDesc': 'Two-dimensional motions, projectile trajectories, and Newton’s core acceleration laws.',
            'amDesc': 'ሁለት አቅጣጫዊ እንቅስቃሴዎች፣ ፕሮጀክታይል ሞሽን እና የኒውተን የጉልበት ህግጋት።',
          },
          {
            'id': 'phys_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Work, Energy & Power',
            'amUnit': 'ክፍል 3: ስራ፣ ጉልበት እና ሃይል',
            'enDesc': 'Conservation thresholds, potential fields, collision mechanics, and efficiency calculations.',
            'amDesc': 'የእምቅ ሃይል ክምችት፣ የመጋጨት መካኒክስ እና የውጤታማነት ስሌቶች።',
          },
          {
            'id': 'phys_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Rotational Motion & Gravity',
            'amUnit': 'ክፍል 4: ሽክርክሪት እንቅስቃሴ እና የስበት ኃይል',
            'enDesc': 'Angular pathways, torque balances, center of gravity, and moment of inertia formulas.',
            'amDesc': 'የማዕዘን ጉዞ፣ ቶርክ (ሽክርክሪት ኃይል) እና የመዞሪያ ግትርነት ስሌት።',
          },
          {
            'id': 'phys_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Thermodynamics & Heat Systems',
            'amUnit': 'ክፍል 5: ቴርሞዳይናሚክስ እና ሙቀት',
            'enDesc': 'Heat exchange equations, internal systems state energy, and thermodynamic efficiency.',
            'amDesc': 'የሙቀት ዝውውር መለኪያዎች፣ የውስጣዊ ሃይል መጠን እና የቴርሞዳይናሚክስ ህጎች።',
          },
        ];

      case 'Chemistry':
        return [
          {
            'id': 'chem_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Atomic Structure',
            'amUnit': 'ክፍል 1: የአቶም መዋቅር',
            'enDesc': 'Quantum numbers, orbital levels configuration, chemical properties trends on periodic tables.',
            'amDesc': 'የኳንተም ቁጥሮች፣ የኤሌክትሮን ምደባ መዋቅር እና የጊዜያዊ ሰንጠረዥ ባህሪያት።',
          },
          {
            'id': 'chem_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Chemical Bonding',
            'amUnit': 'ክፍል 2: ኬሚካዊ ትስስር',
            'enDesc': 'Ionic lattices, covalent molecular geometries, molecular orbital systems, and electronegativity.',
            'amDesc': 'አዮኒክ እና ኮቫለንት ትስስሮች፣ የሞለኪውሎች ውቅር እና የኤሌክትሮኔጋቲቪቲ ልዩነቶች።',
          },
          {
            'id': 'chem_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Stoichiometry & Formula Mass',
            'amUnit': 'ክፍል 3: ስቶይኪዮሜትሪ',
            'enDesc': 'The mole concept, limiting reactant calculations, concentration equations and yield yields.',
            'amDesc': 'የሞል ጽንሰ-ሀሳብ፣ ወሳኝ አፀፋዊ ንጥረ ነገሮች እና የተመጣጠነ ኬሚካዊ ስሌቶች።',
          },
          {
            'id': 'chem_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Chemical Equilibria & Acids',
            'amUnit': 'ክፍል 4: ኬሚካዊ ሚዛን እና አሲዶች',
            'enDesc': 'Le Chatelier shifts, solubility product index, pH calculations, and neutralisations.',
            'amDesc': 'የለ ሻተሌየር መርህ፣ የፒኤች (pH) ስሌት እና የአሲድ-ቤዝ ገለልተኛ መሆን ሂደቶች።',
          },
          {
            'id': 'chem_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Introduction to Organic Chemistry',
            'amUnit': 'ክፍል 5: የኦርጋኒክ ኬሚስትሪ መግቢያ',
            'enDesc': 'IUPAC naming conventions of hydrocarbons, structural isomers, and alkanes properties.',
            'amDesc': 'የሃይድሮካርቦኖች የአሰያየም ሥርዓት (IUPAC)፣ አይሶመርስ እና አልኬን ባህሪዎች።',
          },
        ];

      case 'Geography':
        return [
          {
            'id': 'geo_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Map Reading and Interpretation',
            'amUnit': 'ክፍል 1: የካርታ ንባብ እና ትርጓሜ',
            'enDesc': 'Contour structures, scales comparison, grid symbols identification, and elevation slopes.',
            'amDesc': 'የኮንቱር መስመሮች፣ የካርታ ልኬቶች እና የከፍታዎች የቁልቁለት መጠን መመልከት።',
          },
          {
            'id': 'geo_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Lithosphere and Landforms',
            'amUnit': 'ክፍል 2: ሊቶስፌር እና የመሬት ገጽታዎች',
            'enDesc': 'Plate tectonic dynamics, continental movements, weathering cycles and soil profiles.',
            'amDesc': 'የቴክቶኒክ ሳህኖች እንቅስቃሴ፣ የመሬት መንቀጥቀጥ እና የአፈር መሸርሸር ዑደቶች።',
          },
          {
            'id': 'geo_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Weather & Climate of Africa',
            'amUnit': 'ክፍል 3: የአፍሪካ የአየር ሁኔታ እና የአየር ንብረት',
            'enDesc': 'ITCZ air movements, climatic classifications, vegetation distribution, and drought factors.',
            'amDesc': 'የአየር ግፊት እና የአየር ንብረት ክልሎች፣ የአፍሪካ ደኖች ተደራሽነት እና ድርቅ።',
          },
          {
            'id': 'geo_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Human Demographics & Economic Growth',
            'amUnit': 'ክፍል 4: የህዝብ ስብጥር እና ኢኮኖሚያዊ ዕድገት',
            'enDesc': 'Fertility models, urban migrative patterns, and primary resource exploitation in Ethiopia.',
            'amDesc': 'የህዝብ ብዛት ተለዋዋጭነት፣ የከተማ ፍልሰት እና የኢትዮጵያ ኢኮኖሚ ሴክተሮች።',
          },
          {
            'id': 'geo_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: GIS & Remote Sensing Principles',
            'amUnit': 'ክፍል 5: ጂአይኤስ (GIS) እና የርቀት ምርመራ',
            'enDesc': 'Vector vs Raster attributes, satellite photography data overlaying, mapping softwares info.',
            'amDesc': 'የቬክተር እና ራስተር ዳታ ሞዴሎች፣ የሳተላይት ምስሎች እና የካርታ አሰራር።',
          },
        ];

      case 'History':
        return [
          {
            'id': 'hist_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Human Beginnings inside East Africa',
            'amUnit': 'ክፍል 1: የሰዎች መገኛ በምስራቅ አፍሪካ',
            'enDesc': 'Palaeoanthropology discoveries, Australopithecus Afarensis (Lucy), stone-age tool developments.',
            'amDesc': 'የአርኪዮሎጂ ግኝቶች፣ ሉሲ (ድንቅነሽ) በአዋሽ ሸለቆ፣ የድንጋይ ዘመን መሳሪያዎች እድገት።',
          },
          {
            'id': 'hist_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: The Aksumite Kingdom & Maritime Trade',
            'amUnit': 'ክፍል 2: የአክሱም ስርወ-መንግስት እና የባህር ንግድ',
            'enDesc': 'Rise of Aksum state, stone obelisks engineering, coinage systems, and early Christian introduction.',
            'amDesc': 'የአክሱም ስልጣኔ መነሳት፣ የሀውልቶች ጥበብ፣ የሳንቲም ዝውውር እና ክርስትና መስፋፋት።',
          },
          {
            'id': 'hist_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Medieval Kingdoms and Camel Caravan Routes',
            'amUnit': 'ክፍል 3: የመካከለኛው ዘመን መንግስታት እና የንግድ መስመሮች',
            'enDesc': 'The Zagwe dynasty rock-hewn Lalibela architecture, Islamic sultanates, and Gondarian castle period.',
            'amDesc': 'የዛግዌ ስርወ መንግስት የላሊበላ ውቅር አብያተ ክርስቲያናት እና የጎንደር ነገስታት ከተማ ታሪክ።',
          },
          {
            'id': 'hist_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Modern Ethiopia Integration & Adwa Unity',
            'amUnit': 'ክፍል 4: የዘመናዊት ኢትዮጵያ ምስረታ እና የአድዋ ድል',
            'enDesc': 'Emperor Tewodros reunification, Emperor Menelik state expansion, and Battle of Adwa victory.',
            'amDesc': 'የዓፄ ቴዎድሮስ ጥረቶች፣ የዓፄ ምኒልክ አሀዳዊ ምስረታ እና የአድዋ ጦርነት ታሪክ።',
          },
          {
            'id': 'hist_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: 20th Century Conflicts and African Decolonization',
            'amUnit': 'ክፍል 5: የ20ኛው ክፍለ ዘመን ጦርነቶች እና የአፍሪካ ነጻነት',
            'enDesc': 'First & Second World Wars, League of Nations failures, and decolonization timeline.',
            'amDesc': 'የአንደኛውና ሁለተኛው የዓለም ጦርነት፣ የአፍሪካ ነጻነት ንቅናቄዎች መነሳት።',
          },
        ];

      case 'Civics':
        return [
          {
            'id': 'civ_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Constitution and Principles of Law',
            'amUnit': 'ክፍል 1: ህገ-መንግስት እና የህግ መርሆዎች',
            'enDesc': 'Role of supreme state codes, differences of constitution formats, and law supremacy concepts.',
            'amDesc': 'የበላይ የህግ ሰነድ ሚና፣ የህገ-መንግስት አይነቶች እና የህግ የበላይነት መርሆዎች።',
          },
          {
            'id': 'civ_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Human Rights & Democratic Institutions',
            'amUnit': 'ክፍል 2: ሰብአዊ መብቶች እና ዴሞክራሲያዊ ተቋማት',
            'enDesc': 'UN Universal Declaration values, civil liberties definitions, and citizen-state compacts.',
            'amDesc': 'የተባበሩት መንግስታት የሰብአዊ መብቶች ድንጋጌ (UDHR) እና የዜጎች መሠረታዊ መብቶች።',
          },
          {
            'id': 'civ_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Federal Structuring and Local Authority',
            'amUnit': 'ክፍል 3: የፌደራል መዋቅር እና የአካባቢ አስተዳደር',
            'enDesc': 'Nations & Nationalities representation, the bicameral systems, and HoPR governance.',
            'amDesc': 'የብሄር ብሄረሰቦች ተወካይ ምክርቤት፣ የባለ ሁለት ምክርቤቶች ሚና እና የፌደራል አስተዳደር ጥቅሞች።',
          },
          {
            'id': 'civ_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Civic Virtues & Social Responsibilities',
            'amUnit': 'ክፍል 4: የስነ-ምግባር እሴቶች እና ማህበራዊ ኃላፊነት',
            'enDesc': 'Patriotism foundations, corruption fight directives, and general professional integrity rules.',
            'amDesc': 'የሀገር ፍቅር መሠረቶች፣ ሙስናን የመዋጋት መንገዶች እና ሙያዊ ታማኝነት።',
          },
          {
            'id': 'civ_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Global Relations & International Organizations',
            'amUnit': 'ክፍል 5: የዓለም አቀፍ ግንኙነቶች እና ተቋማት',
            'enDesc': 'Ethiopia’s diplomacy history, sovereign equality, AU and UN treaties obligations overview.',
            'amDesc': 'የኢትዮጵያ የዲፕሎማሲ ታሪክ፣ የአፍሪካ ህብረት እና የተባበሩት መንግስታት ሚና።',
          },
        ];

      case 'Agriculture':
        return [
          {
            'id': 'agri_u1',
            'grade': widget.grade,
            'enUnit': 'Unit 1: Introduction to Crop Management',
            'amUnit': 'ክፍል 1: ሰብል አያያዝ እና ልማት መግቢያ',
            'enDesc': 'Traditional tilling methods, mixed farming practices, and nutritional native crops.',
            'amDesc': 'የባህላዊ እርሻ ዘዴዎች፣ ድብልቅ እርሻ እና የአካባቢ ተስማሚ ሰብሎች ምርት።',
          },
          {
            'id': 'agri_u2',
            'grade': widget.grade,
            'enUnit': 'Unit 2: Soil Properties & Water Systems',
            'amUnit': 'ክፍል 2: የአፈር ባህሪያት እና የውሃ አጠቃቀም',
            'enDesc': 'Clay vs sand water holding indexes, organic manure, and primary drainage pathways.',
            'amDesc': 'የአሸዋማ እና ጭቃማ አፈር ባህሪዎች፣ የተፈጥሮ ማዳበሪያ እና መስኖ አጠቃቀም።',
          },
          {
            'id': 'agri_u3',
            'grade': widget.grade,
            'enUnit': 'Unit 3: Crop Parasites & Biological Control',
            'amUnit': 'ክፍል 3: የሰብል ተባዮች እና ባዮሎጂያዊ ቁጥጥር',
            'enDesc': 'Predator-prey insects implementations, rust fungus treatments, and non-chemical methods.',
            'amDesc': 'የተፈጥሮ ተባዮችን መከላከያ ነፍሳት፣ የቡና በሽታ መከላከያዎች እና የአካባቢ ጥበቃ።',
          },
          {
            'id': 'agri_u4',
            'grade': widget.grade,
            'enUnit': 'Unit 4: Agroforestry and Resource Conservation',
            'amUnit': 'ክፍል 4: አግሮ-ፎረስቴሪ እና የተፈጥሮ ሀብት ጥበቃ',
            'enDesc': 'Combining high-productive trees with cereal crops, windbreak buffers, and terracings.',
            'amDesc': 'ዛፎችን ከእርሻ ሰብሎች ጋር ማሳደግ፣ የእርከን ስራዎች እና የንፋስ መከላከያዎች።',
          },
          {
            'id': 'agri_u5',
            'grade': widget.grade,
            'enUnit': 'Unit 5: Advanced Smart Agriculture Systems',
            'amUnit': 'ክፍል 5: ዘመናዊ እና የተራቀቁ የግብርና ዘዴዎች',
            'enDesc': 'Hydroponics structures, drip-irrigation efficiency setups, and greenhouse automation theories.',
            'amDesc': 'ሀይድሮፖኒክስ (ያለ አፈር ማልማት)፣ የተንጠባጠብ መስኖ እና የሙቀት መቆጣጠሪያ ግሪንሃውስ።',
          },
        ];

      default:
        return [];
    }
  }

  String _searchQuery = "";

  void _simulateDownload(String unitId) {
    if (_downloadedUnits.contains(unitId)) return;

    setState(() {
      _downloadProgress[unitId] = 0.0;
    });

    final String languageCode = AppStateProvider.of(context).languageCode;

    // Animate custom downloading to feel incredible and completely responsive
    double current = 0.0;
    void tick() {
      if (!mounted) return;
      current += 0.2;
      if (current >= 1.0) {
        setState(() {
          _downloadProgress.remove(unitId);
          _downloadedUnits.add(unitId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    languageCode == 'en'
                        ? 'Unit has been successfully saved for offline use!'
                        : 'የትምህርት ክፍሉ ከመስመር ውጭ እንዲሰራ ተደርጓል!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _downloadProgress[unitId] = current;
        });
        Future.delayed(const Duration(milliseconds: 250), tick);
      }
    }

    Future.delayed(const Duration(milliseconds: 200), tick);
  }

  void _showInfoSheet() {
    final appConfig = AppStateProvider.of(context);
    final isLight = !appConfig.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.download_for_offline_rounded, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _local('info_sheet'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _local('info_desc'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _local('bytes_info'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live query from AppStateProvider for absolute zero delay updates
    final appConfig = AppStateProvider.of(context);
    final bool isDarkMode = appConfig.isDarkMode;
    final String languageCode = appConfig.languageCode;
    final bool isLight = !isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final allUnits = _getUnits();
    final filteredUnits = allUnits.where((u) {
      final text = languageCode == 'en' 
          ? '${u['enUnit']} ${u['enDesc']}'.toLowerCase()
          : '${u['amUnit']} ${u['amDesc']}'.toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

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
          languageCode == 'en' ? widget.enTitle : widget.amTitle,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: headerTextColor, size: 20),
            onPressed: _showInfoSheet,
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appConfig.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? Container(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              alignment: Alignment.center,
              color: Colors.transparent,
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Hero section with Subject Card presentation
              Container(
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic scaled illustration in unique background box
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 55,
                              height: 55,
                              child: widget.icon,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        // Titles and Grade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  languageCode == 'en'
                                      ? 'GRADE ${widget.grade}'
                                      : 'ክፍል ${widget.grade}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: widget.color,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                languageCode == 'en' ? widget.enTitle : widget.amTitle,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: headerTextColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                languageCode == 'en'
                                    ? 'High-quality comprehensive unit reviews'
                                    : 'ምርጥ ከመስመር ውጭ የትምህርት ክፍሎች',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 20),
                    // Progress metric section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _local('progress_label'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: headerTextColor),
                        ),
                        Text(
                          languageCode == 'en'
                              ? '${_downloadedUnits.length} / ${allUnits.length} Offline'
                              : '${_downloadedUnits.length} / ${allUnits.length} ወርዷል',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Custom layout ProgressBar
                    Stack(
                      children: [
                        Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 7,
                          width: MediaQuery.of(context).size.width * 
                              (allUnits.isEmpty ? 0 : (_downloadedUnits.length / allUnits.length)) * 0.85,
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search field in workspace layout
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        height: 48,
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLight 
                                ? const Color(0xFFE2E8F0) 
                                : const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: descColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: TextStyle(color: headerTextColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: _local('search_hint'),
                                  hintStyle: TextStyle(color: descColor.withValues(alpha: 0.6), fontSize: 13.5),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Subject count text label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  '${_local('units_count')} (${filteredUnits.length})',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w800,
                    color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),

              // Filtered list of Units
              if (filteredUnits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, color: descColor.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _local('no_results'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: descColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    final String unitId = unit['id'];
                    final bool isDownloaded = _downloadedUnits.contains(unitId);
                    final double? progress = _downloadProgress[unitId];

                    final String title = languageCode == 'en' ? unit['enUnit'] : unit['amUnit'];
                    final String desc = languageCode == 'en' ? unit['enDesc'] : unit['amDesc'];

                    final indexFactor = index * 100;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + indexFactor),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, animChild) {
                        return Transform.translate(
                          offset: Offset(0.0, 30.0 * (1.1 - animValue)),
                          child: Opacity(
                            opacity: animValue,
                            child: animChild,
                          ),
                        );
                      },
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLight 
                              ? const Color(0xFFE2E8F0) 
                              : const Color(0xFF334155),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isLight 
                                ? Colors.black.withValues(alpha: 0.02) 
                                : Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Accent line decor indicator on left
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 5,
                              child: Container(
                                color: widget.color.withValues(alpha: isDownloaded ? 1.0 : 0.4),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Unit designation label
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: widget.color.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          languageCode == 'en'
                                              ? 'UNIT 0${index + 1}'
                                              : 'ክፍል 0${index + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: widget.color,
                                          ),
                                        ),
                                      ),
                                      if (isDownloaded)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.download_done_rounded, color: Color(0xFF10B981), size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                _local('downloaded').toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Unit Title
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: headerTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Unit description
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                      color: descColor,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  // Horizontal Divider line
                                  Container(
                                    height: 1,
                                    color: isLight 
                                        ? const Color(0xFFE2E8F0) 
                                        : const Color(0xFF334155),
                                  ),
                                  const SizedBox(height: 14),
                                  // Bottom Row of Custom Controls (Download + Start Practice)
                                  Row(
                                    children: [
                                      // Customizable Box of Unit Download button
                                      Expanded(
                                        child: progress != null
                                            ? Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: widget.color.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child: CircularProgressIndicator(
                                                        value: progress,
                                                        strokeWidth: 2,
                                                        color: widget.color,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _local('downloading'),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: widget.color,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : InkWell(
                                                onTap: () => _simulateDownload(unitId),
                                                borderRadius: BorderRadius.circular(12),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isDownloaded
                                                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                        : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isDownloaded
                                                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                                          : Colors.transparent,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        isDownloaded 
                                                            ? Icons.cloud_done_rounded 
                                                            : Icons.cloud_download_outlined,
                                                        size: 16,
                                                        color: isDownloaded 
                                                            ? const Color(0xFF10B981) 
                                                            : (isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        isDownloaded ? _local('downloaded') : _local('download'),
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: isDownloaded 
                                                              ? const Color(0xFF10B981) 
                                                              : (isLight ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Start Practice / Quiz Screen Arena
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => QuizScreen(
                                                  grade: widget.grade,
                                                  subject: widget.subjectId,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: widget.color,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: widget.color.withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                )
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.play_arrow_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _local('start_quiz'),
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}
}
