import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  static const _intelligenceList = [
    ('ছন্দ ও সংগীতমূলক বুদ্ধিমত্তা', 'Musical-Rhythmic Intelligence', Icons.music_note_rounded, AppColors.primary),
    ('মৌখিক ও ভাষাবৃত্তীয় বুদ্ধিমত্তা', 'Verbal-Linguistic Intelligence', Icons.record_voice_over_rounded, AppColors.dustyGrape),
    ('যৌক্তিক ও গাণিতিক বুদ্ধিমত্তা', 'Logical-Mathematical Intelligence', Icons.calculate_rounded, AppColors.amethystSmoke),
    ('দৃষ্টি ও অবস্থানমূলক বুদ্ধিমত্তা', 'Visual-Spatial Intelligence', Icons.palette_rounded, AppColors.primary),
    ('অনুভূতি ও শরীরবৃত্তীয় বুদ্ধিমত্তা', 'Bodily-Kinesthetic Intelligence', Icons.directions_run_rounded, AppColors.dustyGrape),
    ('আন্তঃব্যক্তিক বুদ্ধিমত্তা', 'Interpersonal Intelligence', Icons.people_rounded, AppColors.amethystSmoke),
    ('অন্তঃব্যক্তিক বুদ্ধিমত্তা', 'Intrapersonal Intelligence', Icons.self_improvement_rounded, AppColors.primary),
    ('প্রাকৃতিক বুদ্ধিমত্তা', 'Naturalistic Intelligence', Icons.eco_rounded, AppColors.dustyGrape),
  ];

  static const _details = [
    _IntelligenceDetail(
      bn: 'ছন্দ ও সংগীতমূলক বুদ্ধিমত্তা',
      en: 'Musical-Rhythmic Intelligence',
      description: 'সঙ্গীত-বুদ্ধিমত্তা সম্পন্ন ব্যক্তিরা ছড়া, ছন্দ ও ধ্বনির তালে তালে সহজে শিখতে পছন্দ করে।',
      symptoms: [
        'তাল ও লয়ের প্রতি আকর্ষণ বেশি থাকে',
        'সুর ও ছন্দ সহজে মনে প্রভাব বিস্তার করে',
        'গান পছন্দ করে',
        'কবিতা ও ছড়া তালে তালে আবৃত্তি করতে পছন্দ করে',
        'বাদ্যযন্ত্র বাজাতে পছন্দ করে',
        'প্রকৃতির বিভিন্ন শব্দ শুনে সহজে আকৃষ্ট হয়',
      ],
    ),
    _IntelligenceDetail(
      bn: 'দৃষ্টি ও অবস্থানমূলক বুদ্ধিমত্তা',
      en: 'Visual-Spatial Intelligence',
      description: 'যারা দৃশ্য-স্থানিক বুদ্ধিমত্তা সম্পন্ন, তারা যে কোন জিনিস কল্পনা করতে ভালোবাসে। যাদের এই বুদ্ধিমত্তা প্রবল তারা ছবি, রেখাচিত্র ও রূপকল্পনার সাহায্যে সহজে শিখে থাকে।',
      symptoms: [
        'ছবির বিষয়বস্তু সম্বন্ধে চিন্তা করে',
        'ছবির সাহায্যে মনে রাখে',
        'ছবি আঁকতে ও রং করতে ভালোবাসে',
        'মানচিত্র, চার্ট এবং নকশা সহজে বুঝতে পারে',
        'কোনো কিছুর চিত্র সহজে কল্পনা করে',
        'রূপক শব্দ ও বাক্য বেশি ব্যবহার করে',
      ],
    ),
    _IntelligenceDetail(
      bn: 'মৌখিক ও ভাষাবৃত্তীয় বুদ্ধিমত্তা',
      en: 'Verbal-Linguistic Intelligence',
      description: 'যারা ভাষাগত-মৌখিক বুদ্ধিমত্তায় শক্তিশালী তারা শোনা, বলা ও পড়ার মাধ্যমে সহজে শিখতে পারে।',
      symptoms: [
        'শুনতে ও বলতে পছন্দ করে',
        'পড়তে ও লিখতে পছন্দ করে',
        'সহজে বানান করে',
        'গল্প বলে ও গল্প লেখে',
        'সাবলীল ভাষায় বিষয়বস্তু উপস্থাপন করে',
        'শব্দভাণ্ডার বেশি ও তা যথাযথ ব্যবহার করে',
        'প্রখর স্মরণশক্তির অধিকারী হয়',
      ],
    ),
    _IntelligenceDetail(
      bn: 'যৌক্তিক ও গাণিতিক বুদ্ধিমত্তা',
      en: 'Logical-Mathematical Intelligence',
      description: 'যারা যৌক্তিক-গাণিতিক বুদ্ধিমত্তায় শক্তিশালী, তারা যুক্তি, প্যাটার্ন চিনতে এবং সমস্যাগুলি যুক্তিযুক্তভাবে বিশ্লেষণ করতে পারে।',
      symptoms: [
        'গুনতে আনন্দ পায়',
        'বস্তুর সাহায্য ছাড়াই কোনো বিষয়ে সহজে ধারণা লাভ করে',
        'যুক্তি দিয়ে বিচার বিবেচনা করে',
        'ধাঁধা ও অঙ্কের খেলা পছন্দ করে',
        'সাজিয়ে ও গুছিয়ে রাখতে পছন্দ করে',
        'সমস্যা সমাধান করতে আনন্দ পায়',
      ],
    ),
    _IntelligenceDetail(
      bn: 'অনুভূতি ও শরীরবৃত্তীয় বুদ্ধিমত্তা',
      en: 'Bodily-Kinesthetic Intelligence',
      description: 'যাদের শারীরিক বুদ্ধিমত্তা বেশি, তারা শরীরের নড়াচড়া, কর্ম সম্পাদন এবং শারীরিক নিয়ন্ত্রণে ভালো।',
      symptoms: [
        'খেলাধুলা পছন্দ করে',
        'কোনো কিছু সহজে ধরতে বা স্পর্শ করতে চায়',
        'হাতেনাতে কাজ করতে পছন্দ করে',
        'হস্তশিল্পে দক্ষ হয়',
        'শরীর ও অঙ্গপ্রত্যঙ্গের ওপর নিজের নিয়ন্ত্রণ থাকে',
        'অংশগ্রহণ করে সহজে শেখে',
      ],
    ),
    _IntelligenceDetail(
      bn: 'আন্তঃব্যক্তিক বুদ্ধিমত্তা',
      en: 'Interpersonal Intelligence',
      description: 'যারা আন্তঃব্যক্তিক বুদ্ধিমত্তায় শক্তিশালী, তারা তাদের নিজস্ব মানসিক অবস্থা, অনুভূতি এবং প্রেরণা সম্পর্কে সচেতন থাকে।',
      symptoms: [
        'অন্যের মনের কথা সহজে বুঝতে পারে',
        'অন্যের সঙ্গে সহজে সম্পর্ক গড়ে তোলে',
        'অনেক বন্ধু বান্ধব থাকে',
        'অন্যের কাজে সাহায্য ও সহযোগিতা করে',
        'দলে কাজ করতে পছন্দ করে',
        'সামাজিক পরিস্থিতি সহজে বুঝতে পারে',
      ],
    ),
    _IntelligenceDetail(
      bn: 'অন্তঃব্যক্তিক বুদ্ধিমত্তা',
      en: 'Intrapersonal Intelligence',
      description: 'যারা ব্যক্তিগত-বুদ্ধিমত্তা সম্পন্ন, তারা একাকী চিন্তা ও কাজ করে সহজে শিখতে পছন্দ করে।',
      symptoms: [
        'একাকী থাকতে পছন্দ করে',
        'কম কথা বলে, অধিক চিন্তা করে',
        'নিজে নিজে শিখতে চায়',
        'নিজের সম্বন্ধে সচেতন থাকে',
        'নিজে নিজেই কাজ করতে উৎসাহিত হয়',
        'নিজের সবলতা ও দুর্বলতা সহজে বুঝতে পারে',
      ],
    ),
    _IntelligenceDetail(
      bn: 'প্রাকৃতিক বুদ্ধিমত্তা',
      en: 'Naturalistic Intelligence',
      description: 'গার্ডনারের মতে, যারা এই ধরনের বুদ্ধিমত্তায় বেশি পারদর্শী তারা প্রকৃতির সাথে বেশি মিল রাখে এবং লালন-পালন, পরিবেশ অন্বেষণ ও অন্যান্য প্রজাতি সম্পর্কে জানতে আগ্রহী।',
      symptoms: [
        'প্রকৃতির গাছপালা ও পশুপাখি পর্যবেক্ষণ করতে পছন্দ করে',
        'গাছপালা ও পশুপাখির বৈশিষ্ট্য নিয়ে চিন্তা করে',
        'গাছ লাগাতে এবং যত্ন করতে ভালোবাসে',
        'জীবজগতের বিভিন্ন তথ্য বিশ্লেষণ করতে পছন্দ করে',
        'প্রাণি ও উদ্ভিদ নিয়ে গবেষণা করতে পছন্দ করে',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    context.locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AuthorCard().animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                _IntroCard().animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                _QuoteCard().animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),
                _EightIntelligencesCard(list: _intelligenceList)
                    .animate()
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                _SectionHeader('বিস্তারিত বিবরণ'),
                const SizedBox(height: 12),
                ..._details.asMap().entries.map((e) => _DetailCard(
                      detail: e.value,
                      index: e.key,
                      color: _intelligenceList[e.key].$4,
                      icon: _intelligenceList[e.key].$3,
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * e.key),
                        )),
                const SizedBox(height: 16),
                _ReferencesCard().animate().fadeIn(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: Text(
          'what_is_mi'.tr(),
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
    );
  }
}

