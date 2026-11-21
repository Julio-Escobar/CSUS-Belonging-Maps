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

  /// Whether this palette comes from the color-safe option.
  ///
  /// Colors cannot identify the option reliably: the color-safe primary is a
  /// different value in light, dark, and high-contrast themes.
  final bool colorSafePalette;

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
    required this.colorSafePalette,
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
    colorSafePalette: false,
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
    colorSafePalette: true,
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
    colorSafePalette: false,
  );

  // Dark palettes (P1-281) used when the device is in dark mode. App bars and
  // buttons keep the light-mode brand green so the dark screens stay muted.
  static const normalDark = AccessibilityColors(
    pageBackground: Color(0xFF121412),
    cardBackground: Color(0xFF1E211F),
    primary: Color(0xFF2F5F3E),
    onPrimary: Colors.white,
    primaryText: Color(0xFFECECEC),
    secondaryText: Color(0xFFBDBDBD),
    action: Color(0xFF7DD3FC),
    destructive: Color(0xFFCC4757),
    menuIcon: Colors.white,
    outline: Color(0xFF8FD3A6),
    colorSafePalette: false,
  );

  static const colorSafeDark = AccessibilityColors(
    pageBackground: Color(0xFF0F1417),
    cardBackground: Color(0xFF1B2328),
    primary: Color(0xFF2B8099),
    onPrimary: Colors.white,
    primaryText: Color(0xFFEDF2F7),
    secondaryText: Color(0xFFC0C8D0),
    action: Color(0xFF7FD4E8),
    destructive: Color(0xFFCC4757),
    menuIcon: Colors.white,
    outline: Color(0xFF7FD4E8),
    colorSafePalette: true,
  );

  static AccessibilityColors forSettings({
    required bool colorSafePalette,
    required bool highContrast,
    bool dark = false,
  }) {
    if (dark) {
      if (highContrast) return highContrastDarkColors(colorSafePalette);
      return colorSafePalette ? colorSafeDark : normalDark;
    }
    if (highContrast) return highContrastColors(colorSafePalette);
    return colorSafePalette ? colorSafe : normal;
  }

  static AccessibilityColors highContrastDarkColors(bool colorSafePalette) {
    // High contrast trades the muted bars for bright fills with dark text.
    final base = colorSafePalette ? colorSafeDark : normalDark;
    return base.copyWith(
      primary: colorSafePalette
          ? const Color(0xFF7FD4E8)
          : const Color(0xFF8FD3A6),
      onPrimary: Colors.black,
      menuIcon: Colors.black,
      pageBackground: Colors.black,
      cardBackground: Colors.black,
      primaryText: Colors.white,
      secondaryText: Colors.white,
      outline: Colors.white,
    );
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
    bool? colorSafePalette,
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
      colorSafePalette: colorSafePalette ?? this.colorSafePalette,
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
      colorSafePalette: t < 0.5 ? colorSafePalette : other.colorSafePalette,
    );
  }
}

class AppTheme {
  static ThemeData light({
    required bool colorSafePalette,
    required bool highContrast,
  }) => _build(
    colorSafePalette: colorSafePalette,
    highContrast: highContrast,
    dark: false,
  );

  static ThemeData dark({
    required bool colorSafePalette,
    required bool highContrast,
  }) => _build(
    colorSafePalette: colorSafePalette,
    highContrast: highContrast,
    dark: true,
  );

  static ThemeData _build({
    required bool colorSafePalette,
    required bool highContrast,
    required bool dark,
  }) {
    final colors = AccessibilityColors.forSettings(
      colorSafePalette: colorSafePalette,
      highContrast: highContrast,
      dark: dark,
    );
    final colorScheme = dark
        ? ColorScheme.dark(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            surface: colors.cardBackground,
            onSurface: colors.primaryText,
            error: colors.destructive,
            onError: Colors.white,
            outline: colors.outline,
          )
        : ColorScheme.light(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            surface: colors.cardBackground,
            onSurface: colors.primaryText,
            error: colors.destructive,
            onError: Colors.white,
            outline: colors.outline,
          );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(color: colors.outline, width: 1.5)
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast
              ? BorderSide(color: colors.outline, width: 1.5)
              : BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.primaryText,
        contentTextStyle: TextStyle(color: colors.cardBackground),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.action),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colors.action,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: colors.secondaryText),
        floatingLabelStyle: TextStyle(color: colors.primary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      extensions: [colors],
    );
  }
}
