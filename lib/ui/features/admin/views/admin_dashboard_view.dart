import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../../data/services/notification_service.dart';
import '../view_models/dispatch_provider.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _mockWorkers = [
    {'id': 'mock-worker-alex', 'name': 'Alex Johnson (Plumbing/HVAC)'},
    {'id': 'mock-worker-sarah', 'name': 'Sarah Smith (Electrical)'},
    {'id': 'mock-worker-bob', 'name': 'Bob Davis (Carpentry/Painting)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsRepo = ref.watch(jobsRepositoryProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right),
            onPressed: () async {
              await authViewModel.signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Jobs Queue'),
            Tab(text: 'Metrics'),
          ],
        ),
      ),
      body: StreamBuilder<List<MaintenanceJob>>(
        stream: jobsRepo.streamJobs(userId: 'admin', role: UserRole.admin),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobs = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildJobsQueue(jobs, theme),
              _buildMetricsTab(jobs, theme),
            ],
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
                    final isUnassigned = job.workerId == null || job.workerId!.isEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF222222)
                              : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  job.tradeType.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              _buildStatusChip(job.status, theme),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            job.description,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(CupertinoIcons.location, size: 14, color: theme.colorScheme.onSurfaceVariant),
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(CupertinoIcons.calendar, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                'Scheduled: ${_formatDateTime(job.scheduleDateTime)}',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF222222)
                                : const Color(0xFFE5E5E5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isUnassigned ? 'Unassigned' : 'Assigned to: ${job.workerId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isUnassigned ? FontWeight.bold : FontWeight.normal,
                                  color: isUnassigned ? Colors.orange : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (isUnassigned && job.status == JobStatus.pending)
                                TextButton(
                                  onPressed: () => _showAssignWorkerSheet(context, job.id),
                                  child: const Text('Assign Worker', style: TextStyle(fontWeight: FontWeight.bold)),
                                )
                              else if (!isUnassigned)
                                Text(
                                  'Worker Dispatched',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showAssignWorkerSheet(BuildContext context, String jobId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Assign Staff Member',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an available technician for this service job.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ..._mockWorkers.map((worker) {
                return ListTile(
                  title: Text(worker['name'] ?? ''),
                  leading: const Icon(CupertinoIcons.person),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      await ref.read(jobsRepositoryProvider).assignWorker(
                            jobId: jobId,
                            workerId: worker['id'] ?? '',
                          );
                      ref.read(notificationServiceProvider).sendNotification(
                            title: 'Worker Dispatched',
                            body: 'Job has been assigned to ${worker['name']}.',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Job assigned to ${worker['name']}')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error assigning job: $e')),
                        );
                      }
                    }
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF222222)
              : const Color(0xFFE5E5E5),
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
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, size: 20, color: color ?? theme.colorScheme.onSurfaceVariant),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
