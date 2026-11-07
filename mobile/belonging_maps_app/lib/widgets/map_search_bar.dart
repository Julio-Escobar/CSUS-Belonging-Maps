import 'package:flutter/material.dart';

import 'search_suggestion_list.dart';

class MapSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<SearchSuggestion> suggestions;

  /// Shown under the field when a search found nothing (P1-328). Leave null
  /// while there is no query or results are still loading.
  final String? noResultsMessage;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.suggestions = const [],
    this.noResultsMessage,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final Object _tapRegionGroupId = Object();
  bool _hasFocus = false;

  void _onFocusChange(bool hasFocus) {
    if (!mounted || _hasFocus == hasFocus) return;
    setState(() => _hasFocus = hasFocus);
  }

  /// Empties the field and tells the map, which restores every location.
  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapRegionGroupId,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(18),
            child: Focus(
              onFocusChange: _onFocusChange,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) => TextField(
                  controller: widget.controller,
                  onChanged: widget.onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Search map locations',
                    hintText: 'Name, category, or address',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search',
                            onPressed: _clear,
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.noResultsMessage != null)
            _NoResultsMessage(message: widget.noResultsMessage!)
          else
            SearchSuggestionList(
              suggestions: _hasFocus ? widget.suggestions : const [],
            ),
        ],
      ),
    );
  }
}

class _NoResultsMessage extends StatelessWidget {
  final String message;

  const _NoResultsMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const ExcludeSemantics(child: Icon(Icons.search_off)),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}
