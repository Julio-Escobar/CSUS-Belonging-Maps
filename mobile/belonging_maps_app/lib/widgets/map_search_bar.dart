import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import 'search_suggestion_list.dart';

class MapSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<SearchSuggestion> suggestions;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.suggestions = const [],
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

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    return TapRegion(
      groupId: _tapRegionGroupId,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colors.cardBackground,
            elevation: 6,
            borderRadius: BorderRadius.circular(18),
            child: Focus(
              onFocusChange: _onFocusChange,
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                style: TextStyle(color: colors.primaryText),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  labelText: 'Search map locations',
                  hintText: 'Search locations...',
                  prefixIcon: Icon(Icons.search, color: colors.primary),
                  border: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.primary, width: 2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          SearchSuggestionList(
            suggestions: _hasFocus ? widget.suggestions : const [],
          ),
        ],
      ),
    );
  }
}
