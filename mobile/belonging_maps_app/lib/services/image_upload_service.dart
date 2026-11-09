import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// An image upload failed. [message] is safe to show to the user.
class ImageUploadException implements Exception {
  final String message;

  const ImageUploadException(this.message);

  @override
  String toString() => message;
}

/// Uploads images to POST /api/images and builds their download URLs
/// (P1-318 / P1-319).
class ImageUploadService {
  ImageUploadService({required http.Client client, String? baseUrl})
      : _client = client,
        _baseUrlOverride = baseUrl;

  final http.Client _client;
  final String? _baseUrlOverride;

  static const Duration uploadTimeout = Duration(seconds: 30);

  /// Uploads [bytes] and returns the new image's id.
  Future<int> upload(Uint8List bytes) async {
    final base = _baseUrl;
    if (base == null) {
      throw const ImageUploadException(
        'The app is missing API_BASE_URL in its .env file.',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse('$base/api/images'))
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'photo.jpg'),
      );

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(uploadTimeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ImageUploadException(
        'Uploading the image took too long. Please try again.',
      );
    } on SocketException {
      throw const ImageUploadException(
        "Couldn't reach the server to upload the image.",
      );
    } on http.ClientException {
      throw const ImageUploadException(
        "Couldn't reach the server to upload the image.",
      );
    }

    if (response.statusCode == 400) {
      throw ImageUploadException(
        response.body.isNotEmpty
            ? response.body.replaceAll('"', '')
            : "That image couldn't be uploaded.",
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageUploadException(
        "Couldn't upload the image (server error ${response.statusCode}).",
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['id'] as int;
    } catch (_) {
      throw const ImageUploadException(
        'The server sent an unexpected response.',
      );
    }
  }

  String? get _baseUrl => _baseUrlOverride ?? imageBaseUrl();

  /// Base URL from .env, or null when it isn't set (or .env isn't loaded,
  /// e.g. in widget tests).
  static String? imageBaseUrl() {
    try {
      return AuthService.baseUrl;
    } catch (_) {
      return null;
    }
  }

  /// Download URL for an uploaded image, or null if there's no image.
  static String? urlFor(int? imageId, {String? baseUrl}) {
    if (imageId == null) return null;
    final base = baseUrl ?? imageBaseUrl();
    if (base == null) return null;
    return '$base/api/images/$imageId';
  }
}
