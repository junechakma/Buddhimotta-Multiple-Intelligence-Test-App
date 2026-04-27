import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _classCodeCtrl = TextEditingController();

  String? _gender;
  int? _age;
  String? _profession;
  String _role = 'student';
  bool _termsChecked = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _classCodeCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) { _snack('err_name'.tr()); return false; }
    if (_gender == null) { _snack('err_gender'.tr()); return false; }
    if (_age == null) { _snack('err_age'.tr()); return false; }
    if (_profession == null) { _snack('err_profession'.tr()); return false; }
    if (_emailCtrl.text.trim().isEmpty) { _snack('err_email'.tr()); return false; }
    if (_passwordCtrl.text.isEmpty) { _snack('err_password'.tr()); return false; }
    if (!_termsChecked) { _snack('err_terms'.tr()); return false; }
    return true;
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now();
    return List.generate(6, (i) {
      final seed = (now.microsecondsSinceEpoch >> (i * 4)) & 0xFF;
      return chars[seed % chars.length];
    }).join();
  }

  Future<void> _register() async {
    if (!_validate()) return;
    setState(() => _loading = true);

    try {
      final code = _classCodeCtrl.text.trim().toUpperCase();

      if (_role == 'student' && code.isNotEmpty) {
        final snap = await FirestoreService.queryWhere('classes', 'classCode', code);
        if (snap.docs.isEmpty) {
          _snack('err_invalid_class_code'.tr());
          setState(() => _loading = false);
          return;
        }
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final uid = cred.user!.uid;
      final name = _nameCtrl.text.trim();

      await FirestoreService.setDocument('users', uid, {
        'name': name,
        'email': _emailCtrl.text.trim(),
        'gender': _gender,
        'age': _age,
        'profession': _profession,
        'role': _role,
        'musicScore': 0,
        'visualScore': 0,
        'linguisticScore': 0,
        'logicalScore': 0,
        'physicalScore': 0,
        'interpersonalScore': 0,
        'intrapersonalScore': 0,
        'naturalisticScore': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_role == 'teacher') {
        final classCode = _generateClassCode();
        await FirestoreService.addDocument('classes', {
          'classCode': classCode,
          'teacherId': uid,
          'teacherName': name,
          'students': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirestoreService.updateDocument('users', uid, {
          'classes': [classCode],
        });
        if (mounted) _showClassCodeDialog(classCode);
      } else if (code.isNotEmpty) {
        await _joinClass(uid, name, code);
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'registration_failed'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinClass(String uid, String name, String code) async {
    final snap = await FirestoreService.queryWhere('classes', 'classCode', code);
    if (snap.docs.isEmpty) return;
    final classId = snap.docs.first.id;
    final students = List<Map>.from(
        (snap.docs.first.data()['students'] as List?) ?? []);
    students.add({'id': uid, 'name': name});
    await FirestoreService.updateDocument(
        'classes', classId, {'students': students});
    await FirestoreService.updateDocument(
        'users', uid, {'enrolledClasses': [code]});
  }

  void _showClassCodeDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'your_class_code'.tr(),
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                code,
                style: GoogleFonts.robotoMono(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'share_class_code'.tr(),
              style: GoogleFonts.hindSiliguri(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ok'.tr(), style: GoogleFonts.hindSiliguri()),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.hindSiliguri())),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // subscribe — rebuilds this widget when locale changes
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildTopBar(context),
                      const SizedBox(height: 24),
                      _buildCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'register'.tr(),
                style: GoogleFonts.hindSiliguri(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'register_subtitle'.tr(),
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const LangToggleButton(),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('personal_info'.tr()),
          const SizedBox(height: 16),
          AuthInputField(
            controller: _nameCtrl,
            hint: 'full_name'.tr(),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _label('gender'.tr()),
          const SizedBox(height: 8),
          _GenderChips(
            selected: _gender,
            onSelected: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          _label('age'.tr()),
          const SizedBox(height: 8),
          StyledDropdown<int>(
            hint: 'select_age'.tr(),
            value: _age,
            items: List.generate(35, (i) => i + 6)
                .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('age_years'.tr(args: ['$v']),
                        style: GoogleFonts.hindSiliguri())))
                .toList(),
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 16),
          _label('profession'.tr()),
          const SizedBox(height: 8),
          StyledDropdown<String>(
            hint: 'select_profession'.tr(),
            value: _profession,
            items: [
              DropdownMenuItem(
                  value: 'student',
                  child: Text('student'.tr(),
                      style: GoogleFonts.hindSiliguri())),
              DropdownMenuItem(
                  value: 'professional',
                  child: Text('professional_occ'.tr(),
                      style: GoogleFonts.hindSiliguri())),
            ],
            onChanged: (v) => setState(() => _profession = v),
          ),
          const SizedBox(height: 24),
          _SectionLabel('account_info'.tr()),
          const SizedBox(height: 16),
          _label('register_as'.tr()),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'student',
                label: Text('learner'.tr(),
                    style: GoogleFonts.hindSiliguri(fontSize: 13)),
                icon: const Icon(Icons.school_outlined, size: 18),
              ),
              ButtonSegment(
                value: 'teacher',
                label: Text('teacher'.tr(),
                    style: GoogleFonts.hindSiliguri(fontSize: 13)),
                icon: const Icon(Icons.cast_for_education_outlined, size: 18),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
          const SizedBox(height: 16),
          if (_role == 'student') ...[
            AuthInputField(
              controller: _classCodeCtrl,
              hint: 'class_code_optional'.tr(),
              icon: Icons.group_outlined,
            ),
            const SizedBox(height: 16),
          ],
          AuthInputField(
            controller: _emailCtrl,
            hint: 'email'.tr(),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          AuthInputField(
            controller: _passwordCtrl,
            hint: 'password'.tr(),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 20),
          _TermsRow(
            checked: _termsChecked,
            onChanged: (v) => setState(() => _termsChecked = v ?? false),
            onTermsTap: () => context.push('/terms'),
          ),
          const SizedBox(height: 24),
          GradientButton(
              label: 'register'.tr(), onTap: _register, loading: _loading),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'already_have_account'.tr(),
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'login_link'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOut);
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.hindSiliguri(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GenderChips extends StatelessWidget {
  const _GenderChips({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String> onSelected;

  static const _options = [
    ('male', 'gender_male'),
    ('female', 'gender_female'),
    ('others', 'gender_other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map((opt) {
        final isSelected = selected == opt.$1;
        return ChoiceChip(
          label: Text(opt.$2.tr(),
              style: GoogleFonts.hindSiliguri(fontSize: 13)),
          selected: isSelected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          onSelected: (_) => onSelected(opt.$1),
        );
      }).toList(),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.checked,
    required this.onChanged,
    required this.onTermsTap,
  });

  final bool checked;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: checked, onChanged: onChanged),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!checked),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(text: 'terms_agree_prefix'.tr()),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onTermsTap,
                      child: Text(
                        'terms_agree_link'.tr(),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: 'terms_agree_suffix'.tr()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
