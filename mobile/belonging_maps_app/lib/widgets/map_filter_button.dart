import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../services/accessibility_theme.dart';

class MapFilterButton extends StatefulWidget {
  final FeatureLayer? featureLayer;
  final String filterField;
  final String label;
  final Future<List<String>> Function()? loadFilters;
  final ValueChanged<String>? onDefinitionExpressionChanged;

  const MapFilterButton({
    super.key,
    required this.featureLayer,
    this.filterField = 'CATEGORY',
    this.label = 'Category',
    this.loadFilters,
    this.onDefinitionExpressionChanged,
  }) : assert(
         featureLayer != null ||
             (loadFilters != null && onDefinitionExpressionChanged != null),
         'Provide a feature layer or controlled filter callbacks.',
       );

  @override
  State<MapFilterButton> createState() => _MapFilterButtonState();
}

class _MapFilterButtonState extends State<MapFilterButton> {
  final Set<String> _selectedFilters = <String>{};
  bool _isActive = false;

  Future<List<String>> _loadFilters() async {
    final values = widget.loadFilters == null
        ? await _queryFilters()
        : await widget.loadFilters!();
    return values.toSet().toList()..sort();
  }

  Future<List<String>> _queryFilters() async {
    final layer = widget.featureLayer;
    if (layer == null) {
      throw StateError('A feature layer is required to load filters.');
    }
    final featureTable = layer.featureTable as ServiceFeatureTable;
    final queryParams = QueryParameters()..whereClause = '1=1';
    final result = await featureTable.queryFeatures(queryParams);
    final values = <String>{};

    for (final feature in result.features()) {
      final value = feature.attributes[widget.filterField]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        values.add(value);
      }
    }

    return values.toList();
  }

  void _applyFilter() {
    if (_selectedFilters.isEmpty) {
      _updateDefinitionExpression('');
      setState(() => _isActive = false);
      _announce('Showing all ${widget.label.toLowerCase()} locations.');
      return;
    }

    final quoted = _selectedFilters.map((filter) => "'$filter'").join(', ');
    _updateDefinitionExpression('${widget.filterField} IN ($quoted)');
    setState(() => _isActive = true);
    _announce(
      'Applied ${_selectedFilters.length} ${widget.label.toLowerCase()} filter${_selectedFilters.length == 1 ? '' : 's'}.',
    );
  }

  void _announce(String message) {
    SemanticsService.announce(message, Directionality.of(context));
  }

  void _updateDefinitionExpression(String expression) {
    widget.featureLayer?.definitionExpression = expression;
    widget.onDefinitionExpressionChanged?.call(expression);
  }

  void _resetFilter() {
    setState(() {
      _selectedFilters.clear();
      _isActive = false;
    });
    _updateDefinitionExpression('');
    _announce('Cleared all ${widget.label.toLowerCase()} filters.');
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AccessibilityColors.of(context).cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colors = AccessibilityColors.of(context);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by ${widget.label}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      if (tempSelected.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setSheetState(() => tempSelected.clear());
                          },
                          child: Text(
                            'Clear all',
                            style: TextStyle(color: colors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    )
                  else if (_availableFilters.isEmpty)
                    Text(
                      'No filter options available.',
                      style: TextStyle(color: colors.secondaryText),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableFilters.map((filter) {
                        final isSelected = tempSelected.contains(filter);
                        return FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.onPrimary
                                  : colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              if (selected) {
                                tempSelected.add(filter);
                              } else {
                                tempSelected.remove(filter);
                              }
                            });
                          },
                          selectedColor: colors.primary,
                          backgroundColor: colors.cardBackground,
                          checkmarkColor: colors.onPrimary,
                          side: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilters
                            ..clear()
                            ..addAll(tempSelected);
                        });
                        _applyFilter();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        tempSelected.isEmpty
                            ? 'Show All'
                            : 'Apply (${tempSelected.length} selected)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedFilters
        ..clear()
        ..addAll(selected);
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isActive ? colors.primary : colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showFilterSheet(context),
            child: Semantics(
              button: true,
              label: 'Filter map locations by ${widget.label}',
              onTap: () => _showFilterSheet(context),
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: _isActive ? colors.onPrimary : colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isActive ? 'Filtered' : 'Filter',
                        style: TextStyle(
                          color: _isActive ? colors.onPrimary : colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isActive) ...[
            const SizedBox(height: 4),
            IconButton(
              onPressed: _resetFilter,
              tooltip: 'Clear map location filters',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(Icons.close, size: 16, color: colors.onPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapFilterSheet extends StatefulWidget {
  const _MapFilterSheet({
    required this.label,
    required this.initiallySelected,
    required this.loadFilters,
  });

  final String label;
  final Set<String> initiallySelected;
  final Future<List<String>> Function() loadFilters;

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  late final Set<String> _selected = Set<String>.from(widget.initiallySelected);
  List<String> _available = const <String>[];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final values = await widget.loadFilters();
      if (!mounted) return;
      setState(() {
        _available = values.toSet().toList()..sort();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _toggleFilter(String filter, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(filter);
      } else {
        _selected.remove(filter);
      }
    });
  }

  void _apply() => Navigator.of(context).pop(Set<String>.from(_selected));

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final canTakeAction = !_isLoading;
    final actionLabel = _hasError
        ? 'Retry'
        : _selected.isEmpty
        ? 'Show All'
        : 'Apply (${_selected.length} selected)';
    final actionSemantics = _hasError ? 'Retry filter options' : actionLabel;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Material(
          color: colors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Semantics(
            namesRoute: true,
            label: 'Filter map locations by ${widget.label}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outline.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Filter by ${widget.label}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: colors.action),
                      ),
                    ],
                  ),
                ),
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(_selected.clear),
                        child: const Text('Clear all'),
                      ),
                    ),
                  ),
                Expanded(child: _buildOptions(scrollController, colors)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SizedBox(
                    height: 48,
                    child: Semantics(
                      button: canTakeAction,
                      label: actionSemantics,
                      onTap: canTakeAction
                          ? (_hasError ? _load : _apply)
                          : null,
                      child: ExcludeSemantics(
                        child: ElevatedButton(
                          onPressed: canTakeAction
                              ? (_hasError ? _load : _apply)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(
    ScrollController scrollController,
    AccessibilityColors colors,
  ) {
    if (_isLoading) {
      return ListView(
        controller: scrollController,
        children: [
          Semantics(
            liveRegion: true,
            label: 'Loading filter options',
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
          ),
        ],
      );
    }

    if (_hasError) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              'Could not load filter options.',
              style: TextStyle(
                color: colors.destructive,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: TextStyle(color: colors.secondaryText),
          ),
        ],
      );
    }

    if (_available.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              'No filter options available.',
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _available.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final filter = _available[index];
        final selected = _selected.contains(filter);
        return Semantics(
          button: true,
          label: filter,
          toggled: selected,
          onTap: () => _toggleFilter(filter, !selected),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: FilterChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: selected ? colors.onPrimary : colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: selected,
                onSelected: (value) => _toggleFilter(filter, value),
                selectedColor: colors.primary,
                backgroundColor: colors.cardBackground,
                checkmarkColor: colors.onPrimary,
                side: BorderSide(color: colors.outline, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
