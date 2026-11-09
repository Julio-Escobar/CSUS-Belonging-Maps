import 'package:flutter/material.dart';

import '../services/favorites_store.dart';

class FavoriteToggleButton extends StatefulWidget {
  final FavoriteEntry favorite;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;
  final double iconSize;

  const FavoriteToggleButton({
    super.key,
    required this.favorite,
    this.onChanged,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton> {
  final FavoritesStore _store = FavoritesStore.instance;
  bool? _isFavorite;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refreshFavoriteState);
    _refreshFavoriteState();
  }

  @override
  void didUpdateWidget(covariant FavoriteToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorite.type != widget.favorite.type ||
        oldWidget.favorite.id != widget.favorite.id) {
      _refreshFavoriteState();
    }
  }

  @override
  void dispose() {
    _store.removeListener(_refreshFavoriteState);
    super.dispose();
  }

  Future<void> _refreshFavoriteState() async {
    try {
      final isFavorite = await _store.contains(
        widget.favorite.type,
        widget.favorite.id,
      );
      if (mounted) setState(() => _isFavorite = isFavorite);
    } catch (error) {
      if (mounted) {
        setState(() => _isFavorite = false);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not load favorites: $error')),
        );
      }
    }
  }

  Future<void> _toggle() async {
    if (_isFavorite == null || _isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final isFavorite = _isFavorite!;
      if (isFavorite) {
        await _store.remove(widget.favorite.type, widget.favorite.id);
      } else {
        await _store.save(widget.favorite);
      }
      if (!mounted) return;
      setState(() => _isFavorite = !isFavorite);
      widget.onChanged?.call(!isFavorite);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not update favorites: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = _isFavorite ?? false;
    final actionLabel = isFavorite
        ? 'Remove ${widget.favorite.title} from favorites'
        : 'Add ${widget.favorite.title} to favorites';

    return IconButton(
      onPressed: _isFavorite == null || _isUpdating ? null : _toggle,
      tooltip: actionLabel,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: _isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : widget.iconColor,
              size: widget.iconSize,
            ),
    );
  }
}
