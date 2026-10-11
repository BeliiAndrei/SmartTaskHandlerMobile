import 'package:flutter/material.dart';

import 'favorites_scope.dart';

Future<void> toggleFavoriteWithFeedback(BuildContext context, int id) async {
  final favorites = FavoritesScope.of(context);
  try {
    final isFavorite = await favorites.toggle(id);
    if (!context.mounted) return;
    _showMessage(
      context,
      isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного',
    );
  } catch (_) {
    if (!context.mounted) return;
    _showMessage(context, 'Не удалось сохранить избранное', isError: true);
  }
}

void _showMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: isError
            ? const Color(0xFFB91C1C)
            : const Color(0xFF15803D),
      ),
    );
}
