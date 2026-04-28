import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/intelligence_data.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class _StudentData {
  final String id;
  final String name;
  final Map<String, double>? miPercentages;
  final Map<String, double>? scenarioPercentages;
  final int? miTotalSeconds;
  final double? miAvgSecondsPerQuestion;
  final int? miTotalAnswerChanges;

  const _StudentData({
    required this.id,
    required this.name,
    this.miPercentages,
    this.scenarioPercentages,
    this.miTotalSeconds,
    this.miAvgSecondsPerQuestion,
    this.miTotalAnswerChanges,
  });

  bool get hasMi => miPercentages != null;
  bool get hasScenario => scenarioPercentages != null;

  // Flag if avg time per question is under 3 seconds (likely didn't read)
  bool get isRushed =>
      miAvgSecondsPerQuestion != null && miAvgSecondsPerQuestion! < 3;

  String get formattedTime {
    if (miTotalSeconds == null) return '-';
    final m = miTotalSeconds! ~/ 60;
    final s = miTotalSeconds! % 60;
    return '${m}m ${s}s';
  }

  String? get topMiKey {
    if (miPercentages == null || miPercentages!.isEmpty) return null;
    return (miPercentages!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  double get topMiPct {
    if (miPercentages == null || miPercentages!.isEmpty) return 0;
    return (miPercentages!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .value;
  }
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String _teacherName = '';
  String _classCode = '';
  List<_StudentData> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirestoreService.getDocument('users', uid);
      if (!mounted || !doc.exists) {
        setState(() => _loading = false);
        return;
      }
      final data = doc.data()!;
      _teacherName = (data['name'] ?? '') as String;

      // Teachers store their code under 'classes' list
      final classesList = (data['classes'] as List?)?.cast<String>() ?? [];
      _classCode = classesList.isNotEmpty ? classesList.first : '';

      if (_classCode.isNotEmpty) {
        await _loadStudents();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStudents() async {
    final snap = await FirestoreService.queryWhere('classes', 'classCode', _classCode);
    if (snap.docs.isEmpty) return;

    final rawStudents = (snap.docs.first.data()['students'] as List?) ?? [];
    final List<_StudentData> loaded = [];

    for (final s in rawStudents) {
      final sid = s['id'] as String? ?? '';
      final sname = s['name'] as String? ?? '';
      if (sid.isEmpty) continue;

      try {
        final userDoc = await FirestoreService.getDocument('users', sid);
        if (!userDoc.exists) {
          loaded.add(_StudentData(id: sid, name: sname));
          continue;
        }
        final d = userDoc.data()!;
        final miRaw = d['miResults'] as Map<String, dynamic>?;
        final scRaw = d['scenarioResults'] as Map<String, dynamic>?;

        loaded.add(_StudentData(
          id: sid,
          name: (d['name'] as String?) ?? sname,
          miPercentages: miRaw != null
              ? (miRaw['percentages'] as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, (v as num).toDouble()))
              : null,
          scenarioPercentages: scRaw != null
              ? (scRaw['percentages'] as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, (v as num).toDouble()))
              : null,
          miTotalSeconds: miRaw?['totalTimeSeconds'] as int?,
          miAvgSecondsPerQuestion:
              (miRaw?['avgSecondsPerQuestion'] as num?)?.toDouble(),
          miTotalAnswerChanges: miRaw?['totalAnswerChanges'] as int?,
        ));
      } catch (_) {
        loaded.add(_StudentData(id: sid, name: sname));
      }
    }

    if (mounted) setState(() => _students = loaded);
  }

  void _copyCode() {
    if (_classCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _classCode));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('class_code_copied'.tr(), style: GoogleFonts.hindSiliguri()),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  int get _submittedCount => _students.where((s) => s.hasMi).length;

  String get _avgScore {
    final withResults = _students.where((s) => s.hasMi).toList();
    if (withResults.isEmpty) return '-';
    final avg = withResults.map((s) => s.topMiPct).reduce((a, b) => a + b) /
        withResults.length;
    return '${avg.toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final isBn = context.locale.languageCode == 'bn';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() => _students = []);
                await _loadStudents();
              },
              child: CustomScrollView(
              slivers: [
                // ── Header ───────────────────────────────
                SliverAppBar(
                  expandedHeight: 150,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration:
                          const BoxDecoration(gradient: AppColors.primaryGradient),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.school_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'nav_dashboard'.tr(),
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_teacherName.isNotEmpty)
                                      Text(_teacherName,
                                          style: GoogleFonts.hindSiliguri(
                                              fontSize: 13, color: Colors.white70)),
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

                if (_classCode.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.class_outlined,
                                size: 56, color: AppColors.amethystSmoke),
                            const SizedBox(height: 16),
                            Text(
                              'no_class_yet'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'no_class_yet_sub'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_classCode.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Class code card ────────────────
                      _ClassCodeCard(code: _classCode, onCopy: _copyCode)
                          .animate()
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 16),

                      // ── Stat cards ─────────────────────
                      _SectionLabel('teacher_overview'.tr()),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_rounded,
                              label: 'total_students'.tr(),
                              value: '${_students.length}',
                              color: AppColors.primary,
                            ).animate().fadeIn(delay: 100.ms),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.assignment_turned_in_rounded,
                              label: 'tests_submitted'.tr(),
                              value: '$_submittedCount',
                              color: AppColors.dustyGrape,
                            ).animate().fadeIn(delay: 150.ms),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.bar_chart_rounded,
                              label: 'avg_score'.tr(),
                              value: _avgScore,
                              color: AppColors.accent,
                            ).animate().fadeIn(delay: 200.ms),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Students section ───────────────
                      _SectionLabel('my_students'.tr()),
                      const SizedBox(height: 10),

                      if (_students.isEmpty)
                        _EmptyStudentsCard().animate().fadeIn(delay: 250.ms)
                      else
                        ..._students.asMap().entries.map((e) =>
                            _StudentCard(student: e.value, isBn: isBn)
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: 100 * e.key),
                                    duration: 400.ms)),

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ── Student card ──────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.isBn});
  final _StudentData student;
  final bool isBn;

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  static const _barColors = [
    AppColors.primary, AppColors.dustyGrape, AppColors.amethystSmoke,
    AppColors.accent, Color(0xFF78A237), Color(0xFFD83C36),
    Color(0xFF9B3DA0), Color(0xFF2196F3),
  ];

  @override
  Widget build(BuildContext context) {
    final topKey = student.topMiKey;
    final topInfo = topKey != null ? getIntelligenceByKey(topKey) : null;
    final topName = topInfo != null ? (isBn ? topInfo.nameBn : topInfo.nameEn) : null;
    final topColor = topKey != null
        ? _barColors[_categoryOrder.indexOf(topKey) % _barColors.length]
        : AppColors.amethystSmoke;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: GoogleFonts.hindSiliguri(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            student.name,
            style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          subtitle: student.hasMi
              ? Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: topColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        topName ?? '',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: topColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (student.miTotalSeconds != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.isRushed
                              ? AppColors.error.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              student.isRushed
                                  ? Icons.warning_amber_rounded
                                  : Icons.timer_outlined,
                              size: 11,
                              color: student.isRushed
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              student.formattedTime,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 11,
                                  color: student.isRushed
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontWeight: student.isRushed
                                      ? FontWeight.w700
                                      : FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : Text(
                  'test_not_taken'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
          children: [
            if (student.hasMi) ...[
              // ── Timing summary ─────────────────────
              if (student.miTotalSeconds != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: student.isRushed
                        ? AppColors.error.withValues(alpha: 0.06)
                        : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: student.isRushed
                        ? Border.all(
                            color: AppColors.error.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        student.isRushed
                            ? Icons.warning_amber_rounded
                            : Icons.timer_outlined,
                        size: 16,
                        color: student.isRushed
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          student.isRushed
                              ? 'rushed_warning'.tr(args: [student.formattedTime])
                              : 'time_taken'.tr(args: [student.formattedTime]),
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 12,
                              color: student.isRushed
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontWeight: student.isRushed
                                  ? FontWeight.w600
                                  : FontWeight.normal),
                        ),
                      ),
                      if (student.miTotalAnswerChanges != null)
                        Text(
                          'changes'.tr(args: ['${student.miTotalAnswerChanges}']),
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              _ScoreSection(
                titleKey: 'mi_test',
                percentages: student.miPercentages!,
                categoryOrder: _categoryOrder,
                barColors: _barColors,
                isBn: isBn,
              ),
            ],
            if (student.hasScenario) ...[
              const SizedBox(height: 12),
              _ScoreSection(
                titleKey: 'real_life_test_short',
                percentages: student.scenarioPercentages!,
                categoryOrder: _categoryOrder,
                barColors: _barColors,
                isBn: isBn,
              ),
            ],
            if (!student.hasMi && !student.hasScenario)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'no_results_yet'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({
    required this.titleKey,
    required this.percentages,
    required this.categoryOrder,
    required this.barColors,
    required this.isBn,
  });

  final String titleKey;
  final Map<String, double> percentages;
  final List<String> categoryOrder;
  final List<Color> barColors;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleKey.tr(),
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
          final color = barColors[idx % barColors.length];
          final info = getIntelligenceByKey(cat);
          final name = info != null ? (isBn ? info.nameBn : info.nameEn) : cat;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 4,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Class code card ───────────────────────────────────────────────────────────

class _ClassCodeCard extends StatelessWidget {
  const _ClassCodeCard({required this.code, required this.onCopy});
  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('your_class_code'.tr(),
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(code,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4)),
                const SizedBox(height: 4),
                Text('share_class_code'.tr(),
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.copy_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Empty students card ───────────────────────────────────────────────────────

class _EmptyStudentsCard extends StatelessWidget {
  const _EmptyStudentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: AppColors.amethystSmoke, size: 40),
          ),
          const SizedBox(height: 12),
          Text('no_students_yet'.tr(),
              style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('no_students_sub'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hindSiliguri(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary),
    );
  }
}
