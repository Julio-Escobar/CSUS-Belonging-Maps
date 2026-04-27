import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationInfoData.fromAttributes', () {
    test('maps sprint 4 popup fields from community map attributes', () {
      final data = LocationInfoData.fromAttributes({
        'Company_Name': 'PRIDE Center',
        'WEBSITE': 'https://www.csus.edu/pride-center',
        'PHONE': '916-278-1234',
        'EMAIL': 'pride-center@csus.edu',
      });

      expect(data.cardTitle, 'PRIDE Center');
      expect(data.website, 'https://www.csus.edu/pride-center');
      expect(data.phone, '916-278-1234');
      expect(data.email, 'pride-center@csus.edu');
    });

    test('falls back to URL when WEBSITE is unavailable', () {
      final data = LocationInfoData.fromAttributes({
        'Name': 'Food Pantry',
        'WEBSITE': 'n/a',
        'URL': 'https://www.csus.edu/food-pantry',
      });

      expect(data.cardTitle, 'Food Pantry');
      expect(data.website, 'https://www.csus.edu/food-pantry');
    });
  });

  group('LocationInfoCard', () {
    testWidgets(
      'shows location name, website, and contact info in expanded popup',
      (tester) async {
        final data = LocationInfoData(
          cardTitle: 'PRIDE Center',
          address: '6000 J Street, Sacramento, CA',
          category: 'Community Resource',
          type: 'Support',
          website: 'https://www.csus.edu/pride-center',
          phone: '916-278-1234',
          email: 'pride-center@csus.edu',
          description: 'A welcoming space for students.',
          imageUrl: null,
          socialLinks: const {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationInfoCard(
                data: data,
                showFullInfo: true,
                onClose: () {},
                onShowMore: () {},
                onShowLess: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PRIDE Center'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Website: Click Here'),
          ),
          findsOneWidget,
        );
        expect(find.text('Phone: 916-278-1234'), findsOneWidget);
        expect(find.text('Email: pride-center@csus.edu'), findsOneWidget);
      },
    );
  });
}
