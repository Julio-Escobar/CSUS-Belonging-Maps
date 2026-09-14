import 'package:flutter/material.dart';

@immutable
class AccessibilityColors extends ThemeExtension<AccessibilityColors> {
  final Color pageBackground;
  final Color cardBackground;
  final Color primary;
  final Color onPrimary;
  final Color primaryText;
  final Color secondaryText;
  final Color action;
  final Color destructive;
  final Color menuIcon;
  final Color outline;

  const AccessibilityColors({
    required this.pageBackground,
    required this.cardBackground,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.secondaryText,
    required this.action,
    required this.destructive,
    required this.menuIcon,
    required this.outline,
  });

  static const normal = AccessibilityColors(
    pageBackground: Color(0xFFF9F5FA),
    cardBackground: Colors.white,
    primary: Color(0xFF2F5F3E),
    onPrimary: Colors.white,
    primaryText: Color(0xFF171717),
    secondaryText: Color(0xFF4A4A4A),
    action: Color(0xFF075985),
    destructive: Color(0xFF8B1E2D),
    menuIcon: Colors.white,
    outline: Color(0xFF2F5F3E),
  );

  static const colorSafe = AccessibilityColors(
    pageBackground: Color(0xFFF3F8FA),
    cardBackground: Colors.white,
    primary: Color(0xFF005A70),
    onPrimary: Colors.white,
    primaryText: Color(0xFF111827),
    secondaryText: Color(0xFF374151),
    action: Color(0xFF005A70),
    destructive: Color(0xFF8B1E2D),
    menuIcon: Colors.white,
    outline: Color(0xFF003B4A),
  );

  static const highContrast = AccessibilityColors(
    pageBackground: Colors.white,
    cardBackground: Colors.white,
    primary: Color(0xFF003B24),
    onPrimary: Colors.white,
    primaryText: Colors.black,
    secondaryText: Color(0xFF202020),
    action: Color(0xFF003B5C),
    destructive: Color(0xFF7A0012),
    menuIcon: Colors.white,
    outline: Colors.black,
  );

  static AccessibilityColors forSettings({
    required bool colorSafePalette,
    required bool highContrast,
  }) {
    if (highContrast) return highContrastColors(colorSafePalette);
    return colorSafePalette ? colorSafe : normal;
  }

  static AccessibilityColors highContrastColors(bool colorSafePalette) {
    final base = colorSafePalette ? colorSafe : highContrast;
    return base.copyWith(
      pageBackground: Colors.white,
      cardBackground: Colors.white,
      primaryText: Colors.black,
      secondaryText: Colors.black,
      outline: Colors.black,
    );
  }

  static AccessibilityColors of(BuildContext context) {
    return Theme.of(context).extension<AccessibilityColors>() ?? normal;
  }

  @override
  AccessibilityColors copyWith({
    Color? pageBackground,
    Color? cardBackground,
    Color? primary,
    Color? onPrimary,
    Color? primaryText,
    Color? secondaryText,
    Color? action,
    Color? destructive,
    Color? menuIcon,
    Color? outline,
  }) {
    return AccessibilityColors(
      pageBackground: pageBackground ?? this.pageBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      action: action ?? this.action,
      destructive: destructive ?? this.destructive,
      menuIcon: menuIcon ?? this.menuIcon,
      outline: outline ?? this.outline,
    );
  }

  @override
  AccessibilityColors lerp(covariant AccessibilityColors? other, double t) {
    if (other == null) return this;

    return AccessibilityColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      action: Color.lerp(action, other.action, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      menuIcon: Color.lerp(menuIcon, other.menuIcon, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light({
    required bool colorSafePalette,
    required bool highContrast,
  }) {
    final colors = AccessibilityColors.forSettings(
      colorSafePalette: colorSafePalette,
      highContrast: highContrast,
    );

    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        surface: colors.cardBackground,
        onSurface: colors.primaryText,
        error: colors.destructive,
        onError: Colors.white,
        outline: colors.outline,
      ),
      scaffoldBackgroundColor: colors.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: highContrast
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outline, width: 1.5),
              )
            : null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: colors.secondaryText),
        floatingLabelStyle: TextStyle(color: colors.primary),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      extensions: [colors],
    );
  }
}
