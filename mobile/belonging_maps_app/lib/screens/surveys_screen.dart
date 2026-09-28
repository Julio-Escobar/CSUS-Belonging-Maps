import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/hamburger_menu.dart';
import '../services/accessibility_theme.dart';

//admin = true for testing
final bool isAdmin = true;

const String _storageKey = 'surveys_resources_v1';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  bool _isLoading = true;
  List<_SurveyResource> _resources = [];

  //sample survey
  static const List<_SurveyResource> _defaultResources = [
    _SurveyResource(
      title: 'Sample Feedback Survey',
      description: 'A placeholder survey to test the layout and admin tools.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_storageKey);

    if (storedJson != null && storedJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(storedJson);
        setState(() {
          _resources = decoded
              .map(
                (item) =>
                    _SurveyResource.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }

    setState(() {
      _resources = List<_SurveyResource>.from(_defaultResources);
      _isLoading = false;
    });
    await _saveResources();
  }

  Future<void> _saveResources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_resources.map((res) => res.toJson()).toList()),
    );
  }

  void _showEditDialog(int index) async {
    final target = _resources[index];

    final result = await showDialog<_SurveyResource>(
      context: context,
      builder: (dialogContext) => _SurveyEditorDialog(initialResource: target),
    );

    if (result != null) {
      setState(() => _resources[index] = result);
      await _saveResources();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Survey updated')));
      }
    }
  }

  void _deleteResource(int index) async {
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

    if (shouldDelete == true) {
      setState(() => _resources.removeAt(index));
      await _saveResources();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Survey deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return HamburgerMenu(
      title: 'Surveys',
      body: Scaffold(
        backgroundColor: colors.pageBackground,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _resources.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final resource = _resources[index];
                  return _ResourceCard(
                    resource: resource,
                    isAdmin: isAdmin,
                    onEdit: () => _showEditDialog(index),
                    onDelete: () => _deleteResource(index),
                  );
                },
              ),
      ),
    );
  }
}

class _SurveyEditorDialog extends StatefulWidget {
  final _SurveyResource initialResource;

  const _SurveyEditorDialog({required this.initialResource});

  @override
  State<_SurveyEditorDialog> createState() => _SurveyEditorDialogState();
}

class _SurveyEditorDialogState extends State<_SurveyEditorDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialResource.title);
    descriptionController = TextEditingController(
      text: widget.initialResource.description,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return AlertDialog(
      title: const Text('Edit Survey'),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Placeholder for future feedback survey functionality. For addition within other tickets.
                  },
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Feedback Survey'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Placeholder for future "What is Missing" survey functionality.
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('What is Missing'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            Navigator.pop(
              context,
              _SurveyResource(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _SurveyResource {
  final String title;
  final String description;

  const _SurveyResource({required this.title, required this.description});

  Map<String, dynamic> toJson() => {'title': title, 'description': description};

  factory _SurveyResource.fromJson(Map<String, dynamic> json) =>
      _SurveyResource(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class _ResourceCard extends StatelessWidget {
  final _SurveyResource resource;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ResourceCard({
    required this.resource,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: colors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resource.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 6),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.build, color: colors.action),
                    tooltip: 'Edit ${resource.title}',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: colors.destructive,
                    ),
                    tooltip: 'Delete ${resource.title}',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}