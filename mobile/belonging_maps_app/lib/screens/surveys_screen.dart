import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../constants/strings.dart';
import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../widgets/hamburger_menu.dart';

/// Lists the survey buttons. Each one opens its survey outside the app
/// (P1-136, P1-137). Admins can add surveys with the plus icon (P1-141, P1-142)
/// and edit or delete them from each card.
class SurveysScreen extends StatefulWidget {
  final http.Client? client;

  const SurveysScreen({super.key, this.client});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  static const Duration _requestTimeout = Duration(seconds: 10);

  bool _isLoading = true;
  List<Survey> _surveys = List.of(_defaultSurveys);
  late final http.Client _client;
  late final bool _ownsClient;

  static const List<Survey> _defaultSurveys = [
    Survey(
      title: 'SOMOS Sac State',
      description: '',
      url: AppStrings.somosSacStateSurveyUrl,
    ),
    Survey(
      title: 'SOMOS Sac Community',
      description: '',
      url: AppStrings.somosSacCommunitySurveyUrl,
    ),
    Survey(
      title: 'UMMAH Sac State',
      description: '',
      url: AppStrings.ummahSacStateSurveyUrl,
    ),
    Survey(
      title: 'UMMAH Sac Community',
      description: '',
      url: AppStrings.ummahSacCommunitySurveyUrl,
    ),
    Survey(
      title: 'Ubuntu Sac State',
      description: '',
      url: AppStrings.ubuntuSacStateSurveyUrl,
    ),
    Survey(
      title: 'Ubuntu Sac Community',
      description: '',
      url: AppStrings.ubuntuSacCommunitySurveyUrl,
    ),
    Survey(
      title: 'SOMOS Something Missing?',
      description: '',
      url: AppStrings.somosSomethingMissingSurveyUrl,
    ),
    Survey(
      title: 'UMMAH Something Missing?',
      description: '',
      url: AppStrings.ummahSomethingMissingSurveyUrl,
    ),
    Survey(
      title: 'UBUNTU Something Missing?',
      description: '',
      url: AppStrings.ubuntuSomethingMissingSurveyUrl,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _ownsClient = widget.client == null;
    _loadSurveys();
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }

  Future<void> _loadSurveys() async {
    final uri = _apiUri('/api/surveys');
    if (uri == null) {
      _finishLoadingWithError('API_BASE_URL is missing from .env.');
      return;
    }

    try {
      final response = await _client.get(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError('GET returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is! List) throw const FormatException('Expected a list');

      final surveys = data
          .map((item) => Survey.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _surveys = surveys.isEmpty ? List.of(_defaultSurveys) : surveys;
        _isLoading = false;
      });
    } catch (_) {
      _finishLoadingWithError('Could not load surveys. Please try again.');
    }
  }

  Uri? _apiUri(String path) {
    final baseUrl = AuthService.baseUrl;
    if (baseUrl == null) return null;
    return Uri.parse('$baseUrl$path');
  }

  void _finishLoadingWithError(String message) {
    if (!mounted) return;
    setState(() {
      _surveys = [];
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  void _showRequestError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSurvey(Survey survey) async {
    final uri = Uri.tryParse(survey.url.trim());
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid survey link')));
      return;
    }

    // External mode sends the user to the browser instead of an in-app view.
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open ${survey.title}')));
    }
  }

  // Admin only. Pass an index to edit that survey; omit it to add a new one.
  Future<void> _showSurveyDialog({int? index}) async {
    final isEditing = index != null;
    final result = await showDialog<Survey>(
      context: context,
      builder: (_) => _SurveyEditorDialog(
        initialSurvey: isEditing ? _surveys[index] : null,
      ),
    );

    if (result == null) return;

    final uri = _apiUri(
      isEditing ? '/api/surveys/${result.id}' : '/api/surveys',
    );
    if (uri == null) {
      _showRequestError('API_BASE_URL is missing from .env.');
      return;
    }

    try {
      final body = jsonEncode(result.toJson());
      final response = isEditing
          ? await _client
                .put(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                )
                .timeout(_requestTimeout)
          : await _client
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                )
                .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError(
          '${isEditing ? 'PUT' : 'POST'} returned ${response.statusCode}',
        );
      }

      final saved = Survey.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        if (isEditing) {
          _surveys[index] = saved;
        } else {
          _surveys.add(saved);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Survey updated' : 'Survey added')),
      );
    } catch (_) {
      _showRequestError(
        isEditing
            ? 'Could not update the survey. Please try again.'
            : 'Could not add the survey. Please try again.',
      );
    }
  }

  Future<void> _deleteSurvey(int index) async {
    final colors = AccessibilityColors.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Survey'),
        content: const Text('Are you sure you want to delete this survey?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.destructive,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final id = _surveys[index].id;
    final uri = id == null ? null : _apiUri('/api/surveys/$id');
    if (uri == null) {
      _showRequestError('Could not delete the survey. Please try again.');
      return;
    }

    try {
      final response = await _client.delete(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError('DELETE returned ${response.statusCode}');
      }

      if (!mounted) return;
      setState(() => _surveys.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Survey deleted')));
    } catch (_) {
      _showRequestError('Could not delete the survey. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final isAdmin = AuthService.isAdmin;

    return HamburgerMenu(
      title: 'Surveys',
      actions: [
        // Admin add survey button
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add survey',
            onPressed: () => _showSurveyDialog(),
          ),
      ],
      body: Scaffold(
        backgroundColor: colors.pageBackground,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _surveys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final survey = _surveys[index];
                  return _SurveyCard(
                    survey: survey,
                    isAdmin: isAdmin,
                    onOpen: () => _openSurvey(survey),
                    onEdit: () => _showSurveyDialog(index: index),
                    onDelete: () => _deleteSurvey(index),
                  );
                },
              ),
      ),
    );
  }
}

class Survey {
  final int? id;
  final String title;
  final String description;
  final String url;

  const Survey({
    this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['link'] as String? ?? json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'link': url,
  };
}

class _SurveyCard extends StatelessWidget {
  final Survey survey;
  final bool isAdmin;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SurveyCard({
    required this.survey,
    required this.isAdmin,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Card(
      color: colors.cardBackground,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (survey.description.isNotEmpty) ...[
              Text(
                survey.description,
                style: TextStyle(color: colors.secondaryText, height: 1.4),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                survey.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isAdmin && survey.id != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.build, color: colors.action),
                    tooltip: 'Edit ${survey.title}',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: colors.destructive,
                    ),
                    tooltip: 'Delete ${survey.title}',
                    onPressed: onDelete,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SurveyEditorDialog extends StatefulWidget {
  final Survey? initialSurvey;

  const _SurveyEditorDialog({this.initialSurvey});

  @override
  State<_SurveyEditorDialog> createState() => _SurveyEditorDialogState();
}

class _SurveyEditorDialogState extends State<_SurveyEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.initialSurvey?.title,
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialSurvey?.description,
  );
  late final _urlController = TextEditingController(
    text: widget.initialSurvey?.url,
  );

  bool get _isEditing => widget.initialSurvey != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the survey link';
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Enter a full link starting with https://';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Survey(
        id: widget.initialSurvey?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        url: _urlController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Survey' : 'Add Survey'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Survey Name'),
                textInputAction: TextInputAction.next,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter a survey name'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                minLines: 1,
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Survey Link',
                  hintText: 'https://',
                ),
                keyboardType: TextInputType.url,
                validator: _validateUrl,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          onPressed: _submit,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
