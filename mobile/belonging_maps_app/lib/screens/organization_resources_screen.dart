import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../widgets/hamburger_menu.dart';
import 'somos_community_map.dart';
import 'ummah_community_map.dart';
import 'ubuntu_community_map.dart';

const Map<String, IconData> _iconOptions = {
  'groups': Icons.groups_outlined,
  'school': Icons.school_outlined,
  'diversity': Icons.diversity_3,
  'home': Icons.home_outlined,
  'public': Icons.public_outlined,
  'star': Icons.star_outline,
  'event': Icons.event_outlined,
  'mail': Icons.mail_outline,
};

class OrganizationResourcesScreen extends StatefulWidget {
  final http.Client? client;

  const OrganizationResourcesScreen({super.key, this.client});

  @override
  State<OrganizationResourcesScreen> createState() =>
      _OrganizationResourcesScreenState();
}

class _OrganizationResourcesScreenState
    extends State<OrganizationResourcesScreen> {
  static const Duration _requestTimeout = Duration(seconds: 10);

  bool _isLoading = true;
  List<_OrganizationResource> _resources = [];
  late final http.Client _client;
  late final bool _ownsClient;

  // Maps each org key to the community map screen it should link to.
  // TODO: contact emails and meeting times below are placeholders —
  // swap in the real details before shipping.
  static final Map<String, Widget Function()> _orgMapBuilders = {
    'somos': () => const SomosCommunityMap(),
    'ummah': () => const UmmahCommunityMap(),
    'ubuntu': () => const UbuntuCommunityMap(),
  };

  static const Map<String, String> _orgLabels = {
    'somos': 'SOMOS',
    'ummah': 'Ummah',
    'ubuntu': 'Ubuntu',
  };

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _ownsClient = widget.client == null;
    _loadResources();
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }

  Future<void> _loadResources() async {
    final uri = _apiUri('/api/organizationresources');
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

      if (!mounted) return;
      setState(() {
        _resources = data
            .map(
              (item) =>
                  _OrganizationResource.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      _finishLoadingWithError(
        'Could not load organization resources. Please try again.',
      );
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
      _resources = [];
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

  // Admin only. Pass an index to edit that resource; omit it to add a new one.
  Future<void> _showResourceDialog({int? index}) async {
    final colors = AccessibilityColors.of(context);
    final isEditing = index != null;
    final existing = isEditing ? _resources[index] : null;

    final titleController = TextEditingController(text: existing?.title);
    final categoryController = TextEditingController(text: existing?.category);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    String selectedIcon = existing?.iconKey ?? 'groups';
    String selectedOrgKey = existing?.orgKey ?? _orgLabels.keys.first;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_OrganizationResource>(
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
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedIcon,
                        decoration: const InputDecoration(labelText: 'Icon'),
                        items: _iconOptions.keys
                            .map(
                              (key) => DropdownMenuItem(
                                value: key,
                                child: Row(
                                  children: [
                                    Icon(
                                      _iconOptions[key],
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      key[0].toUpperCase() + key.substring(1),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            dialogSetState(() => selectedIcon = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedOrgKey,
                        decoration: const InputDecoration(
                          labelText: 'Organization (links to its map)',
                        ),
                        items: _orgLabels.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            dialogSetState(() => selectedOrgKey = value);
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
                    final resource = _OrganizationResource(
                      id: existing?.id,
                      title: titleController.text.trim(),
                      category: categoryController.text.trim(),
                      description: descriptionController.text.trim(),
                      iconKey: selectedIcon,
                      orgKey: selectedOrgKey,
                    );
                    Navigator.of(dialogContext).pop(resource);
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final uri = _apiUri(
      isEditing
          ? '/api/organizationresources/${result.id}'
          : '/api/organizationresources',
    );
    if (uri == null || (isEditing && result.id == null)) {
      _showRequestError(
        'Could not save the organization resource. Please try again.',
      );
      return;
    }

    try {
      final response = isEditing
          ? await _client
                .put(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(result.toJson()),
                )
                .timeout(_requestTimeout)
          : await _client
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(result.toJson()),
                )
                .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError(
          '${isEditing ? 'PUT' : 'POST'} returned ${response.statusCode}',
        );
      }

      final saved = _OrganizationResource.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        if (isEditing) {
          _resources[index] = saved;
        } else {
          _resources.add(saved);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Resource updated' : 'Resource added'),
        ),
      );
    } catch (_) {
      _showRequestError(
        isEditing
            ? 'Could not update the organization resource. Please try again.'
            : 'Could not add the organization resource. Please try again.',
      );
    }
  }

  void _showResourceInformation(_OrganizationResource resource) {
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final mapBuilder = _orgMapBuilders[resource.orgKey];
              if (mapBuilder == null) return;
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => mapBuilder()));
            },
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: const Text(
              'View on Map',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteResource(int index) async {
    final colors = AccessibilityColors.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
      ),
    );

    if (shouldDelete != true) return;

    final resource = _resources[index];
    final uri = resource.id == null
        ? null
        : _apiUri('/api/organizationresources/${resource.id}');
    if (uri == null) {
      _showRequestError(
        'Could not delete the organization resource. Please try again.',
      );
      return;
    }

    try {
      final response = await _client.delete(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError('DELETE returned ${response.statusCode}');
      }

      if (!mounted) return;
      setState(() => _resources.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resource deleted')));
    } catch (_) {
      _showRequestError(
        'Could not delete the organization resource. Please try again.',
      );
    }
  }

  @override
  //Check if the user is an admin
  Widget build(BuildContext context) {
    final isAdmin = AuthService.isAdmin;
    final colors = AccessibilityColors.of(context);

    return HamburgerMenu(
      title: 'Organization Resources',
      actions: [
        // Admin add resource button
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: 'Add resource',
            onPressed: () => _showResourceDialog(),
          ),
      ],
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
                    onTap: () => _showResourceInformation(resource),
                    onEdit: () => _showResourceDialog(index: index),
                    onDelete: () => _deleteResource(index),
                  );
                },
              ),
      ),
    );
  }
}

class _OrganizationResource {
  final int? id;
  final String title;
  final String category;
  final String description;
  final String iconKey;
  final String orgKey;

  const _OrganizationResource({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.iconKey,
    required this.orgKey,
  });

  IconData get icon => _iconOptions[iconKey] ?? Icons.groups_outlined;

  factory _OrganizationResource.fromJson(Map<String, dynamic> json) {
    return _OrganizationResource(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'groups',
      orgKey: json['orgKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'description': description,
    'iconKey': iconKey,
    'orgKey': orgKey,
  };
}

class _ResourceCard extends StatelessWidget {
  final _OrganizationResource resource;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ResourceCard({
    required this.resource,
    required this.isAdmin,
    required this.onTap,
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
                    child: Icon(resource.icon, color: colors.primary, size: 26),
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
                      IconButton(
                        tooltip: 'Edit ${resource.title}',
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined, color: colors.action),
                      ),
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
