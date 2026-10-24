import 'dart:convert';

import 'package:belonging_maps_app/screens/community_resources_screen.dart';
import 'package:belonging_maps_app/services/community_resource_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory stand-in for the backend /api/communityresources endpoints.
/// Starts with the same 8 resources the backend seeds (P1-220).
class FakeCommunityResourcesApi {
  final List<Map<String, dynamic>> resources = [
    _seed(1, 'Food Pantry', 'Food', 'food',
        'Free food resources available for students and community members.'),
    _seed(2, 'Mental Health Services', 'Health', 'health',
        'Counseling and mental health support for students.'),
    _seed(3, 'Housing Assistance', 'Housing', 'housing',
        'Resources and support for students experiencing housing insecurity.'),
    _seed(4, 'Tutoring Center', 'Education', 'education',
        'Free academic tutoring and support services on campus.'),
    _seed(5, 'Financial Aid Office', 'Financial', 'financial',
        'Help with scholarships, grants, and financial assistance.'),
    _seed(6, 'Career Center', 'Career', 'career',
        'Job placement, resume help, and career counseling services.'),
    _seed(7, 'Transportation Services', 'Transportation', 'transportation',
        'Bus passes and transportation assistance for students.'),
    _seed(8, 'Childcare Services', 'Family', 'family',
        'Affordable childcare options available for student parents.'),
  ];

  /// When true, every request answers with a 500 error.
  bool failRequests = false;

  int _nextId = 9;

  late final http.Client client = MockClient(_handle);

  /// A service pointed at this fake. Each call acts like a separate device
  /// talking to the same backend.
  CommunityResourceService newService() =>
      CommunityResourceService(client: client, baseUrl: 'http://fake-api');

  static Map<String, dynamic> _seed(
    int id,
    String title,
    String category,
    String iconKey,
    String description,
  ) => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'iconKey': iconKey,
  };

  Future<http.Response> _handle(http.Request request) async {
    if (failRequests) return http.Response('Server error', 500);

    final segments = request.url.pathSegments;
    final id = segments.length > 2 ? int.tryParse(segments[2]) : null;
    final index = id == null ? -1 : resources.indexWhere((r) => r['id'] == id);

    switch (request.method) {
      case 'GET':
        if (id == null) return _json(resources, 200);
        return index == -1 ? http.Response('', 404) : _json(resources[index], 200);
      case 'POST':
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        body['id'] = _nextId++;
        resources.add(body);
        return _json(body, 201);
      case 'PUT':
        if (index == -1) return http.Response('', 404);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        body['id'] = id;
        resources[index] = body;
        return _json(body, 200);
      case 'DELETE':
        if (index == -1) return http.Response('', 404);
        resources.removeAt(index);
        return http.Response('', 204);
    }
    return http.Response('', 405);
  }

  http.Response _json(Object body, int status) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Points CommunityResourcesScreen at a fresh fake API for the current test
/// and restores the real service afterwards. Call from a test or setUp.
FakeCommunityResourcesApi useFakeCommunityResourcesApi() {
  final api = FakeCommunityResourcesApi();
  CommunityResourcesScreen.serviceFactory = api.newService;
  addTearDown(
    () => CommunityResourcesScreen.serviceFactory = CommunityResourceService.new,
  );
  return api;
}
