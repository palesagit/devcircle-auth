import 'package:flutter/material.dart';

class AppColors {
  static const rail = Color(0xFF0E0D1B); // far-left server strip
  static const sidebar = Color(0xFF1A1830); // main sidebar background
  static const chatBg = Color(0xFF141327); // chat area (wide screens)
  static const selected = Color(0xFF2B2848); // highlighted row
  static const accent = Color(0xFFB69CFF); // selected server tile / buttons
  static const onAccent = Color(0xFF1B1038); // dark text on accent / pink
  static const brand = Color(0xFF8E5FC1); // original DevCircle purple
  static const pink = Color(0xFFF5A8CB); // unread badge + avatar
  static const text = Color(0xFFF2F0FA);
  static const muted = Color(0xFFA19EBD);
  static const divider = Color(0xFF2A2842);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: AppColors.sidebar,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.sidebar,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sidebar,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}


String initialsOf(String name) {
  final parts = name
      .split(RegExp(r'[_\s.\-]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
