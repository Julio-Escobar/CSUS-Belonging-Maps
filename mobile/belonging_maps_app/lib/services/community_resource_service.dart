import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/community_resource.dart';
import 'auth_service.dart';

/// A request to the community resources API failed. [message] is safe to show
/// to the user.
class CommunityResourceException implements Exception {
  final String message;

  const CommunityResourceException(this.message);

  @override
  String toString() => message;
}

/// Talks to the backend /api/communityresources endpoints (P1-220) so every
/// device sees the same list (P1-225).
class CommunityResourceService {
  CommunityResourceService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrlOverride = baseUrl;

  final http.Client _client;
  final String? _baseUrlOverride;

  /// How long we wait for the backend before giving up.
  static const Duration requestTimeout = Duration(seconds: 10);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<List<CommunityResource>> fetchAll() async {
    final response = await _send(() => _client.get(_uri()));
    _checkStatus(response, 'load community resources');
    final decoded = _decode(response.body);
    if (decoded is! List) {
      throw const CommunityResourceException(
        'The server sent an unexpected response.',
      );
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CommunityResource.fromJson)
        .toList();
  }

  Future<CommunityResource> create(CommunityResource resource) async {
    final response = await _send(
      () => _client.post(
        _uri(),
        headers: _jsonHeaders,
        body: jsonEncode(resource.toJson()),
      ),
    );
    _checkStatus(response, 'add the resource');
    return _decodeResource(response.body);
  }

  Future<CommunityResource> update(CommunityResource resource) async {
    final response = await _send(
      () => _client.put(
        _uri(resource.id),
        headers: _jsonHeaders,
        body: jsonEncode(resource.toJson()),
      ),
    );
    _checkStatus(response, 'update the resource');
    return _decodeResource(response.body);
  }

  Future<void> delete(int id) async {
    final response = await _send(() => _client.delete(_uri(id)));
    _checkStatus(response, 'delete the resource');
  }

  void close() => _client.close();

  Uri _uri([int? id]) {
    String? base = _baseUrlOverride;
    if (base == null) {
      try {
        base = AuthService.baseUrl;
      } catch (_) {
        // .env was never loaded (e.g. in a widget test).
        base = null;
      }
    }
    if (base == null) {
      throw const CommunityResourceException(
        'The app is missing API_BASE_URL in its .env file.',
      );
    }
    final path = id == null
        ? '/api/communityresources'
        : '/api/communityresources/$id';
    return Uri.parse('$base$path');
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(requestTimeout);
    } on TimeoutException {
      throw const CommunityResourceException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const CommunityResourceException(
        "Couldn't reach the server. Check your connection and try again.",
      );
    } on http.ClientException {
      throw const CommunityResourceException(
        "Couldn't reach the server. Check your connection and try again.",
      );
    }
  }

  void _checkStatus(http.Response response, String action) {
    if (response.statusCode == 404) {
      throw CommunityResourceException(
        "Couldn't $action: it no longer exists. Pull down to refresh.",
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommunityResourceException(
        "Couldn't $action (server error ${response.statusCode}).",
      );
    }
  }

  Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const CommunityResourceException(
        'The server sent an unexpected response.',
      );
    }
  }

  CommunityResource _decodeResource(String body) {
    final decoded = _decode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const CommunityResourceException(
        'The server sent an unexpected response.',
      );
    }
    return CommunityResource.fromJson(decoded);
  }
}
