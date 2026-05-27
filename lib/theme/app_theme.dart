// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for every colour, spacing, and text style.
/// Mirrors the React version's cinematic dark palette.
abstract class AppTheme {
  AppTheme._();

  // ── Core colours ──────────────────────────────────────────────────────────

  static const Color background = Color(0xFF08080D);
  static const Color surface = Color(0xFF10101A);
  static const Color card = Color(0xFF14141F);
  static const Color cardHover = Color(0xFF1A1A2A);

  static const Color accent = Color(0xFF6366F1);
  static const Color accentLight = Color(0xFF818CF8);
  static const Color accentDeep = Color(0xFF5B5EF4);

  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Semi-transparent borders
  static Color get border => Colors.white.withValues(alpha: 0.065);
  static Color get borderFocused => accent.withValues(alpha: 0.42);

  // Glow fills (very transparent)
  static Color get accentGlow => accent.withValues(alpha: 0.1);
  static Color get dangerGlow => danger.withValues(alpha: 0.1);
  static Color get warningGlow => warning.withValues(alpha: 0.08);
  static Color get successGlow => success.withValues(alpha: 0.1);

  // ── Text styles ───────────────────────────────────────────────────────────

  static TextStyle get taskText => GoogleFonts.dmSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: textSecondary,
      );

  static TextStyle get badge => GoogleFonts.dmSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  // ── Material ThemeData ────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentLight,
          surface: card,
          error: danger,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        // Material 3 Date Picker
        datePickerTheme: DatePickerThemeData(
          backgroundColor: card,
          headerBackgroundColor: accent,
          headerForegroundColor: Colors.white,
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return textPrimary;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return Colors.transparent;
          }),
          todayForegroundColor: WidgetStateProperty.all(accentLight),
          todayBackgroundColor: WidgetStateProperty.all(accentGlow),
          todayBorder: const BorderSide(color: accent),
          yearForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return textPrimary;
          }),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        // Material 3 Time Picker
        timePickerTheme: TimePickerThemeData(
          backgroundColor: card,
          dialHandColor: accent,
          dialBackgroundColor: surface,
          hourMinuteColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentGlow;
            return surface;
          }),
          hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentLight;
            return textPrimary;
          }),
          dayPeriodColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentGlow;
            return surface;
          }),
          dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentLight;
            return textSecondary;
          }),
          entryModeIconColor: textSecondary,
          helpTextStyle: GoogleFonts.dmSans(
            color: textSecondary,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

  // Convenience: themed builder for Date / Time pickers
  static Widget Function(BuildContext, Widget?) get pickerThemeBuilder =>
      (context, child) => Theme(data: darkTheme, child: child!);
}
