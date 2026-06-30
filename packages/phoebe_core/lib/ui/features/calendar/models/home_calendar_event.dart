import 'package:flutter/cupertino.dart';
import '../../../../domain/models/trade_type.dart';

enum CalendarEventType { job, recurringTask, warranty, seasonal }

class HomeCalendarEvent {
  final DateTime date;
  final String title;
  final String? subtitle;
  final CalendarEventType type;
  final TradeType? tradeType;
  final IconData icon;
  final Color color;

  const HomeCalendarEvent({
    required this.date,
    required this.title,
    this.subtitle,
    required this.type,
    this.tradeType,
    required this.icon,
    required this.color,
  });
}

List<HomeCalendarEvent> generateRecurringTasks(DateTime month) {
  final year = month.year;

  return [
    HomeCalendarEvent(
      date: DateTime(year, 1, 15),
      title: 'HVAC Air Filter',
      subtitle: 'Replace filter — quarterly',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.wind,
      color: const Color(0xFFD4815A),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 4, 15),
      title: 'HVAC Air Filter',
      subtitle: 'Replace filter — quarterly',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.wind,
      color: const Color(0xFFD4815A),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 7, 15),
      title: 'HVAC Air Filter',
      subtitle: 'Replace filter — quarterly',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.wind,
      color: const Color(0xFFD4815A),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 10, 15),
      title: 'HVAC Air Filter',
      subtitle: 'Replace filter — quarterly',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.wind,
      color: const Color(0xFFD4815A),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 3, 1),
      title: 'Smoke Detector',
      subtitle: 'Test batteries — bi-annual',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.bell_fill,
      color: const Color(0xFF186A6F),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 9, 1),
      title: 'Smoke Detector',
      subtitle: 'Test batteries — bi-annual',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.bell_fill,
      color: const Color(0xFF186A6F),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 4, 1),
      title: 'Gutter Cleaning',
      subtitle: 'Clear debris — spring',
      type: CalendarEventType.seasonal,
      icon: CupertinoIcons.cloud_rain_fill,
      color: const Color(0xFF5B8C5A),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 11, 1),
      title: 'Gutter Cleaning',
      subtitle: 'Clear debris — fall',
      type: CalendarEventType.seasonal,
      icon: CupertinoIcons.cloud_rain_fill,
      color: const Color(0xFF5B8C5A),
    ),
    HomeCalendarEvent(
      date: DateTime(year, 6, 1),
      title: 'Water Heater Flush',
      subtitle: 'Annual maintenance',
      type: CalendarEventType.recurringTask,
      icon: CupertinoIcons.drop_fill,
      color: const Color(0xFF4A90D9),
    ),
  ];
}
