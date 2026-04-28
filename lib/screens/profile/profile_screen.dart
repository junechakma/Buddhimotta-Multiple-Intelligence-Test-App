import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
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
        setState(() {
          _userData = data;
          _nameController.text = (data['name'] ?? '') as String;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.updateDocument('users', uid, {'name': name});
        setState(() {
          _userData['name'] = name;
          _editing = false;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  automaticallyImplyLeading: false,
                  leading: widget.embedded
                      ? null
                      : GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _avatarLetter,
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 10),
                          Text(
                            GuestSession.isGuest
                                ? 'guest'.tr()
                                : (_userData['name'] ?? '') as String,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      GuestSession.isGuest
                          ? [_GuestMessage()]
                          : [
                              _ProfileSection(
                                title: 'personal_info'.tr(),
                                children: [
                                  _EditableNameTile(
                                    editing: _editing,
                                    saving: _saving,
                                    controller: _nameController,
                                    onEdit: () =>
                                        setState(() => _editing = true),
                                    onSave: _saveName,
                                    onCancel: () {
                                      _nameController.text =
                                          (_userData['name'] ?? '') as String;
                                      setState(() => _editing = false);
                                    },
                                  ),
                                  _ProfileTile(
                                    icon: Icons.email_outlined,
                                    label: 'email'.tr(),
                                    value:
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.email ??
                                        '-',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _ProfileSection(
                                title: 'account_info'.tr(),
                                children: [
                                  _ProfileTile(
                                    icon: Icons.person_outline_rounded,
                                    label: 'gender'.tr(),
                                    value: _genderLabel,
                                  ),
                                  _ProfileTile(
                                    icon: Icons.cake_outlined,
                                    label: 'age'.tr(),
                                    value: _userData['age'] != null
                                        ? '${_userData['age']} ${'years'.tr()}'
                                        : '-',
                                  ),
                                  _ProfileTile(
                                    icon: Icons.work_outline_rounded,
                                    label: 'profession'.tr(),
                                    value: _professionLabel,
                                  ),
                                  _ProfileTile(
                                    icon: Icons.school_outlined,
                                    label: 'register_as'.tr(),
                                    value: _roleLabel,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String get _avatarLetter {
    if (GuestSession.isGuest) return 'অ';
    final name = (_userData['name'] ?? '') as String;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get _genderLabel {
    final g = (_userData['gender'] ?? '') as String;
    switch (g) {
      case 'male':
        return 'gender_male'.tr();
      case 'female':
        return 'gender_female'.tr();
      case 'other':
        return 'gender_other'.tr();
      default:
        return '-';
    }
  }

  String get _professionLabel {
    final p = (_userData['profession'] ?? '') as String;
    switch (p) {
      case 'student':
        return 'student'.tr();
      case 'professional':
        return 'professional_occ'.tr();
      default:
        return p.isNotEmpty ? p : '-';
    }
  }

  String get _roleLabel {
    final r = (_userData['role'] ?? '') as String;
    if (r == 'teacher') return 'teacher'.tr();
    return 'learner'.tr();
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableNameTile extends StatelessWidget {
  const _EditableNameTile({
    required this.editing,
    required this.saving,
    required this.controller,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });
  final bool editing;
  final bool saving;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: editing
                ? TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'full_name'.tr(),
                      border: InputBorder.none,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'full_name'.tr(),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        controller.text.isNotEmpty ? controller.text : '-',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
          if (editing) ...[
            if (saving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            else ...[
              GestureDetector(
                onTap: onCancel,
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSave,
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ] else
            GestureDetector(
              onTap: onEdit,
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _GuestMessage extends StatelessWidget {
  const _GuestMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'guest_no_profile'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
