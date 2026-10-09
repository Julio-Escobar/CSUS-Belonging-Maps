import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/auth_service.dart';
import '../services/forum_post_service.dart';
import '../widgets/hamburger_menu.dart';

class ForumsScreen extends StatefulWidget {
  ForumsScreen({super.key, List<ForumPost>? posts}) : posts = posts;

  final List<ForumPost>? posts;

  @override
  State<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends State<ForumsScreen> {
  late final List<ForumPost> _posts;

  @override
  void initState() {
    super.initState();
    _posts = List<ForumPost>.of(widget.posts ?? ForumPostService.samplePosts());
  }

  Future<void> _deletePost(ForumPost post) async {
    if (!AuthService.isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _posts.removeWhere((candidate) => identical(candidate, post));
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final newestFirst = List<ForumPost>.of(_posts)
      ..sort((first, second) => second.postedAt.compareTo(first.postedAt));
    final isAdmin = AuthService.isAdmin;

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
                showDelete: isAdmin,
                onDelete: () => _deletePost(newestFirst[index]),
              ),
            ),
    );
  }
}

class _ForumPostTile extends StatelessWidget {
  const _ForumPostTile({
    required this.post,
    required this.showDelete,
    required this.onDelete,
  });

  final ForumPost post;
  final bool showDelete;
  final VoidCallback onDelete;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (showDelete) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Delete post',
                    onPressed: onDelete,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.delete_outline, color: colors.error),
                  ),
                ],
              ],
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
      child: Padding(padding: EdgeInsets.all(24), child: Text('No posts yet')),
    );
  }
}
