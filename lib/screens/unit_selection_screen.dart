import 'package:flutter/material.dart';
import 'dart:ui';
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

class _UnitSelectionScreenState extends State<UnitSelectionScreen> with SingleTickerProviderStateMixin {
  // Simple in-memory tracker for downloaded units & download progress states
  final Set<String> _downloadedUnits = {};
  final Map<String, double> _downloadProgress = {}; // unitId -> 0.0 to 1.0
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Bootstrap initial offline values to demonstrate completed states
    _downloadedUnits.addAll({
      'math_u1', 'math_u2', 'math_u3', 'math_u4',
      'bio_u1', 'bio_u2', 'bio_u3', 'bio_u4',
      'phys_u1', 'phys_u2', 'phys_u3', 'phys_u4',
      'chem_u1', 'chem_u2', 'chem_u3', 'chem_u4',
      'geo_u1', 'geo_u2', 'geo_u3', 'geo_u4',
      'hist_u1', 'hist_u2', 'hist_u3', 'hist_u4',
      'civ_u1', 'civ_u2', 'civ_u3', 'civ_u4',
      'agri_u1', 'agri_u2', 'agri_u3', 'agri_u4'
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Bilingual translation helper
  String _local(String key) {
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
    return localized[widget.languageCode]?[key] ?? key;
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
                    widget.languageCode == 'en'
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
    final isLight = !widget.isDarkMode;
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
    final bool isLight = !widget.isDarkMode;
    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    // Dynamic extraction of subject units
    final rawUnits = List<Map<String, dynamic>>.from(_getUnits());
    
    // Ensure we have exactly 6 units for the map steps. If there are fewer, append capstone mock items.
    while (rawUnits.length < 6) {
      final int nextIndex = rawUnits.length + 1;
      rawUnits.add({
        'id': 'u${nextIndex}_capstone_${widget.subjectId.toLowerCase()}',
        'grade': widget.grade,
        'enUnit': 'Unit $nextIndex: Advanced Capstone Topics',
        'amUnit': 'ክፍል $nextIndex: የላቁ ማጠቃለያ አርዕስቶች',
        'enDesc': 'Comprehensive core syllabus testing block with smart micro feedback.',
        'amDesc': 'ሁሉንም የትምህርት ይዘቶች ያካተተ የተጠቃለለ የስልጠና ፈተና።',
      });
    }
    
    final List<Map<String, dynamic>> allUnits = rawUnits.take(6).toList();

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
          widget.languageCode == 'en' ? widget.enTitle : widget.amTitle,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Points Counter Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.languageCode == 'en' ? '20 PTS' : '20 ነጥብ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable Journey map area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TITLE HEADER BANNER OF JOURNEY MAP (English: LEARNING JOURNEY / Amharic: የጥናት ጉዞ)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.languageCode == 'en' ? 'LEARNING JOURNEY' : 'የጥናት ጉዞ',
                                style: const TextStyle(
                                  letterSpacing: 1.0,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.languageCode == 'en' 
                                    ? 'Grade ${widget.grade} • Interactive Quiz Progression'
                                    : 'ክፍል ${widget.grade} • በፈተናዎች የተመሰረተ እድገት',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.map_rounded, color: widget.color, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // UNIT PROGRESS HOVER CARD WITH COMPACT PROGRESS WHEEL
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isLight ? 0.03 : 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // 70px Custom Progress ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 62,
                                  width: 62,
                                  child: CircularProgressIndicator(
                                    value: 4 / 6,
                                    strokeWidth: 6,
                                    color: const Color(0xFF10B981),
                                    backgroundColor: widget.color.withOpacity(0.12),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '4/6',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    Text(
                                      widget.languageCode == 'en' ? 'DONE' : 'አልቅቋል',
                                      style: TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        color: descColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.languageCode == 'en' ? 'Excellent Progress!' : 'በጣም ድንቅ እድገት!',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w900,
                                      color: headerTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.languageCode == 'en' 
                                        ? 'You have mastered 4 units! Ready to unlock Intermediate Techniques.'
                                        : '4 ክፍሎችን ጨርሰዋል! ወደ መካከለኛ ደረጃ ትምህርቶች ለማለፍ ዝግጁ ተደርገዋል።',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: descColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PLAYFUL MAP PROGRESS WINDING BOARD SECTION
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double mapWidth = constraints.maxWidth;
                          const double mapHeight = 990.0; // Fixed spacious vertical layout height
                          const double stepY = mapHeight / 6;

                          return SizedBox(
                            height: mapHeight,
                            width: mapWidth,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // BACKROUND LAYER: Dash curving Bezier path
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: WindingPathPainter(
                                      count: 6,
                                      activeColor: const Color(0xFF3B82F6),
                                      completedColor: const Color(0xFF10B981),
                                      lockedColor: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                      isDarkMode: widget.isDarkMode,
                                    ),
                                  ),
                                ),

                                // INTERMEDIATE PATH SEGMENT PERCENTAGE BULB BADGES ON CENTER LINE
                                ...List.generate(5, (index) {
                                  final double midY = (index + 1) * stepY;
                                  
                                  // Content indicator based on path progression index
                                  Widget badgeChild;
                                  Color badgeColor;
                                  Color txtColor;
                                  
                                  if (index < 3) {
                                    badgeChild = const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_rounded, color: Colors.white, size: 10),
                                        SizedBox(width: 3),
                                        Text('100%', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                      ],
                                    );
                                    badgeColor = const Color(0xFF10B981);
                                    txtColor = Colors.white;
                                  } else if (index == 3) {
                                    badgeChild = const Text(
                                      'NEXT',
                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    );
                                    badgeColor = const Color(0xFF3B82F6);
                                    txtColor = Colors.white;
                                  } else {
                                    badgeChild = Icon(Icons.lock_rounded, color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 12);
                                    badgeColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
                                    txtColor = Colors.grey;
                                  }

                                  return Positioned(
                                    left: mapWidth / 2 - 28,
                                    top: midY - 11,
                                    child: Container(
                                      height: 22,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: badgeChild,
                                    ),
                                  );
                                }),

                                // FOREGROUND LAYER: Interactive circular nodes and textual sidecards
                                ...List.generate(6, (index) {
                                  final unit = allUnits[index];
                                  final String unitId = unit['id'];
                                  final bool isDownloaded = _downloadedUnits.contains(unitId);

                                  final String title = widget.languageCode == 'en' ? unit['enUnit'] : unit['amUnit'];
                                  final String desc = widget.languageCode == 'en' ? unit['enDesc'] : unit['amDesc'];

                                  // Status mapping: Index 0-3 = "completed", Index 4 = "active", Index 5+ = "locked"
                                  final String status = index < 4 
                                      ? 'completed' 
                                      : (index == 4 ? 'active' : 'locked');

                                  // Y coordinates calculating
                                  final double centerY = (index + 0.5) * stepY;
                                  final double circleSize = 64.0;
                                  final double topY = centerY - (circleSize / 2);

                                  final bool isEven = index % 2 == 0;
                                  final double circleX = isEven 
                                      ? (mapWidth * 0.22 - (circleSize / 2)) 
                                      : (mapWidth * 0.78 - (circleSize / 2));

                                  // Visual settings based on status
                                  Color circleBorderColor;
                                  Color circleInnerBg;
                                  IconData mathIcon;
                                  Color mathIconColor;
                                  
                                  if (status == 'completed') {
                                    circleBorderColor = const Color(0xFF10B981);
                                    circleInnerBg = isLight ? const Color(0xFFECFDF5) : const Color(0xFF064E3B);
                                    mathIconColor = const Color(0xFF10B981);
                                    
                                    // Illustrative icon mapping
                                    if (index == 0) mathIcon = Icons.star_rounded;
                                    else if (index == 1) mathIcon = Icons.explore_rounded;
                                    else if (index == 2) mathIcon = Icons.science_rounded;
                                    else mathIcon = Icons.psychology_rounded;
                                  } else if (status == 'active') {
                                    circleBorderColor = const Color(0xFF3B82F6);
                                    circleInnerBg = isLight ? const Color(0xFFEFF6FF) : const Color(0xFF172554);
                                    mathIconColor = const Color(0xFF3B82F6);
                                    mathIcon = Icons.extension_rounded;
                                  } else {
                                    circleBorderColor = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
                                    circleInnerBg = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B).withOpacity(0.4);
                                    mathIconColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
                                    mathIcon = Icons.grid_view_rounded;
                                  }

                                  return Stack(
                                    children: [
                                      // 1. Connection node circle clickable button representation
                                      Positioned(
                                        left: circleX,
                                        top: topY,
                                        child: InkWell(
                                          onTap: () {
                                            if (status == 'locked') {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    widget.languageCode == 'en'
                                                        ? 'This Unit is locked! Complete preceding modules or upgrade to PRO.'
                                                        : 'ይህ ክፍል አልተከፈተም! መጀመሪያ ቀዳሚ ማጠቃለያዎችን ይጨርሱ።',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  backgroundColor: widget.color,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              // Launch practice quiz directly for this unit
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => QuizScreen(
                                                    grade: widget.grade,
                                                    subject: widget.subjectId,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(100),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Inner glowing halo rings
                                              if (status == 'active')
                                                ValueListenableBuilder(
                                                  valueListenable: _pulseController,
                                                  builder: (context, pulseVal, child) {
                                                    return Container(
                                                      height: circleSize + (16 * _pulseController.value),
                                                      width: circleSize + (16 * _pulseController.value),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: const Color(0xFF3B82F6).withOpacity(0.12 * (1.0 - _pulseController.value)),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              Container(
                                                height: circleSize,
                                                width: circleSize,
                                                decoration: BoxDecoration(
                                                  color: circleInnerBg,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: circleBorderColor, width: 3.5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: circleBorderColor.withOpacity(isLight ? 0.08 : 0.25),
                                                      blurRadius: status == 'active' ? 12 : 6,
                                                      offset: const Offset(0, 3),
                                                    )
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Icon(mathIcon, color: mathIconColor, size: 28),
                                                ),
                                              ),

                                              // Small badge anchored in bottom-right corner representing node conditions
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    color: status == 'completed' 
                                                        ? const Color(0xFF10B981) 
                                                        : (status == 'active' ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8)),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: cardBgColor, width: 2),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: status == 'completed'
                                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                                                      : (status == 'active' 
                                                          ? Transform.rotate(
                                                              angle: 0.7,
                                                              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 10),
                                                            )
                                                          : const Icon(Icons.lock_rounded, color: Colors.white, size: 9)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 2. Info Description card adjacent to the map nodes
                                      Positioned(
                                        left: isEven ? circleX + circleSize + 14 : 14,
                                        right: isEven ? 14 : (mapWidth - circleX) + 14,
                                        top: topY - 14,
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 300),
                                          opacity: status == 'locked' ? 0.65 : 1.0,
                                          child: InkWell(
                                            onTap: () {
                                              if (status != 'locked') {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => QuizScreen(
                                                      grade: widget.grade,
                                                      subject: widget.subjectId,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: cardBgColor,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: status == 'active' 
                                                      ? const Color(0xFF1E3A8A).withOpacity(0.15) 
                                                      : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                                  width: status == 'active' ? 1.5 : 1.0,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(isLight ? 0.02 : 0.1),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  )
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Unit label identifier tag
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: circleBorderColor.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      widget.languageCode == 'en' 
                                                          ? 'UNIT 0${index + 1}' 
                                                          : 'ክፍል 0${index + 1}',
                                                      style: TextStyle(
                                                        color: circleBorderColor,
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Title
                                                  Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13.5,
                                                      color: headerTextColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  // Description subtitle
                                                  Text(
                                                    desc,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      height: 1.3,
                                                      fontWeight: FontWeight.w500,
                                                      color: descColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // STICKY BOTTOM BUTTON PANEL WITH ATTRACTIVE GRADIENT BUTTON
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.04 : 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Offline download button configuration for Unit 5
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () => _simulateDownload('u5_intermediate_pkg'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                widget.languageCode == 'en' ? 'OFFLINE' : 'ያውርዱ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: headerTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // START NEXT UNIT: Glowing pulse animations active selector button
                    Expanded(
                      flex: 7,
                      child: ValueListenableBuilder(
                        valueListenable: _pulseController,
                        builder: (context, val, child) {
                          final double pulseScale = 1.0 + (_pulseController.value * 0.04);
                          return Transform.scale(
                            scale: pulseScale,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(
                                    grade: widget.grade,
                                    subject: widget.subjectId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.languageCode == 'en' ? 'START NEXT UNIT' : 'ቀጣዩን ክፍል ጀምር',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM BOARD-GAME MAP WINDING PATH PAINTER
// ==========================================
class WindingPathPainter extends CustomPainter {
  final int count;
  final Color activeColor;
  final Color completedColor;
  final Color lockedColor;
  final bool isDarkMode;

  WindingPathPainter({
    required this.count,
    required this.activeColor,
    required this.completedColor,
    required this.lockedColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 1) return;

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double stepY = size.height / count;

    // Calculate the coordinates of node centers
    final List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final double y = (i + 0.5) * stepY;
      final double x = (i % 2 == 0) ? size.width * 0.22 : size.width * 0.78;
      points.add(Offset(x, y));
    }

    // Connect nodes using beautiful S-shaped curves
    for (int i = 0; i < count - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];

      // Styling based on milestone completion rules:
      // Line segments connected to completed index nodes are completed, active index to next is active
      Color segmentColor;
      if (i < 3) {
        segmentColor = completedColor;
      } else if (i == 3) {
        segmentColor = activeColor;
      } else {
        segmentColor = lockedColor;
      }

      linePaint.color = segmentColor;

      // Draw continuous bezier path curves
      final Path path = Path();
      path.moveTo(p0.dx, p0.dy);

      final double midY = (p0.dy + p1.dy) / 2;
      
      // Control points alternate side curves
      final double controlX = size.width / 2;
      path.cubicTo(
        controlX, p0.dy + 25, 
        controlX, p1.dy - 25, 
        p1.dx, p1.dy,
      );

      _drawDashedPath(canvas, path, linePaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;

    final Path dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
