import 'package:flutter/material.dart';

/// Modern dark theme colors for the meeting screen
class MeetingTheme {
  // Background colors
  static const Color backgroundColor = Color(0xFF1A2332);
  static const Color surfaceColor = Color(0xFF243447);
  static const Color cardColor = Color(0xFF2D3E50);

  // Control bar colors
  static const Color controlBarColor = Color(0xFF1E2D3D);
  static const Color controlButtonColor = Color(0xFF3A4A5C);
  static const Color controlButtonActiveColor = Color(0xFF4A90D9);

  // Action colors
  static const Color leaveButtonColor = Color(0xFFE74C3C);
  static const Color joinButtonColor = Color(0xFF27AE60);
  static const Color mutedColor = Color(0xFFE74C3C);

  // Text colors
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFF8B9AAD);
  static const Color nameTagColor = Color(0xCC1A2332);

  // Border and accent colors
  static const Color activeSpeakerBorder = Color(0xFFFFD700);
  static const Color defaultBorder = Color(0xFF3A4A5C);

  // Gradients
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2332), Color(0xFF0F1821)],
  );
}
