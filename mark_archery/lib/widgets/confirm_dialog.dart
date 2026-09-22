import 'package:flutter/material.dart';

/// Shows a Cancel/confirm [AlertDialog] and returns true only if the user
/// tapped the confirm action. [isDestructive] tints the confirm label red,
/// matching the delete-confirmation dialogs used throughout the app.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool isDestructive = true,
}) async {
  final theme = Theme.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: isDestructive
                ? TextStyle(color: theme.colorScheme.error)
                : null,
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
