import '../models/forum_post.dart';

class ForumPostService {
  static List<ForumPost> samplePosts() {
    final now = DateTime.now();
    return [
      ForumPost(
        title: 'Where can I find affordable textbooks this semester?',
        author: 'Maya R.',
        postedAt: now.subtract(const Duration(minutes: 18)),
        bodyPreview:
            'I am looking for ways to save on books for my classes. Are there campus exchanges, library reserves, or other resources you recommend?',
        replyCount: 4,
      ),
      ForumPost(
        title: 'First-generation student study groups',
        author: 'Andre L.',
        postedAt: now.subtract(const Duration(hours: 2)),
        bodyPreview:
            'Would anyone be interested in meeting weekly to study and share tips for navigating campus resources?',
        replyCount: 7,
      ),
      ForumPost(
        title: 'Quiet places to take an online class on campus',
        author: 'Sofia C.',
        postedAt: now.subtract(const Duration(hours: 5)),
        bodyPreview:
            'I have a class between two in-person lectures and need a quiet spot with reliable Wi-Fi. What places have worked for you?',
        replyCount: 2,
      ),
      ForumPost(
        title: 'Looking for volunteers for the community garden',
        author: 'Jordan P.',
        postedAt: now.subtract(const Duration(days: 1)),
        bodyPreview:
            'The garden is welcoming new volunteers this month. No experience is needed, and tools are provided.',
        replyCount: 3,
      ),
      ForumPost(
        title: 'Favorite low-cost lunch spots near campus',
        author: 'Elena M.',
        postedAt: now.subtract(const Duration(days: 2)),
        bodyPreview:
            'Share your go-to lunch spots that are easy to reach between classes and friendly to a student budget.',
        replyCount: 11,
      ),
      ForumPost(
        title: 'Tips for getting around Sacramento by bus',
        author: 'Chris D.',
        postedAt: now.subtract(const Duration(days: 4)),
        bodyPreview:
            'I am new to the area and would appreciate advice on planning trips, finding routes, and using student transit options.',
        replyCount: 5,
      ),
    ];
  }
}
