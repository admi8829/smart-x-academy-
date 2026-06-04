import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';
import '../widgets/education_watermark_background.dart';

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String hint;

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.hint,
  });
}

class QuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  const QuizScreen({super.key, this.grade = 9, this.subject});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- Quiz State ---
  late final List<QuizQuestion> _questions;

  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;
  bool _quizFinished = false;
  bool _hasUsedHintForCurrentQuestion = false;

  // --- AdMob Ads State ---
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _questions = _getQuestionsForGradeAndSubject(widget.grade, widget.subject);
    _initAdMob();
  }

  List<QuizQuestion> _getQuestionsForGradeAndSubject(int grade, String? subject) {
    if (subject == null) {
      return _getQuestionsForGradeFallback(grade);
    }
    
    switch ("$grade-$subject") {
      case "9-Mathematics":
        return const [
          QuizQuestion(
            questionText: "What is the value of x if 2x + 15 = 35?",
            options: ["5", "10", "15", "20"],
            correctAnswerIndex: 1,
            hint: "Subtract 15 from both sides, then divide by 2.",
          ),
          QuizQuestion(
            questionText: "If set A has 3 elements and set B has 4 elements, and they are disjoint, how many elements are in A union B?",
            options: ["3", "4", "7", "12"],
            correctAnswerIndex: 2,
            hint: "Since they are disjoint, just add their element counts.",
          ),
          QuizQuestion(
            questionText: "Which of the following is a prime number?",
            options: ["9", "15", "21", "29"],
            correctAnswerIndex: 3,
            hint: "A prime number is only divisible by 1 and itself.",
          ),
        ];

      case "9-Biology":
        return const [
          QuizQuestion(
            questionText: "The primary organelle responsible for protein synthesis in cells is ...",
            options: ["Mitochondria", "Ribosome", "Nucleus", "Vacuole"],
            correctAnswerIndex: 1,
            hint: "These tiny structures are located on the rough endoplasmic reticulum.",
          ),
          QuizQuestion(
            questionText: "Which process converts glucose into carbon dioxide and water to release cellular energy?",
            options: ["Photosynthesis", "Cellular respiration", "Fermentation", "Mitosis"],
            correctAnswerIndex: 1,
            hint: "It takes place in the powerhouse (mitochondria) of the cell.",
          ),
          QuizQuestion(
            questionText: "What type of cell division results in four daughter cells with half the chromosome number of the parent cell?",
            options: ["Mitosis", "Meiosis", "Binary fission", "Budding"],
            correctAnswerIndex: 1,
            hint: "This division produces gametes for reproduction.",
          ),
        ];

      case "9-Physics":
        return const [
          QuizQuestion(
            questionText: "What is the SI unit of force?",
            options: ["Joule", "Watt", "Newton", "Pascal"],
            correctAnswerIndex: 2,
            hint: "It is named after Sir Isaac Newton.",
          ),
          QuizQuestion(
            questionText: "Work done is defined mathematically as the product of force and...",
            options: ["Velocity", "Displacement", "Time", "Acceleration"],
            correctAnswerIndex: 1,
            hint: "W = F * d * cos(theta)",
          ),
          QuizQuestion(
            questionText: "Which of the following is a scalar quantity?",
            options: ["Velocity", "Acceleration", "Mass", "Force"],
            correctAnswerIndex: 2,
            hint: "This quantity has only magnitude, without direction.",
          ),
        ];

      case "9-Chemistry":
        return const [
          QuizQuestion(
            questionText: "The modern periodic table is organized based on which property?",
            options: ["Atomic mass", "Atomic number", "Neutron number", "Melting point"],
            correctAnswerIndex: 1,
            hint: "This represents the exact number of protons in an atom's nucleus.",
          ),
          QuizQuestion(
            questionText: "Which pH value represents a strong acid?",
            options: ["1.5", "7.0", "9.4", "13.0"],
            correctAnswerIndex: 0,
            hint: "Acidic values are less than 7; the lower the pH, the stronger the acid.",
          ),
          QuizQuestion(
            questionText: "What is the chemical symbol for Sodium?",
            options: ["S", "So", "Na", "K"],
            correctAnswerIndex: 2,
            hint: "It comes from the Latin word 'Natrium'.",
          ),
        ];

      case "9-Geography":
        return const [
          QuizQuestion(
            questionText: "Which of the following is the largest river in the world by water discharge volume?",
            options: ["Nile River", "Amazon River", "Yangtze River", "Mississippi River"],
            correctAnswerIndex: 1,
            hint: "This magnificent river flows through South America.",
          ),
          QuizQuestion(
            questionText: "The layer of the atmosphere closest to earth where all weather changes occur is the...",
            options: ["Stratosphere", "Mesosphere", "Troposphere", "Thermosphere"],
            correctAnswerIndex: 2,
            hint: "It spans up to about 12 km altitude.",
          ),
          QuizQuestion(
            questionText: "The angular distance of a place north or south of the earth's equator is called...",
            options: ["Longitude", "Latitude", "Altitude", "Prime Meridian"],
            correctAnswerIndex: 1,
            hint: "These run horizontally parallel to the equator.",
          ),
        ];

      case "9-History":
        return const [
          QuizQuestion(
            questionText: "Which ancient civilization built the great pyramids at Giza under Pharaoh leadership?",
            options: ["Mesopotamia", "Egyptians", "Romans", "Greeks"],
            correctAnswerIndex: 1,
            hint: "They developed writing called hieroglyphs along the Nile.",
          ),
          QuizQuestion(
            questionText: "Who was the first emperor of the unified German Empire in 1871?",
            options: ["Wilhelm I", "Bismarck", "Adolf Hitler", "Frederick Great"],
            correctAnswerIndex: 0,
            hint: "He was crowned at the Palace of Versailles.",
          ),
          QuizQuestion(
            questionText: "In which year did the famous French Revolution begin with the storming of the Bastille?",
            options: ["1776", "1789", "1804", "1815"],
            correctAnswerIndex: 1,
            hint: "The slogan was 'Liberte, egalite, fraternite'.",
          ),
        ];

      case "9-Civics":
        return const [
          QuizQuestion(
            questionText: "What is the supreme law of the land in a constitutional country?",
            options: ["Regional laws", "The Constitution", "Criminal code", "Civil regulations"],
            correctAnswerIndex: 1,
            hint: "No other laws can contradict its principles.",
          ),
          QuizQuestion(
            questionText: "In a democratic state, whom does supreme power or sovereignty reside in?",
            options: ["The President", "The Military", "The People", "The Parliament"],
            correctAnswerIndex: 2,
            hint: "A government 'of the people, by the people, for the people'.",
          ),
          QuizQuestion(
            questionText: "The process of peaceful dispute settlement by involving an impartial third party is...",
            options: ["Arbitration", "Boycott", "Conflict", "Protest"],
            correctAnswerIndex: 0,
            hint: "This term sounds similar to 'arbitrator'.",
          ),
        ];

      case "9-Agriculture":
        return const [
          QuizQuestion(
            questionText: "The practice of growing crops and raising animals together on the same farm is...",
            options: ["Mono-cropping", "Mixed farming", "Shifting cultivation", "Horticulture"],
            correctAnswerIndex: 1,
            hint: "It diversifies risk and optimizes resource use.",
          ),
          QuizQuestion(
            questionText: "Which soil type holds the highest amount of water due to small pore spacing?",
            options: ["Sandy soil", "Silt soil", "Clay soil", "Peat soil"],
            correctAnswerIndex: 2,
            hint: "It is smooth when wet and hardens heavily when dry.",
          ),
          QuizQuestion(
            questionText: "The process of introducing beneficial insects to control agricultural crop pests is...",
            options: ["Chemical control", "Biological control", "Mechanical control", "Cultural control"],
            correctAnswerIndex: 1,
            hint: "It uses natural predator-prey relationships instead of chemical sprays.",
          ),
        ];

      // ================= GRADE 10 SUBJECT QUIZZES =================
      case "10-Mathematics":
        return const [
          QuizQuestion(
            questionText: "What is the value of log10(1000) using base 10?",
            options: ["1", "2", "3", "4"],
            correctAnswerIndex: 2,
            hint: "10 raised to what power is equal to 1000?",
          ),
          QuizQuestion(
            questionText: "If f(x) = x^2 + 3, what is the value of f(4)?",
            options: ["11", "16", "19", "25"],
            correctAnswerIndex: 2,
            hint: "Substitute 4 in place of x: (4^2) + 3.",
          ),
          QuizQuestion(
            questionText: "What is the distance between points (0,0) and (3,4) in coordinate geometry?",
            options: ["5", "7", "25", "12"],
            correctAnswerIndex: 0,
            hint: "Use Pythagoras: sqrt(a^2 + b^2).",
          ),
        ];

      case "10-Biology":
        return const [
          QuizQuestion(
            questionText: "Which blood cells are primary defenders responsible for fighting body infections?",
            options: ["Red blood cells", "White blood cells", "Platelets", "Plasma"],
            correctAnswerIndex: 1,
            hint: "Also called leukocytes, they travel to wound/infection sites.",
          ),
          QuizQuestion(
            questionText: "What is the primary green pigment used by plants to absorb sunlight during photosynthesis?",
            options: ["Carotenoid", "Chlorophyll", "Xanthophyll", "Phycobilin"],
            correctAnswerIndex: 1,
            hint: "It absorbs blue and red spectrums and reflects green lights.",
          ),
          QuizQuestion(
            questionText: "In genetics, what is the phenotype ratio of a monohybrid cross in the F2 generation?",
            options: ["1:1", "1:2:1", "3:1", "9:3:3:1"],
            correctAnswerIndex: 2,
            hint: "Like Gregor Mendel's classic tall vs dwarf pea plants ratio.",
          ),
        ];

      case "10-Physics":
        return const [
          QuizQuestion(
            questionText: "Which laws state that momentum before collision is equal to momentum after under no external force?",
            options: ["Newton's First Law", "Law of Conservation of Momentum", "Kepler's Law", "Ohm's Law"],
            correctAnswerIndex: 1,
            hint: "It means momentum is conserved during action.",
          ),
          QuizQuestion(
            questionText: "Which mirror is famously used as a wide rear-view mirror in motorcars?",
            options: ["Concave mirror", "Convex mirror", "Plane mirror", "Parabolic mirror"],
            correctAnswerIndex: 1,
            hint: "It curves outwards to provide a wider field of view.",
          ),
          QuizQuestion(
            questionText: "The rate of electrical energy consumption over time is measured in which SI units?",
            options: ["Ohm", "Ampere", "Volt", "Watt"],
            correctAnswerIndex: 3,
            hint: "Power = Voltage * Current, measured in W.",
          ),
        ];

      case "10-Chemistry":
        return const [
          QuizQuestion(
            questionText: "What type of chemical bond is formed by complete transfer of electrons between atoms?",
            options: ["Covalent bond", "Ionic bond", "Metallic bond", "Hydrogen bond"],
            correctAnswerIndex: 1,
            hint: "Usually forms between metals and non-metals.",
          ),
          QuizQuestion(
            questionText: "What is the common household name of the compound Sodium Bicarbonate (NaHCO3)?",
            options: ["Baking soda", "Table salt", "Bleach", "Vinegar"],
            correctAnswerIndex: 0,
            hint: "Used widely in baking as a leavening agent.",
          ),
          QuizQuestion(
            questionText: "Hydrocarbons containing at least one double carbon-carbon covalent bond are called...",
            options: ["Alkanes", "Alkenes", "Alkynes", "Alcohols"],
            correctAnswerIndex: 1,
            hint: "Their suffix ends in -ene.",
          ),
        ];

      case "10-Geography":
        return const [
          QuizQuestion(
            questionText: "What is the highest mountain peak in Africa?",
            options: ["Mount Semien", "Mount Kenya", "Mount Kilimanjaro", "Mount Elgon"],
            correctAnswerIndex: 2,
            hint: "It is located in Tanzania and is a dormant volcano.",
          ),
          QuizQuestion(
            questionText: "The process of physical and chemical breakdown of solid rocks on Earth is called...",
            options: ["Weathering", "Erosion", "Deposition", "Siltation"],
            correctAnswerIndex: 0,
            hint: "Note that it happens in-situ, without transportation.",
          ),
          QuizQuestion(
            questionText: "Which layer of the Earth sits directly below the outer crust?",
            options: ["Inner Core", "Outer Core", "Mantle", "Asthenosphere"],
            correctAnswerIndex: 2,
            hint: "It is composed of hot, semi-fluid silicate rocks.",
          ),
        ];

      case "10-History":
        return const [
          QuizQuestion(
            questionText: "The Berlin Conference of 1884 to partition Africa was hosted by which leader?",
            options: ["Napoleon Bonaparte", "Otto von Bismarck", "King Leopold II", "Queen Victoria"],
            correctAnswerIndex: 1,
            hint: "He was the Chancellor of Germany.",
          ),
          QuizQuestion(
            questionText: "In which year did the historic Battle of Adwa take place in Ethiopia?",
            options: ["1855", "1872", "1896", "1936"],
            correctAnswerIndex: 2,
            hint: "It is in the late 19th Century, March 1.",
          ),
          QuizQuestion(
            questionText: "Who was the prime minister of unified Italy during the unification era?",
            options: ["Mazzini", "Garibaldi", "Count Cavour", "Mussolini"],
            correctAnswerIndex: 2,
            hint: "He was the brilliant statesman of Piedmont-Sardinia.",
          ),
        ];

      case "10-Civics":
        return const [
          QuizQuestion(
            questionText: "Which organ of government is primarily responsible for interpreting the laws?",
            options: ["Legislature", "Executive", "Judiciary", "Federal Council"],
            correctAnswerIndex: 2,
            hint: "This comprises the Supreme Court and federal courts.",
          ),
          QuizQuestion(
            questionText: "In which year was the UN Universal Declaration of Human Rights (UDHR) approved?",
            options: ["1918", "1945", "1948", "1963"],
            correctAnswerIndex: 2,
            hint: "Three years after the conclusion of World War II.",
          ),
          QuizQuestion(
            questionText: "A set of active moral qualities that guide a helpful citizen's public duties is...",
            options: ["Nationalism", "Civic virtues", "Nepotism", "Anarchy"],
            correctAnswerIndex: 1,
            hint: "Includes honesty, integrity, and patriotism.",
          ),
        ];

      case "10-Agriculture":
        return const [
          QuizQuestion(
            questionText: "The primary plant nutrient highly responsible for green foliage growth is...",
            options: ["Phosphorus", "Potassium", "Nitrogen", "Calcium"],
            correctAnswerIndex: 2,
            hint: "It represents 'N' in the classic NPK commercial fertilizers.",
          ),
          QuizQuestion(
            questionText: "Which irrigation method is considered the most water-efficient?",
            options: ["Surface flooding", "Drip irrigation", "Sprinkler method", "Canal irrigation"],
            correctAnswerIndex: 1,
            hint: "It drops water directly and slowly onto plant roots.",
          ),
          QuizQuestion(
            questionText: "Waterlogged soils suffer primarily from a severe deficiency of...",
            options: ["Moisture", "Nitrogen", "Oxygen", "Humus"],
            correctAnswerIndex: 2,
            hint: "Saturated pores leave no space for air respiration.",
          ),
        ];

      // ================= GRADE 11 SUBJECT QUIZZES =================
      case "11-Mathematics":
        return const [
          QuizQuestion(
            questionText: "What is the derivative of the function f(x) = x^4?",
            options: ["4x", "4x^3", "x^3", "3x^4"],
            correctAnswerIndex: 1,
            hint: "Use power rule: d/dx(x^n) = n * x^(n-1).",
          ),
          QuizQuestion(
            questionText: "What is the limit of (x^2 - 1)/(x - 1) as x approaches 1?",
            options: ["0", "1", "2", "Undefined"],
            correctAnswerIndex: 2,
            hint: "Factor numerator to (x-1)(x+1) first, reduce, then substitute.",
          ),
          QuizQuestion(
            questionText: "If vectors A and B are orthogonal, what is their dot product?",
            options: ["-1", "0", "1", "Magnitude product"],
            correctAnswerIndex: 1,
            hint: "Cos of 90 degrees makes this product value zero.",
          ),
        ];

      case "11-Biology":
        return const [
          QuizQuestion(
            questionText: "What is the major structural component found in fungal cell walls?",
            options: ["Cellulose", "Peptidoglycan", "Chitin", "Lignin"],
            correctAnswerIndex: 2,
            hint: "It is also found in insect exoskeletons.",
          ),
          QuizQuestion(
            questionText: "Which plant hormone is responsible for rapid stem elongation and seed germination?",
            options: ["Auxins", "Gibberellins", "Abscisic Acid", "Ethylene"],
            correctAnswerIndex: 1,
            hint: "Discovered first in rice seedlings suffering 'foolish seedling' disease.",
          ),
          QuizQuestion(
            questionText: "Which cellular organelles are known as protein-sorting packaging hubs?",
            options: ["Lysosome", "Golgi apparatus", "Ribosome", "Endoplasmic reticulum"],
            correctAnswerIndex: 1,
            hint: "Often described as the cell's post office or shipping harbor.",
          ),
        ];

      case "11-Physics":
        return const [
          QuizQuestion(
            questionText: "What is the approximate theoretical escape velocity of the Earth?",
            options: ["8.0 km/s", "11.2 km/s", "42.1 km/s", "150 km/s"],
            correctAnswerIndex: 1,
            hint: "Speed needed to break free from Earth's gravity orbit.",
          ),
          QuizQuestion(
            questionText: "A thermodynamic process in which no net heat enters or leaves the system is...",
            options: ["Isothermal", "Isobaric", "Adiabatic", "Isochoric"],
            correctAnswerIndex: 2,
            hint: "Happens very rapidly or inside a heavily insulated cylinder.",
          ),
          QuizQuestion(
            questionText: "What is the vector cross product of two parallel vectors?",
            options: ["Their scalar product", "The zero vector", "Unit vector", "Infinity"],
            correctAnswerIndex: 1,
            hint: "Sine of 0 degrees makes cross product magnitude zero.",
          ),
        ];

      case "11-Chemistry":
        return const [
          QuizQuestion(
            questionText: "According to Le Chatelier, increasing pressure on global balance shifts the reaction to...",
            options: ["The left side", "The side with more gas moles", "The side with fewer gas moles", "No shift"],
            correctAnswerIndex: 2,
            hint: "System works to decrease the extra stress by shrinking moles.",
          ),
          QuizQuestion(
            questionText: "What is the hybridisation of carbon in a Methane (CH4) molecule?",
            options: ["sp", "sp2", "sp3", "dsp2"],
            correctAnswerIndex: 2,
            hint: "Tetrahedral shape with 4 single sigma carbon bonds.",
          ),
          QuizQuestion(
            questionText: "In organic chemistry, what is the chemical formula of Benzene?",
            options: ["C6H12", "C6H6", "C5H5", "CH4"],
            correctAnswerIndex: 1,
            hint: "The simplest aromatic ring structure.",
          ),
        ];

      case "11-Geography":
        return const [
          QuizQuestion(
            questionText: "Ethiopia is situated in which physiographic region of Africa?",
            options: ["Sahara Desert", "Horn of Africa", "Congo Basin", "Kalahari Plains"],
            correctAnswerIndex: 1,
            hint: "The easternmost extension peninsula of African continent.",
          ),
          QuizQuestion(
            questionText: "Which rift valley lake in Ethiopia is famous for being the deepest lake?",
            options: ["Lake Ziway", "Lake Shala", "Lake Langano", "Lake Awasa"],
            correctAnswerIndex: 1,
            hint: "It is highly alkaline and reaches a depth of over 260m.",
          ),
          QuizQuestion(
            questionText: "The ratio of map distance to real physical ground distance is map...",
            options: ["Legend", "Scale", "Direction", "Projection"],
            correctAnswerIndex: 1,
            hint: "Written like 1:50,000.",
          ),
        ];

      case "11-History":
        return const [
          QuizQuestion(
            questionText: "Which Ethiopian King moved the permanent imperial capital base to Gondar in 1636 AD?",
            options: ["Emperor Theodore II", "Emperor Fasilides", "Emperor Zara Yaqob", "Ras Alula"],
            correctAnswerIndex: 1,
            hint: "Famous for the massive stone castles (Fasil Ghebbi).",
          ),
          QuizQuestion(
            questionText: "Who was the Queen of Axum who historically visited King Solomon in Jerusalem?",
            options: ["Queen Makeda (Sheba)", "Empress Taytu", "Empress Zewditu", "Queen Mentewab"],
            correctAnswerIndex: 0,
            hint: "Her son Menelik I founded the Solomonic dynasty.",
          ),
          QuizQuestion(
            questionText: "The ancient Cradle of Mankind, Lucy (Dinknesh), was discovered in which river basin in Ethiopia?",
            options: ["Blue Nile Valley", "Awash River Basin (Hadar)", "Omo River Basin", "Wabe Shebelle"],
            correctAnswerIndex: 1,
            hint: "Discovered in 1974 in Afar region.",
          ),
        ];

      case "11-Civics":
        return const [
          QuizQuestion(
            questionText: "The current federal system of Ethiopia is structured based on which political principle?",
            options: ["Monarchy", "Multi-ethnic federalism", "Unitary dictatorship", "Confederation"],
            correctAnswerIndex: 1,
            hint: "Recognizes diverse regional nations, nationalities, and peoples.",
          ),
          QuizQuestion(
            questionText: "What is the primary responsibility of the House of Peoples' Representatives (HoPR)?",
            options: ["Enforcing bills", "Lawmaking / Legislation", "Military actions", "Judicial reviews"],
            correctAnswerIndex: 1,
            hint: "The legislative chamber of the Ethiopian Federal Government.",
          ),
          QuizQuestion(
            questionText: "Which human rights theory states that rights are moral entitlements from birth?",
            options: ["Positivist theory", "Natural rights theory", "Socialist theory", "Utilitarian theory"],
            correctAnswerIndex: 1,
            hint: "Rights are inalienable, universal, and inherent.",
          ),
        ];

      case "11-Agriculture":
        return const [
          QuizQuestion(
            questionText: "What is the native grain of Ethiopia, which is gluten-free and highly nutritious?",
            options: ["Wheat", "Barley", "Teff", "Sorghum"],
            correctAnswerIndex: 2,
            hint: "Used to make delicious injera pancake bread.",
          ),
          QuizQuestion(
            questionText: "The deliberate cultivation of forest trees along with traditional pasture crops is...",
            options: ["Deforestation", "Monoculture", "Agroforestry", "Silviculture"],
            correctAnswerIndex: 2,
            hint: "Combines trees and farming practices.",
          ),
          QuizQuestion(
            questionText: "The loss of fertile topsoil layers due to extreme wind and rain flows is called...",
            options: ["Siltation", "Soil erosion", "Mulching", "Terracing"],
            correctAnswerIndex: 1,
            hint: "Can be prevented by planting vegetation covers.",
          ),
        ];

      // ================= GRADE 12 SUBJECT QUIZZES =================
      case "12-Mathematics":
        return const [
          QuizQuestion(
            questionText: "What is the limit of (sin x) / x as x approaches 0?",
            options: ["0", "1", "Infinity", "Undefined"],
            correctAnswerIndex: 1,
            hint: "This is a fundamental trigonometric limit, provable by L'Hopital's Rule.",
          ),
          QuizQuestion(
            questionText: "What is the value of the definite integral of 2x from x=1 to x=3?",
            options: ["4", "6", "8", "9"],
            correctAnswerIndex: 2,
            hint: "The antiderivative is x^2. Evaluate (3^2) - (1^2).",
          ),
          QuizQuestion(
            questionText: "What is the focus of the parabola y^2 = 12x?",
            options: ["(3, 0)", "(0, 3)", "(6, 0)", "(-3, 0)"],
            correctAnswerIndex: 0,
            hint: "y^2 = 4px. Solve 4p = 12.",
          ),
        ];

      case "12-Biology":
        return const [
          QuizQuestion(
            questionText: "What is the primary site of sound reception inside the human ear?",
            options: ["Tympanic membrane", "Semicircular canals", "Cochlea", "Auditory nerve"],
            correctAnswerIndex: 2,
            hint: "Contains the spiral Organ of Corti with hair cells.",
          ),
          QuizQuestion(
            questionText: "According to modern taxonomy families, humans belong to which group?",
            options: ["Hominidae", "Felidae", "Pongidae", "Canidae"],
            correctAnswerIndex: 0,
            hint: "An evolutionary family of great primates.",
          ),
          QuizQuestion(
            questionText: "What is the term for a symbiotic relationship where one species benefits and the other is unaffected?",
            options: ["Mutualism", "Parasitism", "Commensalism", "Competition"],
            correctAnswerIndex: 2,
            hint: "Like barnacles on a whale or cattle egrets eating insects.",
          ),
        ];

      case "12-Physics":
        return const [
          QuizQuestion(
            questionText: "In electromagnetic theory, which law states that induced EMF opposes the magnetic change?",
            options: ["Lenz's Law", "Faraday's Law of Induction", "Coulomb's Law", "Ampere's Law"],
            correctAnswerIndex: 0,
            hint: "A negative sign is added to represent this conservation of energy rule.",
          ),
          QuizQuestion(
            questionText: "Which fundamental quantum particle mediates the strong nuclear force that binds quarks?",
            options: ["Photon", "Gluon", "Graviton", "W boson"],
            correctAnswerIndex: 1,
            hint: "Think of particle acting like 'glue' inside hadrons.",
          ),
          QuizQuestion(
            questionText: "Who originally proposed and explained the quantum theory photoelectric effect?",
            options: ["Isaac Newton", "Niels Bohr", "Albert Einstein", "Max Planck"],
            correctAnswerIndex: 2,
            hint: "Awarded the Nobel Prize in Physics 1921 for this explanation.",
          ),
        ];

      case "12-Chemistry":
        return const [
          QuizQuestion(
            questionText: "Which electrochemical cell converts chemical energy into electrical energy spontaneously?",
            options: ["Galvanic / Voltaic cell", "Electrolytic cell", "Battery recharger", "Fuel synthesizer"],
            correctAnswerIndex: 0,
            hint: "Like standard copper-zinc batteries.",
          ),
          QuizQuestion(
            questionText: "What is the rate-determining step in a multi-step chemical reaction mechanism?",
            options: ["The fastest step", "The slowest step", "The initial step", "The equilibrium step"],
            correctAnswerIndex: 1,
            hint: "Like a bottleneck on a highway determining overall speed.",
          ),
          QuizQuestion(
            questionText: "Which quantum number describes the spatial orientation of an electron orbital?",
            options: ["Principal quantum number", "Azimuthal quantum number", "Magnetic quantum number", "Spin quantum number"],
            correctAnswerIndex: 2,
            hint: "Represented by symbol 'm_l'.",
          ),
        ];

      case "12-Geography":
        return const [
          QuizQuestion(
            questionText: "What is the geographical study of human population size, density, and growth dynamics?",
            options: ["Anthropology", "Demography", "Cartography", "Biogeography"],
            correctAnswerIndex: 1,
            hint: "Focuses on birth/death rates, migrations, and structures.",
          ),
          QuizQuestion(
            questionText: "Which GIS data model represents spatial features using points, lines, and polygons?",
            options: ["Raster model", "Vector model", "Grid model", "Triangulated model"],
            correctAnswerIndex: 1,
            hint: "Contrasts with raster grids of pixels.",
          ),
          QuizQuestion(
            questionText: "Which economic activity involves extraction of raw materials directly from nature?",
            options: ["Primary sector", "Secondary sector", "Tertiary sector", "Quaternary sector"],
            correctAnswerIndex: 0,
            hint: "Includes mining, agriculture, forestry, and fishing.",
          ),
        ];

      case "12-History":
        return const [
          QuizQuestion(
            questionText: "The League of Nations was founded primarily in response to which major global war?",
            options: ["World War I", "World War II", "Franco-Prussian War", "Cold War"],
            correctAnswerIndex: 0,
            hint: "Established in 1920 to prevent future global massacres.",
          ),
          QuizQuestion(
            questionText: "The decolonization process across Africa gained massive momentum during which decade?",
            options: ["1920s", "1940s", "1960s", "1980s"],
            correctAnswerIndex: 2,
            hint: "Often called 'The Year of Africa' representing 17 newly sovereign states.",
          ),
          QuizQuestion(
            questionText: "Which agreement officially marked the end of the 1950-1953 Korean War?",
            options: ["Treaty of Versailles", "Panmunjom Armistice Agreement", "Yalta Agreement", "Treaty of Portsmouth"],
            correctAnswerIndex: 1,
            hint: "Signed in 1953, establishing the Demilitarized Zone (DMZ).",
          ),
        ];

      case "12-Civics":
        return const [
          QuizQuestion(
            questionText: "The fundamental concept 'Rule of Law' fundamentally implies that...",
            options: ["The king or premier is above laws", "Everyone is strictly equal before the law", "Only judges write laws", "Police rules with absolute power"],
            correctAnswerIndex: 1,
            hint: "Guarantees accountability, equality, and justice across all classes.",
          ),
          QuizQuestion(
            questionText: "Which standard obligation is a legal duty that citizens must render to state governments?",
            options: ["Volunteering in charities", "Paying taxes on income", "Joining political parties", "Attending public rallies"],
            correctAnswerIndex: 1,
            hint: "Mandatory contributions that finance public infrastructure.",
          ),
          QuizQuestion(
            questionText: "A supreme state power characterized by absolute independence from external forces is...",
            options: ["Autocracy", "Sovereignty", "Federalism", "Democracy"],
            correctAnswerIndex: 1,
            hint: "Represents supreme authority within territorial boundaries.",
          ),
        ];

      case "12-Agriculture":
        return const [
          QuizQuestion(
            questionText: "The genetic crossing of two distinct plant varieties to create superior offspring seeds is...",
            options: ["Cloning", "Hybridization", "Grafting", "Vegetative layering"],
            correctAnswerIndex: 1,
            hint: "Produces 'hybrid vigor' (heterosis) with elevated stress tolerances.",
          ),
          QuizQuestion(
            questionText: "Which plant disease is caused by fungi and severely affects coffee production in Ethiopia?",
            options: ["Stem Rust", "Coffee Berry Disease", "Late Blight", "Powdery Mildew"],
            correctAnswerIndex: 1,
            hint: "Attacks coffee berries directly, causing them to turn black and decay.",
          ),
          QuizQuestion(
            questionText: "The practice of growing crops in sand, gravel, or liquid, without using natural soil, is called...",
            options: ["Hydroponics", "Aquaponics", "Organic tillage", "Terracing"],
            correctAnswerIndex: 0,
            hint: "Nutrients are dissolved directly in the water feeds.",
          ),
        ];

      default:
        return _getQuestionsForGradeFallback(grade);
    }
  }

  // Original fallback grade questions
  List<QuizQuestion> _getQuestionsForGradeFallback(int grade) {
    if (grade == 9) {
      return const [
        QuizQuestion(
          questionText: "What is the value of x if 3x - 7 = 14?",
          options: ["5", "6", "7", "8"],
          correctAnswerIndex: 2,
          hint: "Add 7 to both sides, then divide by 3.",
        ),
        QuizQuestion(
          questionText: "What is the powerhouse of the cell?",
          options: ["Nucleus", "Ribosome", "Mitochondria", "Golgi Apparatus"],
          correctAnswerIndex: 2,
          hint: "It generates most of the cell's supply of adenosine triphosphate (ATP).",
        ),
        QuizQuestion(
          questionText: "Which of the following is a physical quantity that has both magnitude and direction?",
          options: ["Speed", "Mass", "Velocity", "Temperature"],
          correctAnswerIndex: 2,
          hint: "Unlike speed, this vector quantity includes direction.",
        ),
        QuizQuestion(
          questionText: "What is the atomic number of Hydrogen, the most abundant element in the universe?",
          options: ["1", "2", "6", "8"],
          correctAnswerIndex: 0,
          hint: "It is the very first element on the periodic table.",
        ),
      ];
    } else if (grade == 10) {
      return const [
        QuizQuestion(
          questionText: "Which blood cells are highly responsible for fighting infections in the human body?",
          options: ["Red blood cells", "White blood cells", "Platelets", "Plasma"],
          correctAnswerIndex: 1,
          hint: "Also called leukocytes, they act as the body's defense shields.",
        ),
        QuizQuestion(
          questionText: "What type of chemical bond is formed when one element loses electrons and another gains them?",
          options: ["Covalent bond", "Ionic bond", "Metallic bond", "Hydrogen bond"],
          correctAnswerIndex: 1,
          hint: "It involves electrostatic attraction between oppositely charged ions.",
        ),
        QuizQuestion(
          questionText: "What is the primary pigment used by plants during photosynthesis to absorb light energy?",
          options: ["Carotenoid", "Chlorophyll", "Xanthophyll", "Phycobilin"],
          correctAnswerIndex: 1,
          hint: "It gives plants their characteristic green color.",
        ),
        QuizQuestion(
          questionText: "Which laws explain the mathematical relationship between force, mass, and acceleration?",
          options: ["Kepler's Laws", "Newton's Laws of Motion", "Ohm's Law", "First Law of Thermodynamics"],
          correctAnswerIndex: 1,
          hint: "F = ma is the second of these famous laws proposed in 1687.",
        ),
      ];
    } else if (grade == 11) {
      return const [
        QuizQuestion(
          questionText: "What is the vector cross product of two parallel vectors?",
          options: ["Their product", "Zero vector", "Unit vector", "Infinity"],
          correctAnswerIndex: 1,
          hint: "Since the angle theta is 0, sin(0) makes the cross product zero.",
        ),
        QuizQuestion(
          questionText: "In organic chemistry, what is the chemical formula of Benzene, the simplest aromatic hydrocarbon?",
          options: ["C6H12", "C6H6", "C5H5", "CH4"],
          correctAnswerIndex: 1,
          hint: "It represents a beautiful hexagonal ring with alternating double bonds.",
        ),
        QuizQuestion(
          questionText: "Which ancient trading empire was located in northern Ethiopia and Eritrea around the 1st to 8th centuries AD?",
          options: ["Zagwe Dynasty", "Kingdom of Aksum", "Kushite Empire", "Harar Sultanate"],
          correctAnswerIndex: 1,
          hint: "Known for towering stone obelisks (stele) and introducing Christianity.",
        ),
        QuizQuestion(
          questionText: "What is the derivative of f(x) = x^3 with respect to x?",
          options: ["3x", "3x^2", "x^2", "3"],
          correctAnswerIndex: 1,
          hint: "Use the Power Rule: d/dx(x^n) = n * x^(n-1).",
        ),
      ];
    } else if (grade == 12) {
      return const [
        QuizQuestion(
          questionText: "What is the limit of (sin x) / x as x approaches 0?",
          options: ["0", "1", "Infinity", "Undefined"],
          correctAnswerIndex: 1,
          hint: "This is a fundamental trigonometric limit, also provable by L'Hopital's Rule.",
        ),
        QuizQuestion(
          questionText: "In electromagnetic theory, which law states that an induced EMF is proportional to the rate of change of magnetic flux?",
          options: ["Ohm's Law", "Faraday's Law of Induction", "Coulomb's Law", "Ampere's Law"],
          correctAnswerIndex: 1,
          hint: "A negative sign is added to this law by Lenz to indicate direction.",
        ),
        QuizQuestion(
          questionText: "What is the value of the definite integral of 2x from x=1 to x=3?",
          options: ["4", "6", "8", "9"],
          correctAnswerIndex: 2,
          hint: "The antiderivative is x^2. Evaluate (3^2) - (1^2).",
        ),
        QuizQuestion(
          questionText: "Which fundamental particle is responsible for mediating the strong nuclear force that binds quarks together?",
          options: ["Photon", "Gluon", "W boson", "Graviton"],
          correctAnswerIndex: 1,
          hint: "Think of the word 'glue' because it glues quarks together.",
        ),
      ];
    } else {
      // Default / fallback list
      return const [
        QuizQuestion(
          questionText: "What is the capital city of Ethiopia?",
          options: ["Asmara", "Addis Ababa", "Nairobi", "Djibouti"],
          correctAnswerIndex: 1,
          hint: "It is the third highest capital in the world and means 'New Flower'.",
        ),
        QuizQuestion(
          questionText: "Which chemical element has the symbol 'Au'?",
          options: ["Silver", "Gold", "Copper", "Platinum"],
          correctAnswerIndex: 1,
          hint: "It has atomic number 79 and is highly prized for jewelry and investment.",
        ),
        QuizQuestion(
          questionText: "In which year did Ethiopia defeat the Italian army at the Battle of Adwa?",
          options: ["1889", "1896", "1935", "1941"],
          correctAnswerIndex: 1,
          hint: "It happened on the 1st of March in a leap year during the late 19th century.",
        ),
        QuizQuestion(
          questionText: "What is the primary power generation source of the Grand Ethiopian Renaissance Dam (GERD)?",
          options: ["Hydroelectric", "Geothermal", "Solar Power", "Wind Energy"],
          correctAnswerIndex: 0,
          hint: "It utilizes the mighty Blue Nile flow running through massive water turbos.",
        ),
      ];
    }
  }

  /// Initialize AdMob and trigger async loads
  void _initAdMob() {
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // --- BANNER AD ---
  void _loadBannerAd() {
    // Safely dispose prior banner reference if reloading
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
          debugPrint('BannerAd failed to load: $err. Code: ${err.code}');
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
    _bannerAd?.load();
  }

  // --- INTERSTITIAL AD ---
  void _loadInterstitialAd() {
    // Safely dispose prior interstitial reference if preloading fresh
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) {
                setState(() {
                  _isInterstitialAdLoaded = false;
                  _interstitialAd = null;
                });
                _finishQuizAfterAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('InterstitialAd failed to show: $err');
              ad.dispose();
              if (mounted) {
                setState(() {
                  _isInterstitialAdLoaded = false;
                  _interstitialAd = null;
                });
                _finishQuizAfterAd(); // Fail gracefully and proceed
              }
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
          if (mounted) {
            setState(() {
              _isInterstitialAdLoaded = false;
              _interstitialAd = null;
            });
          }
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not loaded. Fallback directly.');
      _finishQuizAfterAd();
    }
  }

  // --- REWARDED AD ---
  void _loadRewardedAd() {
    // Safely dispose prior rewarded reference if preloading fresh
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) {
                setState(() {
                  _isRewardedAdLoaded = false;
                  _rewardedAd = null;
                });
                _loadRewardedAd(); // Preload next one
              }
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('Rewarded ad failed to show: $err');
              ad.dispose();
              if (mounted) {
                setState(() {
                  _isRewardedAdLoaded = false;
                  _rewardedAd = null;
                });
                _loadRewardedAd();
              }
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded ad failed to load: $err');
          if (mounted) {
            setState(() {
              _isRewardedAdLoaded = false;
              _rewardedAd = null;
            });
          }
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          if (mounted) {
            setState(() {
              _hasUsedHintForCurrentQuestion = true;
            });
            _showHintDialog();
          }
        },
      );
    } else {
      // "Ad failed to load: 3" No Fill handling
      // Provide a graceful fallback to ensure the student's learning flow is not halted
      debugPrint('Rewarded ad not ready. Fallback active.');
      if (mounted) {
        setState(() {
          _hasUsedHintForCurrentQuestion = true;
        });
        _showHintDialog(isFallback: true);
      }
      if (mounted) {
        _loadRewardedAd(); // Attempt to load a new ad
      }
    }
  }

  // --- Helpers & Actions ---
  void _submitAnswer() {
    if (_selectedAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an option before continuing!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check correctness
    final currentQ = _questions[_currentQuestionIndex];
    if (_selectedAnswerIndex == currentQ.correctAnswerIndex) {
      _score++;
    }

    // Advance Quiz or Show Interstitial at the finish
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasUsedHintForCurrentQuestion = false;
      });
    } else {
      // Quiz Finished! trigger Interstitial Ad
      _showInterstitialAd();
    }
  }

  void _finishQuizAfterAd() {
    if (mounted) {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _score = 0;
      _quizFinished = false;
      _hasUsedHintForCurrentQuestion = false;
    });
    // Preload fresh ads for the brand-new run
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _showHintDialog({bool isFallback = false}) {
    final currentQ = _questions[_currentQuestionIndex];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF0F172A),
          title: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                isFallback ? "Unlocked Fast-Hint" : "Quiz Hint Unlocked!",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFallback)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Note: No video loading wait, granted hint instantly!",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              Text(
                currentQ.hint,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Help Tip: Match with options closely.",
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Got it!",
                style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // --- Memory Leak Prevention ---
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final primaryBlue = const Color(0xFF0D2353);

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.subject != null
              ? "${widget.subject} - Grade ${widget.grade}"
              : "Smart X Quiz Arena",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Quick dialog describing reward schema
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Quiz Information"),
                  content: const Text(
                    "This test utilizes AdMob Test Ads:\n"
                    "• Rewarded Video Ads play if you unlock a Quiz Hint.\n"
                    "• Interstitial Ads run when the test successfully finishes.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: EducationWatermarkBackground(
        isDarkMode: !isLight,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _quizFinished
                    ? _buildResultsView(isLight, primaryBlue)
                    : _buildQuestionsView(isLight, primaryBlue),
              ),
              
              // --- Bottom Anchor AdMob Banner ---
              if (_isBannerAdLoaded && _bannerAd != null)
                Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: AdWidget(ad: _bannerAd!),
                )
              else
                // Elegant tiny matching space fallback (no jarring layout shift)
                Container(
                  height: 50,
                  color: isLight ? Colors.grey[200] : const Color(0xFF1E293B),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.ad_units, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        "Banner Ad Area (Test AdMob Loaded)",
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
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

  // --- QUESTIONS MAIN LAYOUT ---
  Widget _buildQuestionsView(bool isLight, Color primaryBlue) {
    final currentQ = _questions[_currentQuestionIndex];
    final double percentage = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant Header Progress Bento Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLight ? Colors.grey[300]! : Colors.transparent,
                  ),
                ),
                child: Text(
                  "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isLight ? primaryBlue : const Color(0xFF38BDF8),
                  ),
                ),
              ),
              
              // REWARDED VIDEO HINT BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  if (_hasUsedHintForCurrentQuestion) {
                    _showHintDialog(isFallback: false);
                  } else {
                    _showRewardedAd();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B), // Vibrant Amber Accent
                  foregroundColor: Colors.white,
                  elevation: 1.5,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: Text(
                  _hasUsedHintForCurrentQuestion ? "Hint Active 💡" : "Get Hint 💡",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Smoother Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: isLight ? Colors.grey[300] : const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLight ? const Color(0xFF1E88E5) : const Color(0xFF0EA5E9),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // STYLISH QUESTION CARD
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight 
                    ? [Colors.white, const Color(0xFFF8FAFC)]
                    : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isLight ? Colors.grey[200]! : const Color(0xFF334155),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFF1E88E5),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "ACADEMY CHALLENGE",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentQ.questionText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: isLight ? primaryBlue : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // MULTIPLE CHOICE OPTIONS
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentQ.options.length,
            itemBuilder: (context, index) {
              final optionText = currentQ.options[index];
              final isSelected = _selectedAnswerIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswerIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isLight
                                ? const Color(0xFF1E88E5).withValues(alpha: 0.08)
                                : const Color(0xFF38BDF8).withValues(alpha: 0.12))
                            : (isLight ? Colors.white : const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8))
                              : (isLight ? Colors.grey[200]! : Colors.transparent),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Modern circular indexing
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8))
                                  : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isLight ? primaryBlue : Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? (isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8))
                                    : (isLight ? primaryBlue : const Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: isLight ? const Color(0xFF1E88E5) : const Color(0xFF38BDF8),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 18),
          
          // ACTION BUTTONS (SUBMIT/NEXT)
          ElevatedButton(
            onPressed: _submitAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLight ? primaryBlue : const Color(0xFF38BDF8),
              foregroundColor: isLight ? Colors.white : Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Text(
              _currentQuestionIndex == _questions.length - 1 ? "Submit Challenge" : "Continue",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }

  // --- FINAL SCORE RESULTS VIEW ---
  Widget _buildResultsView(bool isLight, Color primaryBlue) {
    final double correctRatio = _score / _questions.length;
    final bool passed = correctRatio >= 0.75;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Card(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful animated-like badge
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.red[500]!.withValues(alpha: 0.12),
                ),
                child: Icon(
                  passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                  color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                passed ? "Congratulations!" : "Keep Practicing!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isLight ? primaryBlue : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? "You qualified with flying colors in Smart X Arena!"
                    : "Review the course materials and syllabus and try again.",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // BENTO RESULT DIGIT BOXES
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? Colors.grey[200]! : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text("SCORE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${_score}/${_questions.length}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isLight ? primaryBlue : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? Colors.grey[200]! : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text("PERCENTAGE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${(correctRatio * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // RESTART BUTTON
              ElevatedButton.icon(
                onPressed: _restartQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  "Restart Arena Challenge",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // GO BACK HOME BUTTON
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: isLight ? Colors.grey[300]! : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  "Exit to Lobby",
                  style: TextStyle(
                    color: isLight ? primaryBlue : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
