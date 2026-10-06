import 'package:flutter/material.dart';

/// Reusable favorite action shared by task cards and task details.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.compact = false,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isFavorite
        ? const Color(0xFFF59E0B)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return IconButton(
      onPressed: onPressed,
      visualDensity: compact ? VisualDensity.compact : null,
      tooltip: isFavorite ? 'Убрать из избранного' : 'Добавить в избранное',
      icon: Icon(
        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
        color: color,
      ),
    );
  }
}
