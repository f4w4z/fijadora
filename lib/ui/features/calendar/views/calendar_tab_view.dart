import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import '../models/home_calendar_event.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class CalendarTabView extends ConsumerStatefulWidget {
  const CalendarTabView({super.key});

  @override
  ConsumerState<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends ConsumerState<CalendarTabView> with AutomaticKeepAliveClientMixin {
  late DateTime _focusedMonth;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = now;
  }

  void _previousMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  void _goToday() => setState(() {
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = now;
  });

  List<HomeCalendarEvent> _eventsForDay(DateTime day, List<HomeCalendarEvent> allEvents) {
    return allEvents.where((e) =>
      e.date.year == day.year &&
      e.date.month == day.month &&
      e.date.day == day.day,
    ).toList();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final jobsAsync = ref.watch(jobsViewModelProvider);
    final jobs = jobsAsync.jobs;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final theme = Theme.of(context);

    final recurringTasks = generateRecurringTasks(_focusedMonth);

    final jobEvents = jobs
      .where((j) =>
        j.scheduleDateTime.year == _focusedMonth.year &&
        j.scheduleDateTime.month == _focusedMonth.month)
      .map((j) => HomeCalendarEvent(
        date: DateTime(
          j.scheduleDateTime.year,
          j.scheduleDateTime.month,
          j.scheduleDateTime.day,
        ),
        title: j.tradeType.displayName,
        subtitle: j.status.displayName,
        type: CalendarEventType.job,
        tradeType: j.tradeType,
        icon: j.tradeType.icon,
        color: theme.colorScheme.primary,
      ))
      .toList();

    final monthEvents = [...jobEvents, ...recurringTasks];
    final selectedEvents = _eventsForDay(selected, monthEvents);
    final selectedHasEvents = selectedEvents.isNotEmpty;

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final trailingCells = (firstWeekday - 1 + daysInMonth) % 7;
    final totalCells = firstWeekday - 1 + daysInMonth + (trailingCells == 0 ? 0 : 7 - trailingCells);

    final daysWithEvents = <int>{};
    for (final event in monthEvents) {
      if (event.date.month == _focusedMonth.month) {
        daysWithEvents.add(event.date.day);
      }
    }

    final upcomingDays = <DateTime>[];
    for (int i = 0; i < 14; i++) {
      final d = today.add(Duration(days: i));
      if (_eventsForDay(d, monthEvents).isNotEmpty || d == today) {
        upcomingDays.add(d);
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Calendar',
          actions: [
            GestureDetector(
              onTap: _goToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 300)),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),

              // ─── Month nav ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Row(
                    children: [
                      AnimatedTapScale(
                        onTap: _previousMonth,
                        child: Icon(CupertinoIcons.chevron_left, size: 18, color: theme.colorScheme.onSurface),
                      ),
                      const Spacer(),
                      Text(
                        '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const Spacer(),
                      AnimatedTapScale(
                        onTap: _nextMonth,
                        child: Icon(CupertinoIcons.chevron_right, size: 18, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ─── Weekday labels ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: List.generate(7, (i) => Expanded(
                      child: Center(
                        child: Text(
                          _weekdayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ─── Calendar grid ────────────────────────────────────────────
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: List.generate(totalCells ~/ 7, (rowIndex) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: rowIndex < (totalCells ~/ 7) - 1 ? 4 : 0),
                        child: Row(
                          children: List.generate(7, (colIndex) {
                            final cellIndex = rowIndex * 7 + colIndex;
                            final dayNumber = cellIndex - (firstWeekday - 1) + 1;
                            final isValid = dayNumber >= 1 && dayNumber <= daysInMonth;
                            final date = isValid ? DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber) : null;
                            final isToday = date != null && date == today;
                            final isSelected = date != null && date == selected;
                            final hasEvent = isValid && daysWithEvents.contains(dayNumber);

                            return Expanded(
                              child: GestureDetector(
                                onTap: date == null ? null : () => setState(() => _selectedDay = date),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : isToday
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isValid ? '$dayNumber' : '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected || isToday
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? Colors.white
                                              : isToday
                                                  ? Colors.white
                                                  : theme.colorScheme.onSurface,
                                          height: 1.0,
                                        ),
                                      ),
                                      if (hasEvent && !isSelected && !isToday)
                                        Container(
                                          margin: const EdgeInsets.only(top: 3),
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      if (hasEvent && (isSelected || isToday))
                                        Container(
                                          margin: const EdgeInsets.only(top: 3),
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
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

              // ─── Selected day schedule ─────────────────────────────────────
              if (selectedHasEvents) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
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
                    padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                    child: Column(
                      children: List.generate(selectedEvents.length, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i < selectedEvents.length - 1 ? 10 : 0),
                        child: _CalendarEventCard(event: selectedEvents[i]),
                      )),
                    ),
                  ),
                ),
              ],

              // ─── Coming Up ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
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
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                  child: Column(
                    children: List.generate(upcomingDays.length, (i) {
                      final d = upcomingDays[i];
                      final events = _eventsForDay(d, monthEvents);
                      if (events.isEmpty && d == today) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CalendarEventCard(
                            event: HomeCalendarEvent(
                              date: d,
                              title: 'No events today',
                              type: CalendarEventType.recurringTask,
                              icon: CupertinoIcons.checkmark_circle,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: List.generate(events.length, (j) => Padding(
                          padding: EdgeInsets.only(bottom: j < events.length - 1 ? 10 : 10),
                          child: _CalendarEventCard(event: events[j]),
                        )),
                      );
                    }),
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

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

class _CalendarEventCard extends StatelessWidget {
  final HomeCalendarEvent event;
  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'event-icon-${event.hashCode}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(event.icon, size: 18, color: event.color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (event.type == CalendarEventType.job)
            Icon(CupertinoIcons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
