import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

// Color constants matching the app theme
const Color _filterChipSelected = Color(0xFF2F5F3E);
const Color _filterChipUnselected = Colors.white;
const Color _filterChipSelectedText = Colors.white;
const Color _filterChipUnselectedText = Color(0xFF2F5F3E);

class MapFilterButton extends StatefulWidget {
  final FeatureLayer featureLayer;
  final String filterField;
  final String label;

  const MapFilterButton({
    super.key,
    required this.featureLayer,
    this.filterField = 'CATEGORY',
    this.label = 'Category',
  });

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
    final featureTable =
        widget.featureLayer.featureTable as ServiceFeatureTable;

    final queryParams = QueryParameters()
      ..whereClause = '1=1';

    final result = await featureTable.queryFeatures(queryParams);
    final values = <String>{};

    for (final feature in result.features()) {
      final value =
          feature.attributes[widget.filterField]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        values.add(value);
      }
    }

    setState(() {
      _availableFilters = values.toList()..sort();
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Error loading filters: $e');
    setState(() => _isLoading = false);
  }
}

  void _applyFilter() {
    if (_selectedFilters.isEmpty) {
      widget.featureLayer.definitionExpression = '';
      setState(() => _isActive = false);
    } else {
      final quoted =
          _selectedFilters.map((f) => "'$f'").join(', ');
      widget.featureLayer.definitionExpression =
          '${widget.filterField} IN ($quoted)';
      setState(() => _isActive = true);
    }
  }

  void _resetFilter() {
    setState(() {
      _selectedFilters.clear();
      _isActive = false;
    });
    widget.featureLayer.definitionExpression = '';
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
    return GestureDetector(
      onTap: () => _showFilterSheet(context),
      child: Container(
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
            Icon(
              Icons.filter_list,
              size: 18,
              color: _isActive ? Colors.white : const Color(0xFF2F5F3E),
            ),
            const SizedBox(width: 6),
            Text(
              _isActive
                  ? 'Filtered (${_selectedFilters.length})'
                  : 'Filter',
              style: TextStyle(
                color: _isActive ? Colors.white : const Color(0xFF2F5F3E),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (_isActive) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _resetFilter,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}