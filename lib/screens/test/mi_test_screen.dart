import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/intelligence_data.dart';
import '../../models/question_model.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../services/local_results_service.dart';
import '../../theme/app_colors.dart';

class MiTestScreen extends StatefulWidget {
  const MiTestScreen({super.key});

  @override
  State<MiTestScreen> createState() => _MiTestScreenState();
}

class _MiTestScreenState extends State<MiTestScreen> {
  List<List<Question>> _categoryQuestions = [];
  List<Map<int, int>> _answers = [];
  // tracks how many times each answer was changed: [categoryIndex][questionIndex]
  List<Map<int, int>> _answerChanges = [];
  int _currentCategory = 0;
  bool _loading = true;
  bool _saving = false;

  // time tracking
  DateTime? _testStartTime;
  DateTime? _categoryStartTime;
  final Map<int, int> _categoryTimeSeconds = {}; // categoryIndex → seconds spent
  // categoryIndex → questionIndex → seconds from category start when first answered
  final List<Map<int, int>> _questionAnswerTimes = [];

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final jsonStr = await rootBundle.loadString('assets/data.json');
    final raw = json.decode(jsonStr) as List<dynamic>;
    final all = raw.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
    final grouped = _categoryOrder
        .map((cat) => all.where((q) => q.category == cat).toList())
        .toList();
    final now = DateTime.now();
    setState(() {
      _categoryQuestions = grouped;
      _answers = List.generate(grouped.length, (_) => {});
      _answerChanges = List.generate(grouped.length, (_) => {});
      _questionAnswerTimes.addAll(List.generate(grouped.length, (_) => {}));
      _testStartTime = now;
      _categoryStartTime = now;
      _loading = false;
    });
  }

  void _recordCategoryTime() {
    if (_categoryStartTime == null) return;
    final elapsed = DateTime.now().difference(_categoryStartTime!).inSeconds;
    _categoryTimeSeconds[_currentCategory] = elapsed;
    _categoryStartTime = DateTime.now();
  }

  bool get _currentComplete =>
      _categoryQuestions.isNotEmpty &&
      _answers[_currentCategory].length == _categoryQuestions[_currentCategory].length;

  void _selectOption(int qi, int optIdx) {
    setState(() {
      if (_answers[_currentCategory].containsKey(qi)) {
        _answerChanges[_currentCategory][qi] =
            (_answerChanges[_currentCategory][qi] ?? 0) + 1;
      } else {
        // First time answering — record elapsed seconds from category start
        if (_categoryStartTime != null) {
          _questionAnswerTimes[_currentCategory][qi] =
              DateTime.now().difference(_categoryStartTime!).inSeconds;
        }
      }
      _answers[_currentCategory][qi] = optIdx;
    });
  }

  void _next() {
    if (!_currentComplete) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('test_answer_all'.tr(), style: GoogleFonts.hindSiliguri()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    _recordCategoryTime();
    if (_currentCategory < _categoryOrder.length - 1) {
      setState(() => _currentCategory++);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submitTest();
    }
  }

  /// Applies the same boost/deduction as the original RN app:
  /// - Highest ≤ 80%: top 3 get +15/+10/+5, bottom 3 get −10
  /// - Highest ≤ 90% (> 80%): top 1 gets +5, bottom 3 get −10
  /// - Highest > 90%: no adjustment
  Map<String, double> _applyBoostDeduction(Map<String, double> raw) {
    final sorted = raw.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final highest = sorted.first.value;
    final result = <String, double>{};

    for (int i = 0; i < sorted.length; i++) {
      final key = sorted[i].key;
      final val = sorted[i].value;
      if (highest <= 80) {
        if (i < 3) {
          final boost = i == 0 ? 15.0 : i == 1 ? 10.0 : 5.0;
          result[key] = (val + boost).clamp(0, 100);
        } else if (i < sorted.length - 3) {
          result[key] = val;
        } else {
          result[key] = (val - 10).clamp(0, 100);
        }
      } else if (highest <= 90) {
        if (i == 0) {
          result[key] = (val + 5).clamp(0, 100);
        } else if (i < sorted.length - 3) {
          result[key] = val;
        } else {
          result[key] = (val - 10).clamp(0, 100);
        }
      } else {
        result[key] = val;
      }
    }
    return result;
  }

  Future<void> _submitTest() async {
    setState(() => _saving = true);

    // ── Raw scores ──────────────────────────────────────────────────────
    final scores = <String, int>{};
    final rawPercentages = <String, double>{};

    // answer indices per category for teacher view: { 'musical': [3,2,4,...] }
    final answerIndices = <String, List<int>>{};

    for (int ci = 0; ci < _categoryOrder.length; ci++) {
      final cat = _categoryOrder[ci];
      int score = 0;
      final indices = <int>[];
      for (int qi = 0; qi < _categoryQuestions[ci].length; qi++) {
        final optIdx = _answers[ci][qi] ?? 0;
        score += _categoryQuestions[ci][qi].scoreForOption(optIdx);
        indices.add(optIdx);
      }
      scores[cat] = score;
      rawPercentages[cat] = (score / 70) * 100;
      answerIndices[cat] = indices;
    }

    // ── Apply boost/deduction (matches original RN app) ─────────────────
    final percentages = _applyBoostDeduction(rawPercentages)
        .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(1))));

    // Compute timing data (needed for both local save and Firestore)
    final totalSeconds = _testStartTime != null
        ? DateTime.now().difference(_testStartTime!).inSeconds
        : 0;

    final categoryTimes = <String, int>{};
    for (int i = 0; i < _categoryOrder.length; i++) {
      categoryTimes[_categoryOrder[i]] = _categoryTimeSeconds[i] ?? 0;
    }

    final questionTimes = <String, List<int>>{};
    for (int i = 0; i < _categoryOrder.length; i++) {
      final cat = _categoryOrder[i];
      final qCount = _categoryQuestions[i].length;
      questionTimes[cat] = List.generate(
          qCount, (qi) => _questionAnswerTimes[i][qi] ?? 0);
    }

    await LocalResultsService.save(
      scores: scores,
      percentages: percentages,
      answerIndices: answerIndices,
      categoryTimeSeconds: categoryTimes,
      questionTimeSeconds: questionTimes,
      totalTimeSeconds: totalSeconds,
    );

    if (!GuestSession.isGuest) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final totalChanges = _answerChanges.fold<int>(
          0, (sum, m) => sum + m.values.fold(0, (s, v) => s + v),
        );

        final totalQuestions = _categoryQuestions.fold<int>(
          0, (sum, l) => sum + l.length,
        );

        await FirestoreService.updateDocument('users', uid, {
          'miResults': {
            'percentages': percentages,
            'rawPercentages': rawPercentages
                .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(1)))),
            'answerIndices': answerIndices,
            'questionTimeSeconds': questionTimes,
            'date': DateTime.now().toIso8601String(),
            'totalTimeSeconds': totalSeconds,
            'categoryTimeSeconds': categoryTimes,
            'totalAnswerChanges': totalChanges,
            'totalQuestions': totalQuestions,
            'avgSecondsPerQuestion': totalQuestions > 0
                ? (totalSeconds / totalQuestions).roundToDouble()
                : 0,
          },
        });
      }
    }

    if (mounted) {
      context.go('/results', extra: {
        'scores': scores,
        'percentages': percentages,
        'categoryTimeSeconds': categoryTimes,
        'answerIndices': answerIndices,
        'questionTimeSeconds': questionTimes,
      });
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('exit_test_title'.tr(),
            style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
        content: Text('exit_test_body'.tr(),
            style: GoogleFonts.hindSiliguri()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(),
                style: GoogleFonts.hindSiliguri(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('exit'.tr(),
                style: GoogleFonts.hindSiliguri(color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final catKey = _categoryOrder[_currentCategory];
    final info = getIntelligenceByKey(catKey);
    final isBn = context.locale.languageCode == 'bn';
    final catName = info != null ? (isBn ? info.nameBn : info.nameEn) : catKey;
    final questions = _categoryQuestions[_currentCategory];
    final isLast = _currentCategory == _categoryOrder.length - 1;
    final totalAnswered = _answers.fold<int>(0, (sum, m) => sum + m.length);
    final totalQuestions = _categoryQuestions.fold<int>(0, (sum, l) => sum + l.length);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _TestHeader(
              currentCategory: _currentCategory,
              totalCategories: _categoryOrder.length,
              categoryName: catName,
              onBack: _showExitDialog,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: questions.length,
                itemBuilder: (context, qi) => _QuestionCard(
                  index: qi,
                  question: questions[qi],
                  selectedOption: _answers[_currentCategory][qi],
                  onSelect: (o) => _selectOption(qi, o),
                ),
              ),
            ),
            _BottomBar(
              onNext: _saving ? null : _next,
              isLast: isLast,
              saving: _saving,
              answeredCount: _answers[_currentCategory].length,
              totalCount: questions.length,
              totalAnswered: totalAnswered,
              totalQuestions: totalQuestions,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TestHeader extends StatelessWidget {
  const _TestHeader({
    required this.currentCategory,
    required this.totalCategories,
    required this.categoryName,
    required this.onBack,
  });

  final int currentCategory;
  final int totalCategories;
  final String categoryName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (currentCategory + 1) / totalCategories;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'mi_test'.tr(),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentCategory + 1} / $totalCategories',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13, color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    categoryName,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedOption,
    required this.onSelect,
  });

  final int index;
  final Question question;
  final int? selectedOption;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selectedOption != null
                      ? AppColors.primary
                      : AppColors.cardBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.hindSiliguri(
                      color: selectedOption != null
                          ? Colors.white
                          : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.question,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...question.options.asMap().entries.map((e) {
            final idx = e.key;
            final label = e.value;
            final isSelected = selectedOption == idx;
            return GestureDetector(
              onTap: () => onSelect(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 11)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onNext,
    required this.isLast,
    required this.saving,
    required this.answeredCount,
    required this.totalCount,
    required this.totalAnswered,
    required this.totalQuestions,
  });

  final VoidCallback? onNext;
  final bool isLast;
  final bool saving;
  final int answeredCount;
  final int totalCount;
  final int totalAnswered;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final allDone = answeredCount == totalCount;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$totalAnswered / $totalQuestions ${'answered'.tr()}',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${'page'.tr()} $answeredCount/$totalCount',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allDone ? AppColors.primary : AppColors.amethystSmoke,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'view_results'.tr() : 'next_category'.tr(),
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                            isLast
                                ? Icons.bar_chart_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
