import 'package:belonging_maps_app/models/forum_post.dart';
import 'package:belonging_maps_app/screens/forums_screen.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens Forums from the hamburger menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: HamburgerMenu(body: const SizedBox.expand()),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forums'));
    await tester.pumpAndSettle();

    expect(
      find.text('Where can I find affordable textbooks this semester?'),
      findsOneWidget,
    );
  });

  testWidgets('shows sample posts and supports scrolling on iPhone size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: ForumsScreen()));

    expect(
      find.text('Where can I find affordable textbooks this semester?'),
      findsOneWidget,
    );
    expect(find.text('Tips for getting around Sacramento by bus'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Tips for getting around Sacramento by bus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders injected posts by posted date, newest first', (
    tester,
  ) async {
    final olderPost = ForumPost(
      title: 'Older post',
      author: 'Alex',
      postedAt: DateTime(2026, 1, 1, 9),
      bodyPreview: 'An older conversation.',
    );
    final newerPost = ForumPost(
      title: 'Newer post',
      author: 'Sam',
      postedAt: DateTime(2026, 2, 1, 9),
      bodyPreview: 'A newer conversation.',
    );

    await tester.pumpWidget(
      MaterialApp(home: ForumsScreen(posts: [olderPost, newerPost])),
    );

    expect(
      tester.getTopLeft(find.text('Newer post')).dy,
      lessThan(tester.getTopLeft(find.text('Older post')).dy),
    );
  });

  testWidgets('truncates long post text without overflowing on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const longTitle =
        'A very long forum title that needs to be shortened to fit the screen';
    const longPreview =
        'A very long body preview that contains enough words to overflow its available lines. '
        'It should be cut off cleanly with an ellipsis rather than making this post card grow without limit.';
    final post = ForumPost(
      title: longTitle,
      author: 'A community member with a long display name',
      postedAt: DateTime(2026, 4, 1, 14, 30),
      bodyPreview: longPreview,
    );

    await tester.pumpWidget(MaterialApp(home: ForumsScreen(posts: [post])));

    final titleWidget = tester.widget<Text>(find.text(longTitle));
    final previewWidget = tester.widget<Text>(find.text(longPreview));
    expect(titleWidget.maxLines, 2);
    expect(titleWidget.overflow, TextOverflow.ellipsis);
    expect(previewWidget.maxLines, 3);
    expect(previewWidget.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an empty state when there are no posts', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ForumsScreen(posts: const [])));

    expect(find.text('No posts yet'), findsOneWidget);
  });
}