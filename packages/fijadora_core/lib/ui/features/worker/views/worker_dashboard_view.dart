import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../domain/models/job_status.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../view_models/dispatch_provider.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../services/view_models/jobs_view_model.dart';
import 'job_card.dart';
import '../../../core/utilities/responsive_helpers.dart';

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
      return j.scheduleDateTime != null &&
          j.scheduleDateTime!.year == now.year &&
          j.scheduleDateTime!.month == now.month &&
          j.scheduleDateTime!.day == now.day;
    }).toList();

    final completedToday = myJobs
        .where((j) =>
            j.status == JobStatus.completed &&
            j.scheduleDateTime != null &&
            j.scheduleDateTime!.year == DateTime.now().year &&
            j.scheduleDateTime!.month == DateTime.now().month &&
            j.scheduleDateTime!.day == DateTime.now().day)
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
                    padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 0),
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
                        SizedBox(height: AppSpacing.xs),
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
                    padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.lg, context.pagePad, 0),
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
                    padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.lg, context.pagePad, 0),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'My Jobs', 'Available', 'Completed']
                            .map((f) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AppFilterChip(
                                    label: f,
                                    count: switch (f) {
                                      'My Jobs' => myJobs.length,
                                      'Available' => openJobs.length,
                                      'Completed' => myJobs.where((j) => j.status == JobStatus.completed).length,
                                      _ => allDisplayJobs.length,
                                    },
                                    selected: filter == f,
                                    onTap: () =>
                                        ref.read(_dashboardFilterProvider.notifier).state = f,
                                    theme: theme,
                                  ),
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
                      padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xxl, context.pagePad, 0),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
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
                    padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xl, context.pagePad, 0),
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
                    padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final job = filteredJobs[index];
                          final isMine = myJobs.contains(job);
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index == filteredJobs.length - 1 ? 0 : 10),
                            child: WorkerJobCard(
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
                      height: 35.h(context),
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

                SliverToBoxAdapter(child: SizedBox(height: 20.h(context))),

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




