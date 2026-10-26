import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../services/forum_api_service.dart';
import '../widgets/hamburger_menu.dart';

String _formatPostedAt(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(local);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local));
  return '$date, $time';
}

class ForumsScreen extends StatefulWidget {
  ForumsScreen({super.key, List<ForumPost>? posts, this.service})
    : posts = posts;

  final List<ForumPost>? posts;

  final ForumApiService? service;

  @override
  State<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends State<ForumsScreen> {
  late final ForumApiService _service;
  List<ForumPost> _posts = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ForumApiService();
    final initialPosts = widget.posts;
    if (initialPosts != null) {
      _posts = List<ForumPost>.of(initialPosts);
      _isLoading = false;
    } else {
      _loadPosts(showSpinner: false);
    }
  }

  @override
  void dispose() {
    if (widget.service == null) _service.close();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadPosts({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final posts = await _service.fetchPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
        _loadError = null;
      });
    } on ForumApiException catch (error) {
      if (!mounted) return;
      final hasPosts = _posts.isNotEmpty;
      setState(() {
        _isLoading = false;
        if (!hasPosts) _loadError = error.message;
      });
      if (hasPosts) _showMessage(error.message);
    }
  }

  Future<void> _showNewPostDialog() async {
    final created = await showDialog<ForumPost>(
      context: context,
      builder: (_) => _NewPostDialog(
        onSubmit: (data) => _service.createPost(
          title: data.title,
          author: data.author,
          body: data.body,
        ),
      ),
    );

    if (created == null || !mounted) return;

    setState(() => _posts.insert(0, created));
    _showMessage('Post published');
  }

  Future<void> _openPost(ForumPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ForumPostDetailScreen(post: post, service: _service),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _deletePost(ForumPost post) async {
    if (!AuthService.isAdmin) return;
    final colors = AccessibilityColors.of(context);

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.destructive,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final id = post.id;
    if (id != null) {
      try {
        await _service.deletePost(id);
      } on ForumApiException catch (error) {
        _showMessage(error.message);
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _posts.removeWhere((candidate) => identical(candidate, post));
    });
    _showMessage('Post deleted');
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final loadError = _loadError;
    if (loadError != null) {
      return _ForumsErrorState(message: loadError, onRetry: () => _loadPosts());
    }

    final newestFirst = List<ForumPost>.of(_posts)
      ..sort((first, second) => second.postedAt.compareTo(first.postedAt));
    final isAdmin = AuthService.isAdmin;

    return RefreshIndicator(
      onRefresh: () => _loadPosts(showSpinner: false),
      child: newestFirst.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 120), _EmptyForumsState()],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: newestFirst.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = newestFirst[index];
                return _ForumPostTile(
                  post: post,
                  replyCount: post.replyCount,
                  showDelete: isAdmin,
                  onTap: () => _openPost(post),
                  onDelete: () => _deletePost(post),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'Forums',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'New post',
          onPressed: _showNewPostDialog,
        ),
      ],
      body: _buildBody(),
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
    final colors = AccessibilityColors.of(context);
    final postedAt = post.postedAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final postedDate = localizations.formatMediumDate(postedAt);
    final postedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(postedAt),
    );

    return Card(
      margin: EdgeInsets.zero,
      color: colors.cardBackground,
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
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                  if (showDelete) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete ${post.title}',
                      onPressed: onDelete,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colors.destructive,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'by ${post.author}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$postedDate, $postedTime',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.secondaryText,
                    ),
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

class _ForumsErrorState extends StatelessWidget {
  const _ForumsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: colors.destructive),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
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
  const _NewPostDialog({required this.onSubmit});

  final Future<ForumPost> Function(_NewPostData data) onSubmit;

  @override
  State<_NewPostDialog> createState() => _NewPostDialogState();
}

class _NewPostDialogState extends State<_NewPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final created = await widget.onSubmit(
        _NewPostData(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          body: _bodyController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ForumApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = AccessibilityColors.of(context);

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
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
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(labelText: 'Title'),
                    textCapitalization: TextCapitalization.sentences,
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _authorController,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(labelText: 'Author'),
                    textCapitalization: TextCapitalization.words,
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _bodyController,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Body',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 4,
                    maxLines: 8,
                    validator: _required,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: brand.destructive)),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _ForumPostDetailScreen extends StatefulWidget {
  const _ForumPostDetailScreen({required this.post, required this.service});

  final ForumPost post;
  final ForumApiService service;

  @override
  State<_ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<_ForumPostDetailScreen> {
  Future<ForumReply> _submitReply(_ReplyData data) async {
    final id = widget.post.id;
    if (id == null) {
      // Local-only post: nothing to send to the server.
      return ForumReply(
        author: data.author,
        body: data.body,
        postedAt: DateTime.now(),
      );
    }
    return widget.service.addReply(
      postId: id,
      author: data.author,
      body: data.body,
    );
  }

  Future<void> _showReplyDialog() async {
    final reply = await showDialog<ForumReply>(
      context: context,
      builder: (_) => _ReplyDialog(post: widget.post, onSubmit: _submitReply),
    );

    if (reply == null || !mounted) return;

    setState(() => widget.post.replies.add(reply));
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
    final totalReplies = post.replyCount;

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
          if (post.replies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No replies to show yet.', style: textTheme.bodyMedium),
            )
          else
            for (final reply in post.replies) _ReplyTile(reply: reply),
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

  final ForumReply reply;

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
  const _ReplyDialog({required this.post, required this.onSubmit});

  final ForumPost post;
  final Future<ForumReply> Function(_ReplyData data) onSubmit;

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authorController = TextEditingController();
  final _bodyController = TextEditingController();
  final _originalScrollController = ScrollController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _authorController.dispose();
    _bodyController.dispose();
    _originalScrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final name = _authorController.text.trim();

    try {
      final reply = await widget.onSubmit(
        _ReplyData(
          author: name.isEmpty ? 'Anonymous' : name,
          body: _bodyController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(reply);
    } on ForumApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brand = AccessibilityColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
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
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional)',
                      hintText: 'Anonymous',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  TextFormField(
                    controller: _bodyController,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Reply',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 6,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: brand.destructive)),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }
}