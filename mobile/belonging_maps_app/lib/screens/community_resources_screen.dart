import 'package:flutter/material.dart';
  // When authentication is implemented, replace this with actual user role check
  final bool isAdmin = true;

const Color _primaryGreen = Color(0xFF2F5F3E);

class CommunityResourcesScreen extends StatefulWidget {

  const CommunityResourcesScreen({super.key});

  @override
  State<CommunityResourcesScreen> createState() => _CommunityResourcesScreenState();
}
class _CommunityResourcesScreenState extends State<CommunityResourcesScreen> {
  // Placeholder resources — replace with real data when available
  final List<Map<String, String>> _resources = [
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

void _addResource() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    String selectedIcon = 'food';

    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (context) { 
      return StatefulBuilder(
          // Needed so the dropdown can update inside the dialog
          builder: (context, setDialogState) {
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
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedIcon,
                        decoration: const InputDecoration(labelText: 'Icon'),
                        items: const [
                          DropdownMenuItem(value: 'food', child: Text('Food')),
                          DropdownMenuItem(value: 'health', child: Text('Health')),
                          DropdownMenuItem(value: 'housing', child: Text('Housing')),
                          DropdownMenuItem(value: 'education', child: Text('Education')),
                          DropdownMenuItem(value: 'financial', child: Text('Financial')),
                          DropdownMenuItem(value: 'career', child: Text('Career')),
                          DropdownMenuItem(value: 'transportation', child: Text('Transportation')),
                          DropdownMenuItem(value: 'family', child: Text('Family')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedIcon = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _resources.add({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'category': categoryController.text,
                          'icon': selectedIcon,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
// Function to delete a resource within the list, showing a confirmation dialog before deletion
void _deleteResource (int index) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog (
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
          onPressed: () {
            setState(() {
              _resources.removeAt(index);
            });
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resource deleted')),
            );
          },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
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
        actions: [
          // When authentication is implemented, replace this with actual user role check
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              tooltip: 'Add resource',
              onPressed: _addResource,
            ),
        ],
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
            isAdmin: isAdmin,
            onDelete: () => _deleteResource(index),
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
  final bool isAdmin;
  final VoidCallback onDelete;

  const _ResourceCard({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.isAdmin,
    required this.onDelete,
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
                      // Show delete icon only for admin users
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
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