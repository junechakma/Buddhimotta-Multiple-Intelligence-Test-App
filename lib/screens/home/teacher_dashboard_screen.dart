import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/intelligence_data.dart';
import '../../models/question_model.dart';
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
  final Map<String, List<int>>? answerIndices; // category → [optionIndex per question]
  final Map<String, List<int>>? questionTimeSeconds; // category → [seconds per question]

  const _StudentData({
    required this.id,
    required this.name,
    this.miPercentages,
    this.scenarioPercentages,
    this.miTotalSeconds,
    this.miAvgSecondsPerQuestion,
    this.miTotalAnswerChanges,
    this.answerIndices,
    this.questionTimeSeconds,
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
  List<String> _classCodes = [];
  String _activeCode = '';
  List<_StudentData> _students = [];
  Map<String, List<Question>> _questions = {};
  bool _loading = true;
  bool _exporting = false;
  bool _creating = false;

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadQuestions() async {
    final jsonStr = await rootBundle.loadString('assets/data.json');
    final raw = json.decode(jsonStr) as List<dynamic>;
    final all = raw.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
    _questions = {
      for (final cat in _categoryOrder)
        cat: all.where((q) => q.category == cat).toList(),
    };
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

      final classesList = (data['classes'] as List?)?.cast<String>() ?? [];
      _classCodes = classesList;
      _activeCode = classesList.isNotEmpty ? classesList.first : '';

      if (_activeCode.isNotEmpty) {
        await Future.wait([_loadStudents(), _loadQuestions()]);
      } else {
        await _loadQuestions();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStudents() async {
    final snap = await FirestoreService.queryWhere('classes', 'classCode', _activeCode);
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
          answerIndices: miRaw?['answerIndices'] != null
              ? (miRaw!['answerIndices'] as Map<String, dynamic>).map(
                  (k, v) => MapEntry(
                    k,
                    (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
                  ),
                )
              : null,
          questionTimeSeconds: miRaw?['questionTimeSeconds'] != null
              ? (miRaw!['questionTimeSeconds'] as Map<String, dynamic>).map(
                  (k, v) => MapEntry(
                    k,
                    (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
                  ),
                )
              : null,
        ));
      } catch (_) {
        loaded.add(_StudentData(id: sid, name: sname));
      }
    }

    if (mounted) setState(() => _students = loaded);
  }

  String _csvEscape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Future<void> _exportCsv() async {
    if (_exporting || _students.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final buf = StringBuffer();

      // ── Header ──────────────────────────────────────────────────────────
      final headerCols = <String>['Student Name'];
      for (final cat in _categoryOrder) {
        final info = getIntelligenceByKey(cat);
        headerCols.add(_csvEscape('${info?.nameEn ?? cat} %'));
      }
      for (final cat in _categoryOrder) {
        final qs = _questions[cat] ?? [];
        for (int qi = 0; qi < qs.length; qi++) {
          final questionText = qs[qi].question;
          headerCols.add(_csvEscape('$questionText [Option 1-5]'));
          headerCols.add(_csvEscape('$questionText [Score]'));
          headerCols.add(_csvEscape('$questionText [Time(s)]'));
        }
      }
      headerCols.addAll(['TotalTime(s)', 'AvgTime/Q(s)', 'AnswerChanges']);
      buf.writeln(headerCols.join(','));

      // ── Rows ─────────────────────────────────────────────────────────────
      for (final student in _students) {
        final row = <String>[_csvEscape(student.name)];

        // Category percentages
        for (final cat in _categoryOrder) {
          final pct = student.miPercentages?[cat];
          row.add(pct != null ? pct.toStringAsFixed(1) : '');
        }

        // Per-question answers and times
        for (final cat in _categoryOrder) {
          final qs = _questions[cat] ?? [];
          final answers = student.answerIndices?[cat] ?? [];
          final times = student.questionTimeSeconds?[cat] ?? [];

          for (int qi = 0; qi < qs.length; qi++) {
            final q = qs[qi];
            if (qi < answers.length) {
              final optIdx = answers[qi];
              final score = q.scoreForOption(optIdx);
              final timeSec = qi < times.length ? times[qi] : 0;
              // Option index is 0-based internally; show as 1-based
              row.add('${optIdx + 1}');
              row.add('$score');
              row.add('$timeSec');
            } else {
              row.addAll(['', '', '']);
            }
          }
        }

        // Timing summary
        row.add(student.miTotalSeconds?.toString() ?? '');
        final avgQ = student.miAvgSecondsPerQuestion;
        row.add(avgQ != null ? avgQ.toStringAsFixed(1) : '');
        row.add(student.miTotalAnswerChanges?.toString() ?? '');

        buf.writeln(row.join(','));
      }

      final csvString = buf.toString();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/class_results.csv');
      await file.writeAsString(csvString);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Class Results - $_activeCode',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _copyCode() {
    if (_activeCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _activeCode));
    _showSnack('class_code_copied'.tr());
  }

  Future<void> _switchClass(String code) async {
    if (code == _activeCode) return;
    setState(() {
      _activeCode = code;
      _students = [];
    });
    await _loadStudents();
    if (mounted) setState(() {});
  }

  Future<void> _confirmDeleteClass(String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'delete_class'.tr(),
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.class_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    code,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'delete_class_confirm'.tr(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(),
                style: GoogleFonts.hindSiliguri(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('delete'.tr(),
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteClass(code);
  }

  Future<void> _deleteClass(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      // Delete the class document from Firestore
      final snap = await FirestoreService.queryWhere('classes', 'classCode', code);
      for (final doc in snap.docs) {
        await FirestoreService.deleteDocument('classes', doc.id);
      }

      // Remove code from teacher's list
      final updatedCodes = _classCodes.where((c) => c != code).toList();
      await FirestoreService.updateDocument('users', uid, {'classes': updatedCodes});

      if (mounted) {
        setState(() {
          _classCodes = updatedCodes;
          _activeCode = updatedCodes.isNotEmpty ? updatedCodes.first : '';
          _students = [];
        });
        _showSnack('class_deleted'.tr());
      }

      if (_activeCode.isNotEmpty) await _loadStudents();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _showSnack('err_try_again'.tr(), error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.hindSiliguri()),
      backgroundColor: error ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _creating = true);
    try {
      final code = _generateCode();
      await FirestoreService.addDocument('classes', {
        'classCode': code,
        'students': [],
        'teacherId': uid,
      });
      final updatedCodes = [..._classCodes, code];
      await FirestoreService.updateDocument('users', uid, {
        'classes': updatedCodes,
      });
      if (_questions.isEmpty) await _loadQuestions();
      if (mounted) {
        setState(() {
          _classCodes = updatedCodes;
          _activeCode = code;
          _students = [];
        });
        _showSnack('class_created'.tr());
      }
    } catch (_) {
      if (mounted) _showSnack('err_try_again'.tr(), error: true);
    }
    if (mounted) setState(() => _creating = false);
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
      floatingActionButton: FloatingActionButton(
        onPressed: _creating ? null : _createClass,
        backgroundColor: AppColors.primary,
        tooltip: 'create_class'.tr(),
        child: _creating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded, color: Colors.white),
      ),
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

                if (_activeCode.isEmpty)
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
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _creating ? null : _createClass,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: _creating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_rounded, size: 20),
                                label: Text(
                                  'create_class'.tr(),
                                  style: GoogleFonts.hindSiliguri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_activeCode.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Class switcher (shown when multiple classes) ──
                      if (_classCodes.length > 1) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _classCodes.map((code) {
                              final active = code == _activeCode;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _switchClass(code),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                      boxShadow: active
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      code,
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: active
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Class code card ────────────────
                      _ClassCodeCard(
                        code: _activeCode,
                        onCopy: _copyCode,
                        onDelete: () => _confirmDeleteClass(_activeCode),
                      )
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

                      const SizedBox(height: 16),

                      // ── Export CSV ─────────────────────
                      if (_submittedCount > 0)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _exporting ? null : _exportCsv,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dustyGrape,
                              side: const BorderSide(
                                  color: AppColors.dustyGrape, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
                              'export_class_csv'.tr(),
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ).animate().fadeIn(delay: 220.ms),

                      const SizedBox(height: 24),

                      // ── Students section ───────────────
                      _SectionLabel('my_students'.tr()),
                      const SizedBox(height: 10),

                      if (_students.isEmpty)
                        _EmptyStudentsCard().animate().fadeIn(delay: 250.ms)
                      else
                        ..._students.asMap().entries.map((e) =>
                            _StudentCard(student: e.value, isBn: isBn, questions: _questions)
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
  const _StudentCard({
    required this.student,
    required this.isBn,
    required this.questions,
  });
  final _StudentData student;
  final bool isBn;
  final Map<String, List<Question>> questions;

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
            if (student.hasMi && student.answerIndices != null && questions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AnswerReviewSection(
                answerIndices: student.answerIndices!,
                questionTimeSeconds: student.questionTimeSeconds,
                questions: questions,
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

// ── Answer review section ─────────────────────────────────────────────────────

class _AnswerReviewSection extends StatelessWidget {
  const _AnswerReviewSection({
    required this.answerIndices,
    required this.questions,
    required this.categoryOrder,
    required this.barColors,
    required this.isBn,
    this.questionTimeSeconds,
  });

  final Map<String, List<int>> answerIndices;
  final Map<String, List<int>>? questionTimeSeconds;
  final Map<String, List<Question>> questions;
  final List<String> categoryOrder;
  final List<Color> barColors;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: Icon(Icons.quiz_outlined,
              size: 18, color: AppColors.dustyGrape),
          title: Text(
            'view_answers'.tr(),
            style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.dustyGrape),
          ),
          children: [
            ...categoryOrder.asMap().entries.map((ce) {
              final idx = ce.key;
              final cat = ce.value;
              final catAnswers = answerIndices[cat];
              final catQuestions = questions[cat];
              if (catAnswers == null ||
                  catQuestions == null ||
                  catAnswers.isEmpty) {
                return const SizedBox.shrink();
              }
              final color = barColors[idx % barColors.length];
              final info = getIntelligenceByKey(cat);
              final catName =
                  info != null ? (isBn ? info.nameBn : info.nameEn) : cat;

              return Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2)),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    title: Text(
                      catName,
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                    subtitle: Text(
                      '${catAnswers.length} questions',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                    children: catAnswers.asMap().entries.map((qe) {
                      final qi = qe.key;
                      final selectedIdx = qe.value;
                      final q = qi < catQuestions.length
                          ? catQuestions[qi]
                          : null;
                      if (q == null) return const SizedBox.shrink();

                      final qTimes = questionTimeSeconds?[cat];
                      final timeSec = (qTimes != null && qi < qTimes.length)
                          ? qTimes[qi]
                          : null;
                      final isQuickAnswer = timeSec != null && timeSec < 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question number + text + time badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Q${qi + 1}',
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    q.question,
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                        height: 1.4),
                                  ),
                                ),
                                if (timeSec != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isQuickAnswer
                                          ? AppColors.error.withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isQuickAnswer
                                              ? Icons.flash_on_rounded
                                              : Icons.timer_outlined,
                                          size: 10,
                                          color: isQuickAnswer
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${timeSec}s',
                                          style: GoogleFonts.hindSiliguri(
                                              fontSize: 9,
                                              color: isQuickAnswer
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                              fontWeight: isQuickAnswer
                                                  ? FontWeight.w700
                                                  : FontWeight.normal),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Options
                            ...q.options.asMap().entries.map((oe) {
                              final oi = oe.key;
                              final opt = oe.value;
                              final isSelected = oi == selectedIdx;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.4)
                                        : Colors.grey.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 13,
                                      color: isSelected
                                          ? color
                                          : AppColors.textSecondary
                                              .withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: GoogleFonts.hindSiliguri(
                                            fontSize: 11,
                                            color: isSelected
                                                ? color
                                                : AppColors.textSecondary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${q.scoreForOption(oi)} pts',
                                          style: GoogleFonts.hindSiliguri(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Class code card ───────────────────────────────────────────────────────────

class _ClassCodeCard extends StatelessWidget {
  const _ClassCodeCard({
    required this.code,
    required this.onCopy,
    required this.onDelete,
  });
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white70, size: 22),
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
