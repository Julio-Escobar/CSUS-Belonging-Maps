import 'package:flutter/material.dart';

class SearchSuggestion {
  final String title;
  final String? subtitle;
  final VoidCallback onSelected;

  const SearchSuggestion({
    required this.title,
    this.subtitle,
    required this.onSelected,
  });
}

class SearchSuggestionList extends StatelessWidget {
  final List<SearchSuggestion> suggestions;

  const SearchSuggestionList({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Search suggestions',
      child: Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Semantics(
              button: true,
              label: suggestion.subtitle == null
                  ? 'Open ${suggestion.title}'
                  : 'Open ${suggestion.title}, ${suggestion.subtitle}',
              onTap: suggestion.onSelected,
              child: ExcludeSemantics(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.search),
                  title: Text(suggestion.title),
                  subtitle: suggestion.subtitle == null
                      ? null
                      : Text(suggestion.subtitle!),
                  onTap: suggestion.onSelected,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
