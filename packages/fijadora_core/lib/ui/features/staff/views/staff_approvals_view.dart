import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../domain/models/job_status.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../services/view_models/jobs_view_model.dart';
import 'manager_job_detail_view.dart';


class StaffApprovalsView extends ConsumerStatefulWidget {
  const StaffApprovalsView({super.key});

  @override
  ConsumerState<StaffApprovalsView> createState() => _StaffApprovalsViewState();
}

class _StaffApprovalsViewState extends ConsumerState<StaffApprovalsView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = ref.read(notificationServiceProvider);
    final jobsRepo = ref.read(jobsRepositoryProvider);
    final jobsAsync = ref.watch(jobsStreamProvider);

    final cachedJobs = jobsAsync.valueOrNull;
    final approvals = cachedJobs != null
        ? (cachedJobs.where((j) => j.status == JobStatus.waitingApproval).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        : <MaintenanceJob>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Approvals', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                  ),
                  if (approvals.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${approvals.length} pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: jobsAsync.maybeWhen(
                data: (jobs) {
                  final approvalsList = jobs
                      .where((j) => j.status == JobStatus.waitingApproval)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (approvalsList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.checkmark_seal_fill, size: 48, color: const Color(0xFF34C759).withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No pending approvals', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  final workers = ref
                      .read(authRepositoryProvider)
                      .getAllWorkers()
                      .map((w) => {'id': w.id, 'name': w.name})
                      .toList();

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 120),
                    itemCount: approvalsList.length,
                    itemBuilder: (context, index) {
                      final job = approvalsList[index];
                      return _ApprovalCard(
                        job: job,
                        workers: workers,
                        onApprove: () async {
                          try {
                            await jobsRepo.updateJobStatus(jobId: job.id, status: JobStatus.completed);
                            notificationService.sendNotification(
                              title: 'Job Approved',
                              body: '${job.tradeType.displayName} job has been approved',
                            );
                            if (context.mounted) {
                              context.showSnackBar('Job approved', type: SnackBarType.success);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnackBar('Failed to approve: $e', type: SnackBarType.error);
                            }
                          }
                        },
                        onReject: () async {
                          try {
                            await ref.read(jobsViewModelProvider).rejectJob(job.id);
                            if (context.mounted) {
                              context.showSnackBar('Job rejected & returned to pending list', type: SnackBarType.success);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnackBar('Failed to reject: $e', type: SnackBarType.error);
                            }
                          }
                        },

                      );
                    },
                  );
                },
                orElse: () {
                  if (jobsAsync.hasError) {
                    return Center(child: Text('Error: ${jobsAsync.error}'));
                  }
                  return const ShimmerApprovalCard(count: 2);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.job,
    required this.workers,
    required this.onApprove,
    required this.onReject,
  });

  final MaintenanceJob job;
  final List<Map<String, String>> workers;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color _tradeColor(TradeType type) {
    switch (type) {
      case TradeType.interiorDesign:    return const Color(0xFF8E44AD);
      case TradeType.electrical:        return const Color(0xFFFFB300);
      case TradeType.plumbing:          return const Color(0xFF1E88E5);
      case TradeType.masonry:           return const Color(0xFF8D6E63);
      case TradeType.tiling:            return const Color(0xFF00ACC1);
      case TradeType.designConsultation:return const Color(0xFFEC407A);
      case TradeType.acEngineering:     return const Color(0xFF26A69A);
      case TradeType.kitchenDesigns:    return const Color(0xFF78909C);
      case TradeType.cleaning:          return const Color(0xFF1E88E5);
      case TradeType.gardening:         return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tradeColor = _tradeColor(job.tradeType);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerJobDetailView(
            job: job,
            workers: workers,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEBEBEB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored Top Header Banner
              Container(
                color: tradeColor.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(job.tradeType.icon, size: 16, color: tradeColor),
                    const SizedBox(width: 8),
                    Text(
                      job.tradeType.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tradeColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'REVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      job.description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Proof of Work Image Previews
                    if (job.images.isNotEmpty) ...[
                      Text(
                        'Proof of Work (${job.images.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: job.images.length.clamp(0, 4),
                          itemBuilder: (context, imgIdx) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: job.images[imgIdx],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme.colorScheme.surfaceContainerHigh,
                                    child: const Center(child: CupertinoActivityIndicator(radius: 8)),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: theme.colorScheme.surfaceContainerHigh,
                                    child: const Icon(CupertinoIcons.photo, size: 18),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Info Rows (Location & Scheduled)
                    Row(
                      children: [
                        Icon(CupertinoIcons.location_solid, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            job.address,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Scheduled: ${job.scheduleDateTime != null ? _formatDate(job.scheduleDateTime!) : 'Not scheduled'}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // View details hint
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.eye,
                          size: 13,
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to view job timeline & completion details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Actions Button Row
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedTapScale(
                            onTap: onReject,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.xmark, size: 14, color: theme.colorScheme.error),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reject',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedTapScale(
                            onTap: onApprove,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF34C759).withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.checkmark_alt, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Approve',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
