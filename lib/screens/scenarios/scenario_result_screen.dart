import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/intelligence_data.dart';
import '../../models/scenario_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../services/local_results_service.dart';
import '../../theme/app_colors.dart';

class ScenarioResultScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const ScenarioResultScreen({super.key, this.extra});

  @override
  State<ScenarioResultScreen> createState() => _ScenarioResultScreenState();
}

class _ScenarioResultScreenState extends State<ScenarioResultScreen> {
  Map<String, double> _percentages = {};
  List<String> _choices = [];
  List<int> _scenarioTimesSeconds = [];
  int _totalTimeSeconds = 0;
  String? _testDate;
  bool _loading = true;
  bool _hasResults = false;
  bool _exporting = false;
  int _touchedIndex = -1;

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
    // 1. Fresh results from test screen
    if (widget.extra != null) {
      final pct = widget.extra!['percentages'] as Map<String, dynamic>?;
      if (pct != null) {
        final choicesRaw = widget.extra!['choices'] as List<dynamic>?;
        final timesRaw = widget.extra!['scenarioTimesSeconds'] as List<dynamic>?;
        final totalTime = widget.extra!['totalTimeSeconds'] as int? ?? 0;
        setState(() {
          _percentages = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
          if (choicesRaw != null) _choices = choicesRaw.cast<String>();
          if (timesRaw != null) {
            _scenarioTimesSeconds = timesRaw.map((e) => (e as num).toInt()).toList();
          }
          _totalTimeSeconds = totalTime;
          _hasResults = true;
          _loading = false;
        });
        return;
      }
    }

    // 2. Local storage
    final data = await LocalResultsService.loadScenario();
    if (data != null && mounted) {
      final pct = data['percentages'] as Map<String, dynamic>;
      final choicesRaw = data['choices'] as List<dynamic>?;
      final timesRaw = data['scenarioTimesSeconds'] as List<dynamic>?;
      setState(() {
        _percentages = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
        _testDate = data['date'] as String?;
        if (choicesRaw != null) _choices = choicesRaw.cast<String>();
        if (timesRaw != null) {
          _scenarioTimesSeconds = timesRaw.map((e) => (e as num).toInt()).toList();
        }
        _totalTimeSeconds = data['totalTimeSeconds'] as int? ?? 0;
        _hasResults = true;
      });
    }

    // 3. Firestore fallback
    if (!_hasResults && !GuestSession.isGuest) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await FirestoreService.getDocument('users', uid);
          if (doc.exists) {
            final scRaw = doc.data()!['scenarioResults'] as Map<String, dynamic>?;
            if (scRaw != null) {
              final pct = scRaw['percentages'] as Map<String, dynamic>;
              final parsed = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
              final choicesRaw = scRaw['choices'] as List<dynamic>?;
              final timesRaw = scRaw['scenarioTimesSeconds'] as List<dynamic>?;
              await LocalResultsService.saveScenario(
                scores: {for (final k in parsed.keys) k: 0},
                percentages: parsed,
              );
              if (mounted) {
                setState(() {
                  _percentages = parsed;
                  _testDate = scRaw['date'] as String?;
                  if (choicesRaw != null) _choices = choicesRaw.cast<String>();
                  if (timesRaw != null) {
                    _scenarioTimesSeconds =
                        timesRaw.map((e) => (e as num).toInt()).toList();
                  }
                  _totalTimeSeconds = scRaw['totalTimeSeconds'] as int? ?? 0;
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

  String _csvEscape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final buf = StringBuffer();
      buf.writeln('Scenario#,Title,Question/Situation,ChosenOption,ChosenOptionText,Time(s)');

      for (int i = 0; i < scenarios.length; i++) {
        final s = scenarios[i];
        final choiceId = i < _choices.length ? _choices[i] : '';
        final optionText = choiceId.isNotEmpty
            ? (s.options.where((o) => o.id == choiceId).firstOrNull?.text ?? '')
            : '';
        final timeSec = i < _scenarioTimesSeconds.length
            ? _scenarioTimesSeconds[i]
            : 0;

        buf.write(i + 1);
        buf.write(',');
        buf.write(_csvEscape(s.title));
        buf.write(',');
        buf.write(_csvEscape(s.description));
        buf.write(',');
        buf.write(_csvEscape(choiceId.toUpperCase()));
        buf.write(',');
        buf.write(_csvEscape(optionText));
        buf.write(',');
        buf.writeln(timeSec);
      }

      buf.writeln();
      buf.writeln('Category,Percentage%');
      for (final cat in _categoryOrder) {
        final info = getIntelligenceByKey(cat);
        final name = info?.nameEn ?? cat;
        final pct = _percentages[cat] ?? 0;
        buf.writeln('${_csvEscape(name)},${pct.toStringAsFixed(1)}');
      }

      if (_totalTimeSeconds > 0) {
        buf.writeln();
        buf.writeln('Total Time (s),$_totalTimeSeconds');
      }

      final csvString = buf.toString();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/scenario_results.csv');
      await file.writeAsString(csvString);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Scenario Test Results',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.dustyGrape))
          : CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 130,
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
                                    if (_testDate != null && _testDate!.isNotEmpty)
                                      Text(
                                        _formatDate(_testDate),
                                        style: GoogleFonts.hindSiliguri(
                                            fontSize: 11, color: Colors.white60),
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
                  SliverFillRemaining(child: _NoResultsView())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Chart ─────────────────────────────
                        _SectionLabel(
                          'results_chart_title'.tr(),
                          color: AppColors.dustyGrape,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'scenario_chart_subtitle'.tr(),
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        _ChartCard(
                          percentages: _percentages,
                          categoryOrder: _categoryOrder,
                          barColors: _barColors,
                          isBn: isBn,
                          touchedIndex: _touchedIndex,
                          onTouch: (i) => setState(() => _touchedIndex = i),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 28),

                        // ── Top 3 ─────────────────────────────
                        _SectionLabel('top3_title'.tr(),
                            color: AppColors.dustyGrape),
                        const SizedBox(height: 12),
                        ..._top3.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final key = e.value.key;
                          final pct = e.value.value;
                          final info = getIntelligenceByKey(key);
                          final colorIdx = _categoryOrder.indexOf(key);
                          final color = colorIdx >= 0
                              ? _barColors[colorIdx % _barColors.length]
                              : AppColors.primary;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _IntelCard(
                              rank: rank,
                              info: info,
                              catKey: key,
                              percentage: pct,
                              color: color,
                              isBn: isBn,
                            )
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: rank * 80),
                                    duration: 400.ms)
                                .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    delay: Duration(milliseconds: rank * 80)),
                          );
                        }),

                        const SizedBox(height: 8),

                        // ── All scores ─────────────────────────
                        _SectionLabel('all_scores'.tr(),
                            color: AppColors.dustyGrape),
                        const SizedBox(height: 12),
                        _AllScoresCard(
                          sorted: _sorted,
                          categoryOrder: _categoryOrder,
                          barColors: _barColors,
                          isBn: isBn,
                        ).animate().fadeIn(delay: 280.ms),

                        const SizedBox(height: 16),

                        // ── Disclaimer ──────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dustyGrape.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppColors.dustyGrape.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.dustyGrape, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'scenario_disclaimer'.tr(),
                                  style: GoogleFonts.hindSiliguri(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 340.ms),

                        // ── Timing summary ──────────────────────
                        if (_totalTimeSeconds > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.dustyGrape.withValues(alpha: 0.07),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 18, color: AppColors.dustyGrape),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'test_timing'.tr(),
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                                Text(
                                  _totalTimeSeconds < 60
                                      ? '${_totalTimeSeconds}s'
                                      : '${_totalTimeSeconds ~/ 60}m ${_totalTimeSeconds % 60}s',
                                  style: GoogleFonts.hindSiliguri(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dustyGrape),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 360.ms),
                        ],

