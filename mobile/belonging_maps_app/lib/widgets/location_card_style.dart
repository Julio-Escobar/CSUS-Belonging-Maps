import 'package:flutter/material.dart';

/// One type scale for every location card on the maps (P1-337), so the
/// campus maps, community maps and bathroom map all read the same way.
///
/// Every card uses the same font (the platform font), the same sizes, and
/// the same weights for the same kind of text. Pass the card's text color.
class LocationCardText {
  LocationCardText._();

  /// Inner padding shared by every card section.
  static const double padding = 18;

  /// Place or building name at the top of the card.
  static TextStyle title(Color color) => TextStyle(
    color: color,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Small line under the title, e.g. the category or type. Full-strength
  /// color for contrast; it differs from the title by size and weight.
  static TextStyle subtitle(Color color) => TextStyle(
    color: color,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Short facts: address, floor, "Category: Food".
  static TextStyle detail(Color color) => TextStyle(
    color: color,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Longer descriptions.
  static TextStyle body(Color color) => TextStyle(
    color: color,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Small headings inside a card, e.g. "Follow Us".
  static TextStyle sectionHeader(Color color) => TextStyle(
    color: color,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Tappable text: website, phone, email, "More information", "Show less".
  static TextStyle link(Color color) => TextStyle(
    color: color,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationColor: color,
  );

  /// Left-aligned text button with a 48px tap target, so links line up with
  /// the card's other text instead of being indented by button padding.
  static ButtonStyle linkButtonStyle() => TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(0, 48),
    alignment: Alignment.centerLeft,
  );
}
