import 'package:flutter/material.dart';

import '../models/somos_campus_resource.dart';

/// Shows the SOMOS campus resources in a scrollable list and returns the
/// resource the user tapped, or null when the sheet is dismissed.
Future<SomosCampusResource?> showSomosCampusResourceList(
  BuildContext context,
  List<SomosCampusResource> resources,
) {
  return showModalBottomSheet<SomosCampusResource>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'SOMOS Campus Resources',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a resource to view it on the map.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: resources.isEmpty
                  ? const Center(
                      child: Text('No campus resources are available.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: resources.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final resource = resources[index];
                        final title = '${resource.number}. ${resource.name}';

                        return Semantics(
                          button: true,
                          label: 'Open resource $title',
                          child: ExcludeSemantics(
                            child: ListTile(
                              title: Text(title),
                              subtitle: Text(resource.locationLabel),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).pop(resource),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
