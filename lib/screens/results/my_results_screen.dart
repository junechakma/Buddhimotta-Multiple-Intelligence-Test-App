import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/intelligence_data.dart';
import '../../models/question_model.dart';
import '../../models/scenario_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../services/local_results_service.dart';
import '../../theme/app_colors.dart';

class MyResultsScreen extends StatefulWidget {
  const MyResultsScreen({super.key});

  @override
  State<MyResultsScreen> createState() => _MyResultsScreenState();
}

class _MyResultsScreenState extends State<MyResultsScreen> {
  Map<String, double> _miPct = {};
  Map<String, double> _scenarioPct = {};
  Map<String, List<int>> _miAnswerIndices = {};
  Map<String, List<int>> _miQuestionTimes = {};
  List<String> _scenarioChoices = [];
  List<int> _scenarioTimes = [];
  String? _miDate;
  String? _scenarioDate;
  bool _loading = true;
  bool _exporting = false;

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

  bool get _hasMi => _miPct.isNotEmpty;
  bool get _hasScenario => _scenarioPct.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // ── MI results ─────────────────────────────────────────────────────────────
    final miLocal = await LocalResultsService.load();
    if (miLocal != null) {
      final pct = miLocal['percentages'] as Map<String, dynamic>;
      _miPct = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
      _miDate = miLocal['date'] as String?;
      final ai = miLocal['answerIndices'] as Map<String, dynamic>?;
      if (ai != null) {
        _miAnswerIndices = ai.map((k, v) => MapEntry(k,
            (v as List<dynamic>).map((e) => (e as num).toInt()).toList()));
      }
      final qt = miLocal['questionTimeSeconds'] as Map<String, dynamic>?;
      if (qt != null) {
        _miQuestionTimes = qt.map((k, v) => MapEntry(k,
            (v as List<dynamic>).map((e) => (e as num).toInt()).toList()));
      }
    }

    // ── Scenario results ────────────────────────────────────────────────────────
    final scLocal = await LocalResultsService.loadScenario();
    if (scLocal != null) {
      final pct = scLocal['percentages'] as Map<String, dynamic>;
      _scenarioPct = pct.map((k, v) => MapEntry(k, (v as num).toDouble()));
      _scenarioDate = scLocal['date'] as String?;
      final ch = scLocal['choices'] as List<dynamic>?;
      if (ch != null) _scenarioChoices = ch.cast<String>();
      final st = scLocal['scenarioTimesSeconds'] as List<dynamic>?;
      if (st != null) _scenarioTimes = st.map((e) => (e as num).toInt()).toList();
    }

    // ── Firestore fallback (new device / reinstall) ─────────────────────────────
    if ((!_hasMi || !_hasScenario) && !GuestSession.isGuest) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await FirestoreService.getDocument('users', uid);
          if (doc.exists) {
            final data = doc.data()!;

            if (!_hasMi) {
              final miRaw = data['miResults'] as Map<String, dynamic>?;
              if (miRaw != null) {
                final pct = (miRaw['percentages'] as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, (v as num).toDouble()));
                _miPct = pct;
                _miDate = miRaw['date'] as String?;
                await LocalResultsService.save(
                  scores: {for (final k in pct.keys) k: 0},
                  percentages: pct,
                );
              }
            }

