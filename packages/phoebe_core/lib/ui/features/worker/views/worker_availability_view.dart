import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/utilities/responsive_helpers.dart';

class WorkerAvailabilityView extends StatefulWidget {
  const WorkerAvailabilityView({super.key});

  @override
  State<WorkerAvailabilityView> createState() => _WorkerAvailabilityViewState();
}

class _WorkerAvailabilityViewState extends State<WorkerAvailabilityView> {
  bool _acceptingJobs = true;

  final Map<int, TimeOfDay> _startTimes = {};
  final Map<int, TimeOfDay> _endTimes = {};

  final _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _startTimes[i] = const TimeOfDay(hour: 8, minute: 0);
      _endTimes[i] = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  Future<void> _pickTime(int dayIndex, bool isStart) async {
    final current = isStart
        ? (_startTimes[dayIndex] ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTimes[dayIndex] ?? const TimeOfDay(hour: 17, minute: 0));

    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _TimePickerSheet(initial: current),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTimes[dayIndex] = picked;
        } else {
          _endTimes[dayIndex] = picked;
        }
      });
    }
  }

  String _format(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg),
            child: Icon(CupertinoIcons.chevron_left, size: 22, color: theme.colorScheme.onSurface),
          ),
        ),
        title: Text(
          'Availability',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_acceptingJobs ? const Color(0xFF2E7D32) : theme.colorScheme.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _acceptingJobs ? CupertinoIcons.check_mark_circled : CupertinoIcons.slash_circle,
                    size: 18,
                    color: _acceptingJobs ? const Color(0xFF2E7D32) : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Accepting New Jobs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        _acceptingJobs ? 'You\'ll appear in job dispatch' : 'Paused — not receiving new jobs',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(value: _acceptingJobs, activeTrackColor: theme.colorScheme.primary, onChanged: (v) => setState(() => _acceptingJobs = v)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Working Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          ...List.generate(7, (i) {
            final start = _startTimes[i];
            final end = _endTimes[i];
            final isAvailable = start != null;
            return Padding(
              padding: EdgeInsets.only(bottom: i < 6 ? 8 : 0),
              child: _dayRow(theme, i, isAvailable, start, end),
            );
          }),
        ],
      ),
    );
  }

  Widget _dayRow(ThemeData theme, int i, bool isAvailable, TimeOfDay? start, TimeOfDay? end) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _weekDays[i],
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 10),
          if (isAvailable) ...[
            GestureDetector(
              onTap: () => _pickTime(i, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_format(start!), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('to', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            GestureDetector(
              onTap: () => _pickTime(i, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_format(end!), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
              ),
            ),
          ] else ...[
            Text('Day Off', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
          const Spacer(),
          CupertinoSwitch(
            value: isAvailable,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: (v) {
              setState(() {
                if (v) {
                  _startTimes[i] = const TimeOfDay(hour: 8, minute: 0);
                  _endTimes[i] = const TimeOfDay(hour: 17, minute: 0);
                } else {
                  _startTimes.remove(i);
                  _endTimes.remove(i);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initial;
  const _TimePickerSheet({required this.initial});
  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    _dateTime = DateTime(2000, 1, 1, widget.initial.hour, widget.initial.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context, TimeOfDay(hour: _dateTime.hour, minute: _dateTime.minute)),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: _dateTime,
              onDateTimeChanged: (dt) => _dateTime = dt,
            ),
          ),
        ],
      ),
    );
  }
}
