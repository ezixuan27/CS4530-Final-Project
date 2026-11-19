import 'package:flutter/material.dart';

/// A button on a placeholder screen that navigates to [route].
class PlaceholderAction {
  final String label;
  final String route;
  final Object? arguments;

  /// Replace the current screen instead of pushing on top (e.g. after sign in).
  final bool replace;

  const PlaceholderAction(
    this.label,
    this.route, {
    this.arguments,
    this.replace = false,
  });
}

/// Temporary scaffold for screens that are not built yet.
/// Replace it with the real UI when you implement your story.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String story;
  final String owner;
  final List<PlaceholderAction> actions;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.story,
    required this.owner,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.construction,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                story,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '$owner · TODO',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              for (final action in actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: () => action.replace
                        ? Navigator.pushReplacementNamed(
                            context,
                            action.route,
                            arguments: action.arguments,
                          )
                        : Navigator.pushNamed(
                            context,
                            action.route,
                            arguments: action.arguments,
                          ),
                    child: Text(action.label),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
