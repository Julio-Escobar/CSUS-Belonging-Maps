import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/hamburger_menu.dart';

const Color _primaryGreen = Color(0xFF2F5F3E);
const Color _pageBackground = Color(0xFFF9F5FA);

class OrganizationResourcesScreen extends StatefulWidget {
  const OrganizationResourcesScreen({super.key});

  @override
  State<OrganizationResourcesScreen> createState() =>
      _OrganizationResourcesScreenState();
}

class _OrganizationResourcesScreenState
    extends State<OrganizationResourcesScreen> {
  final List<_OrganizationResource> _resources = [
    const _OrganizationResource(
      title: 'SOMOS Student Organization',
      category: 'SOMOS',
      description: 'Resources and support for SOMOS community members.',
      icon: Icons.groups_outlined,
    ),
    const _OrganizationResource(
      title: 'Ummah Student Organization',
      category: 'Ummah',
      description: 'Resources and support for the Ummah community.',
      icon: Icons.groups_outlined,
    ),
    const _OrganizationResource(
      title: 'Ubuntu Student Organization',
      category: 'Ubuntu',
      description: 'Resources and support for the Ubuntu community.',
      icon: Icons.groups_outlined,
    ),
  ];

  static const Map<String, IconData> _iconOptions = {
    'groups': Icons.groups_outlined,
    'school': Icons.school_outlined,
    'diversity': Icons.diversity_3,
    'home': Icons.home_outlined,
    'public': Icons.public_outlined,
    'star': Icons.star_outline,
  };

  static String _keyForIcon(IconData icon) {
    return _iconOptions.entries
        .firstWhere(
          (entry) => entry.value == icon,
          orElse: () => _iconOptions.entries.first,
        )
        .key;
  }

  // Admin only. Pass an index to edit that resource; omit it to add a new one.
  void _showResourceDialog({int? index}) {
    final isEditing = index != null;
    final existing = isEditing ? _resources[index] : null;

    final titleController = TextEditingController(text: existing?.title);
    final categoryController = TextEditingController(text: existing?.category);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    String selectedIcon = existing != null
        ? _keyForIcon(existing.icon)
        : 'groups';
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
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
                                      color: _primaryGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(key[0].toUpperCase() + key.substring(1)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final resource = _OrganizationResource(
                      title: titleController.text.trim(),
                      category: categoryController.text.trim(),
                      description: descriptionController.text.trim(),
                      icon: _iconOptions[selectedIcon]!,
                    );
                    setState(() {
                      if (isEditing) {
                        _resources[index] = resource;
                      } else {
                        _resources.add(resource);
                      }
                    });
                    Navigator.of(dialogContext).pop();
                    if (isEditing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resource updated')),
                      );
                    }
                  },
                  child: Text(
                    isEditing ? 'Update' : 'Add',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResourceInformation(_OrganizationResource resource) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(resource.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryLabel(category: resource.category),
            const SizedBox(height: 16),
            const Text(
              'Resource information',
              style: TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(resource.description),
          ],
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

  void _deleteResource(int index) {
    showDialog<void>(
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
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
            onPressed: () {
              setState(() => _resources.removeAt(index));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Resource deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  //Check if the user is an admin
  Widget build(BuildContext context) {
    final isAdmin = AuthService.isAdmin;

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
        backgroundColor: _pageBackground,
        body: ListView.separated(
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
  final String title;
  final String category;
  final String description;
  final IconData icon;

  const _OrganizationResource({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
  });
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
    return Semantics(
      button: true,
      label: 'View information for ${resource.title}',
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(resource.icon, color: _primaryGreen, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              resource.title,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CategoryLabel(category: resource.category),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Edit resource',
                              onPressed: onEdit,
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: _primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Delete resource',
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resource.description,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: _primaryGreen,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
