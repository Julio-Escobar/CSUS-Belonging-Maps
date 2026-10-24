import 'package:flutter/material.dart';

import '../models/community_resource.dart';
import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../services/community_resource_service.dart';
import '../widgets/hamburger_menu.dart';

/// Icon keys an admin can pick, in dropdown order, with their labels.
const Map<String, String> _iconOptions = {
  'food': 'Food',
  'health': 'Health',
  'housing': 'Housing',
  'education': 'Education',
  'financial': 'Financial',
  'career': 'Career',
  'transportation': 'Transportation',
  'family': 'Family',
};

IconData _iconForKey(String iconKey) {
  return switch (iconKey) {
    'food' => Icons.restaurant_outlined,
    'health' => Icons.favorite_outline,
    'housing' => Icons.home_outlined,
    'education' => Icons.school_outlined,
    'financial' => Icons.attach_money_outlined,
    'career' => Icons.work_outline,
    'transportation' => Icons.directions_bus_outlined,
    'family' => Icons.family_restroom_outlined,
    _ => Icons.help_outline,
  };
}

/// Lists community resources from the backend so every device sees the same
/// list. Admins can add, edit and delete them (P1-225).
class CommunityResourcesScreen extends StatefulWidget {
  const CommunityResourcesScreen({super.key});

  /// Creates the API service the screen uses. Tests swap this for a fake.
  @visibleForTesting
  static CommunityResourceService Function() serviceFactory =
      CommunityResourceService.new;

  @override
  State<CommunityResourcesScreen> createState() =>
      _CommunityResourcesScreenState();
}

class _CommunityResourcesScreenState extends State<CommunityResourcesScreen> {
  late final CommunityResourceService _service;
  List<CommunityResource> _resources = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _service = CommunityResourcesScreen.serviceFactory();
    _loadResources();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  /// Loads the list from GET /api/communityresources. Shows a full-screen
  /// error with a Retry button if it fails.
  Future<void> _loadResources() async {
    try {
      final resources = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _resources = resources;
        _isLoading = false;
        _loadError = null;
      });
    } on CommunityResourceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    await _loadResources();
  }

  /// Pull-to-refresh: keeps the current list and shows a message on failure.
  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final resources = await _service.fetchAll();
      if (!mounted) return;
      setState(() => _resources = resources);
    } on CommunityResourceException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Runs an API call and shows [successMessage], or the error, in a snackbar.
  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
      messenger?.showSnackBar(SnackBar(content: Text(successMessage)));
    } on CommunityResourceException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addResource() async {
    final draft = await _showResourceForm();
    if (draft == null || !mounted) return;

    await _runAction(() async {
      final created = await _service.create(draft);
      if (!mounted) return;
      setState(() => _resources.add(created));
    }, successMessage: 'Resource added');
  }

  Future<void> _editResource(CommunityResource resource) async {
    final draft = await _showResourceForm(existing: resource);
    if (draft == null || !mounted) return;

    await _runAction(() async {
      final updated = await _service.update(draft);
      if (!mounted) return;
      setState(() {
        final index = _resources.indexWhere((r) => r.id == updated.id);
        if (index != -1) _resources[index] = updated;
      });
    }, successMessage: 'Resource updated');
  }

  Future<void> _deleteResource(CommunityResource resource) async {
    final colors = AccessibilityColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Resource'),
          content: const Text('Are you sure you want to delete this resource?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.destructive,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    await _runAction(() async {
      await _service.delete(resource.id);
      if (!mounted) return;
      setState(() => _resources.removeWhere((r) => r.id == resource.id));
    }, successMessage: 'Resource deleted');
  }

  /// Shared add/edit form. Returns the filled-in resource, or null if the
  /// admin cancels. Pass [existing] to edit.
  Future<CommunityResource?> _showResourceForm({CommunityResource? existing}) {
    final colors = AccessibilityColors.of(context);
    final isEditing = existing != null;
    final titleController = TextEditingController(text: existing?.title);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    final categoryController = TextEditingController(text: existing?.category);
    String selectedIcon = _iconOptions.containsKey(existing?.iconKey)
        ? existing!.iconKey
        : 'food';
    final formKey = GlobalKey<FormState>();

    String? requiredField(String? value) =>
        (value == null || value.trim().isEmpty) ? 'Required' : null;

    return showDialog<CommunityResource>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContextBuild, dialogSetState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Resource' : 'Add Resource'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: requiredField,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                        validator: requiredField,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: requiredField,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedIcon,
                        decoration: const InputDecoration(labelText: 'Icon'),
                        items: [
                          for (final option in _iconOptions.entries)
                            DropdownMenuItem(
                              value: option.key,
                              child: Text(option.value),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            dialogSetState(() => selectedIcon = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(dialogContext).pop(
                      CommunityResource(
                        id: existing?.id ?? 0,
                        title: titleController.text.trim(),
                        category: categoryController.text.trim(),
                        description: descriptionController.text.trim(),
                        iconKey: selectedIcon,
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResourceInformation(
    BuildContext context,
    CommunityResource resource,
  ) {
    final colors = AccessibilityColors.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(resource.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryLabel(category: resource.category),
              const SizedBox(height: 16),
              Text(
                'Resource information',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(resource.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isAdmin) {
    final colors = AccessibilityColors.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.primary,
          semanticsLabel: 'Loading community resources',
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: colors.secondaryText,
              ),
              const SizedBox(height: 12),
              Text(
                "Couldn't load community resources",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: _refresh,
      child: _resources.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: [
                Text(
                  'No community resources yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.secondaryText),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _resources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final resource = _resources[index];
                return _ResourceCard(
                  resource: resource,
                  isAdmin: isAdmin,
                  onTap: () => _showResourceInformation(context, resource),
                  onEdit: isAdmin ? () => _editResource(resource) : null,
                  onDelete: isAdmin ? () => _deleteResource(resource) : null,
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.isAdmin;
    final colors = AccessibilityColors.of(context);

    return HamburgerMenu(
      title: 'Community Resources',
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Add resource',
            onPressed: _isLoading || _loadError != null ? null : _addResource,
          ),
      ],
      body: Scaffold(
        backgroundColor: colors.pageBackground,
        body: _buildBody(context, isAdmin),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final CommunityResource resource;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ResourceCard({
    required this.resource,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Card(
      color: colors.cardBackground,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      _iconForKey(resource.iconKey),
                      color: colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          button: true,
                          label: 'View information for ${resource.title}',
                          onTap: onTap,
                          child: ExcludeSemantics(
                            child: Text(
                              resource.title,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _CategoryLabel(category: resource.category),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                resource.description,
                style: TextStyle(color: colors.secondaryText, height: 1.4),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'Edit ${resource.title}',
                          onPressed: onEdit,
                          icon: Icon(Icons.edit_outlined, color: colors.action),
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete ${resource.title}',
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline,
                            color: colors.destructive,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String category;

  const _CategoryLabel({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
