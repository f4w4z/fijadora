import 'package:flutter/material.dart';
import '../../core/utilities/responsive_helpers.dart';
import '../../core/theme.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  Widget? bottomBar,
  bool showDragHandle = true,
  double maxHeight = 0.8,
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxHeight,
    ),
    builder: (context) {
      final bottom = MediaQuery.of(context).viewInsets.bottom;

      Widget sheetContent = Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Container(
            margin: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
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
                              fit: FlexFit.loose,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.only(
                                  left: context.pagePad,
                                  right: context.pagePad,
                                  top: showDragHandle ? 4 : AppSpacing.xl,
                                  bottom: AppSpacing.xxl,
                                ),
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (bottomBar != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: bottomBar,
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      return sheetContent;
    },
  );
}
