import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the app's optional accessibility fallbacks.
class AccessibilitySettingsController extends ChangeNotifier {
  static const colorSafePaletteKey = 'accessibility_color_safe_palette_v1';
  static const highContrastFallbackKey =
      'accessibility_high_contrast_fallback_v1';

  final SharedPreferences _preferences;
  bool _colorSafePalette;
  bool _highContrastFallback;

  AccessibilitySettingsController(SharedPreferences preferences)
    : _preferences = preferences,
      _colorSafePalette = preferences.getBool(colorSafePaletteKey) ?? false,
      _highContrastFallback =
          preferences.getBool(highContrastFallbackKey) ?? false;

  static Future<AccessibilitySettingsController> load() async {
    return AccessibilitySettingsController(
      await SharedPreferences.getInstance(),
    );
  }

  bool get colorSafePalette => _colorSafePalette;

  bool get highContrastFallback => _highContrastFallback;

  bool effectiveHighContrast(MediaQueryData mediaQuery) {
    return _highContrastFallback || mediaQuery.highContrast;
  }

  Future<void> setColorSafePalette(bool enabled) async {
    if (_colorSafePalette == enabled) return;

    _colorSafePalette = enabled;
    notifyListeners();
    await _preferences.setBool(colorSafePaletteKey, enabled);
  }

  Future<void> setHighContrastFallback(bool enabled) async {
    if (_highContrastFallback == enabled) return;

    _highContrastFallback = enabled;
    notifyListeners();
    await _preferences.setBool(highContrastFallbackKey, enabled);
  }

  Future<void> reset() async {
    final changed = _colorSafePalette || _highContrastFallback;
    _colorSafePalette = false;
    _highContrastFallback = false;

    if (changed) notifyListeners();

    await Future.wait([
      _preferences.remove(colorSafePaletteKey),
      _preferences.remove(highContrastFallbackKey),
    ]);
  }
}

class AccessibilitySettingsScope
    extends InheritedNotifier<AccessibilitySettingsController> {
  const AccessibilitySettingsScope({
    super.key,
    required AccessibilitySettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AccessibilitySettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AccessibilitySettingsScope>();
    assert(
      scope != null,
      'AccessibilitySettingsScope is missing above this widget.',
    );
    return scope!.notifier!;
  }
}
