import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/forum_post_service.dart';
import '../widgets/hamburger_menu.dart';

class ForumsScreen extends StatelessWidget {
  ForumsScreen({super.key, List<ForumPost>? posts})
    : posts = posts ?? ForumPostService.samplePosts();

  final List<ForumPost> posts;

  @override
  Widget build(BuildContext context) {
    final newestFirst = List<ForumPost>.of(posts)
      ..sort((first, second) => second.postedAt.compareTo(first.postedAt));

    return HamburgerMenu(
      title: 'Forums',
      body: newestFirst.isEmpty
          ? const _EmptyForumsState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: newestFirst.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ForumPostTile(
                post: newestFirst[index],
              ),
            ),
    );
  }
}

class _ForumPostTile extends StatelessWidget {
  const _ForumPostTile({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final postedAt = post.postedAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final postedDate = localizations.formatMediumDate(postedAt);
    final postedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(postedAt),
    );

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'by ${post.author}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$postedDate, $postedTime',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.bodyPreview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.mode_comment_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.replyCount} ${post.replyCount == 1 ? 'reply' : 'replies'}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyForumsState extends StatelessWidget {
  const _EmptyForumsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No posts yet'),
      ),
    );
  }
}