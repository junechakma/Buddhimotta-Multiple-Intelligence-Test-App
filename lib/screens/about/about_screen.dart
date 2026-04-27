import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _members = [
    _Member(
      name: 'Swapnil Tarafdar',
      role: 'Innovation Leader',
      roleBn: 'ইনোভেশন লিডার',
      description:
          'Drives innovation within the development team and projects. Facilitated the integration of different aspects of the project deployment phases.',
      image: 'assets/swapnil.jpg',
      email: '1902042@icte.bdu.ac.bd',
      dept: 'Educational Technology and Engineering',
      university: 'Bangladesh Digital University',
      icon: Icons.lightbulb_rounded,
      color: AppColors.accent,
    ),
    _Member(
      name: 'June Chakma',
      role: 'Developer',
      roleBn: 'ডেভেলপার',
      description:
          'Developed the entire app\'s coding infrastructure and logic. Conducted thorough testing to ensure the app\'s functionality and bug-free operation. Implemented the MI theory algorithms and calculations.',
      image: 'assets/june.jpg',
      email: '1902050@icte.bdu.ac.bd',
      dept: 'Educational Technology and Engineering',
      university: 'Bangladesh Digital University',
      icon: Icons.code_rounded,
      color: AppColors.primary,
    ),
    _Member(
      name: 'Sumona Afroz',
      role: 'Navigational Designer',
      roleBn: 'নেভিগেশনাল ডিজাইনার',
      description:
          'Researched and gathered relevant content related to MI theory and intelligence testing. Developed the questions and answer sets for the intelligence assessment. Collaborated with the developer to integrate content and structures seamlessly into the app.',
      image: 'assets/chadnee.jpg',
      email: '1902025@icte.bdu.ac.bd',
      dept: 'Educational Technology and Engineering',
      university: 'Bangladesh Digital University',
      icon: Icons.design_services_rounded,
      color: AppColors.dustyGrape,
    ),
    _Member(
      name: 'Md Ashrafuzzaman',
      role: 'Advisor',
      roleBn: 'উপদেষ্টা',
      description:
          'Provided unwavering guidance and direction throughout the app\'s development journey. Fostered effective communication and collaboration among team members. Painstakingly reviewed and corrected errors, ensuring the app\'s overall quality and accuracy.',
      image: 'assets/asraf.jpg',
      email: null,
      dept: 'Assistant Professor & Chairman\nDepartment of Educational Technology',
      university: 'Bangladesh Digital University',
      icon: Icons.school_rounded,
      color: AppColors.amethystSmoke,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    context.locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset('assets/buddhimotta-logo.png',
                        width: 56, height: 56),
                    const SizedBox(height: 8),
                    Text(
                      'Team TriMatrix',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Bangladesh Digital University',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: Colors.white70,
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
              delegate: SliverChildListDelegate([
                Text(
                  'about_us'.tr(),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ..._members.asMap().entries.map(
                      (e) => _MemberCard(member: e.value)
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 80 * e.key),
                              duration: 400.ms)
                          .slideY(
                              begin: 0.15,
                              end: 0,
                              delay: Duration(milliseconds: 80 * e.key)),
                    ),
                const SizedBox(height: 8),
                _FooterCard(onTermsTap: () => context.push('/terms'))
                    .animate()
                    .fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final _Member member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: member.color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Coloured header strip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: member.color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: member.color, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: member.color.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          member.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: member.color.withValues(alpha: 0.2),
                            child: Icon(member.icon,
                                color: member.color, size: 48),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: member.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child:
                          Icon(member.icon, color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  member.name,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: member.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.role,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.description,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 14),
                _InfoRow(
                    icon: Icons.school_outlined,
                    text: member.dept,
                    color: member.color),
                const SizedBox(height: 6),
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: member.university,
                    color: member.color),
                if (member.email != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.email_outlined,
                      text: member.email!,
                      color: member.color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer card ───────────────────────────────────────────────────────────────

class _FooterCard extends StatelessWidget {
  const _FooterCard({required this.onTermsTap});
  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'TriMatrix',
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bangladesh Digital University',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          _FooterBtn(
            icon: Icons.gavel_rounded,
            label: 'terms'.tr(),
            onTap: onTermsTap,
          ),
          const SizedBox(height: 8),
          _FooterBtn(
            icon: Icons.email_outlined,
            label: 'trimatrix01@gmail.com',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  const _FooterBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _Member {
  final String name;
  final String role;
  final String roleBn;
  final String description;
  final String image;
  final String? email;
  final String dept;
  final String university;
  final IconData icon;
  final Color color;

  const _Member({
    required this.name,
    required this.role,
    required this.roleBn,
    required this.description,
    required this.image,
    required this.email,
    required this.dept,
    required this.university,
    required this.icon,
    required this.color,
  });
}
