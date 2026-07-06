import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../core/utilities/responsive_helpers.dart';

void showJobPreview(BuildContext context, WidgetRef ref, MaintenanceJob job, String? workerId) {
  final theme = Theme.of(context);
  final statusColor = job.status.color(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return Container(
        padding: EdgeInsets.fromLTRB(ctx.pagePad, AppSpacing.xl, ctx.pagePad, 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(job.tradeType.icon, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.tradeType.displayName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text('Available Job', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.status.displayName.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(CupertinoIcons.location, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(job.address, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.3)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.calendar, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(job.scheduleDateTime?.formattedShort ?? 'Not scheduled', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                job.description,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Consumer(
                builder: (context, ref, _) {
                  return AnimatedTapScale(
                    onTap: () {
                      if (workerId == null) return;
                      ref.read(jobsRepositoryProvider).assignWorker(
                        jobId: job.id,
                        workerId: workerId,
                      ).then((_) {
                        ref.read(notificationServiceProvider).sendNotification(
                          title: 'Job Grabbed!',
                          body: 'You claimed the ${job.tradeType.displayName} request.',
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          context.showSnackBar('Job claimed!', type: SnackBarType.success);
                        }
                      }).catchError((e) {
                        if (context.mounted) {
                          context.showSnackBar('Failed: $e', type: SnackBarType.error);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.hand_draw, size: 18, color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 10),
                          Text(
                            'Grab This Job',
                            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ],
          ),
        ),
      );
    },
  );
}

class GrabButton extends ConsumerWidget {
  const GrabButton({super.key, required this.job, required this.workerId});

  final MaintenanceJob job;
  final String? workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: () {
        if (workerId == null) return;
        ref.read(jobsRepositoryProvider).assignWorker(
          jobId: job.id,
          workerId: workerId!,
        ).then((_) {
          ref.read(notificationServiceProvider).sendNotification(
            title: 'Job Grabbed!',
            body: 'You claimed the ${job.tradeType.displayName} request.',
          );
          if (context.mounted) {
            context.showSnackBar('Job claimed!', type: SnackBarType.success);
          }
        }).catchError((e) {
          if (context.mounted) {
            context.showSnackBar('Failed: $e', type: SnackBarType.error);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.hand_draw,
                size: 13, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 6),
            Text(
              'Grab',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
