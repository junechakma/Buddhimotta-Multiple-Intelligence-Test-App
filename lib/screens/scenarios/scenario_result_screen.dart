import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/intelligence_data.dart';
import '../../services/local_results_service.dart';
import '../../theme/app_colors.dart';

class ScenarioResultScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const ScenarioResultScreen({super.key, this.extra});

  @override
  State<ScenarioResultScreen> createState() => _ScenarioResultScreenState();
}

class _ScenarioResultScreenState extends State<ScenarioResultScreen>
    with SingleTickerProviderStateMixin {
  Map<String, double> _percentages = {};
  String? _testDate;
  bool _loading = true;
  bool _hasResults = false;
  late TabController _tabController;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
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
    final data = await LocalResultsService.loadScenario();
    if (mounted) {
      if (data != null) {
        final pct = data['percentages'] as Map<String, dynamic>;
        setState(() {
          _percentages =
              pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
          _testDate = data['date'] as String?;
          _hasResults = true;
        });
      }
      setState(() => _loading = false);
    }
  }

  List<MapEntry<String, double>> get _sorted {
    final entries = _percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                _buildAppBar(context),
                if (!_hasResults)
                  SliverFillRemaining(child: _EmptyState())
                else
                  SliverToBoxAdapter(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.dustyGrape,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.dustyGrape, AppColors.amethystSmoke],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'scenario_results_title'.tr(),
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (_testDate != null)
                          Text(
                            _formatDate(_testDate),
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 12, color: Colors.white70),
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
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.hindSiliguri(
            fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.hindSiliguri(fontSize: 13),
        tabs: [
          Tab(text: 'tab_chart'.tr()),
          Tab(text: 'tab_top3'.tr()),
          Tab(text: 'tab_details'.tr()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: TabBarView(
        controller: _tabController,
        children: [
          _ChartTab(
            percentages: _percentages,
            categoryOrder: _categoryOrder,
            barColors: _barColors,
          ),
          _Top3Tab(sorted: _sorted, barColors: _barColors),
          _DetailsTab(sorted: _sorted, barColors: _barColors),
        ],
      ),
    );
  }
}

// ── Chart tab ──────────────────────────────────────────────────────────────────

class _ChartTab extends StatefulWidget {
  const _ChartTab({
    required this.percentages,
    required this.categoryOrder,
    required this.barColors,
  });

  final Map<String, double> percentages;
  final List<String> categoryOrder;
  final List<Color> barColors;

  @override
  State<_ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<_ChartTab> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final bars = widget.categoryOrder.asMap().entries.map((entry) {
      final i = entry.key;
      final key = entry.value;
      final pct = widget.percentages[key] ?? 0;
      final isTouched = i == _touchedIndex;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pct,
            color: widget.barColors[i % widget.barColors.length],
            width: isTouched ? 18 : 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: AppColors.cardBg,
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'results_chart_title'.tr(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'scenario_chart_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                barGroups: bars,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.cardBg,
                    strokeWidth: 1.5,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 10,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _shortLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _shortLabels[idx],
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 9,
                                color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final key = widget.categoryOrder[groupIndex];
                      final info = getIntelligenceByKey(key);
                      return BarTooltipItem(
                        '${info?.nameBn ?? key}\n${rod.toY.toStringAsFixed(1)}%',
                        GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'scenario_disclaimer'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/scenarios'),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('retake_scenario'.tr(),
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dustyGrape,
              side: const BorderSide(color: AppColors.dustyGrape),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

const _shortLabels = ['সং', 'দৃ', 'ভা', 'যৌ', 'শা', 'আন্ত', 'অন্ত', 'প্র'];

// ── Top 3 tab ──────────────────────────────────────────────────────────────────

class _Top3Tab extends StatelessWidget {
  const _Top3Tab({required this.sorted, required this.barColors});
  final List<MapEntry<String, double>> sorted;
  final List<Color> barColors;

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  @override
  Widget build(BuildContext context) {
    final top3 = sorted.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('top3_title'.tr()),
          const SizedBox(height: 12),
          ...top3.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final key = entry.value.key;
            final pct = entry.value.value;
            final info = getIntelligenceByKey(key);
            final colorIdx = _categoryOrder.indexOf(key);
            final color = colorIdx >= 0
                ? barColors[colorIdx % barColors.length]
                : AppColors.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _Top3Card(
                rank: rank,
                nameBn: info?.nameBn ?? key,
                nameEn: info?.nameEn ?? key,
                percentage: pct,
                color: color,
                strengths: info?.strengths ?? [],
                careers: info?.careers ?? [],
              ).animate().fadeIn(delay: Duration(milliseconds: rank * 120)),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Top3Card extends StatelessWidget {
  const _Top3Card({
    required this.rank,
    required this.nameBn,
    required this.nameEn,
    required this.percentage,
    required this.color,
    required this.strengths,
    required this.careers,
  });

  final int rank;
  final String nameBn;
  final String nameEn;
  final double percentage;
  final Color color;
  final List<String> strengths;
  final List<String> careers;

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(medals[rank - 1],
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nameBn,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(nameEn,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Strengths & careers
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (strengths.isNotEmpty) ...[
                  Text('strengths'.tr(),
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: strengths
                        .map((s) => _Chip(label: s, color: color))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (careers.isNotEmpty) ...[
                  Text('careers'.tr(),
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  ...careers.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_right_rounded,
                              color: color, size: 18),
                          const SizedBox(width: 4),
                          Text(c,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Details tab ────────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.sorted, required this.barColors});
  final List<MapEntry<String, double>> sorted;
  final List<Color> barColors;

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('all_scores'.tr()),
          const SizedBox(height: 12),
          ...sorted.asMap().entries.map((entry) {
            final idx = entry.key;
            final key = entry.value.key;
            final pct = entry.value.value;
            final info = getIntelligenceByKey(key);
            final colorIdx = _categoryOrder.indexOf(key);
            final color = colorIdx >= 0
                ? barColors[colorIdx % barColors.length]
                : AppColors.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScoreRow(
                rank: idx + 1,
                nameBn: info?.nameBn ?? key,
                percentage: pct,
                color: color,
              ).animate().fadeIn(delay: Duration(milliseconds: idx * 60)),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.dustyGrape.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.dustyGrape.withValues(alpha: 0.2)),
            ),
            child: Text(
              'scenario_disclaimer'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.rank,
    required this.nameBn,
    required this.percentage,
    required this.color,
  });

  final int rank;
  final String nameBn;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nameBn,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.cardBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined,
                size: 64, color: AppColors.amethystSmoke),
            const SizedBox(height: 16),
            Text(
              'no_results_yet'.tr(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'no_scenario_results_sub'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/scenarios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dustyGrape,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
              child: Text('take_scenario_test'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

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
            color: AppColors.dustyGrape,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
