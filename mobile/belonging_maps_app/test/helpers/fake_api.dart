import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Surveys the fake backend returns from GET /api/surveys.
const fakeSurveys = [
  {
    'id': 1,
    'title': 'Feedback Survey',
    'description': 'Tell us how the Belonging Maps app is working for you.',
    'link': 'https://example.com/feedback',
  },
  {
    'id': 2,
    'title': 'What is Missing Survey',
    'description':
        'Let us know about places, organizations, or resources we should add.',
    'link': 'https://example.com/missing',
  },
];

/// Opportunities the fake backend returns from GET /api/opportunities.
const fakeOpportunities = [
  {
    'id': 1,
    'title': 'SOMOS Scholarships',
    'category': 'SOMOS',
    'description':
        'List of scholarships and opportunities for SOMOS, Ummah, and Ubuntu students.',
    'iconKey': 'book',
    'links': [
      {'name': 'Spirit of Giving', 'url': 'https://example.com/spirit'},
      {'name': 'Chicana Latina', 'url': 'https://example.com/chicana'},
    ],
  },
];

/// Loads a test API_BASE_URL so screens can build their request URLs.
void loadTestEnv() {
  dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:5162');
}

/// A MockClient that acts like the backend for surveys and opportunities.
/// GET returns the fake lists, POST/PUT echo the body back with an id,
/// and DELETE returns 204.
http.Client fakeApiClient() {
  return MockClient((request) async {
    final path = request.url.path;
    final List<Map<String, Object>> items;
    if (path.startsWith('/api/surveys')) {
      items = fakeSurveys;
    } else if (path.startsWith('/api/opportunities')) {
      items = fakeOpportunities;
    } else {
      return http.Response('', 404);
    }

    switch (request.method) {
      case 'GET':
        return http.Response(jsonEncode(items), 200);
      case 'POST':
      case 'PUT':
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'id': 99, ...body}), 200);
      case 'DELETE':
        return http.Response('', 204);
      default:
        return http.Response('', 405);
    }
  });
}
