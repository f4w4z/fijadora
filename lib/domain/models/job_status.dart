import 'package:flutter/material.dart';

enum JobStatus {
  pending,
  assigned,
  workerEnRoute,
  workerArrived,
  inProgress,
  waitingApproval,
  completed,
  rejected,
  cancelled;

  String get displayName {
    switch (this) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.workerEnRoute:
        return 'En Route';
      case JobStatus.workerArrived:
        return 'Arrived';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.waitingApproval:
        return 'Waiting Approval';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.rejected:
        return 'Rejected';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case JobStatus.pending:
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17); // Amber
      case JobStatus.assigned:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2); // Blue
      case JobStatus.workerEnRoute:
      case JobStatus.workerArrived:
      case JobStatus.inProgress:
        return isDark ? const Color(0xFF7986CB) : const Color(0xFF3F51B5); // Indigo
      case JobStatus.waitingApproval:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100); // Orange
      case JobStatus.completed:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32); // Green
      case JobStatus.rejected:
      case JobStatus.cancelled:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828); // Red
    }
  }

  static JobStatus fromString(String? value) {
    if (value == null) return JobStatus.pending;
    return JobStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => JobStatus.pending,
    );
  }
}
