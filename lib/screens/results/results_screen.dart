import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/intelligence_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const ResultsScreen({super.key, this.extra});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, double> _percentages = {};
  bool _loading = true;
  bool _hasResults = false;

  final List<String> _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  static const List<Color> _barColors = [
    AppColors.primary,
    AppColors.dustyGrape,
    AppColors.amethystSmoke,
    AppColors.accent,
    Color(0xFF78A237),
    AppColors.primary,
    AppColors.dustyGrape,
    AppColors.amethystSmoke,
  ];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    // If navigated from test screen with fresh results
    if (widget.extra != null) {
      final pct = widget.extra!['percentages'] as Map<String, dynamic>?;
      if (pct != null) {
        setState(() {
          _percentages = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
          _hasResults = true;
          _loading = false;
        });
        return;
      }
    }

    // Otherwise load from Firestore
    if (GuestSession.isGuest) {
      setState(() => _loading = false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirestoreService.getDocument('users', uid);
      if (mounted && doc.exists) {
        final data = doc.data()!;
        final pct = data['mi_percentages'] as Map<String, dynamic>?;
        if (pct != null) {
          setState(() {
            _percentages = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
            _hasResults = true;
          });
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  List<MapEntry<String, double>> get _sortedByScore {
    final entries = _percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<MapEntry<String, double>> get _top3 => _sortedByScore.take(3).toList();

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
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'results'.tr(),
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ),
                  leading: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                  ),
                ),
                if (!_hasResults)
                  SliverFillRemaining(
                    child: _NoResultsView(
                      onTakeTest: () => context.push('/test'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionTitle('results_chart_title'.tr()),
                        const SizedBox(height: 12),
                        _BarChartCard(
                          categoryOrder: _categoryOrder,
                          percentages: _percentages,
                          barColors: _barColors,
                          isBn: isBn,
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle('top3_title'.tr()),
                        const SizedBox(height: 12),
                        ..._top3.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final catKey = entry.value.key;
                          final pct = entry.value.value;
                          final info = getIntelligenceByKey(catKey);
                          if (info == null) return const SizedBox.shrink();
                          return _IntelligenceCard(
                            rank: rank,
                            info: info,
                            percentage: pct,
                            color: _barColors[
                                _categoryOrder.indexOf(catKey) % _barColors.length],
                            isBn: isBn,
                          );
                        }),
                        const SizedBox(height: 16),
                        _AllScoresCard(
                          categoryOrder: _categoryOrder,
                          percentages: _percentages,
                          barColors: _barColors,
                          isBn: isBn,
                        ),
                        const SizedBox(height: 16),
                        _DisclaimerCard(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              'retake_test'.tr(),
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Bar chart card ────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                        final abbr = _abbr(info, isBn);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            abbr,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: categoryOrder.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final pct = percentages[cat] ?? 0;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: pct,
                        color: barColors[idx % barColors.length],
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _abbr(IntelligenceInfo? info, bool isBn) {
    if (info == null) return '?';
    if (isBn) {
      final name = info.nameBn;
      return name.length > 4 ? name.substring(0, 4) : name;
    }
    return info.nameEn.split(' ').first.substring(0, 3).toUpperCase();
  }
}

// ── Intelligence detail card ──────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final name = isBn ? info.nameBn : info.nameEn;
    final rankEmojis = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
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
              Text(rankEmojis[rank - 1], style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
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
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── All scores card ───────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...categoryOrder.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
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
                        child: Text(
                          name,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
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

// ── Disclaimer card ───────────────────────────────────────────────────────────

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'results_disclaimer'.tr(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No results view ───────────────────────────────────────────────────────────

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
            const Icon(Icons.bar_chart_rounded,
                size: 72, color: AppColors.amethystSmoke),
            const SizedBox(height: 16),
            Text(
              'no_results_yet'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'no_results_sub'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onTakeTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'take_test'.tr(),
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hindSiliguri(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
