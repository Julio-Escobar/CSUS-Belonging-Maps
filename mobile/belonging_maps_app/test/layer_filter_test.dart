import 'package:belonging_maps_app/services/layer_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildTypeClause', () {
    const types = ['Bakery', 'Salon', 'Supermarket'];

    test('returns an empty clause when no types are known', () {
      expect(buildTypeClause(const [], const {}), '');
    });

    test('returns an empty clause when every type is selected', () {
      expect(buildTypeClause(types, {...types}), '');
    });

    test('narrows to the selected types', () {
      expect(
        buildTypeClause(types, {'Salon', 'Bakery'}),
        "Type IN ('Salon', 'Bakery')",
      );
    });

    test('matches nothing when every type is deselected', () {
      expect(buildTypeClause(types, const {}), '1=0');
    });

    test('honours a custom type field name', () {
      expect(
        buildTypeClause(types, {'Salon'}, typeField: 'CATEGORY'),
        "CATEGORY IN ('Salon')",
      );
    });

    test('escapes single quotes in type values', () {
      expect(
        buildTypeClause(const ["O'Brien's"], const {"O'Brien's"}),
        '',
      );
      expect(
        buildTypeClause(const ['A', "O'Brien's"], const {"O'Brien's"}),
        "Type IN ('O''Brien''s')",
      );
    });
  });
}
