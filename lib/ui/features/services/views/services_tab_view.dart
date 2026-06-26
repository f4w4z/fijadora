import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/trade_type.dart';
import '../view_models/jobs_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../ui/features/services/views/new_request_page.dart';
import '../../../../ui/features/services/views/job_details_page.dart';
import '../../../../ui/features/services/views/live_tracking_view.dart';
import '../../../../ui/shared/widgets/app_bottom_sheet.dart';
import '../../../../ui/shared/widgets/custom_pinned_header.dart';
import '../../../../ui/shared/widgets/floating_header_layout.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../core/theme.dart';

final _quotes = [
  'Your home runs on care',
  'Service made simple',
  'Every fix matters',
  'Home is where the heart is',
  'Built to last, served with care',
  'Your peace of mind, delivered',
];

const _serviceGradients = {
  TradeType.plumbing: [Color(0xFF1A5276), Color(0xFF2980B9), Color(0xFF5DADE2)],
  TradeType.electrical: [Color(0xFF7D3C98), Color(0xFFA569BD), Color(0xFFD2B4DE)],
  TradeType.carpentry: [Color(0xFF935116), Color(0xFFCA6F1E), Color(0xFFE59866)],
  TradeType.painting: [Color(0xFFC0392B), Color(0xFFE74C3C), Color(0xFFF1948A)],
  TradeType.hvac: [Color(0xFF0E6251), Color(0xFF148F77), Color(0xFF52BE80)],
  TradeType.cleaning: [Color(0xFF1B4F72), Color(0xFF2E86C1), Color(0xFF85C1E9)],
  TradeType.generalRepairs: [Color(0xFF4A235A), Color(0xFF76448A), Color(0xFFBB8FCE)],
};

const _serviceTaglines = {
  TradeType.plumbing: 'Fix leaks, unclog drains, install fixtures',
  TradeType.electrical: 'Wiring, switches, panels & smart home',
  TradeType.carpentry: 'Custom builds, repairs & furniture assembly',
  TradeType.painting: 'Interior & exterior, touch-ups to full rooms',
  TradeType.hvac: 'AC, heating, ventilation & thermostat setup',
  TradeType.cleaning: 'Deep clean, move-in/out & routine upkeep',
  TradeType.generalRepairs: 'Handyman fixes & odd jobs around the house',
};

const _startingPrices = {
  TradeType.plumbing: r'$85',
  TradeType.electrical: r'$75',
  TradeType.carpentry: r'$95',
  TradeType.painting: r'$120',
  TradeType.hvac: r'$110',
  TradeType.cleaning: r'$65',
  TradeType.generalRepairs: r'$55',
};

const _serviceImages = {
  TradeType.plumbing: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&h=500&fit=crop&auto=format',
  TradeType.electrical: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&h=500&fit=crop&auto=format',
  TradeType.carpentry: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&h=500&fit=crop&auto=format',
  TradeType.painting: 'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=400&h=500&fit=crop&auto=format',
  TradeType.hvac: 'https://images.unsplash.com/photo-1631545806600-52e4fdc2cade?w=400&h=500&fit=crop&auto=format',
  TradeType.cleaning: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=500&fit=crop&auto=format',
  TradeType.generalRepairs: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400&h=500&fit=crop&auto=format',
};

class ServicesTabView extends ConsumerStatefulWidget {
  const ServicesTabView({super.key});

  @override
  ConsumerState<ServicesTabView> createState() => _ServicesTabViewState();
}

class _ServicesTabViewState extends ConsumerState<ServicesTabView> {
  int _quoteIndex = 0;
  TradeType? _selectedTrade;

  @override
  void initState() {
    super.initState();
    _loadAndUpdateQuoteIndex();
  }

