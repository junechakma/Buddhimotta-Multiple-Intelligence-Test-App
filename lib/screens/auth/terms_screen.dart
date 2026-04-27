import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // subscribe — rebuilds this widget when locale changes
    return Scaffold(
      appBar: AppBar(
        title: Text('terms'.tr()),
        actions: const [Padding(
          padding: EdgeInsets.only(right: 12),
          child: LangToggleButton(),
        )],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _heading('terms_title'.tr()),
          _body('terms_intro'.tr()),
          _section('terms_s1_title'.tr()),
          _body('terms_s1_body'.tr()),
          _bullet('terms_s1_b1'.tr()),
          _body('terms_s1_b1_body'.tr()),
          _bullet('terms_s1_b2'.tr()),
          _body('terms_s1_b2_body'.tr()),
          _section('terms_s2_title'.tr()),
          _body('terms_s2_body'.tr()),
          _bullet('terms_s2_b1'.tr()),
          _bullet('terms_s2_b2'.tr()),
          _bullet('terms_s2_b3'.tr()),
          _bullet('terms_s2_b4'.tr()),
          _bullet('terms_s2_b5'.tr()),
          _section('terms_s3_title'.tr()),
          _body('terms_s3_body'.tr()),
          _section('terms_s4_title'.tr()),
          _body('terms_s4_body'.tr()),
          _section('terms_s5_title'.tr()),
          _body('terms_s5_body'.tr()),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'terms_thanks'.tr(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
}
