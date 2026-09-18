import 'package:flutter/painting.dart';

/// Light theme color tokens (docs/02 §10.2). Widgets read colors from `Theme.of(context)`, not here.
abstract final class AppColors {
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF1F5);
  static const border = Color(0xFFD5DAE1);
  static const borderStrong = Color(0xFF8A939E);
  static const textPrimary = Color(0xFF1B1F24);
  static const textSecondary = Color(0xFF505A66);
  static const primary = Color(0xFF2F5BD3);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFE3EAFB);
  static const onPrimaryContainer = Color(0xFF1C3C94);
  static const danger = Color(0xFFB42318);
  static const dangerContainer = Color(0xFFFDECEA);
}
