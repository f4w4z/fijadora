import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../services/views/new_request_page.dart';
import '../../../../domain/models/trade_type.dart';

class ApplianceDetailPage extends ConsumerWidget {
  const ApplianceDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.statusText,
    this.statusColor,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String? statusText;
  final Color? statusColor;
  final IconData? icon;

  TradeType _getTradeType() {
    final name = title.toLowerCase();
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
    final isNeedsService = statusText == 'Needs Service';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null)
              Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor?.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText?.toUpperCase() ?? 'ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor ?? Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle.contains('|') ? subtitle.split('|').last.trim() : 'General',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Model Ref: ${subtitle.contains('|') ? subtitle.split('|').first.trim() : subtitle}\nPower consumption: Standard eco-mode\nEnrolled in: SmartHome Diagnostics',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Recent History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  isNeedsService ? 'No recent repairs. Needs checkup.' : 'Last service: 2 months ago (Routine)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ElevatedButton(
              onPressed: () {
                // Automatically open the NewRequestPage directly on top
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NewRequestPage(
                      initialTrade: _getTradeType(),
                      initialDescription: 'Service required for $title:\n'
                          'Model / Info: $subtitle\n'
                          'Current status: $statusText\n'
                          'Please diagnose and resolve.',
                    ),
                  ),
                );

                context.showSnackBar('Pre-filling diagnostic ticket for $title...', type: SnackBarType.info);
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
