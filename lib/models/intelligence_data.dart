class IntelligenceInfo {
  final String key;
  final String nameBn;
  final String nameEn;
  final List<String> strengths;
  final List<String> careers;

  const IntelligenceInfo({
    required this.key,
    required this.nameBn,
    required this.nameEn,
    required this.strengths,
    required this.careers,
  });
}

const List<IntelligenceInfo> intelligenceList = [
  IntelligenceInfo(
    key: 'musical',
    nameBn: 'সঙ্গীত বুদ্ধিমত্তা',
    nameEn: 'Musical Intelligence',
    strengths: [
      'সঙ্গীত তৈরি ও উপলব্ধি',
      'তাল ও লয় অনুধাবন',
      'বাদ্যযন্ত্র বাজানো',
      'গান গাওয়া',
    ],
    careers: [
      'সঙ্গীতজ্ঞ',
      'গায়ক',
      'সুরকার',
      'সংগীত পরিচালক',
      'শব্দ প্রকৌশলী',
      'সঙ্গীত শিক্ষক',
    ],
  ),
  IntelligenceInfo(
    key: 'visual',
    nameBn: 'স্থান-চাক্ষুষ বুদ্ধিমত্তা',
    nameEn: 'Visual-Spatial Intelligence',
    strengths: [
      'চিত্রকলা',
      'ভাস্কর্য',
      'নকশা',
      'স্থাপত্য',
      'দিকনির্ণয়',
    ],
    careers: [
      'শিল্পী',
      'নকশাকার',
      'স্থপতি',
      'ভূগোলবিদ',
      'নাবিক',
    ],
  ),
  IntelligenceInfo(
    key: 'linguistic',
    nameBn: 'ভাষাগত বুদ্ধিমত্তা',
    nameEn: 'Linguistic Intelligence',
    strengths: [
      'ভাব প্রকাশ',
      'বক্তৃতা',
      'লেখালেখি',
      'ভাষা শেখা',
      'অনুবাদ',
    ],
    careers: [
      'লেখক',
      'শিক্ষক',
      'বক্তা',
      'সাংবাদিক',
      'অনুবাদক',
      'আইনজীবী',
    ],
  ),
  IntelligenceInfo(
    key: 'logical',
    nameBn: 'যৌক্তিক-গাণিতিক বুদ্ধিমত্তা',
    nameEn: 'Logical-Mathematical Intelligence',
    strengths: [
      'গাণিতিক সমস্যা সমাধান',
      'বিশ্লেষণ',
      'গণনা',
      'গবেষণা',
      'যুক্তি প্রয়োগ',
    ],
    careers: [
      'বিজ্ঞানী',
      'প্রকৌশলী',
      'গণিতবিদ',
      'পরিসংখ্যানবিদ',
      'অর্থনীতিবিদ',
      'কম্পিউটার প্রোগ্রামার',
    ],
  ),
  IntelligenceInfo(
    key: 'physical',
    nameBn: 'শারীরিক-গতিজ বুদ্ধিমত্তা',
    nameEn: 'Bodily-Kinesthetic Intelligence',
    strengths: [
      'শারীরিক দক্ষতা',
      'সমন্বয়',
      'নৃত্য',
      'খেলাধুলা',
      'স্বাস্থ্যসেবা',
    ],
    careers: [
      'ক্রীড়াবিদ',
      'নৃত্যশিল্পী',
      'ফিটনেস প্রশিক্ষক',
      'শারীরিক থেরাপিস্ট',
      'সার্জন',
    ],
  ),
  IntelligenceInfo(
    key: 'interpersonal',
    nameBn: 'আন্তঃব্যক্তিক বুদ্ধিমত্তা',
    nameEn: 'Interpersonal Intelligence',
    strengths: [
      'সহানুভূতি',
      'যোগাযোগ',
      'নেতৃত্ব',
      'দলগত কাজ',
      'সম্পর্ক গড়া',
    ],
    careers: [
      'শিক্ষক',
      'মনোবিজ্ঞানী',
      'রাজনীতিবিদ',
      'ব্যবসায়ী',
      'দার্শনিক',
      'উপদেষ্টা',
    ],
  ),
  IntelligenceInfo(
    key: 'intrapersonal',
    nameBn: 'অন্তর্ব্যক্তিক বুদ্ধিমত্তা',
    nameEn: 'Intrapersonal Intelligence',
    strengths: [
      'আত্ম-সচেতনতা',
      'আত্ম-নিয়ন্ত্রণ',
      'প্রেরণা',
      'লক্ষ্য নির্ধারণ',
      'আত্ম-প্রতিফলন',
    ],
    careers: [
      'থেরাপিস্ট',
      'গবেষক',
      'ধ্যান শিক্ষক',
      'লেখক',
      'শিল্পী',
    ],
  ),
  IntelligenceInfo(
    key: 'naturalistic',
    nameBn: 'প্রকৃতিবাদী বুদ্ধিমত্তা',
    nameEn: 'Naturalistic Intelligence',
    strengths: [
      'প্রকৃতির প্রতি আগ্রহ',
      'জীববিজ্ঞান',
      'উদ্ভিদ ও প্রাণী সম্পর্কে জ্ঞান',
    ],
    careers: [
      'জীববিজ্ঞানী',
      'পরিবেশবিদ',
      'বনবিদ',
      'কৃষিবিদ',
      'পশুচিকিৎসক',
    ],
  ),
];

IntelligenceInfo? getIntelligenceByKey(String key) {
  try {
    return intelligenceList.firstWhere((i) => i.key == key);
  } catch (_) {
    return null;
  }
}
