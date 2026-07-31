import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/property.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../services/views/job_details_page.dart';
import 'appliance_detail_page.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../core/theme.dart';
import '../../../shared/utils/date_extensions.dart';

class HomeDetailListView extends ConsumerStatefulWidget {
  const HomeDetailListView({super.key, required this.type, this.property});

  final String type;
  final Property? property;

  @override
  ConsumerState<HomeDetailListView> createState() => _HomeDetailListViewState();
}

class _HomeDetailListViewState extends ConsumerState<HomeDetailListView> {
  // Keeps track of which room index is expanded
  int? _expandedRoomIndex;

  String get _title {
    switch (widget.type) {
      case 'rooms':
        return 'Rooms';
      case 'appliances':
        return 'Appliances';
      case 'history':
        return 'Maintenance History';
      default:
        return 'Details';
    }
  }

  String get _subtitle {
    if (widget.type == 'rooms') {
      final roomCount = widget.property?.units.expand((u) => u.rooms).length ?? 0;
      return '$roomCount spaces configured';
    } else if (widget.type == 'appliances') {
      final rooms = widget.property?.units.expand((u) => u.rooms).toList() ?? [];
      final applianceCount = rooms.expand((r) => r.assets.where((a) => a.type == 'Appliance')).length;
      return '$applianceCount smart assets tracked';
    } else {
      return 'Timeline of your service tickets';
    }
  }

  IconData _roomIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lowerName.contains('bed')) {
      return CupertinoIcons.bed_double_fill;
    } else if (lowerName.contains('living') || lowerName.contains('lounge') || lowerName.contains('hall')) {
      return CupertinoIcons.house_fill;
    } else if (lowerName.contains('bath') || lowerName.contains('toilet') || lowerName.contains('shower')) {
      return CupertinoIcons.drop_fill;
    } else if (lowerName.contains('garden') || lowerName.contains('yard') || lowerName.contains('outdoor')) {
      return CupertinoIcons.leaf_arrow_circlepath;
    }
    return CupertinoIcons.square_grid_2x2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              _subtitle,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildContent(theme, isDark),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (widget.type == 'rooms') {
      return _buildRoomsList(theme, isDark);
    } else if (widget.type == 'appliances') {
      return _buildAppliancesGrid(theme, isDark);
    } else if (widget.type == 'history') {
      return _buildHistoryList(theme, isDark);
    }
    return const Center(child: Text('Invalid Type'));
  }

  // ─── Rooms List ──────────────────────────────────────────────────────────
  Widget _buildRoomsList(ThemeData theme, bool isDark) {
    final rooms = widget.property?.units.expand((u) => u.rooms).toList() ?? [];

    if (rooms.isEmpty) {
      return _buildEmptyState(theme, CupertinoIcons.house, 'No Rooms Configured', 'This property has no rooms added yet.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: rooms.length,
      itemBuilder: (context, idx) {
        final room = rooms[idx];
        final isExpanded = _expandedRoomIndex == idx;
        final roomIcon = _roomIcon(room.name);

        return FadeSlideTransition(
          delay: Duration(milliseconds: idx * 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(roomIcon, color: theme.colorScheme.primary, size: 20),
                  ),
                  title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('${room.assets.length} items tracked', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                  trailing: Icon(
                    isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 16,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedRoomIndex = isExpanded ? null : idx;
                    });
                  },
                ),
                if (isExpanded) ...[
                  const Divider(height: 1),
                  Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: room.assets.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No assets registered in this room.',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          )
                        : Column(
                            children: room.assets.map((asset) {
                              final isAppliance = asset.type == 'Appliance';
                              final isHealthy = asset.status == 'Healthy';
                              
                              return ListTile(
                                dense: true,
                                title: Text(
                                  asset.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: isAppliance ? TextDecoration.underline : null,
                                  ),
                                ),
                                subtitle: Text(
                                  isAppliance ? 'Smart Appliance' : 'Fixture/Fittings',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isHealthy ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    asset.status.toUpperCase(),
                                    style: TextStyle(
                                      color: isHealthy ? Colors.green : Colors.orange,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onTap: isAppliance
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ApplianceDetailPage(
                                                asset: asset,
                                                roomName: room.name,
                                              ),
                                            ),
                                          );
                                        }
                                    : null,
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Appliances Grid ──────────────────────────────────────────────────────
  Widget _buildAppliancesGrid(ThemeData theme, bool isDark) {
    final rooms = widget.property?.units.expand((u) => u.rooms).toList() ?? [];
    final List<MapEntry<Room, PropertyAsset>> appliances = [];

    for (final room in rooms) {
      for (final asset in room.assets) {
        if (asset.type == 'Appliance') {
          appliances.add(MapEntry(room, asset));
        }
      }
    }

    if (appliances.isEmpty) {
      return _buildEmptyState(theme, CupertinoIcons.device_desktop, 'No Appliances Found', 'We haven\'t detected any appliances registered at your property.');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: appliances.length,
      itemBuilder: (context, idx) {
        final room = appliances[idx].key;
        final asset = appliances[idx].value;
        final isHealthy = asset.status == 'Healthy';

        return FadeSlideTransition(
          delay: Duration(milliseconds: idx * 50),
          child: AnimatedTapScale(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApplianceDetailPage(
                    asset: asset,
                    roomName: room.name,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(_roomIcon(room.name), color: theme.colorScheme.primary, size: 24),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isHealthy ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.name,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Maintenance History ──────────────────────────────────────────────────
  Widget _buildHistoryList(ThemeData theme, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final jobsAsync = ref.watch(jobsStreamProvider);

        return jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading history: $err')),
          data: (jobs) {
            // Include completed, rejected, cancelled, and also current active ones if needed,
            // but sorted with newest first. Let's show all historical service tickets.
            if (jobs.isEmpty) {
              return _buildEmptyState(theme, CupertinoIcons.clock, 'No Maintenance History', 'You have not raised any service requests yet.');
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: jobs.length,
              itemBuilder: (context, idx) {
                final job = jobs[idx];
                final statusColor = job.status.color(context);

                return FadeSlideTransition(
                  delay: Duration(milliseconds: idx * 50),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        child: Icon(job.tradeType.icon, color: theme.colorScheme.primary, size: 16),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.tradeType.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              job.status.displayName.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            job.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(CupertinoIcons.calendar, size: 10, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                job.createdAt.formattedDateOnly,
                                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _openSheet(context, job),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openSheet(BuildContext context, MaintenanceJob job) {
    showAppBottomSheet(
      context: context,
      child: _JobHistoryDetailsSheet(job: job),
      maxHeight: 0.75,
    );
  }

  // ─── Empty State Helper ──────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme, IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Job Detail Sheet ──────────────────────────────────────────────
class _JobHistoryDetailsSheet extends ConsumerWidget {
  const _JobHistoryDetailsSheet({required this.job});
  final MaintenanceJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
              child: Text(
                job.status.displayName,
                style: TextStyle(color: job.status.color(context), fontSize: 12, fontWeight: FontWeight.bold),
              ),
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
        Text('Created Date', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(job.createdAt.formattedFull, style: theme.textTheme.bodyMedium),
        if (job.scheduleDateTime != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Scheduled Appointment', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(job.scheduleDateTime!.formattedFull, style: theme.textTheme.bodyMedium),
        ],
        if (job.images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Photos', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: job.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(job.images[index], fit: BoxFit.cover),
                );
              },
            ),
          ),
        ],
        if (job.status == JobStatus.waitingApproval) ...[
          CustomerReviewPanel(jobId: job.id),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
