import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

bool _matches(Pattern pattern, String value) {
  return pattern is RegExp ? pattern.hasMatch(value) : pattern == value;
}

SemanticsFinder semanticTapByLabel(Pattern label) {
  return find.semantics.byPredicate(
    (node) {
      final data = node.getSemanticsData();
      return _matches(label, data.label) && data.hasAction(SemanticsAction.tap);
    },
    describeMatch: (plurality) =>
        '$plurality semantic tap action with label "$label"',
  );
}

SemanticsFinder semanticTapByTooltip(Pattern tooltip) {
  return find.semantics.byPredicate(
    (node) {
      final data = node.getSemanticsData();
      return _matches(tooltip, data.tooltip) &&
          data.hasAction(SemanticsAction.tap);
    },
    describeMatch: (plurality) =>
        '$plurality semantic tap action with tooltip "$tooltip"',
  );
}
