class ForumPost {
  const ForumPost({
    required this.title,
    required this.author,
    required this.postedAt,
    required this.bodyPreview,
    this.replyCount = 0,
  });

  final String title;
  final String author;
  final DateTime postedAt;
  final String bodyPreview;
  final int replyCount;
}