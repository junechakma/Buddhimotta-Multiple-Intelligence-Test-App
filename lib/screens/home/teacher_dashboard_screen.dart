import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('nav_dashboard'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          'nav_dashboard'.tr(),
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
