import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shares accurate location details through an accessible action', (
    tester,
  ) async {
    String? sharedText;
    const data = LocationInfoData(
      cardTitle: 'PRIDE Center',
      address: '6000 J Street, Sacramento, CA',
      category: 'Community Resource',
      type: 'Support',
      website: 'https://www.csus.edu/pride-center',
      phone: '',
      email: '',
      description: 'A welcoming space for students.',
      imageUrl: null,
      socialLinks: {},
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
            onShare: (text) async => sharedText = text,
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Share PRIDE Center'));
    await tester.pump();

    expect(
      sharedText,
      'PRIDE Center\n6000 J Street, Sacramento, CA\nhttps://www.csus.edu/pride-center',
    );
  });
}
