import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/hamburger_menu.dart';

const Color _primaryGreen = Color(0xFF2F5F3E);
const Color _pageBackground = Color(0xFFF9F5FA);

class CommunityResourcesScreen extends StatefulWidget {
  const CommunityResourcesScreen({super.key});

  @override
  State<CommunityResourcesScreen> createState() =>
      _CommunityResourcesScreenState();
}

class _CommunityResourcesScreenState extends State<CommunityResourcesScreen> {
  final List<_CommunityResource> _resources = [
    const _CommunityResource(
      title: 'Food Pantry',
      category: 'Food',
      description:
          'Free food resources available for students and community members.',
      icon: Icons.restaurant_outlined,
    ),
    const _CommunityResource(
      title: 'Mental Health Services',
      category: 'Health',
      description: 'Counseling and mental health support for students.',
      icon: Icons.favorite_outline,
    ),
    const _CommunityResource(
      title: 'Housing Assistance',
      category: 'Housing',
      description:
          'Resources and support for students experiencing housing insecurity.',
      icon: Icons.home_outlined,
    ),
    const _CommunityResource(
      title: 'Tutoring Center',
      category: 'Education',
      description: 'Free academic tutoring and support services on campus.',
      icon: Icons.school_outlined,
    ),
    const _CommunityResource(
      title: 'Financial Aid Office',
      category: 'Financial',
      description: 'Help with scholarships, grants, and financial assistance.',
      icon: Icons.attach_money_outlined,
    ),
    const _CommunityResource(
      title: 'Career Center',
      category: 'Career',
      description:
          'Job placement, resume help, and career counseling services.',
      icon: Icons.work_outline,
    ),
    const _CommunityResource(
      title: 'Transportation Services',
      category: 'Transportation',
      description: 'Bus passes and transportation assistance for students.',
      icon: Icons.directions_bus_outlined,
    ),
    const _CommunityResource(
      title: 'Childcare Services',
      category: 'Family',
      description:
          'Affordable childcare options available for student parents.',
      icon: Icons.family_restroom_outlined,
    ),
  ];

  static IconData _iconForKey(String iconKey) {
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

  void _addResource() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    String selectedIcon = 'food';
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContextBuild, dialogSetState) {
            return AlertDialog(
              title: const Text('Add Resource'),
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedIcon,
                        decoration: const InputDecoration(labelText: 'Icon'),
                        items: const [
                          DropdownMenuItem(value: 'food', child: Text('Food')),
                          DropdownMenuItem(
                            value: 'health',
                            child: Text('Health'),
                          ),
                          DropdownMenuItem(
                            value: 'housing',
                            child: Text('Housing'),
                          ),
                          DropdownMenuItem(
                            value: 'education',
                            child: Text('Education'),
                          ),
                          DropdownMenuItem(
                            value: 'financial',
                            child: Text('Financial'),
                          ),
                          DropdownMenuItem(
                            value: 'career',
                            child: Text('Career'),
                          ),
                          DropdownMenuItem(
                            value: 'transportation',
                            child: Text('Transportation'),
                          ),
                          DropdownMenuItem(
                            value: 'family',
                            child: Text('Family'),
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
                    backgroundColor: _primaryGreen,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      print('ADD RESOURCE SUBMIT: ${titleController.text.trim()}');
                      setState(() {
                        _resources.add(
                          _CommunityResource(
                            title: titleController.text.trim(),
                            category: categoryController.text.trim(),
                            description: descriptionController.text.trim(),
                            icon: _iconForKey(selectedIcon),
                          ),
                        );
                      });
                      print('RESOURCE COUNT: ${_resources.length}');
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
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
    _CommunityResource resource,
  ) {
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

  void _editResource(int index) {
    final resource = _resources[index];
    final titleController = TextEditingController(text: resource.title);
    final descriptionController = TextEditingController(text: resource.description);
    final categoryController = TextEditingController(text: resource.category);
    String selectedIcon = switch (resource.icon) {
      Icons.restaurant_outlined => 'food',
      Icons.favorite_outline => 'health',
      Icons.home_outlined => 'housing',
      Icons.school_outlined => 'education',
      Icons.attach_money_outlined => 'financial',
      Icons.work_outline => 'career',
      Icons.directions_bus_outlined => 'transportation',
      Icons.family_restroom_outlined => 'family',
      _ => 'food',
    };
    final formKey = GlobalKey<FormState>();
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContextBuild, dialogSetState) {
            return AlertDialog(
              title: const Text('Edit Resource'),
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedIcon,
                        decoration: const InputDecoration(labelText: 'Icon'),
                        items: const [
                          DropdownMenuItem(value: 'food', child: Text('Food')),
                          DropdownMenuItem(
                            value: 'health',
                            child: Text('Health'),
                          ),
                          DropdownMenuItem(
                            value: 'housing',
                            child: Text('Housing'),
                          ),
                          DropdownMenuItem(
                            value: 'education',
                            child: Text('Education'),
                          ),
                          DropdownMenuItem(
                            value: 'financial',
                            child: Text('Financial'),
                          ),
                          DropdownMenuItem(
                            value: 'career',
                            child: Text('Career'),
                          ),
                          DropdownMenuItem(
                            value: 'transportation',
                            child: Text('Transportation'),
                          ),
                          DropdownMenuItem(
                            value: 'family',
                            child: Text('Family'),
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
                    backgroundColor: _primaryGreen,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _resources[index] = _CommunityResource(
                          title: titleController.text.trim(),
                          category: categoryController.text.trim(),
                          description: descriptionController.text.trim(),
                          icon: _iconForKey(selectedIcon),
                        );
                      });
                      Navigator.of(dialogContext).pop();
                      scaffoldMessenger?.showSnackBar(
                        const SnackBar(content: Text('Resource updated')),
                      );
                    }
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteResource(int index) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
                setState(() {
                  _resources.removeAt(index);
                });
                Navigator.of(dialogContext).pop();
                scaffoldMessenger?.showSnackBar(
                  const SnackBar(content: Text('Resource deleted')),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.isAdmin;
    // final isAdmin = true; // For testing purposes, set to true. Change to AuthService.isAdmin in production.

    return HamburgerMenu(
      title: 'Community Resources',
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Add resource',
            onPressed: _addResource,
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
              onTap: () => _showResourceInformation(context, resource),
              onEdit: isAdmin ? () => _editResource(index) : null,
              onDelete: isAdmin ? () => _deleteResource(index) : null,
            );
          },
        ),
      ),
    );
  }
}

class _CommunityResource {
  final String title;
  final String category;
  final String description;
  final IconData icon;

  const _CommunityResource({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
  });
}

class _ResourceCard extends StatelessWidget {
  final _CommunityResource resource;
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
                            if (onEdit != null) ...[
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
                            ],
                            if (onDelete != null) ...[
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
