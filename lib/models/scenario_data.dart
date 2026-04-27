class ScenarioOption {
  final String id;
  final String text;
  final Map<String, int> intelligencePoints;

  const ScenarioOption({
    required this.id,
    required this.text,
    required this.intelligencePoints,
  });
}

class Scenario {
  final int id;
  final String title;
  final String description;
  final List<ScenarioOption> options;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });
}

const List<Scenario> scenarios = [
  Scenario(
    id: 1,
    title: 'অপরিচিত শহর',
    description:
        'আপনি একটি নতুন শহরে এসেছেন এবং আপনার হোটেল থেকে একটি বিখ্যাত জাদুঘরে যেতে হবে। আপনার মোবাইলে ইন্টারনেট নেই। আপনি কীভাবে গন্তব্যে পৌঁছাবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'একটি মানচিত্র কিনে রাস্তা খুঁজে বের করবেন',
        intelligencePoints: {'visual': 4, 'logical': 2},
      ),
      ScenarioOption(
        id: 'b',
        text: 'স্থানীয় লোকদের কাছে জিজ্ঞাসা করে দিক নির্দেশনা নেবেন',
        intelligencePoints: {'interpersonal': 4, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'সূর্যের অবস্থান ও দিক অনুসারে আনুমানিক পথ বের করবেন',
        intelligencePoints: {'logical': 3, 'visual': 2, 'intrapersonal': 1},
      ),
      ScenarioOption(
        id: 'd',
        text: 'চারপাশের প্রাকৃতিক চিহ্ন (যেমন পাহাড়, নদী) দেখে দিক নির্ণয় করবেন',
        intelligencePoints: {'naturalistic': 4, 'visual': 2},
      ),
    ],
  ),
  Scenario(
    id: 2,
    title: 'টিম প্রজেক্ট',
    description:
        'আপনি একটি গুরুত্বপূর্ণ প্রজেক্টে দলনেতা হিসেবে নিযুক্ত হয়েছেন। দলের সদস্যদের মধ্যে মতপার্থক্য দেখা দিয়েছে। আপনি কীভাবে এই সমস্যা সমাধান করবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'সবার মতামত শুনে একটি যৌক্তিক সিদ্ধান্তে পৌঁছাবেন',
        intelligencePoints: {'logical': 3, 'linguistic': 2, 'interpersonal': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'দলের সদস্যদের সাথে ব্যক্তিগতভাবে কথা বলে মতপার্থক্যের কারণ বুঝবেন',
        intelligencePoints: {'interpersonal': 4, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'সমস্যার একটি ভিজ্যুয়াল ম্যাপ তৈরি করে সমাধান খুঁজবেন',
        intelligencePoints: {'visual': 4, 'logical': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'নিজের অভিজ্ঞতা থেকে সবচেয়ে ভালো সমাধান বেছে নেবেন',
        intelligencePoints: {'intrapersonal': 4, 'logical': 1},
      ),
    ],
  ),
  Scenario(
    id: 3,
    title: 'সংগীত অনুষ্ঠান',
    description:
        'আপনি একটি সংগীত অনুষ্ঠানে গেছেন। অনুষ্ঠান শেষে আপনার বন্ধু জানতে চায় আপনার অভিজ্ঞতা কেমন ছিল। আপনি কীভাবে আপনার অভিজ্ঞতা বর্ণনা করবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'সংগীতের সুর, তাল ও ছন্দের বিস্তারিত বর্ণনা দেবেন',
        intelligencePoints: {'musical': 5, 'linguistic': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'অনুষ্ঠানের আবেগময় মুহূর্তগুলো ভাষায় প্রকাশ করবেন',
        intelligencePoints: {'linguistic': 4, 'intrapersonal': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'অনুষ্ঠানের পরিবেশ ও দৃশ্যের বর্ণনা দেবেন',
        intelligencePoints: {'visual': 4, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'অনুষ্ঠানে উপস্থিত লোকজন ও তাদের প্রতিক্রিয়া নিয়ে আলোচনা করবেন',
        intelligencePoints: {'interpersonal': 4, 'linguistic': 2},
      ),
    ],
  ),
  Scenario(
    id: 4,
    title: 'নতুন দক্ষতা',
    description: 'আপনি একটি নতুন দক্ষতা শিখতে চান। আপনি কোন পদ্ধতি বেছে নেবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'ভিডিও টিউটোরিয়াল দেখে নিজে অনুশীলন করবেন',
        intelligencePoints: {'visual': 3, 'intrapersonal': 2, 'physical': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'একজন অভিজ্ঞ ব্যক্তির কাছ থেকে সরাসরি শিখবেন',
        intelligencePoints: {'interpersonal': 3, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'বই পড়ে ধাপে ধাপে শিখবেন',
        intelligencePoints: {'linguistic': 4, 'logical': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'বারবার চেষ্টা করে ভুল-শুদ্ধির মাধ্যমে শিখবেন',
        intelligencePoints: {'physical': 3, 'intrapersonal': 3},
      ),
    ],
  ),
  Scenario(
    id: 5,
    title: 'প্রকৃতিতে হারিয়ে যাওয়া',
    description:
        'আপনি বন্ধুদের সাথে একটি অরণ্যে ভ্রমণে গেছেন এবং দলছুট হয়ে গেছেন। সন্ধ্যা হয়ে আসছে। আপনি কী করবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'গাছপালা ও প্রাকৃতিক চিহ্ন দেখে পথ খুঁজবেন',
        intelligencePoints: {'naturalistic': 5, 'logical': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'উঁচু স্থানে উঠে চারপাশের দৃশ্য দেখে দিক নির্ণয় করবেন',
        intelligencePoints: {'visual': 4, 'physical': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'তারা ও চাঁদের অবস্থান দেখে দিক নির্ণয় করবেন',
        intelligencePoints: {'logical': 4, 'naturalistic': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'শান্ত থেকে পরিস্থিতি বিশ্লেষণ করে সিদ্ধান্ত নেবেন',
        intelligencePoints: {'intrapersonal': 4, 'logical': 2},
      ),
    ],
  ),
  Scenario(
    id: 6,
    title: 'জটিল সমস্যা',
    description:
        'আপনার কাজে একটি জটিল সমস্যা দেখা দিয়েছে যা দীর্ঘদিন ধরে সমাধান করা যাচ্ছে না। আপনি কীভাবে এটি সমাধান করবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'সমস্যাটি ছোট ছোট অংশে ভেঙে পর্যায়ক্রমে সমাধান করবেন',
        intelligencePoints: {'logical': 5, 'intrapersonal': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'সমস্যাটি নিয়ে একটি ভিজ্যুয়াল ম্যাপ বা ডায়াগ্রাম তৈরি করবেন',
        intelligencePoints: {'visual': 4, 'logical': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'সহকর্মীদের সাথে ব্রেইনস্টর্মিং করবেন',
        intelligencePoints: {'interpersonal': 4, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'নিজের অবচেতন মনকে কাজ করতে দেওয়ার জন্য সমস্যা থেকে কিছুক্ষণ দূরে থাকবেন',
        intelligencePoints: {'intrapersonal': 5, 'logical': 1},
      ),
    ],
  ),
  Scenario(
    id: 7,
    title: 'নতুন ভাষা',
    description: 'আপনি একটি নতুন ভাষা শিখতে চান। আপনি কোন পদ্ধতি অবলম্বন করবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'ভাষার নিয়ম ও ব্যাকরণ শিখে অনুশীলন করবেন',
        intelligencePoints: {'linguistic': 4, 'logical': 2},
      ),
      ScenarioOption(
        id: 'b',
        text: 'ওই ভাষায় কথা বলা মানুষদের সাথে কথোপকথন করবেন',
        intelligencePoints: {'interpersonal': 3, 'linguistic': 3},
      ),
      ScenarioOption(
        id: 'c',
        text: 'ওই ভাষার গান শুনে ও গেয়ে শিখবেন',
        intelligencePoints: {'musical': 4, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'ছবি ও ভিজ্যুয়াল এইড ব্যবহার করে শব্দ মনে রাখবেন',
        intelligencePoints: {'visual': 4, 'linguistic': 2},
      ),
    ],
  ),
  Scenario(
    id: 8,
    title: 'শারীরিক চ্যালেঞ্জ',
    description:
        'আপনি একটি শারীরিক চ্যালেঞ্জে অংশগ্রহণ করেছেন (যেমন মারাথন দৌড়, পাহাড়ে চড়া)। আপনি কীভাবে প্রস্তুতি নেবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'নিয়মিত অনুশীলন ও শারীরিক প্রশিক্ষণ করবেন',
        intelligencePoints: {'physical': 5, 'intrapersonal': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'একটি বিস্তারিত প্রশিক্ষণ পরিকল্পনা তৈরি করবেন',
        intelligencePoints: {'logical': 4, 'intrapersonal': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'অন্যান্য অভিজ্ঞ ব্যক্তিদের পরামর্শ নেবেন',
        intelligencePoints: {'interpersonal': 4, 'linguistic': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'মানসিক প্রস্তুতি ও আত্মবিশ্বাস বাড়ানোর উপর জোর দেবেন',
        intelligencePoints: {'intrapersonal': 5, 'logical': 1},
      ),
    ],
  ),
  Scenario(
    id: 9,
    title: 'সৃজনশীল প্রকল্প',
    description:
        'আপনাকে একটি সৃজনশীল প্রকল্প (যেমন একটি অনুষ্ঠান আয়োজন, একটি শিল্পকর্ম তৈরি) করতে বলা হয়েছে। আপনি কীভাবে শুরু করবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'বিভিন্ন ধারণা নিয়ে স্কেচ বা ড্রয়িং করবেন',
        intelligencePoints: {'visual': 4, 'intrapersonal': 2},
      ),
      ScenarioOption(
        id: 'b',
        text: 'অনুরূপ প্রকল্পগুলি দেখে অনুপ্রেরণা নেবেন',
        intelligencePoints: {'visual': 3, 'intrapersonal': 3},
      ),
      ScenarioOption(
        id: 'c',
        text: 'একটি বিস্তারিত পরিকল্পনা ও সময়সূচি তৈরি করবেন',
        intelligencePoints: {'logical': 5, 'intrapersonal': 1},
      ),
      ScenarioOption(
        id: 'd',
        text: 'অন্যদের সাথে আলোচনা করে ধারণা সংগ্রহ করবেন',
        intelligencePoints: {'interpersonal': 4, 'linguistic': 2},
      ),
    ],
  ),
  Scenario(
    id: 10,
    title: 'প্রকৃতি পর্যবেক্ষণ',
    description:
        'আপনি একটি প্রাকৃতিক অভয়ারণ্যে ভ্রমণে গেছেন। সেখানে আপনি কী করতে সবচেয়ে বেশি আগ্রহী হবেন?',
    options: [
      ScenarioOption(
        id: 'a',
        text: 'বিভিন্ন প্রজাতির গাছপালা ও প্রাণী চিহ্নিত করবেন',
        intelligencePoints: {'naturalistic': 5, 'logical': 1},
      ),
      ScenarioOption(
        id: 'b',
        text: 'প্রকৃতির সৌন্দর্য ছবি বা স্কেচের মাধ্যমে ধারণ করবেন',
        intelligencePoints: {'visual': 4, 'naturalistic': 2},
      ),
      ScenarioOption(
        id: 'c',
        text: 'প্রকৃতির শব্দ ও সুর শুনে উপভোগ করবেন',
        intelligencePoints: {'musical': 4, 'naturalistic': 2},
      ),
      ScenarioOption(
        id: 'd',
        text: 'একাকী হাঁটতে হাঁটতে প্রকৃতির সাথে সংযোগ অনুভব করবেন',
        intelligencePoints: {'intrapersonal': 3, 'naturalistic': 3},
      ),
    ],
  ),
];
