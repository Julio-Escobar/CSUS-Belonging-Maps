import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Returns an in-memory organization-resource API client for widget tests.
http.Client fakeOrganizationResourcesClient() {
  final resources = <Map<String, dynamic>>[
    {
      'id': 1,
      'title': 'SOMOS Student Organization',
      'category': 'SOMOS',
      'description': 'Student support and community events.',
      'iconKey': 'groups',
      'orgKey': 'somos',
    },
  ];

  return MockClient((request) async {
    if (request.method == 'GET') {
      return http.Response(jsonEncode(resources), 200);
    }

    final id = int.tryParse(request.url.pathSegments.last);
    final index = resources.indexWhere((resource) => resource['id'] == id);
    if (index == -1) return http.Response('', 404);

    if (request.method == 'PUT') {
      final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      body['id'] = id;
      resources[index] = body;
      return http.Response(jsonEncode(body), 200);
    }
    if (request.method == 'DELETE') {
      resources.removeAt(index);
      return http.Response('', 200);
    }
    return http.Response('', 405);
  });
}
