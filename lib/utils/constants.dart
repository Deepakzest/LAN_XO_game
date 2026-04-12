import 'package:flutter/material.dart';

class AppConstants {
  static const int serverPort = 4040;

  static const String movePrefix = 'MOVE:';
  static const String reset = 'RESET';
  static const String disconnect = 'DISCONNECT';
}

class AppColors {
  static const Color background = Color(0xFF0D0D0D);
  static const Color panel = Color(0xFF161616);
  static const Color border = Color(0xFF2A2A2A);
  static const Color neonBlue = Color(0xFF00D9FF);
  static const Color neonPurple = Color(0xFF8A2EFF);
  static const Color neonPink = Color(0xFFFF4FD8);
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFFA4A4A4);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [
      AppColors.neonBlue,
      AppColors.neonPurple,
      AppColors.neonPink,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtle = LinearGradient(
    colors: [
      Color(0x332C2C2C),
      Color(0x2200D9FF),
      Color(0x228A2EFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
