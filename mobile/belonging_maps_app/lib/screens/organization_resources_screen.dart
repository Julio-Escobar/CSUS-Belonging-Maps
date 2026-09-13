import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'Organization Resources',
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
              onTap: () => _showResourceInformation(resource),
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
  final VoidCallback onTap;

  const _ResourceCard({required this.resource, required this.onTap});

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
