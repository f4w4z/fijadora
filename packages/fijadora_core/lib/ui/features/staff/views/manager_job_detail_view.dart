import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../services/views/live_tracking_view.dart';
import '../../services/service_constants.dart';
import '../../services/view_models/jobs_view_model.dart';

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
    // Live job from the stream so staff actions (quote, approvals) reflect
    // immediately instead of showing the stale snapshot passed in.
    final liveJob = ref
            .watch(jobsStreamProvider)
            .valueOrNull
            ?.where((j) => j.id == widget.job.id)
            .firstOrNull ??
        widget.job;
    final job = liveJob;
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
                  // ── Track Technician button ────────────────────────────────
                  if (job.status == JobStatus.workerEnRoute || job.status == JobStatus.workerArrived)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, AppPageRoute(
                              builder: (_) => LiveTrackingView(jobId: job.id, address: job.address),
                            ));
                          },
                          icon: const Icon(CupertinoIcons.car, size: 18),
                          label: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
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
                        if (job.contactPhone.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _InfoRow(
                            icon: CupertinoIcons.phone,
                            label: 'Contact',
                            value: job.contactPhone,
                            theme: theme,
                          ),
                        ],
                        if (job.accessNotes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _InfoRow(
                            icon: CupertinoIcons.lock_fill,
                            label: 'Access',
                            value: job.accessNotes,
                            theme: theme,
                          ),
                        ],
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


                  // ── Quote form (staff) ─────────────────────────────────
                  if (job.status == JobStatus.pending) ...[
                    _JobQuoteForm(job: job),
                    SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Change orders (staff) ──────────────────────────────
                  if (job.changeOrders.isNotEmpty) ...[
                    _ChangeOrdersSection(job: job),
                    SizedBox(height: AppSpacing.xl),
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

// ── Quote form (staff sends a quote to the customer) ──────────────────────────
class _JobQuoteForm extends ConsumerStatefulWidget {
  const _JobQuoteForm({required this.job});
  final MaintenanceJob job;

  @override
  ConsumerState<_JobQuoteForm> createState() => _JobQuoteFormState();
}

class _JobQuoteFormState extends ConsumerState<_JobQuoteForm> {
  final _amountController = TextEditingController();
  final _maxController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _sendQuote() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quote amount')),
      );
      return;
    }
    final maxText = _maxController.text.trim();
    final maxAmount = maxText.isEmpty ? null : double.tryParse(maxText);
    if (maxText.isNotEmpty && (maxAmount == null || maxAmount < amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maximum (not to exceed) must be at least the quote amount')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await ref.read(jobsRepositoryProvider).sendJobQuote(
            jobId: widget.job.id,
            amount: amount,
            maxAmount: maxAmount,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Quote sent for ${formatGhs(updated.quoteAmount ?? amount)} — deposit ${formatGhs(updated.depositAmount ?? 0)}'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send quote: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.money_dollar_circle, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Send Quote',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The customer must accept and pay the deposit before a technician is assigned.',
            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Quote amount (GH₵)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _maxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Maximum (not to exceed, optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendQuote,
                    icon: const Icon(CupertinoIcons.paperplane_fill, size: 15),
                    label: const Text('Send Quote to Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Change orders (staff reviews & approves) ──────────────────────────────────
class _ChangeOrdersSection extends ConsumerWidget {
  const _ChangeOrdersSection({required this.job});
  final MaintenanceJob job;

  String _statusLabel(String status) => switch (status) {
        'pending' => 'Pending approval',
        'approved' => 'Awaiting customer payment',
        'paid' => 'Paid',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'pending' => Colors.orange,
        'approved' => Colors.amber,
        'paid' => const Color(0xFF2E7D32),
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change Orders',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.3)),
        const SizedBox(height: 10),
        ...job.changeOrders.map((co) {
          final isPending = co.status == 'pending';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPending
                    ? Colors.orange.withValues(alpha: 0.4)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(co.description,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(co.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(co.status),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(co.status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('+${formatGhs(co.amount)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100))),
                    const Spacer(),
                    if (isPending)
                      AnimatedTapScale(
                        onTap: () async {
                          try {
                            await ref
                                .read(jobsRepositoryProvider)
                                .approveChangeOrder(jobId: job.id, changeOrderId: co.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Change order approved — sent to customer for payment')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to approve: $e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Approve',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimary)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
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
