import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/scenario_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../services/local_results_service.dart';
import '../../theme/app_colors.dart';

class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _advancing = false;

  // Timing
  DateTime? _testStartTime;
  DateTime? _scenarioStartTime;
  final List<int> _scenarioTimesSeconds = [];

  // Per-scenario choice (option id: a/b/c/d)
  final List<String> _chosenOptionIds = [];

  // Accumulated raw scores across all scenarios
  final Map<String, int> _scores = {
    'musical': 0,
    'visual': 0,
    'linguistic': 0,
    'logical': 0,
    'physical': 0,
    'interpersonal': 0,
    'intrapersonal': 0,
    'naturalistic': 0,
  };

  // Max possible points per category (to compute percentages)
  final Map<String, int> _maxPoints = {
    'musical': 0,
    'visual': 0,
    'linguistic': 0,
    'logical': 0,
    'physical': 0,
    'interpersonal': 0,
    'intrapersonal': 0,
    'naturalistic': 0,
  };

  Scenario get _current => scenarios[_currentIndex];

  @override
  void initState() {
    super.initState();
    _computeMaxPoints();
    final now = DateTime.now();
    _testStartTime = now;
    _scenarioStartTime = now;
  }

  void _computeMaxPoints() {
    for (final scenario in scenarios) {
      // For each scenario, find the maximum each option can contribute per category
      // and accumulate across scenarios
      for (final option in scenario.options) {
        option.intelligencePoints.forEach((key, value) {
          _maxPoints[key] = (_maxPoints[key] ?? 0) + value;
        });
      }
    }
    // We use proportional scoring: user_score / theoretical_max
    // But theoretical max is sum of all options' points (they pick one per scenario).
    // Instead, compute per-scenario max contribution per category as the highest
    // single option value, summed across scenarios.
  }

  void _selectOption(String id) {
    if (_selectedOptionId != null || _advancing) return;
    setState(() => _selectedOptionId = id);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _applyScores();
    });
  }

  void _applyScores() {
    // Record the choice and elapsed time for this scenario
    if (_chosenOptionIds.length <= _currentIndex) {
      _chosenOptionIds.add(_selectedOptionId!);
    } else {
      _chosenOptionIds[_currentIndex] = _selectedOptionId!;
    }
    if (_scenarioStartTime != null) {
      final elapsed = DateTime.now().difference(_scenarioStartTime!).inSeconds;
      if (_scenarioTimesSeconds.length <= _currentIndex) {
        _scenarioTimesSeconds.add(elapsed);
      } else {
        _scenarioTimesSeconds[_currentIndex] = elapsed;
      }
      _scenarioStartTime = DateTime.now();
    }

    final option = _current.options.firstWhere((o) => o.id == _selectedOptionId);
    option.intelligencePoints.forEach((key, value) {
      _scores[key] = (_scores[key] ?? 0) + value;
    });

    if (_currentIndex < scenarios.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _advancing = false;
      });
    } else {
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    // Compute percentages: for each category, user score vs total possible
    // "Total possible" = sum across all scenarios of the highest option score for that category
    final Map<String, int> perScenarioMax = {
      'musical': 0, 'visual': 0, 'linguistic': 0, 'logical': 0,
      'physical': 0, 'interpersonal': 0, 'intrapersonal': 0, 'naturalistic': 0,
    };
    for (final scenario in scenarios) {
      for (final key in perScenarioMax.keys) {
        int maxForScenario = 0;
        for (final option in scenario.options) {
          final pts = option.intelligencePoints[key] ?? 0;
          if (pts > maxForScenario) maxForScenario = pts;
        }
        perScenarioMax[key] = (perScenarioMax[key] ?? 0) + maxForScenario;
      }
    }

    final Map<String, double> percentages = {};
    for (final key in _scores.keys) {
      final max = perScenarioMax[key] ?? 1;
      percentages[key] = max > 0 ? (_scores[key]! / max * 100).clamp(0, 100) : 0;
    }

    final totalSeconds = _testStartTime != null
        ? DateTime.now().difference(_testStartTime!).inSeconds
        : 0;

    await LocalResultsService.saveScenario(
      scores: Map<String, int>.from(_scores),
      percentages: percentages,
      choices: List<String>.from(_chosenOptionIds),
      scenarioTimesSeconds: List<int>.from(_scenarioTimesSeconds),
      totalTimeSeconds: totalSeconds,
    );

    if (!GuestSession.isGuest) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.updateDocument('users', uid, {
          'scenarioResults': {
            'percentages': percentages,
            'choices': List<String>.from(_chosenOptionIds),
            'scenarioTimesSeconds': List<int>.from(_scenarioTimesSeconds),
            'totalTimeSeconds': totalSeconds,
            'date': DateTime.now().toIso8601String(),
          },
        });
      }
    }

    if (mounted) {
      context.go('/scenario-results', extra: {
        'percentages': percentages,
        'scores': Map<String, int>.from(_scores),
        'choices': List<String>.from(_chosenOptionIds),
        'scenarioTimesSeconds': List<int>.from(_scenarioTimesSeconds),
        'totalTimeSeconds': totalSeconds,
      });
    }
  }

  Future<bool> _onWillPop() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('exit_test_title'.tr(),
            style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
        content: Text('exit_test_body'.tr(),
            style: GoogleFonts.hindSiliguri()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(),
                style: GoogleFonts.hindSiliguri(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('exit'.tr(), style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final should = await _onWillPop();
          if (should && context.mounted) context.go('/home');
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  current: _currentIndex + 1,
                  total: scenarios.length,
                  onExit: () async {
                    final should = await _onWillPop();
                    if (should && context.mounted) context.go('/home');
                  },
                ),
                Expanded(
                  child: _ScenarioBody(
                    key: ValueKey(_currentIndex),
                    scenario: _current,
                    selectedId: _selectedOptionId,
                    onSelect: _selectOption,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.current,
    required this.total,
    required this.onExit,
  });

  final int current;
  final int total;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final progress = current / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onExit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'real_life_test'.tr(),
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      '${'scenario'.tr()} $current / $total',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Scenario body ──────────────────────────────────────────────────────────────

class _ScenarioBody extends StatelessWidget {
  const _ScenarioBody({
    super.key,
    required this.scenario,
    required this.selectedId,
    required this.onSelect,
  });

  final Scenario scenario;
  final String? selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              scenario.title,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Scenario description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              scenario.description,
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          Text(
            'choose_your_response'.tr(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 10),

          // Options
          ...scenario.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final option = entry.value;
            final isSelected = selectedId == option.id;
            final isUnselected = selectedId != null && !isSelected;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                option: option,
                isSelected: isSelected,
                isUnselected: isUnselected,
                onTap: () => onSelect(option.id),
              ).animate().fadeIn(delay: Duration(milliseconds: 200 + idx * 80)),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Option card ────────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.isUnselected,
    required this.onTap,
  });

  final ScenarioOption option;
  final bool isSelected;
  final bool isUnselected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelMap = {'a': 'ক', 'b': 'খ', 'c': 'গ', 'd': 'ঘ'};

    Color bgColor = Colors.white;
    Color borderColor = Colors.transparent;
    Color labelBg = AppColors.cardBg;
    Color labelFg = AppColors.textSecondary;

    if (isSelected) {
      bgColor = AppColors.primary.withValues(alpha: 0.08);
      borderColor = AppColors.primary;
      labelBg = AppColors.primary;
      labelFg = Colors.white;
    } else if (isUnselected) {
      bgColor = Colors.white.withValues(alpha: 0.5);
    }

    return GestureDetector(
      onTap: isSelected || isUnselected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.05),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : Text(
                      labelMap[option.id] ?? option.id.toUpperCase(),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: labelFg,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  option.text,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: isUnselected
                        ? AppColors.textSecondary.withValues(alpha: 0.6)
                        : AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
