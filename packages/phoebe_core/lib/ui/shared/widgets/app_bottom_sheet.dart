import 'package:flutter/material.dart';
import '../../core/theme.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  Widget? bottomBar,
  bool showDragHandle = true,
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      final viewInsets = MediaQuery.of(context).viewInsets;

      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 40,
                        offset: const Offset(0, -12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showDragHandle)
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 4),
                              child: Container(
                                width: 36,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: showDragHandle ? 4 : 20,
                                bottom: 24,
                              ),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (bottomBar != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: bottomBar,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
