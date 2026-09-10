import 'package:flutter/material.dart';

const Color _primaryGreen = Color(0xFF2F5F3E);

class CommunityResourcesScreen extends StatelessWidget {
  const CommunityResourcesScreen({super.key});

  // Placeholder resources — replace with real data when available
  static const List<Map<String, String>> _resources = [
    {
      'title': 'Food Pantry',
      'description': 'Free food resources available for students and community members.',
      'category': 'Food',
      'icon': 'food',
    },
    {
      'title': 'Mental Health Services',
      'description': 'Counseling and mental health support for students.',
      'category': 'Health',
      'icon': 'health',
    },
    {
      'title': 'Housing Assistance',
      'description': 'Resources and support for students experiencing housing insecurity.',
      'category': 'Housing',
      'icon': 'housing',
    },
    {
      'title': 'Tutoring Center',
      'description': 'Free academic tutoring and support services on campus.',
      'category': 'Education',
      'icon': 'education',
    },
    {             
      'title': 'Financial Aid Office',
      'description': 'Help with scholarships, grants, and financial assistance.',
      'category': 'Financial',
      'icon': 'financial',
    },
    {
      'title': 'Career Center',
      'description': 'Job placement, resume help, and career counseling services.',
      'category': 'Career',
      'icon': 'career',
    },
    {
      'title': 'Transportation Services',
      'description': 'Bus passes and transportation assistance for students.',
      'category': 'Transportation',
      'icon': 'transportation',
    },
    {
      'title': 'Childcare Services',
      'description': 'Affordable childcare options available for student parents.',
      'category': 'Family',
      'icon': 'family',
    },
  ];

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'health':
        return Icons.favorite_outline;
      case 'housing':
        return Icons.home_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'financial':
        return Icons.attach_money_outlined;
      case 'career':
        return Icons.work_outline;
      case 'transportation':
        return Icons.directions_bus_outlined;
      case 'family':
        return Icons.family_restroom_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Resources',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _ResourceCard(
            title: resource['title']!,
            description: resource['description']!,
            category: resource['category']!,
            icon: _getIcon(resource['icon']!),
          );
        },
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final IconData icon;

  const _ResourceCard({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2F5F3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}