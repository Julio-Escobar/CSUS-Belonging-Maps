import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../services/forum_post_service.dart';
import '../widgets/hamburger_menu.dart';

String _formatPostedAt(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(local);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local));
  return '$date, $time';
}

class ForumsScreen extends StatefulWidget {
  ForumsScreen({super.key, List<ForumPost>? posts}) : posts = posts;

  final List<ForumPost>? posts;

  @override
  State<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends State<ForumsScreen> {
  late final List<ForumPost> _posts;

  final Map<ForumPost, List<_ForumReply>> _replies = Map.identity();

  @override
  void initState() {
    super.initState();
    _posts = List<ForumPost>.of(widget.posts ?? ForumPostService.samplePosts());
  }

  Future<void> _showNewPostDialog() async {
    final result = await showDialog<_NewPostData>(
      context: context,
      builder: (_) => const _NewPostDialog(),
    );

    if (result == null || !mounted) return;

    setState(() {
      _posts.add(
        ForumPost(
          title: result.title,
          author: result.author,
          postedAt: DateTime.now(),
          bodyPreview: result.body,
          replyCount: 0,
        ),
      );
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post published')));
  }

  Future<void> _openPost(ForumPost post) async {
    final replies = _replies.putIfAbsent(post, () => <_ForumReply>[]);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ForumPostDetailScreen(post: post, replies: replies),
      ),
    );

    if (mounted) setState(() {});
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
      _replies.remove(post);
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
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'New post',
          onPressed: _showNewPostDialog,
        ),
      ],
      body: newestFirst.isEmpty
          ? const _EmptyForumsState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: newestFirst.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = newestFirst[index];
                return _ForumPostTile(
                  post: post,
                  replyCount: post.replyCount + (_replies[post]?.length ?? 0),
                  showDelete: isAdmin,
                  onTap: () => _openPost(post),
                  onDelete: () => _deletePost(post),
                );
              },
            ),
    );
  }
}

class _ForumPostTile extends StatelessWidget {
  const _ForumPostTile({
    required this.post,
    required this.replyCount,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
  });

  final ForumPost post;
  final int replyCount;
  final bool showDelete;
  final VoidCallback onTap;
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
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
                    '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
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

class _NewPostData {
  const _NewPostData({
    required this.title,
    required this.author,
    required this.body,
  });

  final String title;
  final String author;
  final String body;
}

class _NewPostDialog extends StatefulWidget {
  const _NewPostDialog();

  @override
  State<_NewPostDialog> createState() => _NewPostDialogState();
}

class _NewPostDialogState extends State<_NewPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _NewPostData(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Post'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: _required,
                ),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: 'Author'),
                  textCapitalization: TextCapitalization.words,
                  validator: _required,
                ),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Post')),
      ],
    );
  }
}

class _ForumReply {
  const _ForumReply({
    required this.author,
    required this.body,
    required this.postedAt,
  });

  final String author;
  final String body;
  final DateTime postedAt;
}

class _ForumPostDetailScreen extends StatefulWidget {
  const _ForumPostDetailScreen({required this.post, required this.replies});

  final ForumPost post;
  final List<_ForumReply> replies;

  @override
  State<_ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<_ForumPostDetailScreen> {
  Future<void> _showReplyDialog() async {
    final result = await showDialog<_ReplyData>(
      context: context,
      builder: (_) => _ReplyDialog(post: widget.post),
    );

    if (result == null || !mounted) return;

    setState(() {
      widget.replies.add(
        _ForumReply(
          author: result.author,
          body: result.body,
          postedAt: DateTime.now(),
        ),
      );
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reply posted')));
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final brand = AccessibilityColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalReplies = post.replyCount + widget.replies.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: brand.primary,
        foregroundColor: brand.onPrimary,
        title: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: textTheme.titleLarge?.copyWith(
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
                          style: textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatPostedAt(context, post.postedAt),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.bodyPreview, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$totalReplies ${totalReplies == 1 ? 'reply' : 'replies'}',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (widget.replies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No replies to show yet.', style: textTheme.bodyMedium),
            )
          else
            for (final reply in widget.replies) _ReplyTile(reply: reply),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _showReplyDialog,
            icon: const Icon(Icons.reply),
            label: const Text('Reply'),
          ),
        ),
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply});

  final _ForumReply reply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reply.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatPostedAt(context, reply.postedAt),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(reply.body, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ReplyData {
  const _ReplyData({required this.author, required this.body});

  final String author;
  final String body;
}

class _ReplyDialog extends StatefulWidget {
  const _ReplyDialog({required this.post});

  final ForumPost post;

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authorController = TextEditingController();
  final _bodyController = TextEditingController();
  final _originalScrollController = ScrollController();

  @override
  void dispose() {
    _authorController.dispose();
    _bodyController.dispose();
    _originalScrollController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _authorController.text.trim();
    Navigator.of(context).pop(
      _ReplyData(
        author: name.isEmpty ? 'Anonymous' : name,
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Reply'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Replying to', style: textTheme.labelMedium),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Scrollbar(
                    controller: _originalScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _originalScrollController,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${widget.post.author}',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.post.bodyPreview,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    hintText: 'Anonymous',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Reply',
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Post')),
      ],
    );
  }
}