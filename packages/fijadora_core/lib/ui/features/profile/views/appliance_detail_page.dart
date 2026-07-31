import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/property.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../services/views/new_request_page.dart';

class ApplianceDetailPage extends ConsumerWidget {
  const ApplianceDetailPage({
    super.key,
    required this.asset,
    required this.roomName,
  });

  final PropertyAsset asset;
  final String roomName;

  TradeType _getTradeType() {
    final name = asset.name.toLowerCase();
    if (name.contains('ac') || name.contains('hvac') || name.contains('air') || name.contains('cool')) {
      return TradeType.acEngineering;
    } else if (name.contains('water') || name.contains('plumb') || name.contains('sink') || name.contains('heater') || name.contains('shower')) {
      return TradeType.plumbing;
    } else if (name.contains('kitchen') || name.contains('cook') || name.contains('stove') || name.contains('oven')) {
      return TradeType.kitchenDesigns;
    }
    return TradeType.electrical;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isNeedsService = asset.status == 'Needs Service';
    final jobsAsync = ref.watch(jobsStreamProvider);
    final assetJobs = jobsAsync.valueOrNull?.where((j) => j.assetId == asset.id).toList() ?? [];
    final lastJob = assetJobs.isNotEmpty ? assetJobs.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isNeedsService ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    asset.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isNeedsService ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  roomName,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Type: ${asset.type.isNotEmpty ? asset.type : 'General'}\n'
              'Location: $roomName\n'
              'Status: ${asset.status}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Recent History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            if (lastJob != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.clock, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Last service: ${lastJob.createdAt.day}/${lastJob.createdAt.month}/${lastJob.createdAt.year} (${lastJob.status.displayName})',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastJob.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(CupertinoIcons.clock, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    isNeedsService ? 'No recent repairs. Needs checkup.' : 'No service history for this appliance.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            if (assetJobs.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${assetJobs.length - 1} more service ${assetJobs.length - 1 == 1 ? 'record' : 'records'} available',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NewRequestPage(
                      initialTrade: _getTradeType(),
                      initialDescription: 'Service required for ${asset.name}:\n'
                          'Located in: $roomName\n'
                          'Current status: ${asset.status}\n'
                          'Please diagnose and resolve.',
                    ),
                  ),
                );

                context.showSnackBar('Pre-filling diagnostic ticket for ${asset.name}...', type: SnackBarType.info);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isNeedsService ? Colors.orange : theme.colorScheme.primary,
                foregroundColor: isNeedsService ? Colors.white : theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isNeedsService ? 'Schedule Diagnostic Check' : 'Book Maintenance',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
