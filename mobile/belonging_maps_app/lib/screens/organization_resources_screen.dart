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

  // Admin only
  void _showAddResourceDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              setState(() {
                _resources.add(
                  _OrganizationResource(
                    title: titleController.text.trim(),
                    category: categoryController.text.trim(),
                    description: descriptionController.text.trim(),
                    icon: Icons.groups_outlined,
                  ),
                );
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
    setState(() => _resources.removeAt(index));
  }

  @override
  //Check if the user is an admin
  Widget build(BuildContext context) {
    final isAdmin = AuthService.isAdmin;

    return HamburgerMenu(
      title: 'Organization Resources',
      actions: [
        // Admint add resource button
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: 'Add resource',
            onPressed: _showAddResourceDialog,
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
  final VoidCallback onDelete;

  const _ResourceCard({
    required this.resource,
    required this.isAdmin,
    required this.onTap,
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
                // Delete button
                if (isAdmin)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Delete resource',
                    onPressed: onDelete,
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
