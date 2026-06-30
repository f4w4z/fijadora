import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../../../ui/shared/widgets/empty_state_widget.dart';
import '../../admin/view_models/dispatch_provider.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../shared/utils/notification_helper.dart';
import 'worker_job_details_view.dart';

final _dashboardFilterProvider = StateProvider<String>((ref) => 'All');
final _searchQueryProvider = StateProvider<String>((ref) => '');

const _greetings = [
  'Let\'s get to work',
  'Another day, another job',
  'Ready to serve',
  'Time to shine',
  'Your customers are waiting',
  'Good to see you',
];

class WorkerDashboardTab extends ConsumerStatefulWidget {
  const WorkerDashboardTab({super.key});

  @override
  ConsumerState<WorkerDashboardTab> createState() => _WorkerDashboardTabState();
}

class _WorkerDashboardTabState extends ConsumerState<WorkerDashboardTab>
    with AutomaticKeepAliveClientMixin {
  int _greetingIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadGreetingIndex();
  }

  void _loadGreetingIndex() {
    try {
      final box = Hive.box('app_preferences');
      final lastIndex = box.get('worker_greeting_index', defaultValue: -1) as int;
      final nextIndex = (lastIndex + 1) % _greetings.length;
      box.put('worker_greeting_index', nextIndex);
      _greetingIndex = nextIndex;
    } catch (e) {
      _greetingIndex = 0;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).user;
    final jobsViewModel = ref.watch(jobsViewModelProvider);
    final dispatchMode = ref.watch(dispatchModelProvider);
    final filter = ref.watch(_dashboardFilterProvider);
    final searchQuery = ref.watch(_searchQueryProvider);

    final myJobs = jobsViewModel.jobs
        .where((j) => j.workerId == user?.id)
        .toList();

    final openJobs = jobsViewModel.jobs
        .where((j) => j.workerId == null || j.workerId!.isEmpty)
        .toList();

    final allDisplayJobs = [...myJobs, ...openJobs];

    final filteredByCategory = switch (filter) {
      'My Jobs' => myJobs,
      'Available' => openJobs,
      'Completed' => myJobs.where((j) => j.status == JobStatus.completed).toList(),
      _ => allDisplayJobs,
    };

    final filteredJobs = searchQuery.isEmpty
        ? filteredByCategory
        : filteredByCategory.where((j) {
            final q = searchQuery.toLowerCase();
            return j.tradeType.displayName.toLowerCase().contains(q) ||
                j.description.toLowerCase().contains(q) ||
                j.address.toLowerCase().contains(q);
          }).toList();

    final todayJobs = myJobs.where((j) {
      final now = DateTime.now();
      return j.scheduleDateTime.year == now.year &&
          j.scheduleDateTime.month == now.month &&
          j.scheduleDateTime.day == now.day;
    }).toList();

    final completedToday = myJobs
        .where((j) =>
            j.status == JobStatus.completed &&
            j.scheduleDateTime.year == DateTime.now().year &&
            j.scheduleDateTime.month == DateTime.now().month &&
            j.scheduleDateTime.day == DateTime.now().day)
        .length;

    final firstName = user?.name.isNotEmpty == true
        ? user!.name.split(' ').first
        : 'there';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Dashboard',
          actions: [
            GroupedHeaderActions(
              actions: [
                GroupedActionItem(
                  icon: CupertinoIcons.arrow_counterclockwise,
                  onTap: () => ref.read(jobsViewModelProvider).refresh(),
                ),
              ],
            ),
          ],
          bottomChild: SizedBox(
            height: 40,
            child: CupertinoSearchTextField(
              placeholder: 'Search jobs...',
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        headerHeight: 170,
        bodyBuilder: (context, topPadding) {
          return RefreshIndicator(
            onRefresh: () async => ref.read(jobsViewModelProvider).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding)),

                // Greeting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey $firstName,',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            _greetings[_greetingIndex],
                            key: ValueKey(_greetings[_greetingIndex]),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              height: 1.0,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        _StatCard(
                          theme: theme,
                          value: '${todayJobs.length}',
                          label: 'Today',
                          icon: CupertinoIcons.clock_fill,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          theme: theme,
                          value: '$completedToday',
                          label: 'Completed',
                          icon: CupertinoIcons.check_mark_circled,
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          theme: theme,
                          value: '${openJobs.length}',
                          label: 'Available',
                          icon: CupertinoIcons.hand_draw,
                          color: const Color(0xFFE65100),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'My Jobs', 'Available', 'Completed']
                            .map((f) => _FilterChip(
                                  label: f,
                                  count: switch (f) {
                                    'My Jobs' => myJobs.length,
                                    'Available' => openJobs.length,
                                    'Completed' => myJobs.where((j) => j.status == JobStatus.completed).length,
                                    _ => allDisplayJobs.length,
                                  },
                                  isSelected: filter == f,
                                  onTap: () =>
                                      ref.read(_dashboardFilterProvider.notifier).state = f,
                                  theme: theme,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),

                // Open Board disabled state
                if (filter == 'Available' &&
                    dispatchMode == DispatchModel.adminAssigned)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(CupertinoIcons.lock_shield,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Admin Assigned Only',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Jobs are assigned by dispatch only.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Jobs section
                if (filteredJobs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            filter == 'All'
                                ? 'All Jobs'
                                : filter,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${filteredJobs.length} ${filteredJobs.length == 1 ? 'job' : 'jobs'}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final job = filteredJobs[index];
                          final isMine = myJobs.contains(job);
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index == filteredJobs.length - 1 ? 0 : 10),
                            child: _WorkerJobCard(
                              job: job,
                              isMine: isMine,
                              workerId: user?.id,
                            ),
                          );
                        },
                        childCount: filteredJobs.length,
                      ),
                    ),
                  ),
                ],

                if (filteredJobs.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 240,
                      child: EmptyStateWidget(
                        icon: CupertinoIcons.hammer,
                        title: filter == 'Available'
                            ? 'No open jobs'
                            : 'No jobs yet',
                        message: filter == 'Available'
                            ? 'All available jobs have been claimed.'
                            : 'Assigned jobs will appear here.',
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.theme,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final ThemeData theme;
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _WorkerJobCard extends ConsumerWidget {
  const _WorkerJobCard({
    required this.job,
    required this.isMine,
    required this.workerId,
  });

  final MaintenanceJob job;
  final bool isMine;
  final String? workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = job.status.color(context);

    return AnimatedTapScale(
      scaleFactor: 0.97,
      onTap: isMine
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkerJobDetailsView(jobId: job.id),
                ),
              );
            }
          : () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(job.tradeType.icon,
                      size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.tradeType.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(CupertinoIcons.location,
                              size: 10,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.status.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.5,
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
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.calendar,
                    size: 13, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  job.scheduleDateTime.formattedShort,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (!isMine)
                  _GrabButton(job: job, workerId: workerId)
                else
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GrabButton extends ConsumerWidget {
  const _GrabButton({required this.job, required this.workerId});

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
