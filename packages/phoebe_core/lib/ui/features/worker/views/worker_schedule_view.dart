import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../shared/utils/date_extensions.dart';
import 'worker_job_details_view.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class WorkerScheduleView extends ConsumerStatefulWidget {
  const WorkerScheduleView({super.key});

  @override
  ConsumerState<WorkerScheduleView> createState() =>
      _WorkerScheduleViewState();
}

class _WorkerScheduleViewState extends ConsumerState<WorkerScheduleView>
    with AutomaticKeepAliveClientMixin {
  late DateTime _focusedMonth;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = now;
  }

  @override
  bool get wantKeepAlive => true;

  void _previousMonth() =>
      setState(() => _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() =>
      setState(() => _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDay = now;
    });
  }

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final jobs = ref.watch(jobsViewModelProvider).jobs;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day);

    final jobsOnDay = jobs.where((j) {
      final d = j.scheduleDateTime;
      return d.year == selected.year &&
          d.month == selected.month &&
          d.day == selected.day;
    }).toList();

    final monthJobs = jobs.where((j) {
      return j.scheduleDateTime.year == _focusedMonth.year &&
          j.scheduleDateTime.month == _focusedMonth.month;
    }).toList();

    final daysWithJobs = <int>{};
    for (final j in monthJobs) {
      daysWithJobs.add(j.scheduleDateTime.day);
    }

    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final trailingCells = (firstWeekday - 1 + daysInMonth) % 7;
    final totalCells = firstWeekday - 1 + daysInMonth +
        (trailingCells == 0 ? 0 : 7 - trailingCells);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Schedule',
          actions: [
            GestureDetector(
              onTap: _goToday,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(jobsViewModelProvider).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding)),

                // Month nav
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        AnimatedTapScale(
                          onTap: _previousMonth,
                          child: Icon(CupertinoIcons.chevron_left,
                              size: 18,
                              color: theme.colorScheme.onSurface),
                        ),
                        const Spacer(),
                        Text(
                          '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.0,
                            height: 1.0,
                          ),
                        ),
                        const Spacer(),
                        AnimatedTapScale(
                          onTap: _nextMonth,
                          child: Icon(CupertinoIcons.chevron_right,
                              size: 18,
                              color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Weekday labels
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: List.generate(7,
                          (i) => Expanded(
                                child: Center(
                                  child: Text(
                                    _weekdayLabels[i],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              )),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Calendar grid
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < 0) {
                        _nextMonth();
                      } else if (details.primaryVelocity! > 0) {
                        _previousMonth();
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: List.generate(
                            totalCells ~/ 7, (rowIndex) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    rowIndex < (totalCells ~/ 7) - 1
                                        ? 4
                                        : 0),
                            child: Row(
                              children:
                                  List.generate(7, (colIndex) {
                                final cellIndex =
                                    rowIndex * 7 + colIndex;
                                final dayNumber =
                                    cellIndex - (firstWeekday - 1) + 1;
                                final isValid = dayNumber >= 1 &&
                                    dayNumber <= daysInMonth;
                                final date = isValid
                                    ? DateTime(_focusedMonth.year,
                                        _focusedMonth.month, dayNumber)
                                    : null;
                                final isToday =
                                    date != null && date == today;
                                final isSelected =
                                    date != null && date == selected;
                                final hasJob = isValid &&
                                    daysWithJobs.contains(dayNumber);

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: date == null
                                        ? null
                                        : () => setState(
                                            () => _selectedDay = date),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected || isToday
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                      ),
                                      child: Column(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          Text(
                                            isValid ? '$dayNumber' : '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ||
                                                      isToday
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected || isToday
                                                  ? theme.colorScheme
                                                      .onPrimary
                                                  : theme.colorScheme
                                                      .onSurface,
                                              height: 1.0,
                                            ),
                                          ),
                                          if (hasJob &&
                                              !isSelected &&
                                              !isToday)
                                            Container(
                                              margin: const EdgeInsets
                                                  .only(top: 3),
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: theme
                                                    .colorScheme.primary,
                                              ),
                                            ),
                                          if (hasJob &&
                                              (isSelected || isToday))
                                            Container(
                                              margin: const EdgeInsets
                                                  .only(top: 3),
                                              width: 4,
                                              height: 4,
                                              decoration:
                                                  const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white70,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Jobs for selected day
                if (jobsOnDay.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(28, 32, 28, 0),
                      child: Text(
                        '${_monthName(selected.month)} ${selected.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(28, 14, 28, 0),
                      child: Column(
                        children: List.generate(
                            jobsOnDay.length,
                            (i) => Padding(
                                  padding: EdgeInsets.only(
                                      bottom: i < jobsOnDay.length - 1
                                          ? 10
                                          : 0),
                                  child: _ScheduleJobCard(
                                      job: jobsOnDay[i]),
                                )),
                      ),
                    ),
                  ),
                ],

                // Upcoming
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(28, 32, 28, 0),
                    child: Text(
                      'Coming Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(28, 14, 28, 0),
                    child: Column(
                      children: List.generate(
                        jobs.length > 5 ? 5 : jobs.length,
                        (i) {
                          final job = jobs[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ScheduleJobCard(job: job),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleJobCard extends ConsumerWidget {
  const _ScheduleJobCard({required this.job});

  final MaintenanceJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = job.status.color(context);

    return AnimatedTapScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WorkerJobDetailsView(jobId: job.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(job.tradeType.icon,
                  size: 18, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.tradeType.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.scheduleDateTime.formattedShort,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                job.status.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
