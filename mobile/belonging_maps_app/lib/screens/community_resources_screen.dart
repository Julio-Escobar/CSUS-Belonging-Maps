import 'package:flutter/material.dart';

const Color _primaryGreen = Color(0xFF2F5F3E);
const Color _pageBackground = Color(0xFFF9F5FA);

class CommunityResourcesScreen extends StatelessWidget {
  const CommunityResourcesScreen({super.key});

  // Placeholder resources from the pending Community Resources screen.
  static const List<_CommunityResource> _resources = [
    _CommunityResource(
      title: 'Food Pantry',
      category: 'Food',
      description:
          'Free food resources available for students and community members.',
      icon: Icons.restaurant_outlined,
    ),
    _CommunityResource(
      title: 'Mental Health Services',
      category: 'Health',
      description: 'Counseling and mental health support for students.',
      icon: Icons.favorite_outline,
    ),
    _CommunityResource(
      title: 'Housing Assistance',
      category: 'Housing',
      description:
          'Resources and support for students experiencing housing insecurity.',
      icon: Icons.home_outlined,
    ),
    _CommunityResource(
      title: 'Tutoring Center',
      category: 'Education',
      description: 'Free academic tutoring and support services on campus.',
      icon: Icons.school_outlined,
    ),
    _CommunityResource(
      title: 'Financial Aid Office',
      category: 'Financial',
      description: 'Help with scholarships, grants, and financial assistance.',
      icon: Icons.attach_money_outlined,
    ),
    _CommunityResource(
      title: 'Career Center',
      category: 'Career',
      description:
          'Job placement, resume help, and career counseling services.',
      icon: Icons.work_outline,
    ),
    _CommunityResource(
      title: 'Transportation Services',
      category: 'Transportation',
      description: 'Bus passes and transportation assistance for students.',
      icon: Icons.directions_bus_outlined,
    ),
    _CommunityResource(
      title: 'Childcare Services',
      category: 'Family',
      description:
          'Affordable childcare options available for student parents.',
      icon: Icons.family_restroom_outlined,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text(
          'Community Resources',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _ResourceCard(
            resource: resource,
            onTap: () => _showResourceInformation(context, resource),
          );
        },
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
