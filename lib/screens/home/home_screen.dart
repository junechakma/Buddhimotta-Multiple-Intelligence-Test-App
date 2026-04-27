import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // subscribe — rebuilds this widget when locale changes
    return Scaffold(
      appBar: AppBar(
        actions: const [Padding(
          padding: EdgeInsets.only(right: 12),
          child: LangToggleButton(),
        )],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Text(
            'home_coming_soon'.tr(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
