import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../router/app_router.dart';
import '../../services/guest_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _snack('err_email_password'.tr());
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'login_failed'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _guestLogin() {
    GuestSession.start();
    AppRouter.refreshAuth();
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('err_enter_email'.tr());
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('password_reset_sent'.tr());
    } catch (_) {
      _snack('err_try_again'.tr());
    }
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
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: const LangToggleButton(),
                ),
                const SizedBox(height: 36),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildCard(),
                const SizedBox(height: 20),
                _buildGuestButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/buddhimotta-logo.png',
          width: 180,
          height: 180,
        )
            .animate()
            .scale(
              begin: const Offset(0.4, 0.4),
              duration: 700.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 8),
        Text(
          'app_subtitle'.tr(),
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 320.ms),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
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
          Text(
            'login'.tr(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'login_subtitle'.tr(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: Text(
                'forgot_password'.tr(),
                style: GoogleFonts.hindSiliguri(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GradientButton(
              label: 'login'.tr(), onTap: _login, loading: _loading),
          const SizedBox(height: 22),
          Center(
            child: GestureDetector(
              onTap: () => context.push('/signup'),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.hindSiliguri(fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'no_account'.tr(),
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'register_link'.tr(),
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
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _guestLogin,
        icon: const Icon(Icons.person_outline_rounded, size: 20),
        label: Text(
          'guest_login'.tr(),
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 400.ms);
  }
}
