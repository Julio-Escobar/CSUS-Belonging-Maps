import 'package:belonging_maps_app/models/forum_post.dart';
import 'package:belonging_maps_app/screens/forums_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AuthService.isAdmin = false);

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
    expect(
      find.text('Tips for getting around Sacramento by bus'),
      findsNothing,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(
      find.text('Tips for getting around Sacramento by bus'),
      findsOneWidget,
    );
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
    AuthService.isAdmin = true;
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
    final deleteButton = find.ancestor(
      of: find.byTooltip('Delete post'),
      matching: find.byType(IconButton),
    );
    expect(tester.getSize(deleteButton).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(deleteButton).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an empty state when there are no posts', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ForumsScreen(posts: const [])));

    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('only admins see the delete control', (tester) async {
    AuthService.isAdmin = false;
    await tester.pumpWidget(MaterialApp(home: ForumsScreen()));
    expect(find.byTooltip('Delete post'), findsNothing);

    AuthService.isAdmin = true;
    await tester.pumpWidget(MaterialApp(home: ForumsScreen()));
    expect(find.byTooltip('Delete post'), findsAtLeastNWidgets(1));
  });

  testWidgets('canceling or dismissing confirmation keeps the post', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    final post = ForumPost(
      title: 'Keep this post',
      author: 'Alex',
      postedAt: DateTime(2026, 1, 1),
      bodyPreview: 'This post should remain.',
    );
    await tester.pumpWidget(MaterialApp(home: ForumsScreen(posts: [post])));

    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    expect(find.text("This can't be undone."), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Keep this post'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Keep this post'), findsOneWidget);
    expect(find.text('Post deleted'), findsNothing);
  });

  testWidgets('confirmed deletion preserves order and shows feedback', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    final posts = [
      ForumPost(
        title: 'Older post',
        author: 'Alex',
        postedAt: DateTime(2026, 1, 1),
        bodyPreview: 'Older.',
      ),
      ForumPost(
        title: 'Middle post',
        author: 'Sam',
        postedAt: DateTime(2026, 2, 1),
        bodyPreview: 'Middle.',
      ),
      ForumPost(
        title: 'Newer post',
        author: 'Taylor',
        postedAt: DateTime(2026, 3, 1),
        bodyPreview: 'Newer.',
      ),
    ];
    await tester.pumpWidget(MaterialApp(home: ForumsScreen(posts: posts)));

    await tester.tap(find.byTooltip('Delete post').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Middle post'), findsNothing);
    expect(find.text('Newer post'), findsOneWidget);
    expect(find.text('Older post'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Newer post')).dy,
      lessThan(tester.getTopLeft(find.text('Older post')).dy),
    );
    expect(find.text('Post deleted'), findsOneWidget);
  });

  testWidgets('deleting the last post shows the empty state', (tester) async {
    AuthService.isAdmin = true;
    final post = ForumPost(
      title: 'Only post',
      author: 'Alex',
      postedAt: DateTime(2026, 1, 1),
      bodyPreview: 'The last post.',
    );
    await tester.pumpWidget(MaterialApp(home: ForumsScreen(posts: [post])));

    await tester.tap(find.byTooltip('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Only post'), findsNothing);
    expect(find.text('No posts yet'), findsOneWidget);
    expect(find.text('Post deleted'), findsOneWidget);
  });
}
