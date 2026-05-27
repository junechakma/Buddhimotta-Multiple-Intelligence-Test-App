import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/intelligence_data.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  String _studentName = '';
  String _joinedClassCode = '';
  Map<String, double>? _miPercentages;
  Map<String, double>? _scenarioPercentages;
  bool _loading = true;
  bool _joining = false;

  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirestoreService.getDocument('users', uid);
      if (mounted && doc.exists) {
        final data = doc.data()!;
        final miRaw = data['miResults'] as Map<String, dynamic>?;
        final scenarioRaw = data['scenarioResults'] as Map<String, dynamic>?;
        setState(() {
          _studentName = (data['name'] ?? '') as String;
          _joinedClassCode = (data['classCode'] ?? '') as String;
          _miPercentages = miRaw != null
              ? (miRaw['percentages'] as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, (v as num).toDouble()))
              : null;
          _scenarioPercentages = scenarioRaw != null
              ? (scenarioRaw['percentages'] as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, (v as num).toDouble()))
              : null;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _joinClass() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _joining = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final result = await FirestoreService.queryWhere('classes', 'classCode', code);
      if (result.docs.isEmpty) {
        if (mounted) {
          _showSnack('err_invalid_class_code'.tr(), error: true);
        }
      } else {
        // Remove from old class first
        if (_joinedClassCode.isNotEmpty) {
          await _removeFromClass(uid, _joinedClassCode);
        }

        // Add to new class
        final classDoc = result.docs.first;
        final students = List<Map>.from((classDoc.data()['students'] as List?) ?? []);
        if (!students.any((s) => s['id'] == uid)) {
          students.add({'id': uid, 'name': _studentName});
          await FirestoreService.updateDocument('classes', classDoc.id, {'students': students});
        }

        await FirestoreService.updateDocument('users', uid, {
          'classCode': code,
          'enrolledClasses': [code],
        });

        if (mounted) {
          setState(() => _joinedClassCode = code);
          _codeController.clear();
          _showSnack('class_joined'.tr());
        }
      }
    } catch (_) {
      if (mounted) _showSnack('err_try_again'.tr(), error: true);
    }
    if (mounted) setState(() => _joining = false);
  }

  Future<void> _confirmLeaveClass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'leave_class'.tr(),
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.class_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _joinedClassCode,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'leave_class_confirm'.tr(),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('leave_class'.tr(),
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _leaveClass();
  }

  Future<void> _leaveClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _removeFromClass(uid, _joinedClassCode);
      await FirestoreService.updateDocument('users', uid, {
        'classCode': '',
        'enrolledClasses': [],
      });
      if (mounted) {
        setState(() => _joinedClassCode = '');
        _showSnack('class_left'.tr());
      }
    } catch (_) {
      if (mounted) _showSnack('err_try_again'.tr(), error: true);
    }
  }

  Future<void> _removeFromClass(String uid, String code) async {
    if (code.isEmpty) return;
    final snap = await FirestoreService.queryWhere('classes', 'classCode', code);
    if (snap.docs.isEmpty) return;
    final classDoc = snap.docs.first;
    final students = List<Map>.from((classDoc.data()['students'] as List?) ?? []);
    students.removeWhere((s) => s['id'] == uid);
    await FirestoreService.updateDocument('classes', classDoc.id, {'students': students});
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.hindSiliguri()),
      backgroundColor: error ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
                // ── Header ────────────────────────────────
                SliverAppBar(
                  expandedHeight: 150,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient),
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
                                child: const Icon(Icons.book_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'nav_classes'.tr(),
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_studentName.isNotEmpty)
                                      Text(
                                        _studentName,
                                        style: GoogleFonts.hindSiliguri(
                                            fontSize: 13,
                                            color: Colors.white70),
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

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Joined class ───────────────────
                      if (_joinedClassCode.isNotEmpty) ...[
                        _JoinedClassCard(
                          code: _joinedClassCode,
                          onLeave: _confirmLeaveClass,
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),
                      ],

                      // ── Join section ───────────────────
                      _SectionLabel(
                        _joinedClassCode.isEmpty
                            ? 'join_a_class'.tr()
                            : 'change_class'.tr(),
                      ),
                      const SizedBox(height: 10),
                      _JoinClassCard(
                        controller: _codeController,
                        joining: _joining,
                        onJoin: _joinClass,
                        hasClass: _joinedClassCode.isNotEmpty,
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 24),

                      // ── My progress ────────────────────
                      _SectionLabel('my_progress'.tr()),
                      const SizedBox(height: 10),
                      _ProgressCard(
                        miPercentages: _miPercentages,
                        scenarioPercentages: _scenarioPercentages,
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 20),

                      // ── Coming soon ────────────────────
                      _ComingSoonBanner()
                          .animate()
                          .fadeIn(delay: 250.ms),

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Joined class card ─────────────────────────────────────────────────────────

class _JoinedClassCard extends StatelessWidget {
  const _JoinedClassCard({required this.code, required this.onLeave});
  final String code;
  final VoidCallback onLeave;

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.class_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'my_class'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12, color: Colors.white70),
                ),
                Text(
                  code,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'class_active'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLeave,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.exit_to_app_rounded,
                  color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Join class card ───────────────────────────────────────────────────────────

class _JoinClassCard extends StatelessWidget {
  const _JoinClassCard({
    required this.controller,
    required this.joining,
    required this.onJoin,
    required this.hasClass,
  });

  final TextEditingController controller;
  final bool joining;
  final VoidCallback onJoin;
  final bool hasClass;

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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasClass
                ? 'enter_new_class_code'.tr()
                : 'enter_class_code_hint'.tr(),
            style: GoogleFonts.hindSiliguri(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'class_code_optional'.tr(),
                    hintStyle: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    prefixIcon: const Icon(Icons.tag_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: joining ? null : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: joining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'join'.tr(),
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({this.miPercentages, this.scenarioPercentages});
  final Map<String, double>? miPercentages;
  final Map<String, double>? scenarioPercentages;

  static const _categoryOrder = [
    'musical', 'visual', 'linguistic', 'logical',
    'physical', 'interpersonal', 'intrapersonal', 'naturalistic',
  ];

  static const _barColors = [
    AppColors.primary, AppColors.dustyGrape, AppColors.amethystSmoke,
    AppColors.accent, Color(0xFF78A237), Color(0xFFD83C36),
    Color(0xFF9B3DA0), Color(0xFF2196F3),
  ];

  String? _topKey(Map<String, double> pct) {
    if (pct.isEmpty) return null;
    return (pct.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.locale.languageCode == 'bn';
    final hasMi = miPercentages != null;
    final hasScenario = scenarioPercentages != null;

    if (!hasMi && !hasScenario) {
      return Container(
        padding: const EdgeInsets.all(18),
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
            const Icon(Icons.insights_rounded, color: AppColors.amethystSmoke, size: 40),
            const SizedBox(height: 10),
            Text('no_progress_yet'.tr(),
                style: GoogleFonts.hindSiliguri(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('take_test_first'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMi) _ResultSection(
            titleKey: 'mi_test',
            icon: Icons.psychology_rounded,
            percentages: miPercentages!,
            categoryOrder: _categoryOrder,
            barColors: _barColors,
            topKey: _topKey(miPercentages!),
            isBn: isBn,
          ),
          if (hasMi && hasScenario) const SizedBox(height: 16),
          if (hasScenario) _ResultSection(
            titleKey: 'real_life_test_short',
            icon: Icons.auto_stories_outlined,
            percentages: scenarioPercentages!,
            categoryOrder: _categoryOrder,
            barColors: _barColors,
            topKey: _topKey(scenarioPercentages!),
            isBn: isBn,
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.titleKey,
    required this.icon,
    required this.percentages,
    required this.categoryOrder,
    required this.barColors,
    required this.topKey,
    required this.isBn,
  });

  final String titleKey;
  final IconData icon;
  final Map<String, double> percentages;
  final List<String> categoryOrder;
  final List<Color> barColors;
  final String? topKey;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(titleKey.tr(),
                style: GoogleFonts.hindSiliguri(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        ...categoryOrder.asMap().entries.map((e) {
          final idx = e.key;
          final cat = e.value;
          final pct = percentages[cat] ?? 0;
          final color = barColors[idx % barColors.length];
          final info = getIntelligenceByKey(cat);
          final name = info != null ? (isBn ? info.nameBn : info.nameEn) : cat;
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
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
                const SizedBox(height: 3),
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
    );
  }
}

// ── Coming soon banner ────────────────────────────────────────────────────────

class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner();

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
        children: [
          const Icon(Icons.rocket_launch_rounded,
              color: AppColors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'coming_soon'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  'classes_coming_soon_sub'.tr(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4),
                ),
              ],
            ),
          ),
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
