import 'package:belonging_maps_app/models/location_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the official lactation room building name field', () {
    expect(
      locationTitleFromAttributes({'RefName': 'Tahoe Hall'}),
      'Tahoe Hall',
    );
  });

  test('uses the uppercase NAME key of the bundled campus datasets', () {
    expect(
      locationTitleFromAttributes({'NAME': 'Martin Luther King Jr. Center'}),
      'Martin Luther King Jr. Center',
    );
  });

  test('keeps the existing name fields ahead of uppercase NAME', () {
    expect(
      locationTitleFromAttributes({
        'Name': 'Public Art Name',
        'NAME': 'Bundled Campus Name',
      }),
      'Public Art Name',
    );
  });

  test('falls back when no supported name field is usable', () {
    expect(locationTitleFromAttributes({'NAME': 'N/A'}), 'Unnamed location');
    expect(locationTitleFromAttributes(null), 'Unnamed location');
  });
}
