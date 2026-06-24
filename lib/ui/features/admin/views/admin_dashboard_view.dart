import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../view_models/dispatch_provider.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> {
  int _activeTab = 0;

  final List<Map<String, String>> _mockWorkers = [
    {'id': 'mock-worker-alex', 'name': 'Alex Johnson (Plumbing/HVAC)'},
    {'id': 'mock-worker-sarah', 'name': 'Sarah Smith (Electrical)'},
    {'id': 'mock-worker-bob', 'name': 'Bob Davis (Carpentry/Painting)'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsRepo = ref.watch(jobsRepositoryProvider);

    return Scaffold(
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Operations Portal',
          actions: [
            HeaderActionButton(
              icon: CupertinoIcons.square_arrow_right,
              onTap: () async {
                await ref.read(authViewModelProvider.notifier).signOut();
              },
            ),
          ],
          bottomChild: SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _activeTab,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Jobs Queue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Metrics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              },
              onValueChanged: (val) {
                if (val != null) {
                  setState(() => _activeTab = val);
                }
              },
            ),
          ),
        ),
        bodyBuilder: (context, topPadding) {
          return Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: StreamBuilder<List<MaintenanceJob>>(
              stream: jobsRepo.streamJobs(userId: 'admin', role: UserRole.admin),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final jobs = snapshot.data ?? [];

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _activeTab == 0
                      ? _buildJobsQueue(jobs, theme)
                      : _buildMetricsTab(jobs, theme),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobsQueue(List<MaintenanceJob> jobs, ThemeData theme) {
    final dispatchMode = ref.watch(dispatchModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: CupertinoSlidingSegmentedControl<DispatchModel>(
            groupValue: dispatchMode,
            children: const {
              DispatchModel.adminAssigned: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Admin Assigned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              DispatchModel.firstComeGrab: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('First-Come Grab', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            },
            onValueChanged: (val) {
              if (val != null) {
                ref.read(dispatchModelProvider.notifier).state = val;
              }
            },
          ),
        ),
        Expanded(
          child: jobs.isEmpty
              ? Center(
                  child: Text('No maintenance requests found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return MaintenanceJobCard(
                      job: job,
                      mockWorkers: _mockWorkers,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetricsTab(List<MaintenanceJob> jobs, ThemeData theme) {
    final total = jobs.length;
    final unassigned = jobs.where((j) => j.workerId == null || j.workerId!.isEmpty).length;
    final inProgress = jobs.where((j) => j.status == JobStatus.inProgress).length;
    final completed = jobs.where((j) => j.status == JobStatus.completed).length;
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(24.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard('Total Jobs', '$total', CupertinoIcons.square_list, theme),
        _buildMetricCard('Unassigned', '$unassigned', CupertinoIcons.person_crop_circle_badge_exclam, theme, color: Colors.orange),
        _buildMetricCard('In Progress', '$inProgress', CupertinoIcons.gear_alt, theme, color: Colors.blue),
        _buildMetricCard('Completion', '$completionRate%', CupertinoIcons.check_mark_circled, theme, color: Colors.green),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, ThemeData theme, {Color? color}) {
    final displayColor = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: displayColor),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class MaintenanceJobCard extends ConsumerStatefulWidget {
  final MaintenanceJob job;
  final List<Map<String, String>> mockWorkers;

  const MaintenanceJobCard({
    super.key,
    required this.job,
    required this.mockWorkers,
  });

  @override
  ConsumerState<MaintenanceJobCard> createState() => _MaintenanceJobCardState();
}

class _MaintenanceJobCardState extends ConsumerState<MaintenanceJobCard> {
  bool _isExpanded = false;
  bool _isAssigning = false;
  String? _assigningWorkerId;

  List<Color> _getGradientForTrade(TradeType type) {
    switch (type) {
      case TradeType.plumbing:
        return [const Color(0xFF1E88E5), const Color(0xFF0D47A1)];
      case TradeType.electrical:
        return [const Color(0xFFFFB300), const Color(0xFFFF6F00)];
      case TradeType.carpentry:
        return [const Color(0xFF8D6E63), const Color(0xFF4E342E)];
      case TradeType.painting:
        return [const Color(0xFFEC407A), const Color(0xFF880E4F)];
      case TradeType.hvac:
        return [const Color(0xFF00ACC1), const Color(0xFF006064)];
      case TradeType.cleaning:
        return [const Color(0xFF26A69A), const Color(0xFF004D40)];
      case TradeType.generalRepairs:
        return [const Color(0xFF78909C), const Color(0xFF37474F)];
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second';
    }
    return name[0];
  }

  Color _getAvatarColor(String name) {
    if (name.contains('Plumbing') || name.contains('HVAC')) {
      return const Color(0xFF1E88E5);
    }
    if (name.contains('Electrical')) {
      return const Color(0xFFFFB300);
    }
    if (name.contains('Carpentry') || name.contains('Painting')) {
      return const Color(0xFF8D6E63);
    }
    return const Color(0xFF26A69A);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;
    final isUnassigned = job.workerId == null || job.workerId!.isEmpty;
    final gradientColors = _getGradientForTrade(job.tradeType);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    gradientColors[0].withValues(alpha: 0.15),
                                    gradientColors[1].withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: gradientColors[0].withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    job.tradeType.icon,
                                    size: 10,
                                    color: gradientColors[0],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    job.tradeType.displayName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: gradientColors[0],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusChip(job.status, theme),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          job.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(CupertinoIcons.location_fill, size: 13, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                job.address,
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(CupertinoIcons.calendar_today, size: 13, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Text(
                              'Scheduled: ${job.scheduleDateTime.formattedDateTime}',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: theme.colorScheme.surfaceContainerHighest,
                          thickness: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUnassigned ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.person_crop_circle_fill,
                                    size: 14,
                                    color: isUnassigned ? Colors.orange : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      isUnassigned ? 'Unassigned' : 'Assigned to: ${job.workerId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isUnassigned ? FontWeight.w700 : FontWeight.w500,
                                        color: isUnassigned ? Colors.orange : theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isUnassigned && job.status == JobStatus.pending)
                              AnimatedTapScale(
                                onTap: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isExpanded
                                        ? (theme.brightness == Brightness.dark
                                            ? const Color(0xFF333333)
                                            : const Color(0xFFEEEEEE))
                                        : theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isExpanded
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isExpanded ? CupertinoIcons.xmark : CupertinoIcons.person_badge_plus_fill,
                                        size: 13,
                                        color: _isExpanded
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isExpanded ? 'Cancel' : 'Assign Staff',
                                        style: TextStyle(
                                          color: _isExpanded
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (!isUnassigned)
                              const SizedBox(width: 8),
                            if (!isUnassigned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Worker Dispatched',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_isExpanded && isUnassigned) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const Text(
                            'Select Technician',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.mockWorkers.map((worker) {
                            final workerId = worker['id'] ?? '';
                            final workerName = worker['name'] ?? '';
                            final isThisWorkerAssigning = _isAssigning && _assigningWorkerId == workerId;
                            final initials = _getInitials(workerName);
                            final avatarBgColor = _getAvatarColor(workerName);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: AnimatedTapScale(
                                onTap: _isAssigning
                                    ? () {}
                                    : () => _assignWorker(workerId, workerName),
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? theme.colorScheme.surfaceContainerHigh
                                        : const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.brightness == Brightness.dark
                                          ? theme.colorScheme.surfaceContainerHighest
                                          : const Color(0xFFEBEFF5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: avatarBgColor.withValues(alpha: 0.15),
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            color: avatarBgColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              workerName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(CupertinoIcons.star_fill, size: 10, color: Colors.amber),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '4.9',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'Available Now',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isThisWorkerAssigning)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 14,
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status, ThemeData theme) {
    Color color;
    switch (status) {
      case JobStatus.pending:
        color = Colors.orange;
        break;
      case JobStatus.assigned:
      case JobStatus.workerEnRoute:
      case JobStatus.workerArrived:
      case JobStatus.inProgress:
        color = Colors.blue;
        break;
      case JobStatus.waitingApproval:
        color = Colors.purple;
        break;
      case JobStatus.completed:
        color = Colors.green;
        break;
      case JobStatus.rejected:
      case JobStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _assignWorker(String workerId, String workerName) async {
    setState(() {
      _isAssigning = true;
      _assigningWorkerId = workerId;
    });

    try {
      await ref.read(jobsRepositoryProvider).assignWorker(
            jobId: widget.job.id,
            workerId: workerId,
          );
      
      ref.read(notificationServiceProvider).sendNotification(
            title: 'Worker Dispatched',
            body: 'Job has been assigned to $workerName.',
          );

      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(child: Text('Job assigned to $workerName')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text('Error assigning job: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _assigningWorkerId = null;
        });
      }
    }
  }
}