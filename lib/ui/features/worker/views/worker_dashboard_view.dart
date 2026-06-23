import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../admin/view_models/dispatch_provider.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../services/view_models/jobs_view_model.dart';
import 'worker_job_details_view.dart';

final _workerTabProvider = StateProvider<int>((ref) => 0);

class WorkerDashboardView extends ConsumerWidget {
  const WorkerDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).user;
    final jobsViewModel = ref.watch(jobsViewModelProvider);
    final dispatchMode = ref.watch(dispatchModelProvider);
    final activeTab = ref.watch(_workerTabProvider);

    final assignedJobs = jobsViewModel.jobs.where((j) => j.workerId == user?.id).toList();
    final openJobs = jobsViewModel.jobs.where((j) => j.workerId == null || j.workerId!.isEmpty).toList();

    return Scaffold(
      body: Column(
        children: [
          CustomPinnedHeader(
            title: 'Worker Portal',
            actions: [
              HeaderActionButton(
                icon: CupertinoIcons.square_arrow_right,
                onTap: () async {
                  await ref.read(authViewModelProvider.notifier).signOut();
                },
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Technician Welcoming Card
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF333333)
                              : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(CupertinoIcons.hammer_fill, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Service Professional',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Segmented tabs control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: activeTab,
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Text('My Schedule (${assignedJobs.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Text('Open Board (${openJobs.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) {
                          ref.read(_workerTabProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ),

                // Main body
                Expanded(
                  child: activeTab == 0
                      ? _buildJobsContent(context, jobsViewModel, assignedJobs, false, user?.id)
                      : _buildJobsContent(context, jobsViewModel, openJobs, true, user?.id, dispatchMode: dispatchMode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsContent(
    BuildContext context,
    JobsViewModel vm,
    List<MaintenanceJob> listJobs,
    bool isOpenBoard,
    String? workerId, {
    DispatchModel? dispatchMode,
  }) {
    if (vm.isLoading && listJobs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (isOpenBoard && dispatchMode == DispatchModel.adminAssigned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.lock_shield, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Admin Assigned Only',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'First-Come Grab model is currently disabled by Admin. Only dispatch desk can assign jobs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (listJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOpenBoard ? CupertinoIcons.square_list : CupertinoIcons.check_mark_circled,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                isOpenBoard ? 'No open requests' : 'No jobs scheduled',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                isOpenBoard
                    ? 'All new requests have been claimed by technicians.'
                    : 'All caught up! New assigned requests will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: listJobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _WorkerJobCard(
          job: listJobs[index],
          isOpenBoard: isOpenBoard,
          workerId: workerId,
        );
      },
    );
  }
}

class _WorkerJobCard extends ConsumerWidget {
  const _WorkerJobCard({
    required this.job,
    required this.isOpenBoard,
    required this.workerId,
  });

  final MaintenanceJob job;
  final bool isOpenBoard;
  final String? workerId;

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month at $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = job.status.color(context);

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF222222)
              : const Color(0xFFE5E5E5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(job.tradeType.icon, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      job.tradeType.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    job.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF222222)
                  : const Color(0xFFE5E5E5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.location, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(CupertinoIcons.clock, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  _formatDate(job.scheduleDateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (isOpenBoard) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF222222)
                    : const Color(0xFFE5E5E5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: AnimatedTapScale(
                  onTap: () async {
                    if (workerId == null) return;
                    try {
                      await ref.read(jobsRepositoryProvider).assignWorker(
                            jobId: job.id,
                            workerId: workerId!,
                          );
                      ref.read(notificationServiceProvider).sendNotification(
                            title: 'Job Grabbed!',
                            body: 'You successfully claimed the request for ${job.tradeType.displayName}.',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job claimed successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to claim job: $e')),
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.hand_draw, size: 16, color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Grab Job',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isOpenBoard) return cardWidget;

    return AnimatedTapScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerJobDetailsView(jobId: job.id),
          ),
        );
      },
      child: cardWidget,
    );
  }
}

