import 'package:belonging_maps_app/models/location_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the official lactation room building name field', () {
    expect(
      locationTitleFromAttributes({'RefName': 'Tahoe Hall'}),
      'Tahoe Hall',
    );
  });
}