                        // ── Choices per scenario ─────────────────
                        if (_choices.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionLabel('scenario_choices'.tr(),
                              color: AppColors.dustyGrape),
                          const SizedBox(height: 12),
                          _ScenarioChoicesCard(
                            choices: _choices,
                            scenarioTimes: _scenarioTimesSeconds,
                          ).animate().fadeIn(delay: 380.ms),
                        ],

                        const SizedBox(height: 20),

                        // ── Action buttons ──────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/home'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.dustyGrape,
                                    side: const BorderSide(
                                        color: AppColors.dustyGrape, width: 1.5),
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
                                  onPressed: () => context.go('/scenarios'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.dustyGrape,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 18),
                                  label: Text(
                                    'retake_scenario'.tr(),
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 12),

                        // ── CSV download ─────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _exporting ? null : _exportCsv,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dustyGrape,
                              side: const BorderSide(
                                  color: AppColors.dustyGrape, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: _exporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: AppColors.dustyGrape,
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.download_rounded, size: 18),
                            label: Text(
                              'download_csv'.tr(),
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ).animate().fadeIn(delay: 420.ms),

                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Chart card ─────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.percentages,
    required this.categoryOrder,
    required this.barColors,
    required this.isBn,
    required this.touchedIndex,
    required this.onTouch,
  });

  final Map<String, double> percentages;
  final List<String> categoryOrder;
  final List<Color> barColors;
  final bool isBn;
  final int touchedIndex;
  final void Function(int) onTouch;

  static const _shortLabelsBn = ['সং', 'দৃ', 'ভা', 'যৌ', 'শা', 'আন্ত', 'অন্ত', 'প্র'];
  static const _shortLabelsEn = ['Mus', 'Vis', 'Lin', 'Log', 'Phy', 'Inter', 'Intra', 'Nat'];

  @override
  Widget build(BuildContext context) {
    final labels = isBn ? _shortLabelsBn : _shortLabelsEn;
    final bars = categoryOrder.asMap().entries.map((entry) {
      final i = entry.key;
      final key = entry.value;
      final pct = percentages[key] ?? 0;
      final isTouched = i == touchedIndex;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pct,
            color: barColors[i % barColors.length],
            width: isTouched ? 20 : 15,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: AppColors.cardBg,
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dustyGrape.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 230,
            child: BarChart(
          BarChartData(
            barGroups: bars,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 25,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade100, strokeWidth: 1),
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
                  reservedSize: 32,
                  getTitlesWidget: (val, _) => Text(
                    '${val.toInt()}%',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 9, color: AppColors.textSecondary),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (val, _) {
                    final idx = val.toInt();
                    if (idx < 0 || idx >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[idx],
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 9, color: AppColors.textSecondary),
                        overflow: TextOverflow.visible,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchCallback: (event, response) {
                onTouch(response?.spot?.touchedBarGroupIndex ?? -1);
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.dustyGrape,
                getTooltipItem: (group, _, rod, __) {
                  final key = categoryOrder[group.x];
                  final info = getIntelligenceByKey(key);
                  final name = info != null
                      ? (isBn ? info.nameBn : info.nameEn)
                      : key;
                  return BarTooltipItem(
                    '$name\n${rod.toY.toStringAsFixed(1)}%',
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: categoryOrder.asMap().entries.map((e) {
              final info = getIntelligenceByKey(e.value);
              final name = info != null
                  ? (isBn ? info.nameBn : info.nameEn)
                  : e.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: barColors[e.key % barColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Intelligence card (top 3) ─────────────────────────────────────────────────

class _IntelCard extends StatelessWidget {
  const _IntelCard({
    required this.rank,
    required this.info,
    required this.catKey,
    required this.percentage,
    required this.color,
    required this.isBn,
  });

  final int rank;
  final IntelligenceInfo? info;
  final String catKey;
  final double percentage;
  final Color color;
  final bool isBn;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final name = info != null ? (isBn ? info!.nameBn : info!.nameEn) : catKey;
    final strengths = info?.strengths ?? [];
    final careers = info?.careers ?? [];

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
          // Colored header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(_medals[rank - 1],
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      if (info != null && isBn)
                        Text(
                          info!.nameEn,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 12, color: Colors.white70),
                        ),
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
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          // Strengths & careers
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (strengths.isNotEmpty) ...[
                  _SubLabel(
                    icon: Icons.star_rounded,
                    label: 'strengths'.tr(),
                    color: color,
                  ),
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
                  _SubLabel(
                    icon: Icons.work_outline_rounded,
                    label: 'careers'.tr(),
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 6),
                  ...careers.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_right_rounded,
                              color: color, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(c,
                                style: GoogleFonts.hindSiliguri(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ),
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

// ── All scores card ────────────────────────────────────────────────────────────

class _AllScoresCard extends StatelessWidget {
  const _AllScoresCard({
    required this.sorted,
    required this.categoryOrder,
    required this.barColors,
    required this.isBn,
  });

  final List<MapEntry<String, double>> sorted;
  final List<String> categoryOrder;
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
            color: AppColors.dustyGrape.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: sorted.asMap().entries.map((e) {
          final key = e.value.key;
          final pct = e.value.value;
          final colorIdx = categoryOrder.indexOf(key);
          final color = colorIdx >= 0
              ? barColors[colorIdx % barColors.length]
              : AppColors.primary;
          final info = getIntelligenceByKey(key);
          final name = info != null ? (isBn ? info.nameBn : info.nameEn) : key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 5,
                    backgroundColor: color.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SubLabel extends StatelessWidget {
  const _SubLabel(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      ],
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.hindSiliguri(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Scenario choices card ─────────────────────────────────────────────────────

class _ScenarioChoicesCard extends StatelessWidget {
  const _ScenarioChoicesCard({
    required this.choices,
    required this.scenarioTimes,
  });

  final List<String> choices;
  final List<int> scenarioTimes;

  static const _optionLabels = {'a': 'ক', 'b': 'খ', 'c': 'গ', 'd': 'ঘ'};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dustyGrape.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: scenarios.asMap().entries.map((e) {
          final idx = e.key;
          final scenario = e.value;
          final choiceId = idx < choices.length ? choices[idx] : '';
          final option = choiceId.isNotEmpty
              ? scenario.options.where((o) => o.id == choiceId).firstOrNull
              : null;
          final timeSec = idx < scenarioTimes.length ? scenarioTimes[idx] : null;
          final isFirst = idx == 0;

          return Container(
            decoration: BoxDecoration(
              border: isFirst
                  ? null
                  : Border(
                      top: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.1))),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.dustyGrape.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${idx + 1}',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dustyGrape),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      if (option != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.dustyGrape,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _optionLabels[choiceId] ??
                                    choiceId.toUpperCase(),
                                style: GoogleFonts.hindSiliguri(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                option.text,
                                style: GoogleFonts.hindSiliguri(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (timeSec != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.dustyGrape.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timeSec < 60
                          ? '${timeSec}s'
                          : '${timeSec ~/ 60}m ${timeSec % 60}s',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 10,
                          color: AppColors.dustyGrape,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── No results ─────────────────────────────────────────────────────────────────

class _NoResultsView extends StatelessWidget {
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
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  size: 56, color: AppColors.amethystSmoke),
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
              'no_scenario_results_sub'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/scenarios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dustyGrape,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.psychology_rounded),
                label: Text(
                  'take_scenario_test'.tr(),
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