// ── Author card ───────────────────────────────────────────────────────────────

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2.5),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'হাওয়ার্ড গার্ডনার',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'মনোবিজ্ঞানী',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'হার্ভার্ড বিশ্ববিদ্যালয়',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Intro card ────────────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Text(
        'যুক্তরাষ্ট্রের হার্ভার্ড বিশ্ববিদ্যালয়ের মনোবিজ্ঞানী হাওয়ার্ড গার্ডনার তাঁর বিখ্যাত তত্ত্ব "মাল্টিপল ইন্টেলিজেন্স" প্রদান করেন। এই পৃথিবীতে আমরা প্রত্যেকেই যেকোনো কিছু শেখার বা জানার ক্ষমতা রাখি, কিন্তু এই ক্ষমতাটা একেকজনের একেক রকম। কেউ কিছু দেখে শিখতে পছন্দ করে, কেউ শুনে শিখতে, আবার কেউ যুক্তির মাধ্যমে বা গানের মাধ্যমে শিখতে পছন্দ করে। মূলত এখানেই আমাদের সকলের বুদ্ধিমত্তার পার্থক্যটা দেখা যায়।',
        style: GoogleFonts.hindSiliguri(
          fontSize: 14,
          height: 1.7,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}

// ── Quote card ────────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(
            '"It\'s not how smart you are that matters, what really counts is how you are smart."',
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Howard Gardner',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 8 intelligences overview ──────────────────────────────────────────────────

class _EightIntelligencesCard extends StatelessWidget {
  const _EightIntelligencesCard({required this.list});
  final List<(String, String, IconData, Color)> list;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.view_list_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '৮ ধরণের বুদ্ধিমত্তা',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'তাঁর বিখ্যাত বই "Frames of Mind" তে হাওয়ার্ড গার্ডনার ৮ ধরণের বুদ্ধিমত্তার কথা উল্লেখ করেছেন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...list.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.$4,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(item.$3, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          item.$2,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.$4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Detail card (expandable) ──────────────────────────────────────────────────

class _DetailCard extends StatefulWidget {
  const _DetailCard({
    required this.detail,
    required this.index,
    required this.color,
    required this.icon,
  });

  final _IntelligenceDetail detail;
  final int index;
  final Color color;
  final IconData icon;

  @override
  State<_DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends State<_DetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.detail.bn,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.detail.en,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: widget.color.withValues(alpha: 0.2)),
                  const SizedBox(height: 6),
                  Text(
                    widget.detail.description,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'লক্ষণসমূহ',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.detail.symptoms.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: widget.color, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s,
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

// ── References card ───────────────────────────────────────────────────────────

class _ReferencesCard extends StatelessWidget {
  const _ReferencesCard();

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: AppColors.dustyGrape, size: 20),
              const SizedBox(width: 8),
              Text(
                'তথ্যসূত্র',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RefItem(
            '১। ড. এম. এ. ওহাব ও মোঃ আশরাফুজ্জামান (২০১৮). সবার জন্য শিক্ষা নিশ্চিতকরণে একীভূত শিক্ষা, প্রভাতী লাইব্রেরি, ঢাকা।',
          ),
          const SizedBox(height: 8),
          _RefItem(
            '২। MSEd, K. C. (2023). Gardner\'s Theory of Multiple Intelligences. Verywell Mind.',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'আরও জানতে',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _LinkChip('গার্ডনারের মাল্টিপল ইন্টেলিজেন্স তত্ত্ব'),
                const SizedBox(height: 6),
                _LinkChip('উইকিপিডিয়া: মাল্টিপল ইন্টেলিজেন্স'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefItem extends StatelessWidget {
  const _RefItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hindSiliguri(
        fontSize: 12,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_new_rounded,
              color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _IntelligenceDetail {
  final String bn;
  final String en;
  final String description;
  final List<String> symptoms;

  const _IntelligenceDetail({
    required this.bn,
    required this.en,
    required this.description,
    required this.symptoms,
  });
}
