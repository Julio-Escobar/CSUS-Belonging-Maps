import 'package:flutter/material.dart';

import '../services/map_location_source.dart';

Future<MapLocation?> showMapLocationBrowser(
  BuildContext context,
  List<MapLocationSource> sources,
) {
  return showModalBottomSheet<MapLocation>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Browse locations',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: sources.isEmpty
                  ? const Center(
                      child: Text('Turn on a map layer to browse locations.'),
                    )
                  : ListView(
                      children: [
                        for (final source in sources)
                          MapLocationSection(
                            key: ValueKey(source.name),
                            source: source,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MapLocationSection extends StatefulWidget {
  final MapLocationSource source;

  const MapLocationSection({super.key, required this.source});

  @override
  State<MapLocationSection> createState() => _MapLocationSectionState();
}

class _MapLocationSectionState extends State<MapLocationSection> {
  final List<MapLocation> _locations = [];
  bool _started = false;
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_started) _loadMore();
  }

  void _openLocation(MapLocation location) {
    Navigator.of(context).pop(location);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _started = true;
      _loading = true;
      _failed = false;
    });

    try {
      final page = await widget.source.loadPage(_locations.length);
      if (!mounted) return;
      setState(() {
        _locations.addAll(page.locations);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          header: true,
          expanded: _expanded,
          label: widget.source.name,
          hint: _expanded ? 'Collapse locations' : 'Expand locations',
          onTap: _toggleExpanded,
          child: ExcludeSemantics(
            child: ListTile(
              title: Text(widget.source.name),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: _toggleExpanded,
            ),
          ),
        ),
        if (_expanded) ...[
          for (var i = 0; i < _locations.length; i++)
            Semantics(
              key: ValueKey('${widget.source.name}-$i'),
              container: true,
              button: true,
              label: 'Open ${_locations[i].name}, ${_locations[i].category}',
              onTap: () => _openLocation(_locations[i]),
              child: ExcludeSemantics(
                child: ListTile(
                  title: Text(_locations[i].name),
                  subtitle: Text(_locations[i].category),
                  onTap: () => _openLocation(_locations[i]),
                ),
              ),
            ),
          if (_loading)
            Semantics(
              liveRegion: true,
              label: 'Loading ${widget.source.name}',
              child: const ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_failed) ...[
            const Text('Could not load locations.'),
            TextButton(onPressed: _loadMore, child: const Text('Retry')),
          ],
          if (_started && !_loading && !_failed && _locations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No locations found.'),
            ),
          if (_started && !_loading && !_failed && _hasMore)
            TextButton(onPressed: _loadMore, child: const Text('Load more')),
        ],
      ],
    );
  }
}
