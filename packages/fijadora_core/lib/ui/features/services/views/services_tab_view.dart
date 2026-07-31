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
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import 'new_request_page.dart';
import 'job_details_page.dart';
import 'live_tracking_view.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../core/theme.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../profile/views/home_detail_list_view.dart';
import '../service_constants.dart';

const _quotes = [
  'Your home runs on care',
  'Service made simple',
  'Every fix matters',
  'Home is where the heart is',
  'Built to last, served with care',
  'Your peace of mind, delivered',
];

class ServicesTabView extends ConsumerStatefulWidget {
  const ServicesTabView({super.key});

  @override
  ConsumerState<ServicesTabView> createState() => _ServicesTabViewState();
}

class _ServicesTabViewState extends ConsumerState<ServicesTabView> with AutomaticKeepAliveClientMixin {
  int _quoteIndex = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAndUpdateQuoteIndex();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAndUpdateQuoteIndex() {
    try {
      final box = Hive.box('app_preferences');
      final lastIndex = box.get('quote_index', defaultValue: -1) as int;
      final nextIndex = (lastIndex + 1) % _quotes.length;
      box.put('quote_index', nextIndex);
      _quoteIndex = nextIndex;
    } catch (e) {
      _quoteIndex = 0;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

    final activeJobsSet = activeJobs.toSet();
    final pastJobs = jobs.where((j) => !activeJobsSet.contains(j)).toList();

    final trades = TradeType.values;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingHeaderLayout(
          header: CustomPinnedHeader(
            title: 'Services',
            actions: [
              GestureDetector(
                onTap: () => _showNewRequest(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, size: 16, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(
                        'New Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
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
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        bodyBuilder: (context, topPadding) {
          return RefreshIndicator(
            onRefresh: () async => ref.read(jobsViewModelProvider).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),

              // Hero greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.pagePad, 16, context.pagePad, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey $firstName,',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
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
                            color: theme.colorScheme.onSurface,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Service category chips + grid
              SliverToBoxAdapter(child: _ServiceGrid(trades: trades)),

              // Active requests section
              if (activeJobs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.pagePad, 16, context.pagePad, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Requests',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
                        ),
                        TextButton(
                          onPressed: () => _scrollToMyRequests(),
                          child: Text('${activeJobs.length} active', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(context.pagePad, 8, context.pagePad, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = activeJobs[index];
                        return StaggeredListItem(
                          index: index,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: index == activeJobs.length - 1 ? 0 : 10),
                            child: _ActiveJobCard(job: job, index: index),
                          ),
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
                    padding: EdgeInsets.fromLTRB(context.pagePad, 16, context.pagePad, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            AppPageRoute(builder: (_) => const HomeDetailListView(type: 'history')),
                          ),
                          child: Text('${jobs.length - activeJobs.length} past', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(context.pagePad, 8, context.pagePad, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = pastJobs[index];
                        return StaggeredListItem(
                          index: index,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: index == pastJobs.length - 1 ? 0 : 10),
                            child: _ActiveJobCard(job: job, index: index),
                          ),
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
                    height: 35.h(context),
                    child: EmptyStateWidget(
                      icon: CupertinoIcons.hammer,
                      title: 'No requests yet',
                      message: 'Browse services above to get started with your first request.',
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

  void _showNewRequest(BuildContext context) {
    Navigator.push(context, AppPageRoute(builder: (_) => const NewRequestPage()));
  }

  void _scrollToMyRequests() {
    if (!_scrollController.hasClients) return;
    final target = 460.0; // estimated offset past header + greeting + grid
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target > max ? max : target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ServiceGrid extends StatefulWidget {
  final List<TradeType> trades;
  const _ServiceGrid({required this.trades});

  @override
  State<_ServiceGrid> createState() => _ServiceGridState();
}

class _ServiceGridState extends State<_ServiceGrid> {
  TradeType? _selectedTrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trades = widget.trades;
    final filteredTrades = _selectedTrade == null
        ? trades
        : trades.where((t) => t == _selectedTrade).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.pagePad, 4, context.pagePad, 0),
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
        Padding(
          padding: EdgeInsets.fromLTRB(context.pagePad, 4, context.pagePad, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
              ),
              TextButton(
                onPressed: () => _showNewRequest(context),
                child: Text('See All', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.gridCols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final trade = filteredTrades[index];
              return _ServiceCard(
                trade: trade,
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) => NewRequestPage(initialTrade: trade),
                    ),
                  );
                },
              );
            },
            itemCount: filteredTrades.length,
          ),
        ),
      ],
    );
  }

  void _showNewRequest(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestPage()));
  }
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
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.defaultCurve,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
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
    final gradients = serviceGradients[trade]!;
    final tagline = serviceTaglines[trade]!;
    final price = serviceStartingPrices[trade]!;

    return AnimatedTapScale(
      scaleFactor: 0.95,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background image or fallback gradient
            CachedNetworkImage(
              imageUrl: serviceImages[trade]!,
              memCacheWidth: 360,
              fit: BoxFit.cover,
              fadeInDuration: AppDurations.normal,
              fadeOutDuration: AppDurations.fast,
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

            // 2. Dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 3. Trade Icon in the top-right corner
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(trade.icon, size: 16, color: Colors.white),
              ),
            ),

            // 4. Overlay Text content at the bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trade.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tagline,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'from $price',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 11,
                          color: theme.colorScheme.primary,
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
}

class _ActiveJobCard extends ConsumerWidget {
  const _ActiveJobCard({required this.job, required this.index});
  final MaintenanceJob job;
  final int index;

  String get _dateLabel {
    final dt = job.scheduleDateTime?.formattedShort ?? '';
    if (job.status == JobStatus.completed) return 'Completed $dt';
    if (job.status == JobStatus.cancelled) return 'Cancelled';
    if (job.status == JobStatus.rejected) return 'Rejected';
    return dt;
  }

  String _daysLabel(DateTime now) {
    final dt = job.scheduleDateTime;
    if (dt == null) return '';
    if (job.status == JobStatus.completed || job.status == JobStatus.cancelled || job.status == JobStatus.rejected) {
      final days = now.difference(dt).inDays;
      if (days == 0) return 'Today';
      return '${days}d ago';
    }
    final days = dt.difference(now).inDays;
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
      case JobStatus.quoted: return 'Quoted';
      case JobStatus.assigned: return 'Assigned';
      case JobStatus.onHold: return 'On Hold';
      case JobStatus.rescheduled: return 'Rescheduled';
      case JobStatus.awaitingParts: return 'Awaiting Parts';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = job.status.color(context);
    final now = DateTime.now();

    return Dismissible(
      key: ValueKey('job_${job.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(CupertinoIcons.archivebox, color: statusColor),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Dismiss this request?'),
            content: Text('Archive "${job.tradeType.displayName}" request?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dismiss')),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.showSnackBar('${job.tradeType.displayName} dismissed', type: SnackBarType.success);
      },
      child: AnimatedTapScale(
        scaleFactor: 0.97,
        onTap: () => _openSheet(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'service-icon-${job.id}',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(job.tradeType.icon, size: 17, color: theme.colorScheme.onSurface),
                ),
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
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 10, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        _dateLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _daysLabel(now),
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
                  Navigator.push(context, AppPageRoute(
                    builder: (_) => LiveTrackingView(jobId: job.id, address: job.address),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          : null,
      maxHeight: 0.75,
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
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(job.status.displayName, style: TextStyle(color: job.status.color(context), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Description', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        Text('Address / Location', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.address, style: theme.textTheme.bodyMedium),
        if (job.contactPhone.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Contact Phone', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(CupertinoIcons.phone, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(job.contactPhone, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
        if (job.accessNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Access Instructions', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(CupertinoIcons.lock_fill, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(job.accessNotes, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Scheduled Time', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.scheduleDateTime?.formattedFull ?? '', style: theme.textTheme.bodyMedium),
        if (job.status == JobStatus.waitingApproval) ...[
          CustomerReviewPanel(jobId: job.id),
        ],
        const SizedBox(height: AppSpacing.xxl),
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
