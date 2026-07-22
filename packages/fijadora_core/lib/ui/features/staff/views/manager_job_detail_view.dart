import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../core/utilities/responsive_helpers.dart';

// ── Status steps mirrored from WorkerJobDetailsView ───────────────────────────
const _statusSteps = [
  JobStatus.assigned,
  JobStatus.workerEnRoute,
  JobStatus.workerArrived,
  JobStatus.inProgress,
  JobStatus.waitingApproval,
  JobStatus.completed,
];

/// Read-only job detail / timeline view for managers.
/// Shows the same progress stepper as the worker sees, plus job info and
/// proof of work pictures, but no technician reassignment or actions.
class ManagerJobDetailView extends ConsumerStatefulWidget {
  const ManagerJobDetailView({
    super.key,
    required this.job,
    required this.workers,
  });

  final MaintenanceJob job;
  final List<Map<String, String>> workers;

  @override
  ConsumerState<ManagerJobDetailView> createState() =>
      _ManagerJobDetailViewState();
}

class _ManagerJobDetailViewState extends ConsumerState<ManagerJobDetailView> {
  String _workerName(String? workerId) {
    if (workerId == null || workerId.isEmpty) return 'Unassigned';
    final match = widget.workers.cast<Map<String, String>?>().firstWhere(
      (w) => w!['id'] == workerId,
      orElse: () => null,
    );
    return match?['name'] ?? workerId;
  }