            if (!_hasScenario) {
              final scRaw = data['scenarioResults'] as Map<String, dynamic>?;
              if (scRaw != null) {
                final pct = (scRaw['percentages'] as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, (v as num).toDouble()));
                _scenarioPct = pct;
                _scenarioDate = scRaw['date'] as String?;
                await LocalResultsService.saveScenario(
                  scores: {for (final k in pct.keys) k: 0},
                  percentages: pct,
                );
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
      final jsonStr = await rootBundle.loadString('assets/data.json');
      final raw = json.decode(jsonStr) as List<dynamic>;
      final all = raw.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
      final questions = {
        for (final cat in _categoryOrder)
          cat: all.where((q) => q.category == cat).toList(),
      };

      final buf = StringBuffer();

      // ── MI Test section ──────────────────────────────────────────────────
      if (_miPct.isNotEmpty) {
        buf.writeln('=== MI Test Results ===');
        buf.writeln('Category,Percentage%');
        for (final cat in _categoryOrder) {
          final info = getIntelligenceByKey(cat);
          buf.writeln('${_csvEscape(info?.nameEn ?? cat)},${(_miPct[cat] ?? 0).toStringAsFixed(1)}');
        }
        buf.writeln();

        if (_miAnswerIndices.isNotEmpty) {
          buf.writeln('Category,Question#,Question,SelectedOption,Score,Time(s)');
          for (final cat in _categoryOrder) {
            final qs = questions[cat] ?? [];
            final answers = _miAnswerIndices[cat] ?? [];
            final times = _miQuestionTimes[cat] ?? [];
            final info = getIntelligenceByKey(cat);
            final catName = info?.nameEn ?? cat;
            for (int qi = 0; qi < qs.length; qi++) {
              final q = qs[qi];
              final optIdx = qi < answers.length ? answers[qi] : -1;
              final optText = optIdx >= 0 && optIdx < q.options.length
                  ? q.options[optIdx]
                  : '';
              final score = optIdx >= 0 ? q.scoreForOption(optIdx) : 0;
              final timeSec = qi < times.length ? times[qi] : 0;
              buf.write(_csvEscape(catName));
              buf.write(',');
              buf.write(qi + 1);
              buf.write(',');
              buf.write(_csvEscape(q.question));
              buf.write(',');
              buf.write(_csvEscape(optText));
              buf.write(',');
              buf.write(score);
              buf.write(',');
              buf.writeln(timeSec);
            }
          }
          buf.writeln();
        }
      }

      // ── Scenario Test section ────────────────────────────────────────────
      if (_scenarioPct.isNotEmpty) {
        buf.writeln('=== Scenario Test Results ===');
        buf.writeln('Category,Percentage%');
        for (final cat in _categoryOrder) {
          final info = getIntelligenceByKey(cat);
          buf.writeln('${_csvEscape(info?.nameEn ?? cat)},${(_scenarioPct[cat] ?? 0).toStringAsFixed(1)}');
        }
        buf.writeln();

        if (_scenarioChoices.isNotEmpty) {
          buf.writeln('Scenario#,Title,Question/Situation,ChosenOption,ChosenOptionText,Time(s)');
          for (int i = 0; i < scenarios.length; i++) {
            final s = scenarios[i];
            final choiceId = i < _scenarioChoices.length ? _scenarioChoices[i] : '';
            final optionText = choiceId.isNotEmpty
                ? (s.options.where((o) => o.id == choiceId).firstOrNull?.text ?? '')
                : '';
            final timeSec = i < _scenarioTimes.length ? _scenarioTimes[i] : 0;
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
        }
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/my_results.csv');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'My Intelligence Results',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  List<MapEntry<String, double>> _top3(Map<String, double> pct) =>
      (pct.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .toList();

  @override
  Widget build(BuildContext context) {
    context.locale;
    final isBn = context.locale.languageCode == 'bn';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // ── App bar ─────────────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 120,
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
                              Text(
                                'results'.tr(),
                                style: GoogleFonts.hindSiliguri(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── MI Test section ──────────────────────────────────────
                      _ResultSection(
                        icon: Icons.psychology_rounded,
                        titleKey: 'mi_test',
                        color: AppColors.primary,
                        date: _fmtDate(_miDate),
                        hasResults: _hasMi,
                        percentages: _miPct,
                        categoryOrder: _categoryOrder,
                        barColors: _barColors,
                        top3: _hasMi ? _top3(_miPct) : [],
                        isBn: isBn,
                        onViewFull: () => context.push('/results'),
                        onRetake: () => context.push('/test'),
                        viewLabel: 'view_results'.tr(),
                        retakeLabel: 'retake_test'.tr(),
                        emptyLabel: 'no_results_sub'.tr(),
                        takeLabel: 'take_test'.tr(),
                        onTake: () => context.push('/test'),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

                      const SizedBox(height: 20),

                      // ── Scenario Test section ────────────────────────────────
                      _ResultSection(
                        icon: Icons.auto_stories_outlined,
                        titleKey: 'real_life_test_short',
                        color: AppColors.dustyGrape,
                        date: _fmtDate(_scenarioDate),
                        hasResults: _hasScenario,
                        percentages: _scenarioPct,
                        categoryOrder: _categoryOrder,
                        barColors: _barColors,
                        top3: _hasScenario ? _top3(_scenarioPct) : [],
                        isBn: isBn,
                        onViewFull: () => context.push('/scenario-results'),
                        onRetake: () => context.push('/scenarios'),
                        viewLabel: 'view_results'.tr(),
                        retakeLabel: 'retake_scenario'.tr(),
                        emptyLabel: 'no_scenario_results_sub'.tr(),
                        takeLabel: 'take_scenario_test'.tr(),
                        onTake: () => context.push('/scenarios'),
                      )
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 400.ms)
                          .slideY(begin: 0.06, end: 0, delay: 120.ms),

                      // ── CSV download ─────────────────────────────────────
                      if (_hasMi || _hasScenario) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
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
                        ).animate().fadeIn(delay: 250.ms),
                      ],

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Result section card ────────────────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.icon,
    required this.titleKey,
    required this.color,
    required this.date,
    required this.hasResults,
    required this.percentages,
    required this.categoryOrder,
    required this.barColors,
    required this.top3,
    required this.isBn,
    required this.onViewFull,
    required this.onRetake,
    required this.viewLabel,
    required this.retakeLabel,
    required this.emptyLabel,
    required this.takeLabel,
    required this.onTake,
  });

  final IconData icon;
  final String titleKey;
  final Color color;
  final String date;
  final bool hasResults;
  final Map<String, double> percentages;
  final List<String> categoryOrder;
  final List<Color> barColors;
  final List<MapEntry<String, double>> top3;
  final bool isBn;
  final VoidCallback onViewFull;
  final VoidCallback onRetake;
  final String viewLabel;
  final String retakeLabel;
  final String emptyLabel;
  final String takeLabel;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleKey.tr(),
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 11, color: Colors.white60),
                        ),
                    ],
                  ),
                ),
                if (hasResults)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${top3.isNotEmpty ? top3.first.value.toStringAsFixed(0) : 0}%',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          if (!hasResults) ...[
            // ── Empty state ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 48,
                      color: color.withValues(alpha: 0.35)),
                  const SizedBox(height: 12),
                  Text(
                    emptyLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onTake,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(takeLabel,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── Top 3 chips ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'top3_title'.tr(),
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: top3.asMap().entries.map((e) {
                      const medals = ['🥇', '🥈', '🥉'];
                      final key = e.value.key;
                      final pct = e.value.value;
                      final info = getIntelligenceByKey(key);
                      final name = info != null
                          ? (isBn ? info.nameBn : info.nameEn)
                          : key;
                      final colorIdx = categoryOrder.indexOf(key);
                      final c = colorIdx >= 0
                          ? barColors[colorIdx % barColors.length]
                          : color;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: c.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(medals[e.key],
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text(
                              '$name  ${pct.toStringAsFixed(0)}%',
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: c),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Score bars ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'all_scores'.tr(),
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ...categoryOrder.asMap().entries.map((e) {
                    final idx = e.key;
                    final cat = e.value;
                    final pct = percentages[cat] ?? 0;
                    final c = barColors[idx % barColors.length];
                    final info = getIntelligenceByKey(cat);
                    final name = info != null
                        ? (isBn ? info.nameBn : info.nameEn)
                        : cat;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              name,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor:
                                    c.withValues(alpha: 0.10),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(c),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: c),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Action buttons ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: onRetake,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(retakeLabel,
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onViewFull,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.bar_chart_rounded, size: 16),
                        label: Text(viewLabel,
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
