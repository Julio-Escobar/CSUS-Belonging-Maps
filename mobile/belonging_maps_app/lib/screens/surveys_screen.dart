import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/strings.dart';
import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../widgets/hamburger_menu.dart';

const String _storageKey = 'surveys_v1';

/// Lists the survey buttons. Each one opens its survey outside the app
/// (P1-136, P1-137). Admins can add surveys with the plus icon (P1-141, P1-142).
class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  bool _isLoading = true;
  List<Survey> _surveys = [];

  static const List<Survey> _defaultSurveys = [
    Survey(
      title: 'Feedback Survey',
      description: 'Tell us how the Belonging Maps app is working for you.',
      url: AppStrings.feedbackSurveyUrl,
    ),
    Survey(
      title: 'What is Missing Survey',
      description:
          'Let us know about places, organizations, or resources we should add.',
      url: AppStrings.whatIsMissingSurveyUrl,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_storageKey);

    if (storedJson != null && storedJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(storedJson);
        if (!mounted) return;
        setState(() {
          _surveys = decoded
              .map((item) => Survey.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _surveys = List<Survey>.from(_defaultSurveys);
      _isLoading = false;
    });
    await _saveSurveys();
  }

  Future<void> _saveSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_surveys.map((survey) => survey.toJson()).toList()),
    );
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

  Future<void> _showAddSurveyDialog() async {
    final result = await showDialog<Survey>(
      context: context,
      builder: (_) => const _AddSurveyDialog(),
    );

    if (result == null) return;

    setState(() => _surveys.add(result));
    await _saveSurveys();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Survey added')));
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
            onPressed: _showAddSurveyDialog,
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
                    onOpen: () => _openSurvey(survey),
                  );
                },
              ),
      ),
    );
  }
}

class Survey {
  final String title;
  final String description;
  final String url;

  const Survey({
    required this.title,
    required this.description,
    required this.url,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'url': url,
  };
}

class _SurveyCard extends StatelessWidget {
  final Survey survey;
  final VoidCallback onOpen;

  const _SurveyCard({required this.survey, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Card(
      color: colors.cardBackground,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (survey.description.isNotEmpty) ...[
              Text(
                survey.description,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
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
          ],
        ),
      ),
    );
  }
}

class _AddSurveyDialog extends StatefulWidget {
  const _AddSurveyDialog();

  @override
  State<_AddSurveyDialog> createState() => _AddSurveyDialogState();
}

class _AddSurveyDialogState extends State<_AddSurveyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

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
      title: const Text('Add Survey'),
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
