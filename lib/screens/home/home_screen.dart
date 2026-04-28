import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../router/app_router.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_session.dart';
import '../../theme/app_colors.dart';
import '../profile/profile_screen.dart';
import 'student_classes_screen.dart';
import 'teacher_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _role = 'student';
  String _userName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
          _role = (data['role'] ?? 'student') as String;
          _userName = (data['name'] ?? '') as String;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    if (GuestSession.isGuest) {
      GuestSession.end();
      AppRouter.refreshAuth();
      return;
    }
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    context.locale;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final bool isGuest = GuestSession.isGuest;

    // Tab index is always: 0=Home, 1=Classes/Dashboard, 2=Profile
    // For guests: only tab 0 is available — clamp index
    final safeIndex = isGuest ? 0 : _selectedIndex.clamp(0, 2);

    final tabs = [
      _HomeTab(userName: _userName, onLogout: _logout),
      if (!isGuest)
        _role == 'teacher'
            ? const TeacherDashboardScreen()
            : const StudentClassesScreen(),
      if (!isGuest) const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: safeIndex.clamp(0, tabs.length - 1),
        children: tabs,
      ),
      bottomNavigationBar: isGuest
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: safeIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.amethystSmoke,
                backgroundColor: AppColors.cardBg,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: GoogleFonts.hindSiliguri(fontSize: 12),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home_rounded),
                    label: 'nav_home'.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(_role == 'teacher'
                        ? Icons.school_outlined
                        : Icons.book_outlined),
                    activeIcon: Icon(_role == 'teacher'
                        ? Icons.school_rounded
                        : Icons.book_rounded),
                    label: (_role == 'teacher' ? 'nav_dashboard' : 'nav_classes').tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded),
                    activeIcon: const Icon(Icons.person_rounded),
                    label: 'nav_profile'.tr(),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.userName, required this.onLogout});
  final String userName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isGuest = GuestSession.isGuest;
    final greeting = isGuest
        ? 'guest'.tr()
        : userName.isNotEmpty
            ? userName
            : 'app_name'.tr();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Top bar ──────────────────────────
                _TopBar(onLogout: onLogout)
                    .animate()
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ── Greeting ─────────────────────────
                _GreetingCard(greeting: greeting)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 28),

                // ── Section label ─────────────────────
                Text(
                  'home_section_label'.tr(),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 14),

                // ── 2x2 card grid ─────────────────────
                _CardGrid().animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/buddhimotta-logo.png', width: 52, height: 52),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'app_name'.tr(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        _IconBtn(
          icon: Icons.info_outline_rounded,
          tooltip: 'about_us'.tr(),
          onTap: () => context.push('/about'),
        ),
        const SizedBox(width: 4),
        _IconBtn(
          icon: Icons.logout_rounded,
          tooltip: 'logout'.tr(),
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

// ── Greeting card ─────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home_welcome'.tr(),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  greeting,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'app_subtitle'.tr(),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.psychology_rounded,
            color: Colors.white30,
            size: 64,
          ),
        ],
      ),
    );
  }
}

// ── Card grid ─────────────────────────────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  const _CardGrid();

  static const _cards = [
    (
      titleKey: 'what_is_mi',
      subtitleKey: 'what_is_mi_sub',
      icon: Icons.lightbulb_outline_rounded,
      color: AppColors.dustyGrape,
      route: '/intro',
    ),
    (
      titleKey: 'mi_test',
      subtitleKey: 'mi_test_sub',
      icon: Icons.psychology_rounded,
      color: AppColors.primary,
      route: '/test',
    ),
    (
      titleKey: 'real_life_test_short',
      subtitleKey: 'real_life_test_sub',
      icon: Icons.auto_stories_outlined,
      color: AppColors.dustyGrape,
      route: '/scenarios',
    ),
    (
      titleKey: 'results',
      subtitleKey: 'results_sub',
      icon: Icons.bar_chart_rounded,
      color: AppColors.accent,
      route: '/my-results',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _cards.asMap().entries.map((entry) {
        final i = entry.key;
        final card = entry.value;
        return _HomeCard(
          titleKey: card.titleKey,
          subtitleKey: card.subtitleKey,
          icon: card.icon,
          color: card.color,
          onTap: () => context.push(card.route),
        )
            .animate()
            .scale(
              begin: const Offset(0.88, 0.88),
              duration: 400.ms,
              delay: Duration(milliseconds: 80 * i),
              curve: Curves.easeOut,
            )
            .fadeIn(delay: Duration(milliseconds: 80 * i));
      }).toList(),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAccent = color == AppColors.accent;
    final textColor = isAccent ? AppColors.primaryDark : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const Spacer(),
            Text(
              titleKey.tr(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitleKey.tr(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.70),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
