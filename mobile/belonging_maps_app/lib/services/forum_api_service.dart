import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/forum_post.dart';

class ForumApiException implements Exception {
  const ForumApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ForumApiService {
  ForumApiService({http.Client? client}) : _client = client ?? clientFactory();

  static http.Client Function() clientFactory = () => http.Client();
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  void close() => _client.close();

  Uri _uri(String path) {
    final base = dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null;
    if (base == null || base.trim().isEmpty) {
      throw const ForumApiException(
        'API_BASE_URL is missing from .env. See .env.example.',
      );
    }
    final trimmed = base.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$trimmed$path');
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ForumApiException(
          'The server returned an error (${response.statusCode}). '
          'Please try again.',
        );
      }
      return response;
    } on ForumApiException {
      rethrow;
    } catch (_) {
      throw const ForumApiException(
        "Can't reach the server. Check your connection and try again.",
      );
    }
  }

  T _parse<T>(http.Response response, T Function(dynamic json) convert) {
    try {
      return convert(jsonDecode(response.body));
    } catch (_) {
      throw const ForumApiException(
        'The server sent a response the app could not read.',
      );
    }
  }

  Future<List<ForumPost>> fetchPosts() async {
    final response = await _send(() => _client.get(_uri('/api/forums')));
    return _parse(
      response,
      (json) => (json as List<dynamic>)
          .map((item) => ForumPost.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ForumPost> createPost({
    required String title,
    required String author,
    required String body,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/api/forums'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'author': author, 'body': body}),
      ),
    );
    return _parse(
      response,
      (json) => ForumPost.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ForumReply> addReply({
    required int postId,
    required String author,
    required String body,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/api/forums/$postId/replies'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'author': author, 'body': body}),
      ),
    );
    return _parse(
      response,
      (json) => ForumReply.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deletePost(int postId) async {
    await _send(() => _client.delete(_uri('/api/forums/$postId')));
  }
}