import 'package:belonging_maps_app/screens/gender_neutral_bathrooms_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gender neutral bathroom browse entries', () {
    test('uses the building name as the list title', () {
      expect(
        genderNeutralBathroomListingName({
          'BuildingName': 'University Union',
          'Floor': '2',
          'LocationDetails': 'One across from Starbucks',
        }),
        'University Union',
      );
    });

    test('falls back when the layer has no building name', () {
      expect(
        genderNeutralBathroomListingName({'BuildingName': ' N/A '}),
        'Gender Neutral Bathroom',
      );
      expect(
        genderNeutralBathroomListingName({'BuildingName': null}),
        'Gender Neutral Bathroom',
      );
      expect(genderNeutralBathroomListingName({}), 'Gender Neutral Bathroom');
    });

    test('combines the floor and location details in the subtitle', () {
      expect(
        genderNeutralBathroomListingCategory({
          'BuildingName': 'Sacramento Hall',
          'Floor': '1',
          'LocationDetails': 'Two past front desk, across from room 218',
        }),
        'Floor 1 • Two past front desk, across from room 218',
      );
    });

    test('shows the details alone when the layer records no floor', () {
      expect(
        genderNeutralBathroomListingCategory({
          'BuildingName': 'Riverview Hall',
          'Floor': null,
          'LocationDetails': 'Thirteen in Building, Restricted to Residents',
        }),
        'Thirteen in Building, Restricted to Residents',
      );
    });

    test('falls back when the floor and details are placeholders', () {
      expect(
        genderNeutralBathroomListingCategory({
          'BuildingName': 'Sutter Hall',
          'Floor': 'n/a',
          'LocationDetails': ' ',
        }),
        'Gender neutral bathroom',
      );
      expect(
        genderNeutralBathroomListingCategory({}),
        'Gender neutral bathroom',
      );
    });
  });
}
