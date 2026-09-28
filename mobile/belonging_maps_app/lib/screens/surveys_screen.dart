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
/// (P1-136, P1-137). Admins can add surveys with the plus icon (P1-141, P1-142)
/// and edit or delete them from each card.
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

    setState(() {
      if (isEditing) {
        _surveys[index] = result;
      } else {
        _surveys.add(result);
      }
    });
    await _saveSurveys();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Survey updated' : 'Survey added')),
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

    setState(() => _surveys.removeAt(index));
    await _saveSurveys();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Survey deleted')));
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
            if (isAdmin)
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
