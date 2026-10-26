class ForumReply {
  const ForumReply({
    this.id,
    required this.author,
    required this.body,
    required this.postedAt,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
    id: json['id'] as int?,
    author: json['author'] as String? ?? 'Anonymous',
    body: json['body'] as String? ?? '',
    postedAt: DateTime.parse(json['postedAt'] as String),
  );

  final int? id;
  final String author;
  final String body;
  final DateTime postedAt;
}

class ForumPost {
  ForumPost({
    this.id,
    required this.title,
    required this.author,
    required this.postedAt,
    required this.bodyPreview,
    int replyCount = 0,
    List<ForumReply>? replies,
  }) : replies = replies ?? <ForumReply>[],
       _baseReplyCount = replyCount;

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final replies = (json['replies'] as List<dynamic>? ?? const [])
        .map((item) => ForumReply.fromJson(item as Map<String, dynamic>))
        .toList();

    return ForumPost(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? 'Anonymous',
      postedAt: DateTime.parse(json['postedAt'] as String),
      bodyPreview: json['body'] as String? ?? '',
      replies: replies,
    );
  }

  final int? id;
  final String title;
  final String author;
  final DateTime postedAt;

  final String bodyPreview;

  final List<ForumReply> replies;
  final int _baseReplyCount;

  int get replyCount => _baseReplyCount + replies.length;
}