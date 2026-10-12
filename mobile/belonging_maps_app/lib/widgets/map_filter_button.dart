import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

// Color constants matching the app theme
const Color _filterChipSelected = Color(0xFF2F5F3E);
const Color _filterChipUnselected = Colors.white;
const Color _filterChipSelectedText = Colors.white;
const Color _filterChipUnselectedText = Color(0xFF2F5F3E);

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
  final Set<String> _selectedFilters = {};
  List<String> _availableFilters = [];
  bool _isLoading = false;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoading = true);
    try {
      final values = widget.loadFilters == null
          ? await _queryFilters()
          : await widget.loadFilters!();
      if (!mounted) return;

      setState(() {
        _availableFilters = values.toSet().toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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

    return values.toList()..sort();
  }

  void _applyFilter() {
    if (_selectedFilters.isEmpty) {
      _updateDefinitionExpression('');
      setState(() => _isActive = false);
    } else {
      final quoted = _selectedFilters.map((f) => "'$f'").join(', ');
      _updateDefinitionExpression('${widget.filterField} IN ($quoted)');
      setState(() => _isActive = true);
    }
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
  }

  void _showFilterSheet(BuildContext context) {
    final tempSelected = Set<String>.from(_selectedFilters);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F5F3E),
                        ),
                      ),
                      if (tempSelected.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setSheetState(() => tempSelected.clear());
                          },
                          child: const Text(
                            'Clear all',
                            style: TextStyle(color: Color(0xFF2F5F3E)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2F5F3E),
                      ),
                    )
                  else if (_availableFilters.isEmpty)
                    const Text(
                      'No filter options available.',
                      style: TextStyle(color: Colors.grey),
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
                                  ? _filterChipSelectedText
                                  : _filterChipUnselectedText,
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
                          selectedColor: _filterChipSelected,
                          backgroundColor: _filterChipUnselected,
                          checkmarkColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF2F5F3E),
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
                        backgroundColor: const Color(0xFF2F5F3E),
                        foregroundColor: Colors.white,
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isActive ? const Color(0xFF2F5F3E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _showFilterSheet(context),
            child: Semantics(
              button: true,
              label: 'Filter map locations by ${widget.label}',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: _isActive
                            ? Colors.white
                            : const Color(0xFF2F5F3E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isActive
                            ? 'Filtered (${_selectedFilters.length})'
                            : 'Filter',
                        style: TextStyle(
                          color: _isActive
                              ? Colors.white
                              : const Color(0xFF2F5F3E),
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
            const SizedBox(width: 6),
            IconButton(
              onPressed: _resetFilter,
              tooltip: 'Clear map location filters',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
