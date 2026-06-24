import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../view_models/jobs_view_model.dart';
import '../../../../ui/shared/widgets/shimmer_loading.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../../../ui/features/services/views/voice_assistant_page.dart';
import '../../../../ui/features/services/views/qr_scanner_page.dart';
import '../../../../ui/features/services/views/new_request_page.dart';
import '../../../../ui/features/services/views/job_details_page.dart';
import '../../../../ui/features/services/views/live_tracking_view.dart';
import '../../../../ui/shared/widgets/app_bottom_sheet.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';


class ServicesTabView extends ConsumerStatefulWidget {
  const ServicesTabView({super.key});

  @override
  ConsumerState<ServicesTabView> createState() => _ServicesTabViewState();
}

class _ServicesTabViewState extends ConsumerState<ServicesTabView> {
  String _searchQuery = '';

  void _showQrScannerSim(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsViewModel = ref.watch(jobsViewModelProvider);

    return Scaffold(
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Services',
          actions: [
            _ExpandableActions(
              onNewRequest: () => _showNewRequestSheet(context),
              onQrScanner: () => _showQrScannerSim(context),
              onVoiceAssistant: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VoiceAssistantPage()),
                );
              },
              onRefresh: () => ref.invalidate(jobsViewModelProvider),
            ),
          ],
          bottomChild: CupertinoSearchTextField(
            placeholder: 'Search requests...',
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: theme.colorScheme.onSurface),
            placeholderStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            itemColor: theme.colorScheme.onSurfaceVariant,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.inputDecorationTheme.fillColor
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFE5E5E5),
              ),
            ),
          ),
        ),
        bodyBuilder: (context, topPadding) {
          return _buildBody(context, jobsViewModel, topPadding);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobsViewModel vm, double topPadding) {
    if (vm.isLoading && vm.jobs.isEmpty) {
      return ShimmerListPlaceholder(
        padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 96),
      );
    }

    if (vm.errorMessage != null && vm.jobs.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (vm.jobs.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.wrench,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No maintenance requests',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything in your home is running smoothly. Need something repaired? Request a service below.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredJobs = vm.jobs.where((job) {
      return _searchQuery.isEmpty ||
          job.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.tradeType.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return _JobList(jobs: filteredJobs, topPadding: topPadding);
  }

  void _showNewRequestSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewRequestPage()),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs, required this.topPadding});
  final List<MaintenanceJob> jobs;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 120),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0x1F8BA5A7),
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: _JobCard(job: jobs[index]),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final MaintenanceJob job;

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = job.status.color(context);

    return AnimatedTapScale(
      onTap: () => _showDetailsSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  job.tradeType.displayName,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 20,
                    height: 1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                job.status.displayName.toUpperCase(),
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                _formatDate(job.scheduleDateTime),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (job.status == JobStatus.completed) ...[
            const SizedBox(height: 8),
            Text(
              '30-Day Workmanship Guarantee Active'.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    final canTrack = job.status == JobStatus.workerEnRoute || job.status == JobStatus.workerArrived;
    showAppBottomSheet(
      context: context,
      child: _JobDetailsSheet(job: job),
      bottomBar: canTrack
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveTrackingView(
                        jobId: job.id,
                        address: job.address,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          : null,
    );
  }
}

class _ExpandableActions extends StatefulWidget {
  const _ExpandableActions({
    required this.onNewRequest,
    required this.onQrScanner,
    required this.onVoiceAssistant,
    required this.onRefresh,
  });

  final VoidCallback onNewRequest;
  final VoidCallback onQrScanner;
  final VoidCallback onVoiceAssistant;
  final VoidCallback onRefresh;

  @override
  State<_ExpandableActions> createState() => _ExpandableActionsState();
}

class _ExpandableActionsState extends State<_ExpandableActions> {
  bool _expanded = false;

  void _close() {
    if (_expanded) setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      (icon: CupertinoIcons.add, onTap: () { _close(); widget.onNewRequest(); }),
      (icon: CupertinoIcons.qrcode_viewfinder, onTap: () { _close(); widget.onQrScanner(); }),
      (icon: CupertinoIcons.mic_fill, onTap: () { _close(); widget.onVoiceAssistant(); }),
      (icon: CupertinoIcons.refresh, onTap: () { _close(); widget.onRefresh(); }),
    ];

    return GestureDetector(
      onTap: _expanded ? null : () => setState(() => _expanded = true),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFE5E5E5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_expanded)
                _buildIcon(CupertinoIcons.add, () => setState(() => _expanded = true))
              else
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(item.icon, item.onTap),
                      if (idx < items.length - 1)
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFE5E5E5),
                          indent: 8,
                          endIndent: 8,
                        ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        color: Colors.transparent,
        child: Center(
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _JobDetailsSheet extends ConsumerStatefulWidget {
  const _JobDetailsSheet({required this.job});
  final MaintenanceJob job;

  @override
  ConsumerState<_JobDetailsSheet> createState() => _JobDetailsSheetState();
}

class _JobDetailsSheetState extends ConsumerState<_JobDetailsSheet> {
  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                job.tradeType.displayName,
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: job.status.color(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                job.status.displayName,
                style: TextStyle(
                  color: job.status.color(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Description',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(job.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Text(
          'Address / Location',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(job.address, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text(
          'Scheduled Time',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(_formatDate(job.scheduleDateTime), style: theme.textTheme.bodyMedium),
        if (job.status == JobStatus.waitingApproval) ...[
          CustomerReviewPanel(jobId: job.id),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.videocam_fill, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎥 Body cam active. Footage stored 6 months. Under T&Cs, claims cannot be made after 6 months.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
