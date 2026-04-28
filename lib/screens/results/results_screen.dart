import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/intelligence_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../services/local_results_service.dart';
import '../../theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const ResultsScreen({super.key, this.extra});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, double> _percentages = {};
  Map<String, int> _categoryTimes = {};
  String? _testDate;
  bool _loading = true;
  bool _hasResults = false;

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  static const _barColors = [
    AppColors.primary,
    AppColors.dustyGrape,
    AppColors.amethystSmoke,
    AppColors.accent,
    Color(0xFF78A237),
    Color(0xFFD83C36),
    Color(0xFF9B3DA0),
    Color(0xFF2196F3),
  ];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    // 1. Fresh results passed directly from test screen
    if (widget.extra != null) {
      final pct = widget.extra!['percentages'] as Map<String, dynamic>?;
      if (pct != null) {
        final catTimes = widget.extra!['categoryTimeSeconds'] as Map<String, dynamic>?;
        setState(() {
          _percentages = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
          if (catTimes != null) {
            _categoryTimes = catTimes.map((k, v) => MapEntry(k, (v as num).toInt()));
          }
          _hasResults = true;
          _loading = false;
        });
        return;
      }
    }

    // 2. Local storage (fast, works offline)
    final saved = await LocalResultsService.load();
    if (saved != null) {
      final pct = saved['percentages'] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _percentages = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
          _testDate = saved['date'] as String?;
          _hasResults = true;
          _loading = false;
        });
      }
      return;
    }

    // 3. Firestore fallback (new device / reinstall)
    if (!GuestSession.isGuest) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await FirestoreService.getDocument('users', uid);
          if (doc.exists) {
            final miRaw = doc.data()!['miResults'] as Map<String, dynamic>?;
            if (miRaw != null) {
              final pct = miRaw['percentages'] as Map<String, dynamic>;
              final date = miRaw['date'] as String?;
              final catTimesRaw = miRaw['categoryTimeSeconds'] as Map<String, dynamic>?;
              final parsed = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
              await LocalResultsService.save(
                scores: {for (final k in parsed.keys) k: 0},
                percentages: parsed,
              );
              if (mounted) {
                setState(() {
                  _percentages = parsed;
                  _testDate = date;
                  if (catTimesRaw != null) {
                    _categoryTimes = catTimesRaw
                        .map((k, v) => MapEntry(k, (v as num).toInt()));
                  }
                  _hasResults = true;
                });
              }
            }
          }
        } catch (_) {}
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  List<MapEntry<String, double>> get _sorted =>
      _percentages.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  List<MapEntry<String, double>> get _top3 => _sorted.take(3).toList();

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final isBn = context.locale.languageCode == 'bn';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 130,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient),
                      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.go('/home'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'results'.tr(),
                                      style: GoogleFonts.hindSiliguri(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                    if (_testDate != null &&
                                        _testDate!.isNotEmpty)
                                      Text(
                                        _formatDate(_testDate),
                                        style: GoogleFonts.hindSiliguri(
                                            fontSize: 11,
                                            color: Colors.white60),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_hasResults)
                  SliverFillRemaining(
                    child: _NoResultsView(
                        onTakeTest: () => context.push('/test')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Chart ───────────────────────
                        _SectionLabel('results_chart_title'.tr()),
                        const SizedBox(height: 10),
                        _BarChartCard(
                          categoryOrder: _categoryOrder,
                          percentages: _percentages,
                          barColors: _barColors,
                          isBn: isBn,
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 24),

                        // ── Top 3 ────────────────────────
                        _SectionLabel('top3_title'.tr()),
                        const SizedBox(height: 10),
                        ..._top3.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final catKey = e.value.key;
                          final pct = e.value.value;
                          final info = getIntelligenceByKey(catKey);
                          if (info == null) return const SizedBox.shrink();
                          final color = _barColors[
                              _categoryOrder.indexOf(catKey) %
                                  _barColors.length];
                          return _IntelligenceCard(
                            rank: rank,
                            info: info,
                            percentage: pct,
                            color: color,
                            isBn: isBn,
                          )
                              .animate()
                              .fadeIn(
                                  delay:
                                      Duration(milliseconds: 80 * e.key),
                                  duration: 400.ms)
                              .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  delay:
                                      Duration(milliseconds: 80 * e.key));
                        }),

                        const SizedBox(height: 8),

                        // ── All scores ───────────────────
                        _AllScoresCard(
                          categoryOrder: _categoryOrder,
                          percentages: _percentages,
                          barColors: _barColors,
                          isBn: isBn,
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 14),

                        // ── Disclaimer ───────────────────
                        _DisclaimerCard()
                            .animate()
                            .fadeIn(delay: 350.ms),

                        if (_categoryTimes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _TimingCard(
                            categoryOrder: _categoryOrder,
                            categoryTimes: _categoryTimes,
                            isBn: isBn,
                          ).animate().fadeIn(delay: 380.ms),
                        ],

                        const SizedBox(height: 20),

                        // ── Action buttons ────────────────
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/home'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.home_rounded, size: 18),
                                  label: Text(
                                    'nav_home'.tr(),
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/test'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(
                                    'retake_test'.tr(),
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.categoryOrder,
    required this.percentages,
    required this.barColors,
    required this.isBn,
  });

  final List<String> categoryOrder;
  final Map<String, double> percentages;
  final List<Color> barColors;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: 100,
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 25,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 9, color: AppColors.textSecondary)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= categoryOrder.length) {
                      return const SizedBox.shrink();
                    }
                    final info = getIntelligenceByKey(categoryOrder[idx]);
                    final name = info != null
                        ? (isBn ? info.nameBn : info.nameEn)
                        : categoryOrder[idx];
                    final abbr = name.split(' ').first;
                    final display = abbr.length > 4
                        ? abbr.substring(0, 4)
                        : abbr;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(display,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 8,
                              color: AppColors.textSecondary)),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: categoryOrder.asMap().entries.map((e) {
              final idx = e.key;
              final pct = percentages[e.value] ?? 0;
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: pct,
                    color: barColors[idx % barColors.length],
                    width: 20,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.primaryDark,
                getTooltipItem: (group, _, rod, __) {
                  final cat = categoryOrder[group.x];
                  final info = getIntelligenceByKey(cat);
                  final name = info != null
                      ? (isBn ? info.nameBn : info.nameEn)
                      : cat;
                  return BarTooltipItem(
                    '$name\n${rod.toY.toStringAsFixed(0)}%',
                    GoogleFonts.hindSiliguri(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top 3 intelligence card ───────────────────────────────────────────────────

class _IntelligenceCard extends StatelessWidget {
  const _IntelligenceCard({
    required this.rank,
    required this.info,
    required this.percentage,
    required this.color,
    required this.isBn,
  });

  final int rank;
  final IntelligenceInfo info;
  final double percentage;
  final Color color;
  final bool isBn;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final name = isBn ? info.nameBn : info.nameEn;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_medals[rank - 1], style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 14),
          _InfoSection(
            title: 'strengths'.tr(),
            icon: Icons.star_rounded,
            color: color,
            items: info.strengths,
          ),
          const SizedBox(height: 10),
          _InfoSection(
            title: 'careers'.tr(),
            icon: Icons.work_outline_rounded,
            color: color,
            items: info.careers,
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── All scores ────────────────────────────────────────────────────────────────

class _AllScoresCard extends StatelessWidget {
  const _AllScoresCard({
    required this.categoryOrder,
    required this.percentages,
    required this.barColors,
    required this.isBn,
  });

  final List<String> categoryOrder;
  final Map<String, double> percentages;
  final List<Color> barColors;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'all_scores'.tr(),
            style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          ...categoryOrder.asMap().entries.map((e) {
            final idx = e.key;
            final cat = e.value;
            final pct = percentages[cat] ?? 0;
            final color = barColors[idx % barColors.length];
            final info = getIntelligenceByKey(cat);
            final name = info != null
                ? (isBn ? info.nameBn : info.nameEn)
                : cat;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 5,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.accent, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'results_disclaimer'.tr(),
              style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No results ────────────────────────────────────────────────────────────────

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.onTakeTest});
  final VoidCallback onTakeTest;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 64, color: AppColors.amethystSmoke),
            ),
            const SizedBox(height: 20),
            Text(
              'no_results_yet'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'no_results_sub'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onTakeTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.psychology_rounded),
                label: Text(
                  'take_test'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timing card ───────────────────────────────────────────────────────────────

class _TimingCard extends StatelessWidget {
  const _TimingCard({
    required this.categoryOrder,
    required this.categoryTimes,
    required this.isBn,
  });

  final List<String> categoryOrder;
  final Map<String, int> categoryTimes;
  final bool isBn;

  static const _barColors = [
    AppColors.primary,
    AppColors.dustyGrape,
    AppColors.amethystSmoke,
    AppColors.accent,
    Color(0xFF78A237),
    Color(0xFFD83C36),
    Color(0xFF9B3DA0),
    Color(0xFF2196F3),
  ];

  String _fmt(int sec) {
    if (sec < 60) return '${sec}s';
    return '${sec ~/ 60}m ${sec % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final total = categoryTimes.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'test_timing'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fmt(total),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'test_timing_sub'.tr(),
            style: GoogleFonts.hindSiliguri(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...categoryOrder.asMap().entries.map((e) {
            final idx = e.key;
            final cat = e.value;
            final sec = categoryTimes[cat] ?? 0;
            final frac = total > 0 ? sec / total : 0.0;
            final color = _barColors[idx % _barColors.length];
            final info = getIntelligenceByKey(cat);
            final name = info != null
                ? (isBn ? info.nameBn : info.nameEn)
                : cat;
            // flag if very fast (<3s avg over 7 questions per category ≈ <21s total)
            final isQuick = sec > 0 && sec < 21;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ),
                      if (isQuick)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.flash_on_rounded,
                              size: 13, color: AppColors.error),
                        ),
                      Text(
                        _fmt(sec),
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isQuick ? AppColors.error : color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 4,
                      backgroundColor: color.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isQuick ? AppColors.error : color),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