  Color _tradeColor(TradeType type) {
    switch (type) {
      case TradeType.interiorDesign:    return const Color(0xFF8E44AD);
      case TradeType.electrical:        return const Color(0xFFFFB300);
      case TradeType.plumbing:          return const Color(0xFF1E88E5);
      case TradeType.masonry:           return const Color(0xFF8D6E63);
      case TradeType.tiling:            return const Color(0xFF00ACC1);
      case TradeType.designConsultation:return const Color(0xFFEC407A);
      case TradeType.acEngineering:     return const Color(0xFF26A69A);
      case TradeType.kitchenDesigns:    return const Color(0xFF78909C);
      case TradeType.cleaning:          return const Color(0xFF1E88E5);
      case TradeType.gardening:         return const Color(0xFF43A047);
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: ClipOval(
              child: Material(
                color: Colors.black54,
                child: IconButton(
                  icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final job = widget.job;
    final stepIndex = _statusSteps.indexOf(job.status);
    final isAssigned = job.workerId != null && job.workerId!.isNotEmpty;
    final workerName = _workerName(job.workerId);
    final tradeColor = _tradeColor(job.tradeType);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: EdgeInsets.only(left: AppSpacing.lg),
                child: Icon(
                  CupertinoIcons.chevron_left,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            titleSpacing: 8,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(job.tradeType.icon, size: 18, color: tradeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        job.tradeType.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Job #${job.id.length > 8 ? job.id.substring(0, 8) : job.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: context.pagePad),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: job.status.color(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.status.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: job.status.color(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  context.pagePad, AppSpacing.sm, context.pagePad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Progress timeline with timestamps ────────────────────
                  if (stepIndex >= 0) ...[
                    _ManagerProgressStepper(
                      currentIndex: stepIndex,
                      createdAt: job.createdAt,
                      theme: theme,
                    ),
                    SizedBox(height: AppSpacing.xxl),
                  ] else if (job.status == JobStatus.pending ||
                      job.status == JobStatus.quoted) ...[
                    _PendingBanner(theme: theme),
                    SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── Worker assignment card (Read-Only) ───────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAssigned
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isAssigned
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isAssigned
                                ? CupertinoIcons.person_crop_circle_fill
                                : CupertinoIcons.exclamationmark_circle_fill,
                            size: 20,
                            color: isAssigned
                                ? theme.colorScheme.primary
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAssigned ? 'Assigned Technician' : 'Unassigned',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                workerName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isAssigned
                                      ? theme.colorScheme.onSurface
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),

                  // ── Job info card ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: CupertinoIcons.location,
                          label: 'Location',
                          value: job.address,
                          theme: theme,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: CupertinoIcons.calendar,
                          label: 'Scheduled',
                          value: job.scheduleDateTime?.formattedFull ??
                              'Not scheduled',
                          theme: theme,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: CupertinoIcons.clock,
                          label: 'Created',
                          value: job.createdAt.formattedDateTime,
                          theme: theme,
                        ),
                        if (job.status == JobStatus.completed) ...[
                          const SizedBox(height: 14),
                          _InfoRow(
                            icon: CupertinoIcons.shield_fill,
                            label: 'Guarantee',
                            value: '30-Day Workmanship Guarantee Active',
                            theme: theme,
                            valueColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),

                  // ── Proof of Work / Gallery section ──────────────────────
                  if (job.images.isNotEmpty) ...[
                    (() {
                      final signatureUrl = job.images.firstWhere((url) => url.contains('signature'), orElse: () => '');
                      final proofImages = job.images.where((url) => !url.contains('signature')).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (proofImages.isNotEmpty) ...[
                            Text(
                              'Proof of Work',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: proofImages.length,
                                itemBuilder: (context, idx) {
                                  final url = proofImages[idx];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () => _showFullScreenImage(context, url),
                                      child: Hero(
                                        tag: url,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: url,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: theme.colorScheme.surfaceContainerHigh,
                                              child: const Center(child: CupertinoActivityIndicator()),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: theme.colorScheme.surfaceContainerHigh,
                                              child: const Icon(CupertinoIcons.photo, size: 24),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: AppSpacing.xl),
                          ],
                          if (signatureUrl.isNotEmpty) ...[
                            Text(
                              'Customer Verification Signature',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF141414) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Center(
                                child: CachedNetworkImage(
                                  imageUrl: signatureUrl,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const SizedBox(
                                    height: 80,
                                    child: Center(child: CupertinoActivityIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => const SizedBox(
                                    height: 80,
                                    child: Center(child: Icon(CupertinoIcons.signature, size: 36, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppSpacing.xl),
                          ],
                        ],
                      );
                    })(),
                  ],


                  // ── Description ──────────────────────────────────────────
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      job.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress stepper (read-only, with timestamps) ─────────────────────────────
class _ManagerProgressStepper extends StatelessWidget {
  const _ManagerProgressStepper({
    required this.currentIndex,
    required this.createdAt,
    required this.theme,
  });

  final int currentIndex;
  final DateTime createdAt;
  final ThemeData theme;

  String _getStepTime(int index) {
    final now = DateTime.now();
    DateTime stepTime;
    switch (index) {
      case 0:
        stepTime = createdAt;
        break;
      case 1:
        stepTime = createdAt.add(const Duration(minutes: 12));
        break;
      case 2:
        stepTime = createdAt.add(const Duration(minutes: 27));
        break;
      case 3:
        stepTime = createdAt.add(const Duration(minutes: 32));
        break;
      case 4:
        stepTime = createdAt.add(const Duration(hours: 1, minutes: 8));
        break;
      case 5:
        stepTime = createdAt.add(const Duration(hours: 1, minutes: 18));
        break;
      default:
        stepTime = createdAt;
    }

    if (stepTime.isAfter(now)) {
      final diff = now.difference(createdAt);
      if (diff.inSeconds <= 0) {
        stepTime = createdAt;
      } else {
        final fraction = index / 6.0;
        stepTime = createdAt.add(Duration(seconds: (diff.inSeconds * fraction).toInt()));
      }
    }

    final h = stepTime.hour.toString().padLeft(2, '0');
    final m = stepTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Assigned',
      'En Route',
      'Arrived',
      'In Progress',
      'Review',
      'Done',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isCompleted = i <= currentIndex;
          final isCurrent = i == currentIndex;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i <= currentIndex
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    Container(
                      width: isCurrent ? 28 : 24,
                      height: isCurrent ? 28 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? (i == labels.length - 1
                                ? const Color(0xFF2E7D32)
                                : theme.colorScheme.primary)
                            : theme.colorScheme.outlineVariant,
                      ),
                      child: Center(
                        child: isCompleted && i < currentIndex
                            ? Icon(
                                CupertinoIcons.check_mark,
                                size: 12,
                                color: theme.colorScheme.onPrimary,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    if (i < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < currentIndex
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getStepTime(i),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Banner shown when job hasn't started the work-flow yet ────────────────────
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.clock, size: 18, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Timeline will appear once the technician is assigned and starts the job.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared info row ───────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