  void _loadAndUpdateQuoteIndex() {
    try {
      final box = Hive.box('cached_jobs');
      final lastIndex = box.get('quote_index', defaultValue: -1) as int;
      final nextIndex = (lastIndex + 1) % _quotes.length;
      box.put('quote_index', nextIndex);
      _quoteIndex = nextIndex;
    } catch (e) {
      debugPrint('Hive get/put quote_index error: $e');
      _quoteIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsViewModel = ref.watch(jobsViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final jobs = jobsViewModel.jobs;
    final userName = authViewModel.user?.name ?? '';
    final firstName = userName.isNotEmpty ? userName.split(' ').first : 'there';

    final activeJobs = jobs.where((j) =>
      j.status == JobStatus.pending ||
      j.status == JobStatus.assigned ||
      j.status == JobStatus.workerEnRoute ||
      j.status == JobStatus.workerArrived ||
      j.status == JobStatus.inProgress ||
      j.status == JobStatus.waitingApproval,
    ).toList();

    final trades = TradeType.values;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: FloatingHeaderLayout(
          header: CustomPinnedHeader(
            title: 'Services',
            actions: [
              GestureDetector(
                onTap: () => _showNewRequest(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add, size: 16, color: Color(0xFF1A1A1A)),
                      const SizedBox(width: 6),
                      const Text(
                        'New Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
            bottomChild: SizedBox(
              height: 40,
              child: TextField(
                readOnly: true,
                onTap: () => _showNewRequest(context),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What do you need fixed?',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
                  prefixIcon: Icon(CupertinoIcons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        bodyBuilder: (context, topPadding) {
          final filteredTrades = _selectedTrade == null
              ? trades
              : trades.where((t) => t == _selectedTrade).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),

              // Hero greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey $firstName,',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: Text(
                          _quotes[_quoteIndex],
                          key: ValueKey(_quotes[_quoteIndex]),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Service category chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: trades.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CategoryChip(
                            label: 'All',
                            isSelected: _selectedTrade == null,
                            onTap: () => setState(() => _selectedTrade = null),
                          );
                        }
                        final trade = trades[index - 1];
                        return _CategoryChip(
                          label: trade.displayName,
                          isSelected: _selectedTrade == trade,
                          onTap: () => setState(() => _selectedTrade = trade),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Service grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Services',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.onSurface, letterSpacing: -0.3),
                      ),
                      TextButton(
                        onPressed: () => _showNewRequest(context),
                        child: Text('See All', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trade = filteredTrades[index];
                      return _ServiceCard(
                        trade: trade,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewRequestPage(initialTrade: trade),
                            ),
                          );
                        },
                      );
                    },
                    childCount: filteredTrades.length,
                  ),
                ),
              ),

              // Active requests section
              if (activeJobs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Requests',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.onSurface, letterSpacing: -0.3),
                        ),
                        TextButton(
                          onPressed: () => _scrollToMyRequests(),
                          child: Text('${activeJobs.length} active', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = activeJobs[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == activeJobs.length - 1 ? 0 : 10),
                          child: _ActiveJobCard(job: job, index: index),
                        );
                      },
                      childCount: activeJobs.length,
                    ),
                  ),
                ),
              ],

              // Past jobs section
              if (jobs.length > activeJobs.length) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.onSurface, letterSpacing: -0.3),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('${jobs.length - activeJobs.length} past', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pastJobs = jobs.where((j) => !activeJobs.contains(j)).toList();
                        final job = pastJobs[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == pastJobs.length - 1 ? 0 : 10),
                          child: _ActiveJobCard(job: job, index: index),
                        );
                      },
                      childCount: jobs.length - activeJobs.length,
                    ),
                  ),
                ),
              ],

              if (jobs.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'No requests yet. Browse services above to get started.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          );
        },
      ),
    );
  }

  void _showNewRequest(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestPage()));
  }

  void _scrollToMyRequests() {}
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.trade, required this.onTap});
  final TradeType trade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradients = _serviceGradients[trade]!;
    final tagline = _serviceTaglines[trade]!;
    final price = _startingPrices[trade]!;

    return AnimatedTapScale(
      scaleFactor: 0.95,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.cardSurface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Picture area (unsplash image + gradient overlay + icon)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: _serviceImages[trade]!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradients,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradients,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(trade.icon, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Text(
                            'from $price',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.onSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 12,
                              color: Colors.white,
                            ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends ConsumerWidget {
  const _ActiveJobCard({required this.job, required this.index});
  final MaintenanceJob job;
  final int index;

  String get _dateLabel {
    if (job.status == JobStatus.completed) return 'Completed ${job.scheduleDateTime.formattedShort}';
    if (job.status == JobStatus.cancelled) return 'Cancelled';
    if (job.status == JobStatus.rejected) return 'Rejected';
    return job.scheduleDateTime.formattedShort;
  }

  String get _daysLabel {
    if (job.status == JobStatus.completed || job.status == JobStatus.cancelled || job.status == JobStatus.rejected) {
      final days = DateTime.now().difference(job.scheduleDateTime).inDays;
      if (days == 0) return 'Today';
      return '${days}d ago';
    }
    final days = job.scheduleDateTime.difference(DateTime.now()).inDays;
    if (days == 0) return 'Today';
    if (days < 0) return 'Overdue';
    return '${days}d left';
  }

  String get _statusLabel {
    switch (job.status) {
      case JobStatus.workerEnRoute: return 'En Route';
      case JobStatus.workerArrived: return 'Arrived';
      case JobStatus.inProgress: return 'In Progress';
      case JobStatus.waitingApproval: return 'Review';
      case JobStatus.completed: return 'Done';
      case JobStatus.cancelled: return 'Cancelled';
      case JobStatus.rejected: return 'Rejected';
      case JobStatus.pending: return 'Pending';
      case JobStatus.assigned: return 'Assigned';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = job.status.color(context);

    return AnimatedTapScale(
      scaleFactor: 0.97,
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.scaffold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(job.tradeType.icon, size: 17, color: AppTheme.onSurface),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.tradeType.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 10, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _dateLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _daysLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      child: _JobDetailsSheet(job: job),
      bottomBar: job.status == JobStatus.workerEnRoute || job.status == JobStatus.workerArrived
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LiveTrackingView(jobId: job.id, address: job.address),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          : null,
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
              child: Text(job.tradeType.displayName, style: theme.textTheme.displaySmall?.copyWith(fontSize: 20)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: job.status.color(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(job.status.displayName, style: TextStyle(color: job.status.color(context), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Description', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Text('Address / Location', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.address, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text('Scheduled Time', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.scheduleDateTime.formattedFull, style: theme.textTheme.bodyMedium),
        if (job.status == JobStatus.waitingApproval) ...[
          CustomerReviewPanel(jobId: job.id),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.videocam_fill, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Body cam active. Footage stored 6 months. Under T&Cs, claims cannot be made after 6 months.',
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
